-- TPP Military Mode ][ command script
-- For Emerald and Emerald-based binary hacks
-- Commands: 
--  MOVE    - Selects moves 1-4
--  SWITCH  - Selects pokemon 1-6
--  ITEM    - Selects item by id (if present in bag and applicable to battle)
--  WITH    - Selects pokemon 1-6 from use item menu
--  CATCH   - Throws the currently selected ball
--  RUN     - Runs from battle


-- not used
--  ITEM    - Selects item pocket slot 1-n
--  THROW   - Selects pokeball pocket slot 1-n
--  BERRY   - Selects berry pocket slot 1-n
--  TEACH   - Selects tm/hm pocket slot 1-n (won't be used)
--  KEY     - Selects key items pocket slot 1-n (won't be used)
--  REUSE   - Opens Bag and selects whatever cursor is on

-- EWRAM Address notes
-- 0x002E30: contest move selection 0-3
-- 0x0040D6: Out-of-battle Movelearn Cursor
-- 0x005664: Double battle first mon target selection: 6, 4 if active
-- 0x00567C: Double battle second mon target selection: 6, 4 if active
-- 0x00E7FA(Wrong): Pokemon summary screen: 0, 1 if open
-- 0x00E84D(Wrong): Use Item On party screen: 0, 1 if open
-- 0x01299A: Learn Move Cursor
-- 0x02000E: Use Item On party screen: 0, 1 if open
-- 0x020056: item submenu: 0, 1 if open (167F6?)
-- 0x020071: party submenu: 0, 1 if open
-- 0x0200EF: Pokemon summary screen: 0, 1 if open
-- 0x023064: 0x10 outside of battle, 0x12 in battle menu, 0x14 in fight menu, 0x16 in party menu, 0x15 in bag menu
-- 0x023464: (for double battles) 0x10 outside of battle, 0x12 in battle menu, 0x14 in fight menu, 0x16 in party menu, 0x15 in bag menu
-- 0x024333: Yes/No cursor
-- 0x0244AC battle menu cursor 0-3
-- 0x0244AE second mon battle menu cursor 0-3
-- 0x0244B0 fight menu cursor 0-3
-- 0X03CD92 item/party submenu cursor
-- 0x03CE5D open bag menu: 0 items 1 balls 2 tms 3 berries 4 key items
-- 0x03CE60 items cursor position 0-based
-- 0x03CE62 pokeballs cursor position 0-based
-- 0x03CE64 tmhm cursor position 0-based
-- 0x03CE66 berries cursor position?
-- 0x03CE68 key items cursor position 0-based
-- 0x03CE6A items scroll position 0-based
-- 0x03CE6C pokeballs scroll position?
-- 0x03CE6E tmhm scroll position 0-based
-- 0x03CE70 berries scroll position?
-- 0x03CE72 key items scroll position 0-based
-- 0x3CED1 party menu cursor 0-5, 7 (7 is cancel)

-- IWRAM Address notes
-- 0x5D8C pointer to Save Block 1 (in EWRAM)
-- 0x5D90 pointer to Save Block 2 (in EWRAM)

sBlock1Ptr = 0x03005D8C
sBlock2Ptr = 0x03005D90
musicAddr  = 0x03000F48
inBattle = 0x030026F9

pmAddresses = {
    ["CursorContest"] = 0x002E30,
    ["CursorMoveLearnOverworld"] = 0x0040D6,
    ["FirstMonTargetScreen"] = 0x005664,
    ["SecondMonTargetScreen"] = 0x00567C,
    --["CursorMoveLearnBattle"] = 0x01299A,
    ["UseItemPartyMenu"] = 0x02000E,
    ["SubmenuItem"] = 0x020056,
    ["SubmenuParty"] = 0x020071,
    ["PokemonSummaryScreen"] = 0x0200EF,
    ["DialogText"] = 0x021FC4,
    ["BattleText"] = 0x022E2C,
    ["BattleFlags"] = 0x022FEC,
    ["BattleFlags"] = 0x022FEC,
    ["MenuId"] = 0x023064,
    ["DoubleBattleMenuId"] = 0x023464,
    ["CursorYesNo"] = 0x024333,
    ["CursorBattle"] = 0x0244AC,
    ["CursorDoubleBattle"] = 0x0244AE,
    ["CursorFight"] = 0x0244B0,
    ["CursorDoubleFight"] = 0x0244B2,
    ["CursorSubmenu"] = 0X03CD92,
    ["BagId"] = 0x03CE5D,
    ["CursorBagStart"] = 0x03CE60,
    ["ScrollBagStart"] = 0x03CE6A,
    ["CursorParty"] = 0x03CED1
}
pmBagIndex = {
    ['items'] = 0,
    ['balls'] = 1,
    -- ['tms'] = 2, --no use in battle
    ['berries'] = 3,
    -- ['key'] = 4  --no use in battle
}

Utils = (loadfile "G3Utils.lua")()

function MoveUp() return { ["Up"] = true } end
function MoveDown() return { ["Down"] = true } end
function MoveLeft() return { ["Left"] = true } end
function MoveRight() return { ["Right"] = true } end
function Confirm() return { ["A"] = true } end
function Escape() return { ["B"] = true } end
function NoInput() return {} end

function Active()
    if EvolutionIsHappening() then
        return false
    end
    local battleFlags = memory.read_u32_le(pmAddresses["BattleFlags"], 'EWRAM')
    return (bit.band(battleFlags, 4) == 4
        --and bit.band(battleFlags, 0x80) == 0 -- turn off in Safari Zone
        and Utils.grabTextFromMemory(pmAddresses["BattleText"], 18, 'EWRAM') ~=  "Give a nickname to"
    ) or AboutToLearnMove() or AboutToCancelMove() or InPokemonSummary() or ContestAppealSelect()
end

function InBattle()
    return bit.band(memory.readbyte(inBattle, 'System Bus'), 2) > 0;
end

function InTrainerBattle()
    local battleFlags = memory.read_u32_le(pmAddresses["BattleFlags"], 'EWRAM')
    return bit.band(battleFlags, 8) == 8
end

function InLegendaryBattle()
    local battleFlags = memory.read_u32_le(pmAddresses["BattleFlags"], 'EWRAM')
    return bit.band(battleFlags, 0x70007C00) > 0
end

function InDoubleBattle()
    local battleFlags = memory.read_u32_le(pmAddresses["BattleFlags"], 'EWRAM')
    return bit.band(battleFlags, 1) == 1 
end

function CanUseItems()
    local battleFlags = memory.read_u32_le(pmAddresses["BattleFlags"], 'EWRAM')
    return bit.band(battleFlags, 0x100) == 0 --not in battle facility
end

function BattleStateIs(id)
    local battleState = memory.readbyte(pmAddresses["MenuId"], 'EWRAM')
    if battleState == 0x35 then
        if id == 0x35 then
            return true
        end
        return memory.readbyte(pmAddresses["DoubleBattleMenuId"], 'EWRAM') == id
    end
    return battleState == id
end

function InDoubleBattleMenu() return BattleStateIs(0x35) end
function InBattleMenu() return BattleStateIs(0x12) end
function InFightMenu() return BattleStateIs(0x14) end
function InBagMenu() return BattleStateIs(0x15) end
function InPartyMenu() return BattleStateIs(0x16) or (InUseItemOnPartyMenu() and not InBagMenu()) end
function InBagSubmenu() return memory.readbyte(pmAddresses["SubmenuItem"], 'EWRAM') == 1 end
function InPartySubmenu() return memory.readbyte(pmAddresses["SubmenuParty"], 'EWRAM') == 1 end
function InUseItemOnPartyMenu() return memory.readbyte(pmAddresses["UseItemPartyMenu"], 'EWRAM') == 1 end
function InPokemonSummary() return memory.readbyte(pmAddresses["PokemonSummaryScreen"], 'EWRAM') == 1 end
function InTargetingScreen() return InDoubleBattle() and (memory.readbyte(pmAddresses["FirstMonTargetScreen"]) == 4 or memory.readbyte(pmAddresses["SecondMonTargetScreen"]) == 4) end
function AtSwitchChangePokemonPrompt() return string.find(Utils.grabTextFromMemory(pmAddresses["BattleText"], 255, 'EWRAM'), "Will .+ change\nPokémon?") end
function TriedToSwitchToActivePokemon() return string.find(Utils.grabTextFromMemory(pmAddresses["DialogText"], 255, 'EWRAM'), ".+ is already\nin battle!") end
function EvolutionIsHappening() return memory.read_u16_le(musicAddr, 'System Bus')  == 0x179 end

function AboutToLearnMove()
    return string.find(Utils.grabTextFromMemory(pmAddresses["BattleText"], 255, 'EWRAM'), "Delete a move to make\nroom for .+?")
        or string.find(Utils.grabTextFromMemory(pmAddresses["DialogText"], 255, 'EWRAM'), "Should a move be deleted and\nreplaced with .+?")
end
function AboutToCancelMove()
    return string.find(Utils.grabTextFromMemory(pmAddresses["BattleText"], 255, 'EWRAM'), "Stop learning\n.+?")
        or string.find(Utils.grabTextFromMemory(pmAddresses["DialogText"], 255, 'EWRAM'), "Stop trying to teach\n.+?")
end
function ContestAppealSelect() return string.find(Utils.grabTextFromMemory(pmAddresses["DialogText"], 255, 'EWRAM'), "Which move will be played?") end
function ForcedMonSwitch() return string.find(Utils.grabTextFromMemory(pmAddresses["BattleText"], 255, 'EWRAM'):lower(), ("Use next POKéMON?"):lower()) end

function GetBattleCursor() 
    if InDoubleBattleMenu() then
        return memory.readbyte(pmAddresses["CursorDoubleBattle"], 'EWRAM')
    end
    return memory.readbyte(pmAddresses["CursorBattle"], 'EWRAM')
end
function GetFightCursor() 
    if InDoubleBattleMenu() then
        return memory.readbyte(pmAddresses["CursorDoubleFight"], 'EWRAM')
    end
    return memory.readbyte(pmAddresses["CursorFight"], 'EWRAM')
end
function GetMoveLearnCursor()
    -- if InBattle() then
    --     return memory.readbyte(pmAddresses["CursorMoveLearnBattle"], 'EWRAM')
    -- end
    return memory.readbyte(pmAddresses["CursorMoveLearnOverworld"], 'EWRAM')
end
function GetYesNoCursor() return memory.readbyte(pmAddresses["CursorYesNo"], 'EWRAM') end
function GetSubmenuCursor() return memory.readbyte(pmAddresses["CursorSubmenu"], 'EWRAM') end
function GetContestCursor() return memory.readbyte(pmAddresses["CursorContest"], 'EWRAM') end
function GetBagPocket() return memory.readbyte(pmAddresses["BagId"], 'EWRAM') end
function GetBagCursor() 
    local bagOffset = memory.readbyte(pmAddresses["BagId"], 'EWRAM') * 2
    return memory.readbyte(pmAddresses["CursorBagStart"] + bagOffset, 'EWRAM') + memory.readbyte(pmAddresses["ScrollBagStart"] + bagOffset, 'EWRAM')
end
function GetPartyCursor() 
    local cursor = memory.readbyte(pmAddresses["CursorParty"], 'EWRAM')
    if cursor == 7 then
        return 6 -- range is 0-5 but cancel is 7
    end
    return cursor
end

function MoveRectMenu(start, dest)
    if start == dest then
        return Confirm()
    elseif start == 0 then
        if dest == 1 then -- avoid dest 1 otherwise (Bag)
            return MoveRight()
        end
        return MoveDown()
    elseif start == 1 then
        if dest == 3 then
            return MoveDown()
        end
        return MoveLeft()
    elseif start == 2 then
        if dest == 3 then --avoid dest 3 otherwise (Run)
            return MoveRight()
        end
        return MoveUp()
    end
    if dest == 1 then
        return MoveUp()
    end
    return MoveLeft()
end

function MoveToFight(move)
    if ForcedMonSwitch() then
        if InPartyMenu() then
            return NoInput()
        elseif GetYesNoCursor() == 0 then
            return Confirm()
        end
        return MoveUp()
    elseif InTargetingScreen() then
        if GetFightCursor() == move - 1 then
            return Confirm()
        end
    elseif InFightMenu() then
        return MoveRectMenu(GetFightCursor(), move - 1)
    elseif InBattleMenu() then
        return MoveRectMenu(GetBattleCursor(), 0)
    elseif AboutToCancelMove() then
        return Escape()
    elseif AboutToLearnMove() or (InPokemonSummary() and not InBattle()) then
        if InPokemonSummary() then
            local mDist = (move - 1) - GetMoveLearnCursor()
            if mDist == 0 then
                return Confirm()
            elseif (mDist > 0 and mDist < 3) or mDist < -3 then
                return MoveDown()
            end
            return MoveUp()
        elseif GetYesNoCursor() == 0 then
            return Confirm()
        end
        return MoveUp()
    elseif ContestAppealSelect() then
        local mDist = (move - 1) - GetContestCursor()
        if mDist == 0 then
            return Confirm()
        elseif (mDist > 0 and mDist < 3) or mDist < -3 then
            return MoveDown()
        end
        return MoveUp()
    end
    return Escape()
end

itemCache = nil
pocketCache = nil
function DigestItems(items)
    itemCache = {}
    pocketCache = {}
    for p,parr in pairs(items) do
        local pocket = pmBagIndex[p]
        if pocket ~= nil then
            pocketCache[pocket] = {}
            for slot,i in ipairs(parr) do
                itemCache[i['id']] = { ['pocket'] = pocket, ['slot'] =  slot }
                pocketCache[pocket][slot] = i
            end
        end
    end
end

function UpdateItems()
    local sBlock1Addr = Utils.switchDomainAndGetLocalPointer(memory.read_u32_le(Utils.switchDomainAndGetLocalPointer(sBlock1Ptr)))
    local sBlock2Addr = Utils.switchDomainAndGetLocalPointer(memory.read_u32_le(Utils.switchDomainAndGetLocalPointer(sBlock2Ptr)))
    local securityKey = memory.read_u32_le(sBlock2Addr + 0xAC)
	local halfKey = securityKey % 0x10000
    local items = {
        ["items"] = Utils.getItemCollection(sBlock1Addr + 0x560, 30, halfKey),
        ["balls"] = Utils.getItemCollection(sBlock1Addr + 0x650, 16, halfKey),
        ["berries"] = Utils.getItemCollection(sBlock1Addr + 0x790, 46, halfKey)
    }
    DigestItems(items)
end

function MoveToBag(pocket, item)
    if ForcedMonSwitch() then
        if InPartyMenu() then
            return NoInput()
        elseif GetYesNoCursor() == 0 then
            return Confirm()
        end
        return MoveUp()
    elseif pocket == pmBagIndex['balls'] and InTrainerBattle() or CanUseItems() ~= true then 
        return NoInput() --don't be a thief
    elseif InBagMenu() then
        if pocket == nil then
            return Confirm()
        end
        local pDist = pocket - GetBagPocket()
        if pDist == 0 then
            local cursor = GetBagCursor() + 1
            if item == nil or item == cursor then
                if InBagSubmenu() then
                    if GetSubmenuCursor() > 0 then
                        return MoveUp()
                    elseif InUseItemOnPartyMenu() then
                        return NoInput()
                    end
                    pmLastUsedBagPocket = pocket
                    pmLastUsedBagSlot = item
                    itemCache = nil --used item, rebuild item cache next time
                    return Confirm()
                elseif InUseItemOnPartyMenu() then
                    return NoInput()
                end
                return Confirm()
            elseif InBagSubmenu() then
                return Escape()
            elseif cursor < item then
                return MoveDown()
            end
            return MoveUp()
        elseif InBagSubmenu() then
            return Escape()
        elseif (pDist > 0 and pDist < 3) or pDist < -2 then
            return MoveRight()
        end
        return MoveLeft()
    elseif InBattleMenu() then
        return MoveRectMenu(GetBattleCursor(), 1)
    end
    return Escape()
end

function MoveToParty(slot, inPartyOverride)
    if InPartyMenu() or inPartyOverride == true then
        if InPokemonSummary() or TriedToSwitchToActivePokemon() then
            return Escape()
        elseif slot == nil then
            return NoInput()
        end
        local cDist = (slot - 1) - GetPartyCursor()
        if cDist == 0 then
            if InPartySubmenu() then
                if GetSubmenuCursor() > 0 then
                    return MoveUp()
                end
                return Confirm()
            end
            return Confirm()
        elseif InPartySubmenu() then
            return Escape()
        elseif (cDist > 0 and cDist < 4) or cDist < -4 then
            return MoveDown()
        end
        return MoveUp()
    elseif AtSwitchChangePokemonPrompt() then
        if GetYesNoCursor() == 0 then
            return Confirm()
        end
        return MoveUp()
    elseif ForcedMonSwitch() then
        if GetYesNoCursor() == 0 then
            return Confirm()
        end
        return MoveUp()

    elseif inPartyOverride == false then
        return NoInput()
    elseif InBattleMenu() then
        return MoveRectMenu(GetBattleCursor(), 2)
    end
    return Escape()
end

function MoveToRun()
    if InTrainerBattle() or InLegendaryBattle() then
        return NoInput()
    elseif InBattleMenu() and not ForcedMonSwitch() then
        return MoveRectMenu(GetBattleCursor(), 3)
    end
    return Escape()
end

function MoveToItem(id)
    if itemCache == nil then
        UpdateItems()
    end
    local location = itemCache[id]
    if location ~= nil then
        return MoveToBag(location['pocket'], location['slot'])
    end
    return NoInput()
end

function RunCommand(cmd, num)
    cmd = string.upper(cmd)
    if Active() and commands[cmd] ~= nil then
        return commands[cmd](num)
    else
        itemCache = nil
    end
    return NoInput()
end

function Catch()
    if InTrainerBattle() then
        return NoInput()
    end
    local bagCount = 1 + GetBagCursor()
    if itemCache == nil then
        UpdateItems()
    end
    if pocketCache ~= nil then
        bagCount = 0
        for i,v in ipairs(pocketCache[pmBagIndex['balls']]) do
            bagCount = i
        end
        if bagCount == 0 then
            return NoInput()
        end
    end
    return MoveToBag(pmBagIndex['balls'], math.min(GetBagCursor() + 1, bagCount))
end

function Parse(cmd)
    local out
    pcall(function() out = RunCommand(string.match(cmd, '%a+'), tonumber(string.match(cmd, '%d+'))) end)
    return out
end

function Extend(tbl1, tbl2) 
    for k,v in pairs(tbl2) do
        tbl1[k] = v
    end
    return tbl1
end

commands = {
    ["MOVE"] = MoveToFight,
    ["SWITCH"] = MoveToParty,
    ["ITEM"] = MoveToItem,
    -- ["ITEM"] = function (item) return MoveToBag(pmBagIndex['items'], item) end,
    -- ["THROW"] = function (item) return MoveToBag(pmBagIndex['balls'], item) end,
    -- ["BERRY"] = function (item) return MoveToBag(pmBagIndex['berries'], item) end,
    -- ["TEACH"] = function (item) return MoveToBag(pmBagIndex['tms'], item) end,
    -- ["KEY"] = function (item) return MoveToBag(pmBagIndex['key'], item) end,
    -- ["REUSE"] = function () return MoveToBag(pmLastUsedBagPocket, pmLastUsedBagSlot) end,
    ["ON"] = function (item) return MoveToParty(item, InUseItemOnPartyMenu()) end,
    ["WITH"] = function (item) return MoveToParty(item, InUseItemOnPartyMenu()) end,
    ["CATCH"] = Catch,
    ["RUN"] = MoveToRun
}

function pm(cmd)
    local input = {}
    input = Parse(cmd)
    joypad.set(input)
    return input
end

return {
    ["Parse"] = Parse,
    ["TestInput"] = pm,
    ["DigestItems"] = DigestItems,
    ["Extend"] = Extend
}