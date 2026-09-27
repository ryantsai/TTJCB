#!/usr/bin/env python3
"""Render a reproducible campaign review scene using the native Rive renderer.
The temporary scene uses a local in-memory save and never changes browser saves.
"""
import argparse
from pathlib import Path
import shutil
import subprocess

SCENE = r'''
local Game=require('game')
local C=require('campaign')
local function step(a:any,n:number) for _=1,n do a.advance(a,1/60) end end
local function press(a:any,k:number)
    a.keyboardEvent(a,{key=k,phase='down'});step(a,1)
    a.keyboardEvent(a,{key=k,phase='up'});step(a,1)
end
return function(context:Context):Layout<Game.Main>
    local a:any=Game.create(context)
    a.g.tutorialSeen=true;a.g.progress.cleared=8;a.g.locale='LOCALE'
    press(a,257);a.g.selectedLevel=STAGE
    press(a,257);press(a,257);press(a,257);step(a,100)
    local g=a.g;local h=g.slots[1].fighter
    g.cp=(STAGE-1)*4+WAVE;g.lockX=-1;g.camX=C.checkpoints[g.cp].x
    g.fighters={h};g.shots={};g.pending={};h.x=g.camX+430;h.y=600;h.invuln=10000
    step(a,1);g.waveT=100;step(a,1);step(a,160)
    g.waveT=HAZARD;g.bannerT=0;g.shake=0;h.invuln=0;h.voice.time=0
    for i,f in g.fighters do
        if f.team==2 and f.kind~='trigon' then f.x=g.camX+650+(i%3)*160;f.y=500+(i%3)*65 end
    end
    if MAP then g.mode='map';g.selectedLevel=STAGE end
    a.advance=function(self:any,dt:number):boolean return true end
    return a
end
'''

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--stage',type=int,choices=range(1,9),default=8)
    parser.add_argument('--wave',type=int,choices=range(1,5),default=4)
    parser.add_argument('--hazard',type=float,default=5)
    parser.add_argument('--locale',choices=['en','zh-TW'],default='en')
    parser.add_argument('--map',action='store_true')
    args=parser.parse_args()
    root=Path(__file__).resolve().parents[1]
    name=f'campaign-{args.stage}-'+('map' if args.map else 'play')+'-'+args.locale
    target=root/'build'/name;target.mkdir(parents=True,exist_ok=True)
    for source in root.glob('*.luau'):
        if source.name!='main.luau' and not source.name.endswith('_test.luau'):
            shutil.copy2(source,target/source.name)
    markup='\n'.join(line for line in (root/'scene.rml').read_text().splitlines() if '_test.luau' not in line)
    (target/'scene.rml').write_text(markup)
    scene=SCENE.replace('LOCALE',args.locale).replace('STAGE',str(args.stage)).replace('WAVE',str(args.wave)).replace('HAZARD',str(args.hazard)).replace('MAP',str(args.map).lower())
    (target/'main.luau').write_text(scene)
    (target/'rive.yaml').write_text(f'name: {name}\nmain: main\nartboard:\n  width: 1280\n  height: 720\n')
    for command in [['rive','.', '--verify'],['rive','inspect','.', '--summary'],['rive','.', '--screenshot','--advance=1']]:
        result=subprocess.run(command,cwd=target,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
        if result.returncode: raise RuntimeError(result.stdout)
        if 'error' in result.stdout.lower() and '0 errors' not in result.stdout.lower(): print(result.stdout)
    print(target/'build'/f'{name}.png')
if __name__=='__main__': main()
