#!/usr/bin/env bash
#-*- coding: utf-8 -*-

# Copyright 2013, Milan David Oberkirch <oberkirm@informatik.uni-freiburg.de>
### This script will build a basic archlinux-system with unity as window manager
### and lightdm as display-manager.
### Depends on archInstall.bash.

self_path=$(dirname $(readlink --canonicalize $0))
source "$self_path/archInstall.bash" --load-environment

__NAME__="makeUnityLinux" 
function makeUnityLinux() {
  #region member-functions
    function makeUnityLinuxPrintHelpMessage() {
    ### Prints Details about Usage and Options.
      cat <<EndOfUsageMessage
Usage: $0 [Options]
  $__NAME__ installs linux $(#Wozu ist dein Skript aus Nutzer-Sicht gut?)
Option descriptions:
  -W --wrapper <filename> Use Wrapper in <filename> instead of ./archInstall.bash

$(archInstallPrintCommandLineOptionDescription) "$@" 
EndOfUsageMessage
}

    function makeUnityLinuxParseCommandLine() { #-> 2.
    ### Parse arguments and own options while collecting the options for the
    ### archInstall-wrapper function.
      while [ $1 ]; do
        case $1 in
          -W|--wrapper)
            if [[ "$archInstallWrapperFile" == "./archInstall.bash" ]];
            then
              shift
              archInstallWrapperFile="$1"
            else
              archInstallWrapperOptions+=" $1 $2"
              shift
            fi
            shift;;
          -f|--additional-packages)
            shift
            while [[ "$1" != -* ]]; do
              laterAdditionalPackages+=" $1"
              shift
            done;;
          *)
            archInstallWrapperOptions+=" $1" 
            shift;;
        esac
      done
    }
  #endregion
  #region execution-sequence
    local archInstallWrapperFile="./archInstall.bash" 
    local archInstallWrapperFunction="" 
    local archInstallWrapperOptions="" 
    local laterAdditionalPackages=""
    local conflictingPackages="glib2"

    makeUnityLinuxParseCommandLine "$@"

    local name="$__NAME__" 
    source ${archInstallWrapperFile}
    __NAME__="$name" 
    archInstallWrapperFunction=`basename "$archInstallWrapperFile" .bash`

    if $archInstallWrapperFunction --load-environment\
       ${archInstallWrapperOptions} --additional-packages xorg
    then
      archInstallLog 'info' 'Adding unity-repository to configuration.'
      archInstallChangeRootViaMount "$_OUTPUT_SYSTEM" /bin/bash <<EndOfPatchScript
cat <<EndOfUnityRepository >>/etc/pacman.conf
[Unity-for-Arch]
SigLevel = Optional TrustAll
Server = http://dl.dropbox.com/u/486665/Repos/Unity-for-Arch/\\\$arch

[Unity-for-Arch-Extra] 
SigLevel = Optional TrustAll 
Server = http://dl.dropbox.com/u/486665/Repos/Unity-for-Arch-Extra/\\\$arch
EndOfUnityRepository
EndOfPatchScript
      archInstallLog 'info' 'Syncing package-sources.'
      archInstallChangeRootViaMount "$_OUTPUT_SYSTEM" /usr/bin/pacman\
        --sync --refresh --refresh --arch "$_CPU_ARCHITECTURE"
      archInstallLog 'info' \
        'Collecting list of additional packages to install.'
      local unityPackageList="
        `archInstallChangeRootViaMount "$_OUTPUT_SYSTEM" /usr/bin/pacman\
            --sync --list Unity-for-Arch Unity-for-Arch-Extra |\
        cut -f2 -d' '`"
      archInstallLog 'info'\
        'Temporary removing conflicting dependencies.'
      archInstallChangeRootViaMount "$_OUTPUT_SYSTEM" /usr/bin/pacman \
        --arch "$_CPU_ARCHITECTURE"\
        --remove --nodeps --nodeps --noconfirm "$conflictingPackages"
      archInstallLog 'info'\
        'Installing unity into target-system.'
      archInstallLoadCache
      archInstallChangeRootViaMount "$_OUTPUT_SYSTEM" /usr/bin/pacman \
        --arch "$_CPU_ARCHITECTURE" --sync --noconfirm $unityPackageList
      if [[ "$laterAdditionalPackages" ]]; then
        archInstallChangeRootViaMount "$_OUTPUT_SYSTEM" /usr/bin/pacman \
          --arch "$_CPU_ARCHITECTURE" --sync --noconfirm $laterAdditionalPackages
      fi
      archInstallCache
      archInstallTidyUpSystem
      archInstallLog 'info'\
        'Enable lightdm as display-manager.'
      archInstallChangeRootViaMount "$_OUTPUT_SYSTEM" /bin/bash <<EndOfPatchScript
cat <<EndOfLightdmConfig >/etc/lightdm/lightdm.conf
[LightDM]

[SeatDefaults]
greeter-session=unity-greeter
autologin-user=$_USER_NAME

[XDMCPServer]

[VNCServer]

EndOfLightdmConfig
EndOfPatchScript
      archInstallChangeRootViaMount "$_OUTPUT_SYSTEM" /usr/bin/systemctl\
        enable lightdm.service
      archInstallChangeRootViaMount "$_OUTPUT_SYSTEM"\
        /usr/bin/rm -f /usr/lib/systemd/system/lightdm-plymouth.service
      archInstallLog 'info' 'Finished installing unity.'
    fi
  #endregion
}

if [[ "$0" == *${__NAME__}.bash ]]; then
  "$__NAME__" "$@" 
  exit
fi

# region vim modline

# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:

# endregion
