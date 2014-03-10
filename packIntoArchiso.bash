#!/usr/bin/env bash
# -*- coding: utf-8 -*-

# region header

# Copyright Torben Sickert 16.12.2012

# License
# -------

# This library written by Torben Sickert stand under a creative commons naming
# 3.0 unported license. see http://creativecommons.org/licenses/by/3.0/deed.de

# Example
# -------

# Start install progress command (Assuming internet is available):
# >>> ./packIntoArchIso.bash /path/to/archiso/file.iso \
# ...     /path/to/newly/packed/archiso/file.iso

# Note that you only get very necessary output until you provide "--verbose" as
# commandline options.

# Dependencies
# ------------

# - bash (or any bash like shell)
# - test           - Check file types and compare values.
# - mount          - Filesystem mounter.
# - echo           - Display a line of text.
# - umount         - Filesystem unmounter.
# - mktemp         - Create a temporary file or directory.
# - squashfs-tools - Packs and unpacks the iso embedded squash filesystem.
# - cdrkit         - Suite of programs for CD/DVD recording, ISO image
#                    creation, and audio CD extraction.
# - touch          - Change file timestamps or creates them.
# - grep           - Searches the named input files (or standard input if no
#                    files are named, or if a single hyphen-minus (-) is given
#                    as file name) for lines containing a match to the given
#                    PATTERN. By default, grep prints the matching lines.
# - shift          - Shifts the command line arguments.
# - readlink       - Print resolved symbolic links or canonical file names.
# - rm             - Remove files or directories.

# Optional dependencies:

# - sudo                 - Perform action as another user.
# - arch-install-scripts - Supports to perform an arch-chroot.

__NAME__='packIntoArchiso'

# endregion

