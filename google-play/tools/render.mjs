#!/usr/bin/env node
// Canonical Google Play composition workflow. Copied into each handoff package.
import path from 'node:path';
import fs from 'node:fs/promises';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const args = process.argv.slice(2);
const finalMode = args.includes('--final');
const baseIndex = args.indexOf('--package');
const here = path.dirname(fileURLToPath(import.meta.url));
const base = baseIndex >= 0 ? path.resolve(args[baseIndex + 1]) : path.resolve(here, '..');
const dependencyRoot = process.env.GOOGLE_PLAY_NODE_MODULES;
const require = createRequire(dependencyRoot ? path.join(dependencyRoot, 'package.json') : import.meta.url);
const sharp = require('sharp');
const { chromium } = require('playwright');
const libraryPath = path.resolve(path.dirname(require.resolve('html-to-image')), '../dist/html-to-image.js');
const design = JSON.parse(await fs.readFile(path.join(base, 'design.json'), 'utf8'));
const plan = JSON.parse(await fs.readFile(path.join(base, 'capture-plan.json'), 'utf8'));
const metadata = JSON.parse(await fs.readFile(path.join(base, 'listing/en-US/metadata.json'), 'utf8'));
const outdir = path.join(base, finalMode ? 'screenshots-final' : 'screenshots-draft');
const graphics = path.join(base, 'graphics');

if (finalMode) {
  const provenanceFile = path.join(base, 'source/android/capture-provenance.json');
  let provenance;
  try {
    provenance = JSON.parse(await fs.readFile(provenanceFile, 'utf8'));
  } catch (error) {
    if (error.code !== 'ENOENT') throw error;
    throw new Error('No Android captures are registered. Add real English Android screenshots and source/android/capture-provenance.json before using --final. See README.md.');
  }
  if (provenance.platform !== 'android' || provenance.locale !== 'en-US' || !provenance.build || !provenance.device) {
    throw new Error('Final screenshots require Android/en-US capture provenance, build and device.');
  }
  for (const slide of plan.slides) {
    const file = path.join(base, 'source/android', slide.androidFile);
    const meta = await sharp(file).metadata();
    if (meta.width < 1080 || meta.height < 1080) throw new Error('Android capture must be at least 1080px: ' + file);
  }
}

await fs.mkdir(outdir, { recursive: true });
await fs.mkdir(graphics, { recursive: true });
const font = await uri(path.join(base, 'fonts/Manrope.ttf'), 'font/ttf');
const icon = await uri(path.join(base, design.icon));
const visual = await uri(path.join(base, design.image));
const css = `@font-face{font-family:Manrope;src:url('${font}') format('truetype');font-weight:200 800}*{box-sizing:border-box}html,body{margin:0;padding:0}body{font-family:Manrope,Arial,sans-serif;color:${design.dark}}.canvas{position:relative;overflow:hidden;background:${design.bg}}.brand{display:flex;align-items:center;gap:17px;font-size:27px;font-weight:750;letter-spacing:-.6px}.brand img{width:56px;height:56px;border-radius:12px}.headline{margin:0;font-size:78px;line-height:1.03;font-weight:800;letter-spacing:-3.5px}.screen{position:absolute;overflow:hidden;background:#fff;border-radius:10px;box-shadow:0 18px 55px #091b3026}.screen img{display:block;width:100%;height:100%;object-fit:contain}.hairline{height:1px;background:currentColor;opacity:.14}.feature .brand{font-size:23px}.feature .brand img{width:48px;height:48px}.feature .headline{font-size:53px;line-height:1.1;letter-spacing:-2.4px}.feature{width:1024px;height:500px}.poster{width:1080px;height:1920px}.dark{background:${design.dark};color:#fff}.number{font-size:20px;letter-spacing:2px;opacity:.5}.footer{position:absolute;bottom:20px;left:64px;right:64px;height:1px;background:currentColor;opacity:.13}`;
const brand = `<div class="brand"><img src="${icon}" alt="">${escape(design.brand)}</div>`;

