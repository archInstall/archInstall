#!/bin/bash
# Copyright Milan Oberkirch 2013, published under WTFPL.
# Installs a basic ArchLinux-System.

self_path=$(dirname $(readlink --canonicalize $0))
source "$self_path/archInstall.bash" --load-environement

__NAME__="yourWrapperScript" 
function yourWrapperScript() {
### Wrapper for archInstall to do exactly the same.

  function yourWrapperScriptPrintHelpMessage() {
  ### Prints Details about Usage and Options.
  cat <<EndOfUsageMessage
Usage: $0 [Options]
$__NAME__ installs linux, arch linux

Option descriptions:
-W --wrapper <filename> Use Wrapper in <filename> instead of ./archInstall.bash
$(archInstallPrintCommandLineOptionDescriptions) "$@" 
EndOfUsageMessage
  }

  function yourWrapperScriptParseCommandLine() {
  ### Parse arguments and own options while collecting the options for the
  ### archInstall-wrapper function.
    while [ $1 ]; do
      echo hans
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
        *)
          archInstallWrapperOptions+=" $1" 
          shift;;
      esac
    done
  }

  local archInstallWrapperFile="./archInstall.bash" 
  local archInstallWrapperFunction="" 
  local archInstallWrapperOptions="" 

  yourWrapperScriptParseCommandLine "$@"
  local name="$__NAME__" 
  source ${archInstallWrapperFile}
  __NAME__="$name" 
  archInstallWrapperFunction=`basename "$archInstallWrapperFile" .bash`

  if $archInstallWrapperFunction --load-environement\
    ${archInstallWrapperOptions}
    then
      echo hans
    fi
}

if [[ "$0" == *${__NAME__}.bash ]]; then
  "$__NAME__" "$@" 
  exit
fi
