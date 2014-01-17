#!/bin/bash
# Copyright 2013 Torben Sickert, Milan Oberkirch

SELF_PATH=$(dirname $(readlink --canonicalize $0))/
source "${SELF_PATH}archInstall.bash" --load-environment

__NAME__="makeRamOnlyLinux"

function makeRamOnlyLinux () {
  function staticXorgConfiguration() {
    cat <<! > $tempDirectory/etc/X11/xorg.conf
Section "ServerFlags"
    Option          "AutoAddDevices" "False"
EndSection
!
  }
    function makeRamOnlyLinuxPrintHelpMessage() {
        cat << EOF
Usage: $0 <initramfs-filename> [options]

    $__NAME__ installs an arch linux into an initramfs file and places a
    compatible kernal at "<initramfs-filename>Kernel".

Option descriptions:

    -W --wrapper <filename> Use wrapper in <filename> to generate the
        root-Filesystem to be packed into the initramfs-file.

$(archInstallPrintCommandLineOptionDescriptions "$@" | \
    sed '/^ *-[a-z] --output-system .*$/,/^$/d')
EOF
    }
    local printHelpMessage=$(echo "$@" | grep --extended-regexp '(^| )(-h|--help)($| )')
    if [ ! "$1" ]; then
        archInstallLog 'critical' \
            'You have to provide an initramfs file path.' '\n'
    fi
    if [ ! "$1" ] || [ "$printHelpMessage" ]; then
        echo
        makeRamOnlyLinuxPrintHelpMessage "$@"
        echo
        test "$1"
        exit $?
    else
        local initramfsFilePath="$1"
        shift
    fi
    local tempDirectory=$(mktemp --directory)
    local archInstallWrapperFile="./archInstall.bash"
    local archInstallWrapperOptions="--load-environment --output-system $tempDirectory"
    while [ $1 ]; do
      case $1 in
        -W|--wrapper)
          if [[ "$archInstallWrapperFile" == "./archInstall.bash" ]]
          then
            shift
            archInstallWrapperFile="$1"
          else
            archInstallWrapperOptions+=" $1 $2"
            shift
          fi
          shift;;
        *)
          archInstallWrapperOptions+=" $1"
          shift;;
      esac
    done
    local archInstallWrapperFunction=`basename "$archInstallWrapperFile" .bash`

    local name="$__NAME__"
    source ${archInstallWrapperFile}
    __NAME__="$name"

    if $archInstallWrapperFunction ${archInstallWrapperOptions}
    then
        if [ -d $tempDirectory/etc/X11 ]; then staticXorgConfiguration; fi
        ln --symbolic /usr/lib/systemd/systemd "$tempDirectory/init" && \
        archInstallLog 'info' \
            "Copy initramfs compatible kernel to target location \"${initramfsFilePath}Kernel\"." && \
        cp "$tempDirectory/boot/vmlinuz-linux" "${initramfsFilePath}Kernel" \
            1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
        archInstallLog 'info' \
            'Remove unneeded packages like kernel and initramfs build scripts from ram only system.' && \
        archInstallChangeRoot "$tempDirectory" pacman --arch \
            "$_CPU_ARCHITECTURE" --nodeps --noconfirm --remove linux \
            mkinitcpio 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
        archInstallLog 'info' \
            "Pack initramfs file \"$initramfsFilePath\"." && \
        "${SELF_PATH}/packcpio.sh" "$tempDirectory" "$initramfsFilePath" \
            1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
        rm --recursive --force "$tempDirectory" 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT" && \
        archInstallLog 'info' \
            "Initramfs successfully created into \"$initramfsFilePath\"."
    elif [[ $? == 1 ]]; then
        echo
        makeRamOnlyLinuxPrintHelpMessage "$@"
        echo
    fi
    exit $?
}

[[ "$0" == *${__NAME__}.bash ]] && "$__NAME__" "$@"
