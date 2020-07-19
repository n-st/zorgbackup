#!/bin/sh

set -eu

# Determine passphrase file
pwdfile="${0%.sh}.passphrase.txt"
if ! [ -r "$pwdfile" ]
then
    printf 'Passphrase file at "%s" missing or unreadable. Cannot continue.\n' "$pwdfile" 1>&2
    exit 1
fi

options=""
argument=""
while :; do
    if [ $# -eq 0 ]
    then
        break
    elif [ $# -eq 1 ]
    then
        argument="$1"
    else
        options="$options $1"
    fi

    shift
done

# Load passphrase file
BORG_PASSPHRASE="$(cat "$pwdfile")"

printf '%s\t%s\t%s\t%s\t%s\n' "NAME" "REPO" "TARGET" "OPTIONS" "LAST_ARCHIVE"
zfs get -H -o name -t filesystem $options de.voidptr.zorgbackup:repo "$argument" | \
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
            lastdate="${lastdate:--}"

            printf '%s\t%s\t%s\t%s\t%s\n' "$filesystem" "$repo" "$target" "$borg_options" "$lastdate"
        done
    done