let browser;
try {
  browser = await chromium.launch({ headless: true });
} catch (error) {
  if (!String(error).includes('Executable doesn\'t exist')) throw error;
  browser = await chromium.launch({ channel: 'chrome', headless: true });
}
try {
  const page = await browser.newPage({ viewport: { width: 1200, height: 2050 }, deviceScaleFactor: 1 });
  await sharp(path.join(base, design.icon)).resize(512,512,{fit:'cover'}).ensureAlpha().png().toFile(path.join(graphics,'icon-512.png'));
  const isRental = design.brand === 'Rental Report';
  const feature = isRental
    ? `<div id="capture" class="canvas feature"><img src="${visual}" style="position:absolute;inset:0;width:100%;height:100%;object-fit:cover" alt=""><div style="position:absolute;inset:0;background:linear-gradient(90deg,${design.dark} 0%,${design.dark}f0 40%,${design.dark}00 100%)"></div><div style="position:absolute;left:64px;top:76px;color:white">${brand}<h1 class="headline" style="margin-top:46px">${lines(design.tagline)}</h1></div></div>`
    : `<div id="capture" class="canvas feature"><div style="position:absolute;left:64px;top:76px;width:580px">${brand}<h1 class="headline" style="margin-top:46px">${lines(design.tagline)}</h1><div class="hairline" style="margin-top:36px;width:340px"></div></div><img src="${visual}" alt="" style="position:absolute;right:37px;top:63px;width:310px;height:360px;object-fit:contain"></div>`;
  await exportHtml(page, feature,1024,500,path.join(graphics,'feature-graphic-1024x500.png'));
  const evidence=[];
  for (let i=0;i<plan.slides.length;i++) {
    const slide=plan.slides[i];
    const source=path.join(base,finalMode?'source/android':'source/ios-reference',slide.androidFile);
    let input=sharp(source);const original=await input.metadata();
    let w=original.width,h=original.height;
    // Remove iOS system chrome from a clearly labelled reference draft only.
    if (!finalMode) {
      const top=Math.round(w*.12),bottom=Math.round(w*.065);
      h-=top+bottom;input=input.extract({left:0,top,width:w,height:h});
    }
    const buffer=await input.flatten({background:'#ffffff'}).png().toBuffer();
    const image='data:image/png;base64,'+buffer.toString('base64');
    const imageHeight=Math.min(1530,1520);
    const imageWidth=Math.min(944,Math.round(imageHeight*w/h));
    const actualHeight=Math.round(imageWidth*h/w);
    const dark=i===3;
    const aligned=i%3===1;
    const left=aligned?70:Math.round((1080-imageWidth)/2);
    const html=`<div id="capture" class="canvas poster ${dark?'dark':''}"><header style="position:absolute;left:64px;right:64px;top:48px;display:flex;justify-content:space-between;align-items:center">${brand}<span class="number">${String(i+1).padStart(2,'0')}</span></header><h1 class="headline" style="position:absolute;left:64px;top:138px;max-width:952px">${lines(slide.headline)}</h1><div class="hairline" style="position:absolute;left:64px;right:64px;top:324px"></div><div class="screen" style="left:${left}px;top:355px;width:${imageWidth}px;height:${actualHeight}px"><img src="${image}" alt="${escape(slide.altText)}"></div><div class="footer"></div></div>`;
    const file=path.join(outdir,slide.id+'-1080x1920.png');
    await exportHtml(page,html,1080,1920,file);
    evidence.push({file:path.relative(base,file),source:path.relative(base,source),sourcePlatform:finalMode?'android':'ios-reference',locale:finalMode?'en-US':metadata.title.startsWith('Rental')?'en-US':'zh-CN',headline:slide.headline,width:1080,height:1920,status:finalMode?'android-capture-review-required':'draft-not-for-upload'});
  }
  const thumbs=[];for(let i=0;i<evidence.length;i++)thumbs.push({input:await sharp(path.join(base,evidence[i].file)).resize(216,384).toBuffer(),left:i*216,top:0});
  await sharp({create:{width:216*thumbs.length,height:384,channels:3,background:'#dfe5ea'}}).composite(thumbs).png().toFile(path.join(base,finalMode?'contact-sheet-final.png':'contact-sheet-draft.png'));
  await fs.writeFile(path.join(base,finalMode?'screenshots-final-manifest.json':'screenshots-draft-manifest.json'),JSON.stringify(evidence,null,2)+'\n');
  const rows=await validate(evidence);
  const report={checkedAt:new Date().toISOString(),mode:finalMode?'android':'ios-reference-draft',listingLengths:{title:metadata.title.length,shortDescription:metadata.shortDescription.length,fullDescription:metadata.fullDescription.length},files:rows,remaining:metadata.codeReviewIssues};
  await fs.writeFile(path.join(base,'verification-report.json'),JSON.stringify(report,null,2)+'\n');
  await writePreview(evidence);
  console.log(JSON.stringify({app:design.brand,mode:report.mode,screenshots:evidence.length,verifiedFiles:rows.length,output:base}));
} finally { await browser.close(); }

