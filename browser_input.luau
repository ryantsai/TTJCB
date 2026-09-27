-- Browser keyboard and standard gamepads travel through VM snapshots into
-- the same native input handlers. Browser keyboard events need this bridge
-- because the web runtime does not forward them to scripted layouts.
local B={}
function B.decodeKeyboard(snapshot:string,lastSeq:number):({any},number)
    local out:{any}={}
    local newest=lastSeq
    if #snapshot>2048 then return out,newest end
    for _,record in string.split(snapshot,';') do
        local parts=string.split(record,',')
        if #parts~=3 then continue end
        local seq,key=tonumber(parts[1]),tonumber(parts[2])
        local phase=parts[3]
        if seq and key and seq==math.floor(seq) and seq>newest and key==math.floor(key)
            and key>=0 and key<=512 and (phase=='down' or phase=='up' or phase=='repeat') then
            newest=seq
            table.insert(out,{key=key,phase=phase})
        end
    end
    return out,newest
end
function B.decode(snapshot:string):{any}
    local out:{any}={}
    if #snapshot>1024 then return out end
    for _,record in string.split(snapshot,';') do
        if #out>=4 then break end
        local v=string.split(record,',')
        if #v~=4 then continue end
        local id,x,y,mask=tonumber(v[1]),tonumber(v[2]),tonumber(v[3]),tonumber(v[4])
        if id and x and y and mask and id>=0 and id<=31 and id==math.floor(id)
            and x>=-1 and x<=1 and y>=-1 and y<=1 and mask>=0 and mask<=65535 and mask==math.floor(mask) then
            local bits=mask :: number
            local function down(bit:number):boolean return bit32.band(bits,bit32.lshift(1,bit))~=0 end
            table.insert(out,{deviceId=id,isStandardMapping=true,leftStick=Vector.xy(x,y),
                south=down(0),east=down(1),west=down(2),north=down(3),leftShoulder=down(4),rightShoulder=down(5),
                rightTriggerPressed=down(7),rightTrigger=if down(7) then 1 else 0,
                back=down(8),start=down(9),forward=false,
                dpadUp=down(12),dpadDown=down(13),dpadLeft=down(14),dpadRight=down(15)})
        end
    end
    return out
end
return B
