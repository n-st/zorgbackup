#!/bin/sh

set -eu

## Static configuration
archive_name='zorgbackup_{utcnow:%Y-%m-%d_%H:%M:%S}'
default_options="\
--warning \
--lock-wait $((3 * 3600)) \
--checkpoint-interval $((15 * 60)) \
--exclude-caches \
--exclude-if-present '.nobackup' \
--keep-exclude-tags \
--exclude '*/.[Cc]ache/' \
--exclude '*/.gvfs/' \
--exclude '*/.Trash*/' \
--exclude '*/Trash/' \
--exclude '*/[Cc]ache/' \
--exclude '/dev/' \
--exclude '/proc/' \
--exclude '/sys/' \
--exclude '/tmp/' \
--exclude '/usr/ports/' \
--exclude '/usr/src/' \
--exclude '/var/cache/' \
--exclude '/var/crash/' \
--exclude '/var/tmp/' \
"
## / Static configuration

# Parse arguments
verbose=0
while :; do
    if [ $# -eq 0 ]
    then
        break
    fi
    case $1 in
        -h|-\?|--help)   # Call a "show_help" function to display a synopsis, then exit.
            show_help
            exit
            ;;
        -v|--verbose)
            verbose=$((verbose + 1)) # Each -v argument adds 1 to verbosity.
            ;;
        --)              # End of all options.
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        *)               # Default case: If no more options then break out of the loop.
            break
    esac

    shift
done

# Determine passphrase file
pwdfile="${0%.sh}.passphrase.txt"
if ! [ -r "$pwdfile" ]
then
    printf 'Passphrase file at "%s" missing or unreadable. Cannot continue.\n' "$pwdfile" 1>&2
    exit 1
fi

# Load passphrase file
BORG_PASSPHRASE="$(cat "$pwdfile")"

# Iterate over all filesystems that have a destination repo set *explicitly*
# (not inherited, since that would back up all child filesystems into the same
# borg repo)
zfs get -H -o name -t filesystem -s local de.voidptr.zorgbackup:repo | \
    while read -r filesystem
    do
        mountpoint=$(zfs get -H -o value -t filesystem mountpoint "$filesystem")

        target=$(zfs get -H -o value -t filesystem de.voidptr.zorgbackup:target "$filesystem")
        if [ "$target" = "-" ]
        then
            printf 'No target destination specified. Skipping filesystem "%s".\n' "$filesystem" 1>&2
            continue
        fi

        repo=$(zfs get -H -o value -t filesystem de.voidptr.zorgbackup:repo "$filesystem")
        if [ "$repo" = "-" ]
        then
            printf 'No repo destination specified. Skipping filesystem "%s".\n' "$filesystem" 1>&2
            continue
        fi

        BORG_REPO="${target}${repo}"

        borg_options=$(zfs get -H -o value -t filesystem de.voidptr.zorgbackup:options "$filesystem")
        case "$borg_options" in
            -)
                borg_options="$default_options"
                ;;
            --\ *)
                borg_options="${borg_options#-- }"
                ;;
            *)
                borg_options="$default_options $borg_options"
                ;;
        esac
        if [ $verbose -ge 2 ]
        then
            borg_options="$borg_options --verbose"
        fi
        if [ $verbose -ge 3 ]
        then
            borg_options="$borg_options --progress --stats"
        fi

        if [ $verbose -ge 1 ]
        then
            printf 'Backing up "%s" (at "%s") to "%s"...\n' "$filesystem" "$mountpoint" "$BORG_REPO"
        fi

        if ! cd "$mountpoint"
        then
            printf 'Could not chdir to "%s". Skipping filesystem "%s".\n' "$mountpoint" "$filesystem" 1>&2
            continue
        fi

        export BORG_REPO BORG_PASSPHRASE
        # A bit of trickery to handle the return code despite `set -e`
        rc=0
        borg create $borg_options "::$archive_name" '.' || rc=$?
        if [ $rc -ne 0 ]
        then
            printf 'Borg reported failure (exit code %d).\n' "$rc" 1>&2
        elif [ $verbose -ge 1 ]
        then
            printf 'Borg invocation returned %d.\n' "$rc"
        fi
    done
