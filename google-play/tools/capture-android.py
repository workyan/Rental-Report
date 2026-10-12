#!/usr/bin/env python3
"""Capture real Android UI, and preserve source/build provenance."""
from pathlib import Path
import subprocess, sys, json, time, hashlib, struct, datetime, re

root=Path(sys.argv[1]).resolve()
package=root/'google-play'
plan=json.loads((package/'capture-plan.json').read_text())
design=json.loads((package/'design.json').read_text())
app=design['applicationId']
apk=root/'build/app/outputs/flutter-apk/app-debug.apk'
if not apk.exists():raise SystemExit('Build the English Android debug APK before capture.')
def adb(*args,check=True):
 r=subprocess.run(['adb',*args],capture_output=True,check=check)
 return r.stdout

adb('wait-for-device')
if adb('shell','getprop','sys.boot_completed').strip()!=b'1':raise SystemExit('Android emulator is not booted.')
adb('install','-r',str(apk))
adb('shell','settings','put','system','screen_off_timeout','2147483647')
adb('shell','svc','power','stayon','true')
adb('shell','settings','put','global','sysui_demo_allowed','1')
adb('shell','am','broadcast','-a','com.android.systemui.demo','-e','command','enter',check=False)
adb('shell','am','broadcast','-a','com.android.systemui.demo','-e','command','clock','-e','hhmm','0941',check=False)
adb('shell','am','broadcast','-a','com.android.systemui.demo','-e','command','battery','-e','level','100','-e','plugged','false',check=False)
adb('shell','am','broadcast','-a','com.android.systemui.demo','-e','command','network','-e','wifi','show','-e','level','4',check=False)
dest=package/'source/android';dest.mkdir(exist_ok=True,parents=True)
captured=[]
for slide in plan['slides']:
 adb('shell','am','force-stop',app)
 adb('logcat','-c')
 adb('shell','am','start','-W','-f','0x10008000','-n',app+'/.MainActivity','--ez','APP_STORE_SCREENSHOT_MODE','true','--es','APP_STORE_SCREENSHOT_SCENE',slide['scene'])
 time.sleep(10)
 if slide.get('scrollPixels'):
  amount=int(slide['scrollPixels'])
  adb('shell','input','swipe','540','1450','540',str(1450-amount),'650')
  time.sleep(2)
 windows=adb('shell','dumpsys','window').decode(errors='replace')
 focus=[line for line in windows.splitlines() if 'mCurrentFocus=' in line]
 if not any(app+'/' in line for line in focus):raise RuntimeError('App is not in the foreground: '+str(focus))
 png=adb('exec-out','screencap','-p')
 if png[:8]!=b'\x89PNG\r\n\x1a\n':raise RuntimeError('Invalid screenshot')
 width,height=struct.unpack('>II',png[16:24])
 path=dest/slide['androidFile'];path.write_bytes(png)
 logs=adb('logcat','-d','-s','flutter:E','AndroidRuntime:E').decode(errors='replace')
 (dest/(slide['id']+'-runtime.log')).write_text(logs)
 if any(s in logs for s in ['A RenderFlex overflowed','EXCEPTION CAUGHT','FATAL EXCEPTION']):
  raise RuntimeError('Runtime issue in '+slide['scene']+'; inspect '+str(path))
 captured.append({'id':slide['id'],'scene':slide['scene'],'file':slide['androidFile'],'scrollPixels':slide.get('scrollPixels',0),'scrollTarget':slide.get('scrollTarget'),'width':width,'height':height,'sha256':hashlib.sha256(png).hexdigest(),'runtimeErrorLogEmpty':not logs.strip(),'foregroundActivityConfirmed':True})
 print(app,slide['scene'],width,height,flush=True)
version=re.search(r'^version:\s*(\S+)',(root/'pubspec.yaml').read_text(),re.M).group(1)
provenance={'platform':'android','locale':'en-US','build':version+' (debug capture of actual app UI)','device':'Android API 35 ARM64 emulator; 1080×1920, density 320','applicationId':app,'apkSha256':hashlib.sha256(apk.read_bytes()).hexdigest(),'capturedAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'commitBeforeChanges':subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),'captureBridge':'Native debug-only intent extras; real widgets with deterministic sample data','slides':captured}
(dest/'capture-provenance.json').write_text(json.dumps(provenance,indent=2,ensure_ascii=False)+'\n')
print('Captured',len(captured),'real Android screens for',app,flush=True)
