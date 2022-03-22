# minitracker
## MOD music player for [Mini Micro](https://miniscript.org/MiniMicro)

This project is a player for MOD music files, such as those at [this archive](https://modarchive.org/) (though in MOD format only).  Read more about this fascinating part of our culture at [Wikipedia](https://en.wikipedia.org/wiki/Module_file).

This code is to be used with [Mini Micro](https://miniscript.org/MiniMicro).  To try it out:

1. Clone this archive to your local machine.
2. Launch [Mini Micro](https://miniscript.org/MiniMicro).
3. Mount the archive folder using the disk slot.
4. `load "modPlayer"`
5. `run`

The archive includes several good mod files that should work, but by default it plays [dragnet](https://modarchive.org/module.php?40294).  To change the song played, just edit modPlayer.ms and change the path on the `modFile.Song.load` line (around line 63).

The player as it stands is the result of only a few hours' work.  I plan to develop it further, supporting more effect commands (pitch bend, etc.) as well as providing visualizations as the music plays.
