#!/bin/sh

set -eu

# Determine passphrase file
pwdfile="${0%.sh}.passphrase.txt"
if ! [ -r "$pwdfile" ]
then
    printf 'Passphrase file at "%s" missing or unreadable. Cannot continue.\n' "$pwdfile" 1>&2
    exit 1
fi

# Load passphrase file
BORG_PASSPHRASE="$(cat "$pwdfile")"

zfs get -H -o name -t filesystem de.voidptr.zorgbackup:repo | \
    while read -r filesystem
    do
        repo=$(zfs get -H -o value -t filesystem de.voidptr.zorgbackup:repo "$filesystem")
        targets=$(zfs get -H -o value -t filesystem de.voidptr.zorgbackup:target "$filesystem" | tr ',' ' ')
        borg_options=$(zfs get -H -o value -t filesystem de.voidptr.zorgbackup:options "$filesystem")

        for target in $targets
        do
            lastdate="-"

            if [ "$repo" = "-" ] || [ "$target" = "-" ]
            then
                printf '%s\t%s\t%s\t%s\t%s\n' "$filesystem" "$repo" "$target" "$borg_options" "$lastdate"
                continue
            fi

            BORG_REPO="${target}${repo}"

            export BORG_REPO BORG_PASSPHRASE
            lastdate=$(borg info --last 1 --json | awk '$1=="\"name\":" {name=$2;gsub(/",?/, "", name);print name}')

            printf '%s\t%s\t%s\t%s\t%s\n' "$filesystem" "$repo" "$target" "$borg_options" "$lastdate"
        done
    done
