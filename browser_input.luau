-- The web runtime handles pointer/keyboard input; standard browser gamepads
-- travel through a VM snapshot into the same native gamepad handler.
local B={}
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
