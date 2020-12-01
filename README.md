# TPP Commander Mode

This is a script that converts command strings (e.g. `MOVE1` `ITEM4` `SWITCH3` `RUN`) to button presses that navigate the in-game menus. The goal is to replicate the ease of a touchscreen. Military Mode from Anniversary Crystal did this, but each command instantaneously selected the in-game action. Commander Mode is designed to only advance one button press at a time to allow a chat controlled game to disagree over what action to take.

Currently, Commander Mode only supports Pokemon FireRed (both revisions) and Pokemon Emerald. Any binary hack made from those games is also likely to be supported.

## Using Commander Mode

Commander Mode is written for the [BizHawk](http://tasvideos.org/Bizhawk.html) emulator. It could likely be adapted to work in other emulators, but BizHawk is the only one TPP tests in and uses for GBA.

To use Commander Mode in BizHawk, open the Lua Console from the Tools menu and open `Commander.lua` from the `Commander` folder. If you want to move the scripts elsewhere, make sure all scripts in the `Commander` folder are kept together.

Commands are intended to be issued through a chat-reading input queue. Getting the commands from chat into this script is outside the scope of Commander Mode.
There is a testing function named `cmdr` that can be used to issue commands directly from BizHawk's Lua Console, so the script is functional and testable on its own. To issue commands from the Lua Console, call `cmdr` with your command string, e.g. `cmdr('move1')`.
If you wish to operate Commander Mode using your own script, Commander Mode returns both a `Parse` function that will parse a command string and return a joypad button table and a `TestInput` function that not only parses a command string and returns the joypad table, but also submits that table to the emulator.

Commands are not case-sensitive. `MOVE1`, `Move1`, and `move1` all work.

Commander Mode's scripts are stateless and can be reloaded at any time if necessary. `Commander.lua` needs to be reloaded when switching games, and should automatically reload itself when the emulator loads a saved state.

## Command Reference

### MOVE

The `MOVE` command is followed by a number 1-4 that denotes which move you want the active Pokemon to use next in battle. It will take all necessary steps to navigate to the Fight menu, move the cursor to the requested move, and select it. If you are in a double battle, `MOVE` will not press any buttons on the targeting screen. Use `ON`/`WITH` to target enemy Pokemon 1 (left) or 2 (right).

`MOVE` also confirms learning a move and specifies which move to forget. This works both inside and outside of battle.

### SWITCH

The `SWITCH` command is followed by a number 1-6 that denotes which party slot you want to swap the active Pokemon with. It will take all necessary steps to navigate to the Pokemon menu, move the cursor to the requested Pokemon, and select Switch.

Outside of battle, `SWITCH` will still operate the Pokemon menu when it is open. Currently, it will select the specified Pokemon and the first option in the submenu.

### ITEM

The `ITEM` command is followed by a 1-3 digit number that denotes the [index number](https://bulbapedia.bulbagarden.net/wiki/List_of_items_by_index_number_(Generation_III)) (in decimal) of the desired item to be used. If the item is available, it will take all necessary steps to navigate to the Bag menu, move to the correct pocket, move the cursor to the desired item, and use it. `ITEM` will only use items from the Items, Berries, and Balls pockets. It will not attempt use items from the Balls pocket in Trainer battles. If the item is to be used on a Pokemon in the party, see `ON`/`WITH` below.

`ITEM` will not function outside of battle.

### ON/WITH

The `ON` or `WITH` command is a bag-safe version of `SWITCH`. As with `SWITCH`, it is followed by a number 1-6 that denoted which party slot you want to use an item on. It will operate the Pokemon menu when it is open, but it will not attempt to open the menu if you're not already in it.

Also, `ON` and `WITH` can be used on the target selection screen in a double battle to specify whether to target enemy Pokemon 1 (left) or 2 (right). `ON` and `WITH` will not target allies.

Outside of battle, `ON` and `WITH` will still operate the Pokemon menu when it is open. Currently, they will select the specified Pokemon and the first option in the submenu.

### CATCH

The `CATCH` command will attempt to use whichever ball is currently selected in the Balls pocket. If the cursor is on Close, it will move the cursor up to select the last ball in the bag. `CATCH` will do nothing if there are no available balls to throw, or if not in a Wild battle. 

`CATCH` will not function outside of battle.

### RUN

The `RUN` command takes all necessary steps to run from a Wild battle. It will not attempt to run from Trainer battles.

`RUN` will not function outside of battle.

## Safari Zone

Inside the Safari Zone, `CATCH` will correctly throw a Safari Ball. The other commands still attempt operate as they would in a normal battle. `MOVE` will select the Ball option and throw a Safari Ball. `ITEM` will throw Bait or open the PokeBlock case. `SWITCH` will throw a Rock or select Go Near, and `RUN` will select Run.

## Nicknaming

Commander Mode will select 'Yes' in response to receiving a command while the game is asking whether to nickname a Pokemon. This behavior can be disabled by setting `forceNicknames` to `false` at the top of `Commander.lua` and reload the script. When this is disabled, Commander Mode will not respond to commands while at this prompt.

Additionally, Commander Mode will move the cursor randomly in response to receiving a command while the nicknaming screen is open. This behavior can be disabled by setting `randomizeNicknames` to `false` at the top of `Commander.lua` and reload the script. When this is disabled, Commander Mode will not respond to commands while on this screen.

# Contributing

## Bug Reports

If any bad behaviors are found while using Commander Mode with Pokemon FireRed, Pokemon Emerald, or any binary hack thereof, please create an Issue.

Commander Mode has a verbose output mode where it describes how it decides which button to press. This is invaluable for debugging issues. To enable this, set `debug` to `true` at the top of `Commander.lua` and reload the script.

## Adding Support for Other Games

Commander Mode should theoretically be able to operate any of GameFreak's GBA Pokemon games and their binary hacks. Adding support for the rest of the versions involves creating a table of addresses for Commander's state lookup functions and adding a way to detect that game version in the `Init` function. LeafGreen should be automatically supported by FireRed's code once an address table can be created. Ruby and Sapphire may require additional work. Hacks that recompile part or all of the game will likely need their own address tables. Issues that are submitted against romhacks are not likely to get worked on, but pull requests adding support for specific hacks are welcome.

Building address tables is made far easier by referencing pret's [pokeemerald](https://github.com/pret/pokeemerald/) and [pokefirered](https://github.com/pret/pokefirered/) repos. The games were reverse engineered from their ROMs back into source code. Symbol files generated by building those projects are in the `Symbol Reference` folder in this repository. Each entry in the Commander Mode address tables has its corresponding symbol listed next to it in a comment.

Support for other generations is planned, but not a priorty at the moment. Pull requests that create a new set of Commander scripts for other Pokemon games are appreciated.