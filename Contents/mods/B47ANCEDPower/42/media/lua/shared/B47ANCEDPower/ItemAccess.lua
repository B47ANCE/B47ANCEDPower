local Access={}
local unpackArgs=unpack or table.unpack
function Access.call(object,method,...)
    if not object or type(method)~="string"then return false,nil end
    local args={...};local ok,fn=pcall(function()return object[method]end)
    if not ok or type(fn)~="function"then return false,nil end
    return pcall(fn,object,unpackArgs(args))
end
local function append(out,list)
    local okIterator,iterator=Access.call(list,"iterator")
    if okIterator and iterator then while true do local okHas,has=Access.call(iterator,"hasNext");if not okHas or not has then break end;local okNext,value=Access.call(iterator,"next");if okNext and value then out[#out+1]=value end end;return end
    local okSize,size=Access.call(list,"size");if not okSize or type(size)~="number"then return end
    for i=0,size-1 do local ok,value=Access.call(list,"get",i);if ok and value then out[#out+1]=value end end
end
function Access.ownsInventoryItem(player,item)
    local okInventory,inventory=Access.call(player,"getInventory");local okOuter,outer=Access.call(item,"getOutermostContainer");local okContainer,container=Access.call(item,"getContainer")
    if not okInventory or not inventory or not okOuter or outer~=inventory or not okContainer or not container then return false end
    local checked,present=Access.call(container,"contains",item);return checked and present==true
end
function Access.inventoryItems(player)
    local out={};local okInventory,inventory=Access.call(player,"getInventory");if not okInventory or not inventory then return out end
    if ArrayList and ArrayList.new then local target=ArrayList.new();local ok,list=Access.call(inventory,"getAllEvalRecurse",function()return true end,target);if ok then append(out,list or target);return out end end
    local ok,list=Access.call(inventory,"getItems");if ok then append(out,list)end;return out
end
function Access.weaponParts(weapon)local out={};local ok,list=Access.call(weapon,"getAllWeaponParts");if ok then append(out,list)end;return out end
function Access.findWeaponForPart(player,part)
    if not part or Access.ownsInventoryItem(player,part)then return nil end
    for _,weapon in ipairs(Access.inventoryItems(player))do
        if Access.ownsInventoryItem(player,weapon)then for _,candidate in ipairs(Access.weaponParts(weapon))do
            if candidate==part then local ok,id=Access.call(part,"getID");if ok and type(id)=="number"and id==id and math.abs(id)<math.huge and id==math.floor(id)then return weapon,id end end
        end end
    end
end
function Access.resolveWeaponPart(player,weapon,id)
    if type(id)~="number"or id~=id or math.abs(id)==math.huge or id~=math.floor(id)or not Access.ownsInventoryItem(player,weapon)then return nil end
    local found=nil;for _,part in ipairs(Access.weaponParts(weapon))do local ok,value=Access.call(part,"getID");if ok and value==id then if found then return nil end;found=part end end;return found
end
function Access.ownsItem(player,item)return Access.ownsInventoryItem(player,item)or Access.findWeaponForPart(player,item)~=nil end
function Access.syncConsumer(player,consumer,parentWeapon)
    if parentWeapon then local fn=rawget(_G,"syncHandWeaponFields");return type(fn)=="function"and pcall(fn,player,parentWeapon)or false end
    local sent=false;for _,name in ipairs({"syncItemModData","syncItemFields","syncItemActivated"})do local fn=rawget(_G,name);if type(fn)=="function"then sent=pcall(fn,player,consumer)or sent end end;return sent
end
return Access
