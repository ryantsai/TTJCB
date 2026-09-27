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
local B=require('boss_patterns')
local R=require('remarks')
local F=require('level_features')
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
    g.locale='LOCALE'
    if EQUIPMENT and F.defs[STAGE] then g.pickups={{x=g.camX+540,y=610,t=0,dead=false,kind=F.defs[STAGE].kind}} end
    if SIGNATURE and g.boss then
        local b=g.boss;b.x=g.camX+950;b.y=590;b.state='signature';b.st=PATTERN_TIME;b.hitPause=0
        b.pattern=B.new(b.kind,b.x,b.y,g.camX+520,575,g.camX);b.pattern.t=PATTERN_TIME
        b.voice=R.new(10);R.offer(b.voice,b.kind,'special');b.voice.age=1
        h.x=g.camX+160
        -- Resolve the signature pose through the real game update before freezing.
        step(a,1);g.shake=0
    end
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
    parser.add_argument('--signature',action='store_true')
    parser.add_argument('--equipment',action='store_true')
    parser.add_argument('--pattern-time',type=float,default=.6)
    args=parser.parse_args()
    root=Path(__file__).resolve().parents[1]
    name=f'campaign-{args.stage}-'+('map' if args.map else 'play')+'-'+args.locale
    if args.signature:name+='-signature'
    if args.equipment:name+='-equipment'
    target=root/'build'/name;target.mkdir(parents=True,exist_ok=True)
    for source in root.glob('*.luau'):
        if source.name!='main.luau' and not source.name.endswith('_test.luau'):
            shutil.copy2(source,target/source.name)
    markup='\n'.join(line for line in (root/'scene.rml').read_text().splitlines() if '_test.luau' not in line)
    (target/'scene.rml').write_text(markup)
    scene=SCENE.replace('LOCALE',args.locale).replace('STAGE',str(args.stage)).replace('WAVE',str(args.wave)).replace('HAZARD',str(args.hazard)).replace('MAP',str(args.map).lower()).replace('SIGNATURE',str(args.signature).lower()).replace('EQUIPMENT',str(args.equipment).lower()).replace('PATTERN_TIME',str(args.pattern_time))
    (target/'main.luau').write_text(scene)
    (target/'rive.yaml').write_text(f'name: {name}\nmain: main\nartboard:\n  width: 1280\n  height: 720\n')
    for command in [['rive','.', '--verify'],['rive','inspect','.', '--summary'],['rive','.', '--screenshot','--advance=1']]:
        result=subprocess.run(command,cwd=target,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
        if result.returncode: raise RuntimeError(result.stdout)
        if 'error' in result.stdout.lower() and '0 errors' not in result.stdout.lower(): print(result.stdout)
    print(target/'build'/f'{name}.png')
if __name__=='__main__': main()