function escape(s){return String(s).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;');}
function lines(s){return s.split('\n').map(escape).join('<br>');}
async function uri(file,type='image/png'){return 'data:'+type+';base64,'+(await fs.readFile(file)).toString('base64');}
async function exportHtml(page,markup,width,height,file){
  await page.setContent(`<!doctype html><html lang="en"><head><meta charset="utf-8"><style>${css}</style></head><body>${markup}</body></html>`);
  await page.addScriptTag({path:libraryPath});
  await page.evaluate(async()=>{await document.fonts.ready;await Promise.all(Array.from(document.images).map(i=>i.decode()));});
  const problems=await page.evaluate(()=>{const root=document.querySelector('#capture');const r=root.getBoundingClientRect();return Array.from(root.querySelectorAll('.headline,.brand')).filter(e=>{const b=e.getBoundingClientRect();return b.left<r.left||b.right>r.right||b.top<r.top||b.bottom>r.bottom||e.scrollWidth>e.clientWidth+2;}).map(e=>e.textContent);});
  if(problems.length)throw new Error('Text overflow: '+problems.join(', '));
  const encoded=await page.evaluate(async({width,height})=>{const e=document.querySelector('#capture');const options={width,height,pixelRatio:1,cacheBust:false};await window.htmlToImage.toPng(e,options);return await window.htmlToImage.toPng(e,options);},{width,height});
  await sharp(Buffer.from(encoded.split(',')[1],'base64')).flatten({background:design.bg}).removeAlpha().png().toFile(file);
}
async function validate(evidence){
  if(metadata.title.length>30||metadata.shortDescription.length>80||metadata.fullDescription.length>4000)throw new Error('Listing exceeds Google Play limits');
  const targets=[['graphics/icon-512.png',512,512,true],['graphics/feature-graphic-1024x500.png',1024,500,false],...evidence.map(x=>[x.file,1080,1920,false])];
  const report=[];for(const[file,w,h,alpha]of targets){const full=path.join(base,file);const m=await sharp(full).metadata();const stats=await sharp(full).stats();const size=(await fs.stat(full)).size;if(m.width!==w||m.height!==h||m.hasAlpha!==alpha||stats.channels.every(x=>x.stdev<1))throw new Error('Invalid/blank asset: '+file);if(alpha&&size>1024*1024)throw new Error('Icon exceeds 1MB');report.push({file,width:m.width,height:m.height,channels:m.channels,alpha:m.hasAlpha,bytes:size,nonBlank:true});}return report;
}
async function writePreview(evidence){
  const screenshots=evidence.map(s=>`<figure><img src="${escape(s.file)}" alt="${escape(s.headline.replaceAll('\n',' '))}"><figcaption>${escape(s.headline.replaceAll('\n',' '))}</figcaption></figure>`).join('');
  const status=finalMode?'Android screenshots rendered. Check them against the release build before upload.':'SCREENSHOT DRAFTS — real iOS references; replace with Android English captures before upload.';
  const html=`<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${escape(design.brand)} · Google Play assets</title><style>body{font:16px/1.6 system-ui;margin:40px auto;padding:0 24px;max-width:1300px;background:#f4f6f8;color:#152d43}h1{font-size:38px;line-height:1.15}.notice{padding:16px 20px;background:#fff4d6;border-left:4px solid #c58c1a}.feature{width:min(100%,1024px)}.icon{width:112px;height:112px}.gallery{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:18px;margin:28px 0}figure{margin:0}figure img{width:100%;border:1px solid #ddd}figcaption{font-size:13px}pre{white-space:pre-wrap;font:inherit;padding:20px;background:white}h2{margin-top:36px}.issues{background:#fff;padding:20px}</style><h1>${escape(design.brand)}</h1><p>Google Play · English (United States)</p><p class="notice">${status}</p><h2>Store icon and feature graphic</h2><img class="icon" src="graphics/icon-512.png" alt="Store icon"><p><img class="feature" src="graphics/feature-graphic-1024x500.png" alt="${escape(design.tagline.replaceAll('\n',' '))}"></p><h2>Screenshot story</h2><div class="gallery">${screenshots}</div><h2>Listing text</h2><p><strong>${escape(metadata.title)}</strong></p><p>${escape(metadata.shortDescription)}</p><pre>${escape(metadata.fullDescription)}</pre><h2>Before submission</h2><ul class="issues">${metadata.codeReviewIssues.map(s=>'<li>'+escape(s)+'</li>').join('')}</ul><p><a href="README.md">Package instructions</a> · <a href="verification-report.json">Verification report</a></p></html>`;
  await fs.writeFile(path.join(base,'preview.html'),html);
}
