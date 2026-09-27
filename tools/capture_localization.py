#!/usr/bin/env python3
"""Capture native localized menus without modifying the live game or browser saves."""
import argparse
from pathlib import Path
import shutil
import subprocess

SCENE = r'''
local Game=require('game')
local function step(a:any,n:number) for _=1,n do a.advance(a,1/60) end end
local function press(a:any,k:number)
    a.keyboardEvent(a,{key=k,phase='down'});step(a,1)
    a.keyboardEvent(a,{key=k,phase='up'});step(a,1)
end
return function(context:Context):Layout<Game.Main>
    local a:any=Game.create(context)
    a.g.locale='LOCALE';a.g.progress.cleared=8
    if 'SCREEN'=='tutorial' then press(a,72)
    elseif 'SCREEN'~='title' then
        a.g.tutorialSeen=true;press(a,257)
        if 'SCREEN'=='reset' then press(a,82)
        elseif 'SCREEN'~='map' then
            press(a,257)
            -- Show the longest hero/ability labels in the joined slot.
            a.g.slots[1].hero=3
            if 'SCREEN'~='select' then
                press(a,257);press(a,257);step(a,100)
                if 'SCREEN'=='paused' then a.g.paused=true
                elseif 'SCREEN'=='win' or 'SCREEN'=='over' then a.g.mode='SCREEN';a.g.modeT=2 end
            end
        end
    end
    a.g.t=0;a.g.locale='LOCALE'
    -- These captures use in-memory state; do not hydrate the default browser VM.
    a.init=function(self:any,ctx:any):boolean return true end
    a.advance=function(self:any,dt:number):boolean return true end
    return a
end
'''

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--locale',choices=['en','zh-TW','ja'],default='ja')
    parser.add_argument('--screen',choices=['title','tutorial','map','reset','select','play','paused','win','over'],default='title')
    args=parser.parse_args()
    root=Path(__file__).resolve().parents[1]
    name=f'localization-{args.locale}-{args.screen}'
    target=root/'build'/name;target.mkdir(parents=True,exist_ok=True)
    for source in root.glob('*.luau'):
        if source.name!='main.luau' and not source.name.endswith('_test.luau'):
            shutil.copy2(source,target/source.name)
    (target/'scene.rml').write_text('\n'.join(line for line in (root/'scene.rml').read_text().splitlines() if '_test.luau' not in line))
    (target/'main.luau').write_text(SCENE.replace('LOCALE',args.locale).replace('SCREEN',args.screen))
    (target/'rive.yaml').write_text(f'name: {name}\nmain: main\nartboard:\n  width: 1280\n  height: 720\n')
    for command in [['rive','.', '--verify'],['rive','inspect','.', '--summary'],['rive','.', '--screenshot','--advance=1']]:
        result=subprocess.run(command,cwd=target,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
        if result.returncode: raise RuntimeError(result.stdout)
    print(target/'build'/f'{name}.png')
if __name__=='__main__': main()
