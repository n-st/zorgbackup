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
