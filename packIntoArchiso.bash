#!/usr/bin/env bash
# -*- coding: utf-8 -*-

# region vim modline

# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:

# endregion

# region header

# Copyright Torben Sickert 16.12.2012

# License
#    This library written by Torben Sickert stand under a creative commons
#    naming 3.0 unported license.
#    see http://creativecommons.org/licenses/by/3.0/deed.de

# Examples:

#     # Start install progress command (Assuming internet is available):
#     ./packIntoArchIso.bash /path/to/archiso/file.iso \
#         /path/to/newly/packed/archiso/file.iso

# Note that you only get very necessary output until you provide "--verbose" as
# commandline options.

# Dependencies:

#     bash (or any bash like shell)
#     test           - Check file types and compare values.
#     mount          - Filesystem mounter.
#     umount         - Filesystem unmounter.
#     mktemp         - Create a temporary file or directory.
#     squashfs-tools - Packs and unpacks the iso embedded squash filesystem.
#     cdrkit         - Suite of programs for CD/DVD recording, ISO image
#                      creation, and audio CD extraction
#     touch          - Change file timestamps or creates them.
#     grep           - Searches the named input files (or standard input if no
#                      files are named, or if a single hyphen-minus (-) is
#                      given as file name) for lines containing a match to
#                      the given PATTERN.  By default, grep prints the matching
#                      lines.
#     shift          - Shifts the command line arguments.
#     readlink       - Print resolved symbolic links or canonical file names.

# Optional dependencies:

#     sudo - Perform action as another user.

__NAME__='packIntoArchiso'

# endregion

# TODO manage debug an normal output

