#!/usr/bin/env python3
"""Verify a portable Google Play handoff using only Python's standard library."""
from pathlib import Path
import json, sys, hashlib, struct

root = Path(sys.argv[1]).resolve()
package = root / 'google-play'
read = lambda file: json.loads((package / file).read_text())
sha = lambda file: hashlib.sha256(file.read_bytes()).hexdigest()
plan = read('capture-plan.json')
design = read('design.json')
metadata = read('listing/en-US/metadata.json')
provenance = read('source/android/capture-provenance.json')
manifest = read('screenshots-final-manifest.json')
assert provenance['platform'] == 'android' and provenance['locale'] == 'en-US'
assert metadata['applicationId'] == design['applicationId'] == provenance['applicationId']
assert len(plan['slides']) == len(manifest) == len(provenance['slides']) == 6

for key, file, limit in [('title','title.txt',30),('shortDescription','short-description.txt',80),('fullDescription','full-description.txt',4000)]:
 assert (package/'listing/en-US'/file).read_text().strip() == metadata[key].strip()
 assert 0 < len(metadata[key]) <= limit

def check_png(file, width, height, color):
 b = file.read_bytes()
 assert b[:8] == b'\x89PNG\r\n\x1a\n', file
 w, h, depth, kind, _, _, _ = struct.unpack('>IIBBBBB', b[16:29])
 assert (w, h, depth, kind) == (width, height, 8, color), file

check_png(package/'graphics/icon-512.png',512,512,6)
assert (package/'graphics/icon-512.png').stat().st_size <= 1024*1024
check_png(package/'graphics/feature-graphic-1024x500.png',1024,500,2)
for slide, capture, export in zip(plan['slides'], provenance['slides'], manifest):
 assert slide['id'] == capture['id'] and slide['scene'] == capture['scene']
 assert capture['file'] == slide['androidFile']
 assert capture['runtimeErrorLogEmpty'] and capture['foregroundActivityConfirmed']
 raw = package/'source/android'/slide['androidFile']
 assert sha(raw) == capture['sha256'], raw
 assert export['sourcePlatform'] == 'android' and export['locale'] == 'en-US'
 check_png(package/export['file'],1080,1920,2)

for file, expected in read('source-audit.json')['sourceFiles'].items():
 assert sha(root/file) == expected, 'Source changed since review: '+file
for file, expected in read('quality-review.json')['assetSha256'].items():
 assert sha(package/file) == expected, 'Asset changed since review: '+file

print(json.dumps({'applicationId':design['applicationId'],'screenshots':6,'assetFormatsAndHashes':'passed','sourceHashes':'passed','listingLimits':'passed'}))
