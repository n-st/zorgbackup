zorgbackup — configure borgbackup via ZFS properties
====================================================

ZFS configuration
-----------------

Backup to a single destination ...

    zfs set de.voidptr.zorgbackup:target=borgbackup@moon.example.com:/data/borgrepos/ tank

... or to multiple destinations

    zfs set de.voidptr.zorgbackup:target="borgbackup@moon.example.com:/data/borgrepos/,root@secondary.local:/mnt/tank/borg/" tank

Configure repo names.
Only filesystems which have a repo property set *locally* (not inherited) are backed up!

    zfs set de.voidptr.zorgbackup:repo=tank-userhomes tank/userhomes

Optionally: options!

    zfs set de.voidptr.zorgbackup:options="--compression zstd" tank/userhomes

If you want your options to *replace* zorgbackup's defaults (instead of being
appended after them), prefix them with a single '-- ':

    zfs set de.voidptr.zorgbackup:options="-- --one-file-system --exclude='*/backups/'" tank/userhomes

You can also backup multiple sources into the same repo. In that case, you
should probably specify unique archive names for each of them (otherwise they
will be considered part of the same set when pruning old versions, and you
might lose archives).  
If you don't specify an archive name (or set it to `-`), the archive name will
default to `zorgbackup`.  
Either way, the current UTC date and time will be appended to keep archive
names unique.

    zfs set de.voidptr.zorgbackup:archive="homes" tank/userhomes

Usage
-----

Store your repo password in a plaintext file named like your script (`zorgbackup.sh` -> `zorgbackup.passphrase.txt`).

In the simplest case, run the script without any arguments.
It will run borg backups for all local ZFS filesystems that have a `repo` and
`target` property set on them.
It will only produce output if errors are detected.

Use `-v` if you want to get a one-line message for each filesystem-destination pair that is backed up,
`-v -v` (not `-vv`!) to also get `--progress` output from borg itself.

`-n` to make borg run in "dry-run" mode (i.e. without performing an actual backup).

Example
-------

    $ zfs list -o name,de.voidptr.zorgbackup:repo,de.voidptr.zorgbackup:archive,de.voidptr.zorgbackup:target,de.voidptr.zorgbackup:options
    NAME            DE.VOIDPTR.ZORGBACKUP:REPO  DE.VOIDPTR.ZORGBACKUP:ARCHIVE  DE.VOIDPTR.ZORGBACKUP:TARGET                  DE.VOIDPTR.ZORGBACKUP:OPTIONS
    tank            -                           -                              borgbackup@moon.example.com:/data/borgrepos/  -
    tank/bin        bin                         bin                            borgbackup@moon.example.com:/data/borgrepos/  -
    tank/core       data                        core                           borgbackup@moon.example.com:/data/borgrepos/  -
    tank/extra      -                           -                              borgbackup@moon.example.com:/data/borgrepos/  -
    tank/userhomes  data                        homes                          borgbackup@moon.example.com:/data/borgrepos/  -

    $ ./zorgbackup.sh -v -v
    Backing up "tank/bin" (at "/mnt/tank/bin") to "borgbackup@moon.example.com:/data/borgrepos/bin"...
    Creating archive at "borgbackup@moon.example.com:/data/borgrepos/bin::zorgbackup_2020-07-19_17:41:42"
    Borg invocation returned 0.
    Backing up "tank/core" (at "/mnt/tank/core") to "borgbackup@moon.example.com:/data/borgrepos/core"...
    Creating archive at "borgbackup@moon.example.com:/data/borgrepos/core::zorgbackup_2020-07-19_17:41:47"
    Borg invocation returned 0.
    Backing up "tank/userhomes" (at "/usr/home") to "borgbackup@moon.example.com:/data/borgrepos/foo-home"...
    Creating archive at "borgbackup@moon.example.com:/data/borgrepos/foo-home::zorgbackup_2020-07-19_17:42:17"
    Borg invocation returned 0.