function packIntoArchiso() {
    # Provides the main module scope.

# region configuration

    # region properti es

        # region c ommand line arguments

    local _VERBOSE='no'
    local _SQUASH_FILESYSTEM_COMPRESSOR='lzma'

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
    local _RELATIVE_SOURCE_FILE_PATH="archInstall.bash"
    local _RELATIVE_TARGET_FILE_PATH="usr/bin/localInstall"
    local _BASH_RC_CODE="alias getInstallScript='wget https://raw.github.com/archInstall/archInstall/master/archInstall.bash --output-document archInstall.bash && chmod +x archInstall.bash && ./archInstall.bash'\nalias install='([ -f /root/archInstall.bash ] || getInstallScript);/root/archInstall.bash'"

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
    function printCommandLineOptionDescriptions() {
        # Prints descriptions about each available command line option.
        # NOTE; All letters are used for short options.
        # NOTE: "-k" and "--key-map-configuration" isn't needed in the future.
        cat << EOF
    -h --help Shows this help message.

    -v --verbose Tells you what is going on (default: "$_VERBOSE").

    -d --debug Gives you any output from all tools which are used
        (default: "$_DEBUG").#

    -c --squash-filesystem-compressor Defines the squash filesystem compressor.
        All supported compressors for "mksquashfs" are possible.
        (default: "$_SQUASH_FILESYSTEM_COMPRESSOR").
EOF
    }
    function printHelpMessage() {
        # Provides a help message for this module.
        echo -e "\nUsage: $0 /path/to/archiso/file.iso /path/to/newly/packed/archiso/file.iso [options]\n"
        printUsageMessage "$@"
        echo -e '\nExamples:\n'
        printUsageExamples "$@"
        echo -e '\nOption descriptions:\n'
        printCommandLineOptionDescriptions "$@"
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
        # Remasters given iso into new iso.
        log "Mount \"$_SOURCE_PATH\" to \"$_MOUNPOINT_PATH\"." && \
        mount -t iso9660 -o loop "$_SOURCE_PATH" "$_MOUNPOINT_PATH" && \
        log "Copy content in \"$_MOUNPOINT_PATH\" to \"$_TEMPORARY_REMASTERING_PATH\"." && \
        cp --archiv "${_MOUNPOINT_PATH}/"* "$_TEMPORARY_REMASTERING_PATH" && \
        local path && \
        for path in ${_RELATIVE_PATHS_TO_SQUASH_FILESYSTEM[*]}; do
            log "Extract squash file system in \"${_TEMPORARY_REMASTERING_PATH}/$path\" to \"${_TEMPORARY_FILESYSTEM_REMASTERING_PATH}\"." && \
            unsquashfs -d "${_TEMPORARY_FILESYSTEM_REMASTERING_PATH}" \
                "${_TEMPORARY_REMASTERING_PATH}/${path}" && \
            log "Mount root file system in \"$_TEMPORARY_ROOT_FILESYSTEM_REMASTERING_PATH\"." && \
            mount "${_TEMPORARY_FILESYSTEM_REMASTERING_PATH}/"* \
                "$_TEMPORARY_ROOT_FILESYSTEM_REMASTERING_PATH" && \
            log "Copy \"$(dirname "$(readlink --canonicalize "$0")")/$_RELATIVE_SOURCE_FILE_PATH\" to \"${_TEMPORARY_ROOT_FILESYSTEM_REMASTERING_PATH}/${_RELATIVE_TARGET_FILE_PATH}\"." && \
            cp "$(dirname "$(readlink --canonicalize "$0")")/$_RELATIVE_SOURCE_FILE_PATH" \
                "${_TEMPORARY_ROOT_FILESYSTEM_REMASTERING_PATH}/${_RELATIVE_TARGET_FILE_PATH}" && \
            log 'Set root symbolic link for root user.' && \
            touch "${_TEMPORARY_ROOT_FILESYSTEM_REMASTERING_PATH}/root/.bashrc" && \
            echo -e "$_BASH_RC_CODE" \
                1>"${_TEMPORARY_ROOT_FILESYSTEM_REMASTERING_PATH}/root/.bashrc" && \
            log "Unmount \"$_TEMPORARY_ROOT_FILESYSTEM_REMASTERING_PATH\"." && \
            mksquashfs "${_TEMPORARY_FILESYSTEM_REMASTERING_PATH}" \
                "${_TEMPORARY_REMASTERING_PATH}/${path}" -noappend -comp \
                "$_SQUASH_FILESYSTEM_COMPRESSOR" && \
            rm --recursive --force "${_TEMPORARY_FILESYSTEM_REMASTERING_PATH}"
            umount "$_TEMPORARY_ROOT_FILESYSTEM_REMASTERING_PATH"
            if [[ $? != 0 ]]; then
                log "Unmount \"$_MOUNPOINT_PATH\"." && \
                umount "$_MOUNPOINT_PATH"
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
            "$_TEMPORARY_REMASTERING_PATH" && \
        cd -
        log "Unmount \"$_MOUNPOINT_PATH\"." && \
        umount "$_MOUNPOINT_PATH"
        return $?
    }
    function tidyUp() {
        # Removes temporary created files.
        log "Remove temporary created location \"$_MOUNPOINT_PATH\"." &&
        rm --recursive --force "$_MOUNPOINT_PATH"
        log "Remove temporary created location \"$_TEMPORARY_REMASTERING_PATH\"." && \
        rm --recursive --force "$_TEMPORARY_REMASTERING_PATH"
        log "Remove temporary created location \"$_TEMPORARY_FILESYSTEM_REMASTERING_PATH\"." && \
        rm --recursive --force "$_TEMPORARY_FILESYSTEM_REMASTERING_PATH"
        log "Remove temporary created location \"$_TEMPORARY_ROOT_FILESYSTEM_REMASTERING_PATH\"." && \
        rm --recursive --force "$_TEMPORARY_ROOT_FILESYSTEM_REMASTERING_PATH"
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
        remasterISO && \
        tidyUp
        return $?
    fi

# endregion

}

# region footer

[[ "$0" == *"${__NAME__}.bash" ]] && "$__NAME__" "$@"
exit $?

# endregion
