# steam-launchoptions

Easily set launch options for your Windows/Linux Steam games (single/multiple/all) via CLI on Linux

## About

This script allows you to apply common launch options for your Steam Windows/Linux games simultaneously without touching any Steam GUI options. The script runs and works only on Linux.

You can update launch options for single games, selected group of games or your all games.

You can customize your launch options via interactive shell prompt, offered by the script.

**Advantages:**
- apply massive amount of launch options instantly. No more clicking through Steam GUI options.
- apply launch options for single games, multiple games or all your games

**Disadvantages:**
- runs only on Linux
- can't update launch options while Steam client is running

## Requirements

- Linux OS

- Linux Steam Client

- Linux/Windows games on your Steam game library

# Usage

Just run `bash steam_launchoptions.sh` and follow the instructions.

You can select multiple games by using following syntaxes:

### How-to: Selecting a single Windows/Linux game

On the game selection prompt, use the following syntax:

```
3
```

which stands for "Select game 3 from the presented list (which is shown during script execution)"

### How-to: Selecting individual games

On the game selection prompt, use the following syntax:

```
1 2 5
```

which stands for "Select games 1, 2 and 5 from the presented list (which is shown during script execution)"

### How-to: Selecting all Windows/Linux games

On the game selection prompt, use the following syntax:

```
all
```

stands for "Select all games from the presented list (which is shown during script execution)"

### How-to: Clearing all launch options

When the script asks you to type launch options, just leave it pure blank. The script will tell you that launch options will be emptied for the games you will choose.

You can clear & customize launch options for single/multiple/all games, depending on your further choises.

### LICENSE

This repository uses GPLv3 license. See [LICENSE](LICENSE) for details.
