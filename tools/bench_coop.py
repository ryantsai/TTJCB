#!/usr/bin/env python3
"""Reproducible native Rive draw workload; no browser or gameplay timing claims.

Copies the current game into build/<name>, with four Titans, twelve enemies,
sixteen impact effects and two speech bubbles. Animation follows the same
clock on every run, independent of combat balance or hit-pause changes.
"""
import argparse
from pathlib import Path
import shutil
import subprocess

SCENE = r'''
local Game=require('game')
local R=require('remarks')
local P=require('pose')
local G=require('gfx')
local function step(app:any,n:number) for _=1,n do app.advance(app,1/60) end end
local function press(app:any,key:number)
    app.keyboardEvent(app,{key=key,phase='down'});step(app,1)
    app.keyboardEvent(app,{key=key,phase='up'});step(app,1)
end
return function(context:Context):Layout<Game.Main>
    local app:any=Game.create(context)
    press(app,257);press(app,257);press(app,257);step(app,90)
    press(app,344)
    for id=0,1 do
        app.gamepadEvent(app,{deviceId=id,isStandardMapping=true,leftStick=Vector.xy(0,0),
            dpadLeft=false,dpadRight=false,dpadUp=false,dpadDown=false,south=false,east=false,
            west=false,north=false,rightShoulder=false,rightTriggerPressed=false,rightTrigger=0,
            start=true,forward=false,back=false});step(app,1)
    end
    local g=app.g
    g.locale='BENCH_LOCALE';g.t=0;g.bannerT=0;g.goT=0;g.shake=0;g.camX=0
    g.pending={};g.shots={};g.fx={};g.pickups={};g.fighters={};g.lockX=0
    for i,s in g.slots do
        local f=s.fighter
        f.x=185+(i-1)*295;f.y=672;f.z=0;f.state='attack';f.invuln=0
        f.flash=0;f.pose=P.new();f.voice=R.new(f.id*37)
        f.pose.move=1;f.pose.style=f.kind;f.pose.ext=1;f.pose.active=true
        s.score=12000+i*125;s.energy=100
        table.insert(g.fighters,f)
    end
    for _,i in {1,4} do
        local f=g.slots[i].fighter
        R.offer(f.voice,f.kind,if i==1 then 'encounter' else 'hurt')
        f.voice.age=1
    end
    for i=1,12 do
        local e=table.clone(g.slots[1].fighter)
        e.id=80+i;e.team=2;e.hero=0;e.slot=0
        e.kind=if i%3==0 then 'heavy' else 'bot'
        e.x=130+((i-1)%4)*315;e.y=505+math.floor((i-1)/4)*55
        e.scale=if i%3==0 then 1.5 else 1.35;e.voice=R.new(i)
        e.facing=-1;e.pose=P.new();e.pose.flip=-1;e.pose.move=6;e.pose.ext=.7
        e.hitT=0;e.hp=45;e.maxHp=100
        table.insert(g.fighters,e)
        table.insert(g.fx,{kind='spark',x=e.x-25,y=e.y,z=80,t=i*.013,life=.28,
            text='',color=G.hex(0xFFE14D),size=1})
    end
    for i=1,4 do
        table.insert(g.fx,{kind='word',x=140+(i-1)*300,y=640,z=150,t=.1,life=.7,
            text='POW!',color=G.hex(0xFFE14D),size=30})
    end
    app.advance=function(self:any,dt:number):boolean
        g.t+=1/60
        for _,f in g.fighters do
            f.pose.t=g.t+f.id*.37;f.pose.phase=g.t*8
            f.pose.ext=.65+.35*math.sin(g.t*8+f.id)
            f.pose.stroke=(g.t+f.id*.1)%.3/.3
        end
        for _,e in g.fx do e.t=(e.t+1/60)%e.life end
        return true
    end
    return app
end
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--name', default='coop-perf')
    parser.add_argument('--locale', choices=['en', 'zh-TW'], default='en')
    parser.add_argument('--frames', type=int, default=1200)
    parser.add_argument('--runs', type=int, default=3)
    parser.add_argument('--prepare-only', action='store_true')
    args = parser.parse_args()
    if Path(args.name).name != args.name or args.name in ('.', '..'):
        parser.error('--name must be a directory name')
    root = Path(__file__).resolve().parent.parent
    target = root / 'build' / args.name
    target.mkdir(parents=True, exist_ok=True)
    for source in root.glob('*.luau'):
        if source.name != 'main.luau' and not source.name.endswith('_test.luau'):
            shutil.copy2(source, target / source.name)
    (target / 'main.luau').write_text(SCENE.replace('BENCH_LOCALE', args.locale))
    (target / 'rive.yaml').write_text(
        'name: coop_perf\nmain: main\nartboard:\n  width: 1280\n  height: 720\n')
    for command in (['rive', '.', '--verify'], ['rive', 'inspect', '.', '--summary']):
        subprocess.run(command, cwd=target, check=True)
    if not args.prepare_only:
        for i in range(args.runs):
            run = subprocess.run(['rive', '.', f'--bench={args.frames}'], cwd=target,
                                 text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                 check=True)
            (target / f'bench-{i+1}.log').write_text(run.stdout)
            print(run.stdout, end='')
    print(f'Scene: {target}')


if __name__ == '__main__':
    main()