function packIntoArchiso() {
    # Provides the main module scope.

# region configuration

    # region properties

        # region command line arguments

    local _VERBOSE='no'
    local _SQUASH_FILESYSTEM_COMPRESSOR='gzip'
    local _KEYBOARD_LAYOUT='de-latin1'
    local _KEY_MAP_CONFIGURATION_FILE_CONTENT="KEYMAP=${_KEYBOARD_LAYOUT}\nFONT=Lat2-Terminus16\nFONT_MAP="

        # endregion

    local _STANDARD_OUTPUT=/dev/null
    local _ERROR_OUTPUT=/dev/null
    local _SOURCE_PATH=''
    local _TARGET_PATH=''
    local _MOUNPOINT_PATH="$(mktemp --directory)"
    local _TEMPORARY_REMASTERING_PATH="$(mktemp --directory)"
    local _TEMPORARY_FILESYSTEM_REMASTERING_PATH="$(mktemp --directory)/mnt"
    local _TEMPORARY_ROOT_FILESYSTEM_REMASTERING_PATH="$(mktemp --directory)"
    local _RELATIVE_PATHS_TO_SQUASH_FILESYSTEM=(arch/i686/root-image.fs.sfs \
        arch/x86_64/root-image.fs.sfs)
    local _RELATIVE_SOURCE_FILE_PATH='archInstall.bash'
    local _RELATIVE_TARGET_FILE_PATH='usr/bin/'
    local _BASH_RC_CODE="\nalias getInstallScript='wget https://raw.github.com/archInstall/archInstall/master/archInstall.bash --output-document archInstall.bash && chmod +x archInstall.bash'\nalias install='([ -f /root/archInstall.bash ] || getInstallScript);/root/archInstall.bash'"

    # endregion

# endregion

# region functions

    # region command line interface

    function printUsageMessage() {
        # Prints a description about how to use this program.
    cat << EOF
$__NAME__ Packs the current packIntoArchiso.bash script into the archiso image.
EOF
    }
    function printUsageExamples() {
        # Prints a description about how to use this program by providing
        # examples.
        cat << EOF
    # Remaster archiso file.
    >>> $0 ./archiso.iso ./remasteredArchiso.iso

    # Remaster archiso file verbosely.
    >>> $0 ./archiso.iso ./remasteredArchiso.iso --verbose

    # Show help message.
    >>> $0 --help
EOF
    }
    function printCommandLineOptionDescription() {
        # Prints descriptions about each available command line option.
        # NOTE: "-k" and "--key-map-configuration" isn't needed in the future.
        cat << EOF
    -h --help Shows this help message.

    -v --verbose Tells you what is going on (default: "$_VERBOSE").

    -d --debug Gives you any output from all tools which are used
        (default: "$_DEBUG").#

    -c --squash-filesystem-compressor Defines the squash filesystem compressor.
        All supported compressors for "mksquashfs" are possible
        (default: "$_SQUASH_FILESYSTEM_COMPRESSOR").

    -k --keyboard-layout Defines needed key map (default: "$_KEYBOARD_LAYOUT").

    -k --key-map-configuration FILE_CONTENT Keyboard map configuration
        (default: "$_KEY_MAP_CONFIGURATION_FILE_CONTENT").
EOF
    }
    function printHelpMessage() {
        # Provides a help message for this module.
        echo -e "\nUsage: $0 /path/to/archiso/file.iso /path/to/newly/packed/archiso/file.iso [options]\n"
        printUsageMessage "$@"
        echo -e '\nExamples:\n'
        printUsageExamples "$@"
        echo -e '\nOption descriptions:\n'
        printCommandLineOptionDescription "$@"
        echo
    }
    function commandLineInterface() {
        # Provides the command line interface and interactive questions.
        while true; do
            case "$1" in
                -h|--help)
                    shift
                    printHelpMessage "$0"
                    exit 0
                    ;;
                -v|--verbose)
                    shift
                    _VERBOSE='yes'
                    ;;
                -d|--debug)
                    shift
                    _STANDARD_OUTPUT=/dev/stdout
                    _ERROR_OUTPUT=/dev/stderr
                    ;;
                -c|--squash-filesystem-compressor)
                    shift
                    _SQUASH_FILESYSTEM_COMPRESSOR="$1"
                    shift
                    ;;
                -k|--keyboard-layout)
                    shift
                    _KEYBOARD_LAYOUT="$1"
                    shift
                    ;;
                -k|--key-map-configuation)
                    shift
                    _KEY_MAP_CONFIGURATION_FILE_CONTENT="$1"
                    shift
                    ;;

                '')
                    shift
                    break
                    ;;
                *)
                    if [[ ! "$_SOURCE_PATH" ]]; then
                        _SOURCE_PATH="$1"
                    elif [[ ! "$_TARGET_PATH" ]]; then
                        _TARGET_PATH="$1" && \
                        if [[ -d "$_TARGET_PATH" ]]; then
                            _TARGET_PATH="$(readlink --canonicalize \
                                "$_TARGET_PATH")/$(basename "$_SOURCE_PATH")"
                        fi
                    else
                        log 'critical' \
                            "Given argument: \"$1\" is not available." '\n' && \
                        printHelpMessage "$0"
                    fi
                    shift
            esac
        done
        if [[ ! "$_SOURCE_PATH" ]] || [[ ! "$_TARGET_PATH" ]]; then
            log 'critical' \
                'You have to provide source and target file path.' '\n' && \
            printHelpMessage "$0"
            return 1
        fi
    }
    function log() {
        # Handles logging messages. Returns non zero and exit on log level
        # error to support chaining the message into toolchain.
        local loggingType='info' && \
        local message="$1" && \
        if [ "$2" ]; then
            loggingType="$1"
            message="$2"
        fi
        if [ "$_VERBOSE" == 'yes' ] || [ "$loggingType" == 'error' ] || \
           [ "$loggingType" == 'critical' ]; then
            if [ "$3" ]; then
                echo -e -n "$3"
            fi
            echo -e "${loggingType}: $message"
        fi
        if [ "$loggingType" == 'error' ]; then
            exit 1
        fi
    }

    # endregion

    # region tools

    function remasterISO() {
        # Remasters given iso into new iso. If new systemd programs are used
        # (if first argument is "true") they could have problems in change root
        # environment without and exclusive dbus connection.
        log "Mount \"$_SOURCE_PATH\" to \"$_MOUNPOINT_PATH\"." && \
        mount -t iso9660 -o loop "$_SOURCE_PATH" "$_MOUNPOINT_PATH" \
            1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
        log "Copy content in \"$_MOUNPOINT_PATH\" to \"$_TEMPORARY_REMASTERING_PATH\"." && \
        cp --archiv "${_MOUNPOINT_PATH}/"* "$_TEMPORARY_REMASTERING_PATH" \
            1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
        local path && \
        for path in ${_RELATIVE_PATHS_TO_SQUASH_FILESYSTEM[*]}; do
            log "Extract squash file system in \"${_TEMPORARY_REMASTERING_PATH}/$path\" to \"${_TEMPORARY_FILESYSTEM_REMASTERING_PATH}\"." && \
            unsquashfs -d "${_TEMPORARY_FILESYSTEM_REMASTERING_PATH}" \
                "${_TEMPORARY_REMASTERING_PATH}/${path}" \
                1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
            rm --force "${_TEMPORARY_REMASTERING_PATH}/${path}" \
                1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
            log "Mount root file system in \"${_TEMPORARY_FILESYSTEM_REMASTERING_PATH}\" to \"$_TEMPORARY_ROOT_FILESYSTEM_REMASTERING_PATH\"." && \
            mount "${_TEMPORARY_FILESYSTEM_REMASTERING_PATH}/"* \
                "$_TEMPORARY_ROOT_FILESYSTEM_REMASTERING_PATH" \
                1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
            log "Copy \"$(dirname "$(readlink --canonicalize "$0")")/$_RELATIVE_SOURCE_FILE_PATH\" to \"${_TEMPORARY_ROOT_FILESYSTEM_REMASTERING_PATH}/${_RELATIVE_TARGET_FILE_PATH}\"." && \
            cp "$(dirname "$(readlink --canonicalize "$0")")/$_RELATIVE_SOURCE_FILE_PATH" \
                "${_TEMPORARY_ROOT_FILESYSTEM_REMASTERING_PATH}/${_RELATIVE_TARGET_FILE_PATH}" \
                1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
            log "Set key map to \"$_KEYBOARD_LAYOUT\"." && \
            if [[ "$1" == 'true' ]]; then
                arch-chroot "$_TEMPORARY_ROOT_FILESYSTEM_REMASTERING_PATH" \
                    localectl set-keymap "$_KEYBOARD_LAYOUT" \
                    1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
                arch-chroot "$_TEMPORARY_ROOT_FILESYSTEM_REMASTERING_PATH" \
                    set-locale LANG="en_US.utf8" 1>"$_STANDARD_OUTPUT" \
                    2>"$_ERROR_OUTPUT"
            else
                echo -e "$_KEY_MAP_CONFIGURATION_FILE_CONTENT" 1>\
                    "${_TEMPORARY_ROOT_FILESYSTEM_REMASTERING_PATH}/etc/vconsole.conf" \
                    2>"$_ERROR_OUTPUT"
            fi
            log 'Set root symbolic link for root user.' && \
            local fileName && \
            for fileName in .bashrc .zshrc; do
                if [[ -f "${_TEMPORARY_ROOT_FILESYSTEM_REMASTERING_PATH}/root/" ]]; then
                    echo -e "$_BASH_RC_CODE" \
                        1>>"${_TEMPORARY_ROOT_FILESYSTEM_REMASTERING_PATH}/root/$fileName"
                else
                    echo -e "$_BASH_RC_CODE" \
                        1>"${_TEMPORARY_ROOT_FILESYSTEM_REMASTERING_PATH}/root/$fileName"
                fi
            done
            log "Unmount \"$_TEMPORARY_ROOT_FILESYSTEM_REMASTERING_PATH\"." && \
            umount "$_TEMPORARY_ROOT_FILESYSTEM_REMASTERING_PATH" \
                1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
            log "Make new squash file system from \"${_TEMPORARY_FILESYSTEM_REMASTERING_PATH}\" to \"${_TEMPORARY_REMASTERING_PATH}/${path}\"." && \
            mksquashfs "${_TEMPORARY_FILESYSTEM_REMASTERING_PATH}" \
                "${_TEMPORARY_REMASTERING_PATH}/${path}" -noappend -comp \
                "$_SQUASH_FILESYSTEM_COMPRESSOR" 1>"$_STANDARD_OUTPUT" \
                2>"$_ERROR_OUTPUT" && \
            rm --recursive --force \
                "${_TEMPORARY_FILESYSTEM_REMASTERING_PATH}" \
                1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
            if [[ $? != 0 ]]; then
                log "Unmount \"$_MOUNPOINT_PATH\"." && \
                umount "$_MOUNPOINT_PATH" 1>"$_STANDARD_OUTPUT" \
                    2>"$_ERROR_OUTPUT"
                return $?
            fi
        done
        local volumeID="$(isoinfo -i "$_SOURCE_PATH" -d | grep \
            --extended-regexp 'Volume id:' | grep --only-matching \
            --extended-regexp '[^ ]+$')" && \
        log "Create new iso file from \"$_TEMPORARY_REMASTERING_PATH\" in \"$_TARGET_PATH\" with old detected volume id \"$volumeID\"." && \
        cd "${_MOUNPOINT_PATH}" && \
        genisoimage -verbose -full-iso9660-filenames -rational-rock -joliet \
            --volid "$volumeID" -eltorito-boot "isolinux/isolinux.bin" \
            -no-emul-boot -boot-load-size 4 -boot-info-table \
            -eltorito-catalog "isolinux/boot.cat" -output "$_TARGET_PATH" \
            "$_TEMPORARY_REMASTERING_PATH" 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT" && \
        cd - 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
        log "Unmount \"$_MOUNPOINT_PATH\"." && \
        umount "$_MOUNPOINT_PATH" 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        return $?
    }
    function tidyUp() {
        # Removes temporary created files.
        log "Remove temporary created location \"$_MOUNPOINT_PATH\"." &&
        rm --recursive --force "$_MOUNPOINT_PATH" 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT"
        log "Remove temporary created location \"$_TEMPORARY_REMASTERING_PATH\"." && \
        rm --recursive --force "$_TEMPORARY_REMASTERING_PATH" \
            1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        log "Remove temporary created location \"$_TEMPORARY_FILESYSTEM_REMASTERING_PATH\"." && \
        rm --recursive --force "$_TEMPORARY_FILESYSTEM_REMASTERING_PATH" \
            1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        log "Remove temporary created location \"$_TEMPORARY_ROOT_FILESYSTEM_REMASTERING_PATH\"." && \
        rm --recursive --force "$_TEMPORARY_ROOT_FILESYSTEM_REMASTERING_PATH" \
            1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        return $?
    }

    # endregion

# endregion

# region controller

    if [[ "$0" == *"${__NAME__}.bash" ]]; then
        commandLineInterface "$@" || return $?
        # Switch user if necessary and possible.
        if [[ root != "$USER" ]] && grep root /etc/passwd &>/dev/null; then
            sudo -u root "$0" "$@"
            return $?
        fi
        remasterISO || archInstallLog 'error' 'Remastering given iso failed.'
        tidyUp || archInstallLog 'error' 'Tidying up failed.'
        archInstallLog \
            "Remastering given image \"$_SOURCE_PATH\" to \"$_TARGET_PARG\" has successfully finished."
        return $?
    fi

# endregion

}

# region footer

[[ "$0" == *"${__NAME__}.bash" ]] && "$__NAME__" "$@"
exit $?

# endregion

# region vim modline

# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:

# endregion
