#!/bin/bash
# Copyright Milan Oberkirch 2013, published under WTFPL.
# Installs a basic ArchLinux-System.

self_path=$(dirname $(readlink --canonicalize $0))
source "$self_path/installArchLinux.bash" --load-environement

__NAME__="yourWrapperScript" 
function yourWrapperScript() {
### Wrapper for installArchlinux to do exactly the same.

  function yourWrapperScriptPrintHelpMessage() {
  ### Prints Details about Usage and Options.
  cat <<EndOfUsageMessage
Usage: $0 [Options]
$__NAME__ installs linux, arch linux

Option descriptions:
-W --wrapper <filename> Use Wrapper in <filename> instead of ./installArchLinux.bash
$(installArchLinuxPrintCommandLineOptionDescriptions) "$@" 
EndOfUsageMessage
  }

  function yourWrapperScriptParseCommandLine() {
  ### Parse arguments and own options while collecting the options for the
  ### installArchlinux-wrapper function.
    while [ $1 ]; do
      echo hans
      case $1 in
        -W|--wrapper)
          if [[ "$installArchLinuxWrapperFile" == "./installArchLinux.bash" ]];
          then
            shift
            installArchLinuxWrapperFile="$1"
          else
            installArchLinuxWrapperOptions+=" $1 $2"
            shift
          fi
          shift;;
        *)
          installArchLinuxWrapperOptions+=" $1" 
          shift;;
      esac
    done
  }

  local installArchLinuxWrapperFile="./installArchLinux.bash" 
  local installArchLinuxWrapperFunction="" 
  local installArchLinuxWrapperOptions="" 

  yourWrapperScriptParseCommandLine "$@"
  local name="$__NAME__" 
  source ${installArchLinuxWrapperFile}
  __NAME__="$name" 
  installArchLinuxWrapperFunction=`basename "$installArchLinuxWrapperFile" .bash`

  if $installArchLinuxWrapperFunction --load-environement\
    ${installArchLinuxWrapperOptions}
    then
      echo hans
    fi
}

if [[ "$0" == *${__NAME__}.bash ]]; then
  "$__NAME__" "$@" 
  exit
fi
