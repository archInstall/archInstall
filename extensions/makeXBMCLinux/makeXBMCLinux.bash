#!/bin/bash
# Copyright 2013 Torben Sickert, Milan Oberkirch

SELF_PATH=$(dirname $(readlink --canonicalize $0))/
source "${SELF_PATH}archInstall.bash" --load-environment

__NAME__='makeXBMCLinux'

makeXBMCLinux() {
    local _OUTPUT_SYSTEM="$__NAME__"
    local _TEMP_ROOT_PATH=$(mktemp --directory)
    local _ADDITIONAL_PACKAGES=(xbmc xorg xorg-xinit alsa-utils pulseaudio openssh)
    local _INSTALL_ARCH_LINUX_OPTIONS=''
    local _MEDIA_FILES_PATH='/var/lib/xbmc/media-files'

    function makeXBMCLinuxPrintHelpMessage() {
        cat << EOF
Usage: $0 [Options]

    $__NAME__ installs an xbmc frontend with an underlying arch linux.

Option descriptions:

    -M --media-files <media-folder> Give a folder with media-files to copy into
        the system. This option doesn't work in combination with "--ram-only".
        (Hint: makeRamOnlyLinux.bash --wrapper makeXBMCLinux.bash --media-files)

    -W --wrapper <filename> Use wrapper in <filename> to generate the
        root-filesystem. This option doesn't work in combination with
        "--ram-only".

$(installArchLinuxPrintCommandLineOptionDescription) "$@"
EOF
    }

    while true; do
        case $1 in
            -h|--help)
                echo
                makeXBMCLinuxPrintHelpMessage "$@"
                echo
                exit
                ;;
            -M|--media-files)
                shift
                local _MEDIA_FOLDER_PATH="$1"
                shift
                ;;
            -W|--wrapper)
                if [ ! "$_WRAPPER_FILENAME" ]; then
                  shift
                  local _WRAPPER_FILENAME="$1"
                else
                  _INSTALL_ARCH_LINUX_OPTIONS+=" $1 $2"
                  shift
                fi
                shift
                ;;
            -o|--output-system)
                shift
                local _OUTPUT_SYSTEM="$1"
                shift
                ;;
            '')
                shift
                break 2
                ;;
            *)
                _INSTALL_ARCH_LINUX_OPTIONS+=" $1"
                shift
                ;;
        esac
    done
    # NOTE: the global "__NAME__" variable has to be restored to let
    # "installArchLinux" know that it should be executed instead of
    # beeing sourced.
    local command="archInstall --output-system $_OUTPUT_SYSTEM"
    local name="$__NAME__"
    if [ "$_WRAPPER_FILENAME" ]; then
        source "$_WRAPPER_FILENAME"
        command=`basename "$_WRAPPER_FILENAME" .bash`
        command+=" --output-system $_OUTPUT_SYSTEM"
    fi
    __NAME__="$name"
    if ${command[*]} --no-reboot --host-name xbmcLinux --load-environment \
        --needed-services xbmc dhcpcd sshd --additional-packages \
        ${_ADDITIONAL_PACKAGES[*]} ${_INSTALL_ARCH_LINUX_OPTIONS[*]}
    then
        if [ "$_MEDIA_FOLDER_PATH" ] && [ -d "$_MEDIA_FOLDER_PATH" ]; then
            if [ -b "$_OUTPUT_SYSTEM" ]; then
                if echo "$_OUTPUT_SYSTEM" | grep --extended-regexp --invert-match "[0-9]$"; then
                    _OUTPUT_SYSTEM+="1"
                fi
                installArchLinuxLog 'info' "Mounting \"$_OUTPUT_SYSTEM\" to \"$_TEMP_ROOT_PATH\"."
                mount "$_OUTPUT_SYSTEM" "$_TEMP_ROOT_PATH"
            else
                _TEMP_ROOT_PATH="$_OUTPUT_SYSTEM"
            fi
            installArchLinuxLog 'info' \
                "Copy \"$_MEDIA_FOLDER_PATH\" to \"${_TEMP_ROOT_PATH}${_MEDIA_FILES_PATH}\"."
            cp --recursive "$_MEDIA_FOLDER_PATH" \
                "${_TEMP_ROOT_PATH}${_MEDIA_FILES_PATH}"
            if [ -b "$_OUTPUT_SYSTEM" ]; then
                umount "$_OUTPUT_SYSTEM" 2>/dev/null
            fi
        fi
    elif [[ $? == 1 ]]; then
        echo
        makeXBMCLinuxPrintHelpMessage "$@"
        echo
    else
        return $?
    fi
}

if [[ "$0" == *${__NAME__}.bash ]]; then
  "$__NAME__" "$@"
  exit $?
fi
