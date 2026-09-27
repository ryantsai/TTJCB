-- Linear campaign progress. Persistence is supplied by the browser host via the VM.
local P={}
P.levels=4
export type State={cleared:number,revision:number,status:string}
export type Bridge={count:Property<number>?,ready:Property<boolean>?,revision:Property<number>?,
    status:Property<string>?,loaded:boolean,lastCount:number,lastRevision:number}

function P.valid(value:number):number
    if value~=value or value<0 or value>P.levels or value~=math.floor(value) then return 0 end
    return value
end
function P.new():State return {cleared=0,revision=0,status='session'} end
function P.unlocked(s:State):number return math.min(P.levels,s.cleared+1) end
function P.canPlay(s:State,level:number):boolean
    return level>=1 and level<=P.unlocked(s) and level==math.floor(level)
end
function P.complete(s:State,level:number):boolean
    if not P.canPlay(s,level) or level<=s.cleared then return false end
    s.cleared=level;s.revision+=1
    return true
end
function P.reset(s:State)
    s.cleared=0;s.revision+=1
end
function P.bridge(context:Context?):Bridge
    local b:Bridge={count=nil,ready=nil,revision=nil,status=nil,loaded=false,lastCount=0,lastRevision=0}
    if context then
        local vm=context:viewModel()
        if vm then
            b.count=vm:getNumber('completedLevels');b.ready=vm:getBoolean('progressReady')
            b.revision=vm:getNumber('progressRevision');b.status=vm:getString('progressStatus')
        end
    end
    return b
end
-- Hydration and cross-tab changes are read before simulation; local mutations
-- are published afterward, so the initial zero can never erase an existing save.
function P.pull(s:State,b:Bridge):boolean
    local count,ready=b.count,b.ready
    if not count or not ready or not ready.value then return false end
    local changed=not b.loaded or count.value~=b.lastCount
    if changed then
        s.cleared=P.valid(count.value)
        b.lastCount=count.value;b.lastRevision=s.revision;b.loaded=true
    end
    if b.status then s.status=b.status.value end
    return changed
end
function P.push(s:State,b:Bridge)
    if not b.loaded or s.revision==b.lastRevision then return end
    local count,revision=b.count,b.revision
    if count and revision then
        count.value=s.cleared;b.lastCount=s.cleared
        revision.value+=1;b.lastRevision=s.revision
    end
end
return P
