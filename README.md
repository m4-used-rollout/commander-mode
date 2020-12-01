# TPP Commander Mode

This is a script that converts command strings (e.g. `MOVE1` `ITEM4` `SWITCH3` `RUN`) to button presses that navigate the in-game menus. The goal is to replicate the ease of a touchscreen. Military Mode from Anniversary Crystal did this, but each command instantaneously selected the in-game action. Commander Mode is designed to only advance one button press at a time to allow a chat controlled game to disagree over what action to take.

Currently, Commander Mode only supports Pokemon Emerald, and should likely support any binary hack made of Pokemon Emerald.

## Using Commander Mode

Commander Mode is written for the BizHawk emulator. It could likely be adapted to work in other emulators, but BizHawk is the only one TPP tests in and uses for GBA.

To use Commander Mode in BizHawk, open the Lua Console from the Tools menu and open `Commander.lua` from the `Commander` folder. If you want to move the scripts elsewhere, make sure all scripts in the `Commander` folder are kept together.

Commands are intended to be issued through a chat-reading input queue. Getting the commands from chat into this script is outside the scope of Commander Mode.
There is a testing function that can be used to issue commands directly from BizHawk's Lua Console, so the script is functional and testable on its own.
If you wish to operate Commander Mode using your own script, Commander Mode returns both a `Parse` function that will parse a command string and return a joypad button table and a `TestInput` function that not only parses a command string and returns the joypad table, but also submits that table to the emulator.

Commands are not case-sensitive. `MOVE1`, `Move1`, and `move1` all work.

Currently, an external script must call the exported `DigestItems` function with a table of the items in the player's Bag for the `ITEM` command to work properly. If this is not possible, see [Alternative ITEM Commands](#alternative-item-commands).

## Command Reference

### MOVE

The `MOVE` command is followed by a number 1-4 that denotes which move you want the active Pokemon to use next in battle. It will take all necessary steps to navigate to the Fight menu, move the cursor to the requested move, and select it. If you are in a double battle, `MOVE` will attack whichever target Pokemon happens to be selected, as long as the move being used is the one requested.

### SWITCH

The `SWITCH` command is followed by a number 1-6 that denotes which party slot you want to swap the active Pokemon with. It will take all necessary steps to navigate to the Pokemon menu, move the cursor to the requested Pokemon, and select Switch.

### ITEM

The `ITEM` command is followed by a 1-3 digit number that denotes the [index number](https://bulbapedia.bulbagarden.net/wiki/List_of_items_by_index_number_(Generation_III)) (in decimal) of the desired item to be used. If the item is available, it will take all necessary steps to navigate to the Bag menu, move to the correct pocket, move the cursor to the desired item, and use it. `ITEM` will only use items from the Items, Berries, and Balls pockets. It will not attempt use items from the Balls pocket in Trainer battles. If the item is to be used on a Pokemon in the party, see `ON` below.

### ON

The `ON` command is a bag-safe version of `SWITCH`. As with `SWITCH`, it is followed by a number 1-6 that denoted which party slot you want to use an item on. It will operate the Pokemon menu when it is open, but it will not attempt to open the menu if you're not already in it.

### RUN

The `RUN` command takes all necessary steps to run from a Wild battle. It will not attempt to run from Trainer battles.

## Alternative ITEM Commands

If reading the contents of the player's bag is not possible, an alternative set of ITEM commands may be used. These commands select items to use by bag pocket and slot. The slot is the item's ordinal number in the bag pocket's menu.

### ITEM

The `ITEM` command is followed by the slot number of the item you wish to use in the Items pocket.

### THROW

The `THROW` command is followed by the slot number of the item you wish to use in the Balls pocket.

### BERRY

The `BERRY` command is followed by the slot number of the item you wish to use in the Berries pocket.

### TEACH

The `TEACH` command is followed by the slot number of the item you wish to use in the TM/HM pocket.

### KEY

The `KEY` command is followed by the slot number of the item you wish to use in the Key Items pocket.

### REUSE

The `REUSE` command will replay the last issued `ITEM`/`THROW`/`BERRY`/`TEACH`/`KEY` command that managed to select `Use` on an item. For example, if you last threw an Ultra Ball with `THROW3`, `REUSE` will attempt to navigate to the Balls pocket and use the item in slot 3.

### Enabling Alternative ITEM Commands

Near the end of the `Commander.lua` script is a table of commands that Commander Mode will parse. 
```
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
    ["CATCH"] = function () return MoveToBag(pmBagIndex['balls'], GetBagCursor() + 1) end,
    ["RUN"] = MoveToRun
}
```
To switch to the alternative ITEM commands, comment out or remove `["ITEM"] = MoveToItem,`, and then uncomment the next 6 lines.