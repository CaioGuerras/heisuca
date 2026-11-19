#!/usr/bin/env python3
"""Capture the real Wayland output composed by Weston inside the CI's Xvfb."""
import argparse,json,os,pathlib,subprocess,time
from PIL import ImageGrab,ImageChops
p=argparse.ArgumentParser();p.add_argument('--binary',required=True);p.add_argument('--output',type=pathlib.Path,required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
exe=pathlib.Path(a.binary).resolve();fixture=pathlib.Path('test/desktop/fixtures/ação teste.mkv').resolve()
for state,args in [('home',[]),('video',[str(fixture)])]:
 with (a.output/(state+'.log')).open('w') as log:
  proc=subprocess.Popen([str(exe),*args],stdout=log,stderr=log,env={**os.environ,"WAYLAND_DEBUG":"client","HEISUCA_VIDEO_DIAGNOSTIC":"1"})
  try:
   time.sleep(7);assert proc.poll() is None,'App exited before capture'
   first=ImageGrab.grab(xdisplay=os.environ['DISPLAY']);first.save(a.output/(state+'-01.png'))
   if state=='video':
    time.sleep(2);second=ImageGrab.grab(xdisplay=os.environ['DISPLAY']);second.save(a.output/'video-02.png')
    box=(320,250,960,600);area=second.crop(box).convert('RGB');diff=ImageChops.difference(first.crop(box).convert('RGB'),area)
    colorful=sum(max(c)-min(c)>80 for c in area.getdata());changed=sum(max(c)>30 for c in diff.getdata())
    assert colorful>5000,('video not visibly rendered',colorful)
    assert changed>2000,('video did not visibly advance',changed)
    (a.output/'evidence.json').write_text(json.dumps({'nativeWayland':True,'compositor':'Weston nested in Xvfb','colorful':colorful,'changed':changed,'physicalAudioCertified':False,'physicalGpuCertified':False},indent=2))
  finally:
   proc.terminate()
   try:proc.wait(timeout=8)
   except subprocess.TimeoutExpired:proc.kill();proc.wait()
