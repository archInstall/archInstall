#!/bin/bash
# Script to build an ArchLinux into a squashfs and generate compatible kernel
# and initramfs.

self_path=$(dirname $(readlink --canonicalize $0))
source "$self_path/archInstall.bash" --load-environment

__NAME__="makeSquashLinux"

function makeSquashLinux () {
  ### Generate Archlinux, patch it to use it to serve kernel and initramfs,
  ### and pack it into a squashfs.
  #region member-functions
  #region makeSquashLinuxPrintHelpMessage, makeSquashLinuxParseCommandLine

  function makeSquashLinuxPrintHelpMessage() {
  ### Prints Details about Usage and Options.
  cat << EOF
Usage: $0 <squashfsFilePath> <kernelFilePath> <initramfsFilePath> [options]

$__NAME__ installs an arch linux into an squashfs file.

Option descriptions:
    -W --wrapper <file>  Use wrapper in <file> to generate the root-Filesystem
    -X --xbmc Use "../makeXBMCLinux/makeXBMCLinux.bash" as wrapper.
    -T --temp-folder <path> Store temporary files in <path>.

$(archInstallPrintCommandLineOptionDescription "$@" | \
  sed '/^ *-[a-z] --output-system .*$/,/^$/d')
EOF
  }

  function makeSquashLinuxValidateCommandLine() {
  ### Checks if all arguments were given. Prints an Usage-message and error-code
  ### if not.
    local printHelpMessageWithErrno
    if [ $(echo "$@" | grep --extended-regexp '(^| )(-h|--help)($| )') ]; then
      printHelpMessageWithErrno=0
    elif [ ! "$1" ]; then
      archInstallLog 'critical' \
        'You have to provide an squashfs file path.' '\n'
      printHelpMessageWithErrno=1
    elif [ ! "$2" ]; then
      archInstallLog 'critical' 'You have to provide an kernel file path.'
      printHelpMessageWithErrno=1
    elif [ ! "$3" ]; then
      archInstallLog 'critical' 
        'You have to provide an initramfs file path.'
      printHelpMessageWithErrno=1
    fi
    if [ "$printHelpMessageWithErrno" ]; then
      echo
      makeSquashLinuxPrintHelpMessage "$@"
      echo
      exit $printHelpMessageWithErrno
    fi
  }

  function makeSquashLinuxParseCommandLine() {
  ### Parse arguments and own options while collecting the options for the
  ### archInstall-wrapper function.
    makeSquashLinuxValidateCommandLine "$@"
    squashfsFilePath="$1"; shift
    kernelFilePath="$1"; shift
    initramfsFilePath="$1"; shift
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
        -X|--xbmc)
          archInstallWrapperFile="../makeXBMCLinux/makeXBMCLinux.bash"
          shift;;
        -T|--temp-folder)
          shift
          tempDirectory="$1"
          mkdir -p "$tempDirectory"
          shift;;
        *)
          archInstallWrapperOptions+=" $1"
          shift;;
      esac
    done
  }

  #endregion
  #region makeSquashLinuxConfigure
  function makeSquashLinuxConfigure() {
  ### Create needed hooks for network-boot and patch pacman.conf and mkinitcpio.conf
  ### to be able to use them.
    cat <<! >> $tempDirectory/etc/pacman.conf
[pfkernel]
SigLevel = Optional TrustAll
Server = http://dl.dropbox.com/u/11734958/\$arch
[archlinuxfr]
SigLevel = Optional TrustAll
Server = http://repo.archlinux.fr/\$arch
!
    cat <<! > $tempDirectory/etc/mkinitcpio.conf
MODULES="i915 radeon nouveau squashfs aufs"
BINARIES="mksquashfs unsquashfs"
FILES=""
HOOKS="base udevNoCleanUp pcmcia keyboard block net filesystems squashfs"
!
    ### Hook to download and mount the squashfs located by the url-parameter.
    cat <<! > $tempDirectory/usr/lib/initcpio/hooks/squashfs
run_hook() {
    local DOWNLOAD_TARGET="/root.sqfs"
    if [ -n "\${url}" ]; then
      if wget "\${url}" --output-document "\${DOWNLOAD_TARGET}"; then
        echo "Setting boot location to \"${DOWNLOAD_TARGET}\"."
        root="\${DOWNLOAD_TARGET}"
        rootfstype="squashfs"
      else
        echo "Getting squash file system from \"\${url}\" failed."
        launch_interactive_shell
      fi
      mount_handler="squashfs_mount_helper"
    fi
}

squashfs_mount_helper() {
  ( modprobe squashfs && \
    modprobe loop && \
    mount -t squashfs "\$root" "\$1" && \
    mkdir /tmpfs && \
    mount -t tmpfs none /tmpfs && \
    mount -t aufs -o "dirs=/tmpfs:\$1=ro" none "\$1") || \
    ( err "Mount failed." ; launch_interactive_shell )
}
!
    cat <<! > $tempDirectory/usr/lib/initcpio/install/squashfs
#!/bin/bash

build() {
  add_module loop
  add_module squashfs
  add_runscript
}

help() {
  cat <<HELPEOF
  Not Acessable by human.
HELPEOF
}
!

    ### Cleaning up a initramfs with mounted squashfs and aufs does not work.
    ### This is the original udev-hook without cleaning up.
    cat <<! > $tempDirectory/usr/lib/initcpio/install/udevNoCleanUp
#!/bin/bash

build() {
    local rules tool

    add_file "/etc/udev/udev.conf"
    add_binary /usr/lib/systemd/systemd-udevd /usr/bin/udevd
    add_binary /usr/bin/udevadm

    for rules in 50-udev-default.rules 60-persistent-storage.rules 64-btrfs.rules 80-drivers.rules; do
        add_file "/usr/lib/udev/rules.d/\$rules"
    done
    for tool in ata_id scsi_id; do
        add_file "/usr/lib/udev/\$tool"
    done

    add_runscript
}

help() {
    cat <<HELPEOF
This hook will use udev to create your root device node and detect the needed
modules for your root device. It is also required for firmware loading in
initramfs. It is recommended to use this hook.
HELPEOF
}
!

    cat <<! > $tempDirectory/usr/lib/initcpio/hooks/udevNoCleanUp
run_earlyhook() {
    udevd --daemon --resolve-names=never
    udevd_running=1
}

run_hook() {
    msg ":: Triggering uevents..."
    udevadm trigger --action=add --type=subsystems
    udevadm trigger --action=add --type=devices
    udevadm settle

    init="/cleanSystemdStart.bash"
}
!

    ### Try to cleanup after the switch_root
    cat <<! > $tempDirectory/cleanSystemdStart.bash
#!/bin/bash
echo ":: cleaning up udev"
udevadm control --exit
udevadm info --cleanup-db
exec /usr/lib/systemd/systemd
!
    chmod +x $tempDirectory/cleanSystemdStart.bash

    #region hwinfo
    ### This is another attempt to replace the original udev.
    ### Needed Modules are named by hwinfo and then loaded.
    cat <<! > $tempDirectory/usr/lib/initcpio/hooks/hwinfo
run_hook() {
  # mount the important standard directories
  [ ! -d /run ] && mount -n -t tmpfs -o 'mode=755' run /run
  [ ! -f /proc/cpuinfo ] && mount -n -t proc proc /proc
  [ ! -d /sys/class ] && mount -n -t sysfs sysfs /sys

  echo "/sbin/mdev" > /proc/sys/kernel/hotplug
  # read graphic and network adaptor configuration (without proprietary drivers yet)

  ( hwinfo --gfxcard > /etc/hwinfo ) &
  ( hwinfo --netcard > /etc/netcard ) &

  while ps | grep -v grep | grep -q "  hwinfo --gfxcard" ; do sleep 1 ; done

  case \$(cat /etc/hwinfo) in
  *i915*)
    modprobe i915 2>/dev/null
    ;;
  *intel*|*Intel*)
    (modprobe i810
     modprobe i830
     modprobe i915) 2>/dev/null
    ;;
  *nvidia*|*NVidia*|*nouveau*)
    modprobe -q nouveau 2>/dev/null
    ;;
  *radeon*|*Radeon*)
    modprobe -q radeon 2>/dev/null
    ;;
  *mga*|*matrox*|*Matrox*)
    modprobe -q mga 2>/dev/null
    ;;
  *VMWare*|*VMWARE*)
    modprobe -q uvesafb mode_option=1024x768-32 mtrr=3 scroll=ywrap 2>/dev/null
    modprobe -q vmwgfx 2>/dev/null
    ;;
  *)
    modprobe -q r128
    modprobe -q savage 
    modprobe -q sis
    modprobe -q tdfx
    modprobe -q ttm
    modprobe -q via
    modprobe -q viafb
    ;;
  esac
  (modprobe drm; mdev -s ) &

  # load required network and usb controller drivers, filter out wireless adaptors
  while ps | grep -v grep | grep -q "  hwinfo --netcard" ; do sleep 1 ; done
  nwcardlist="forcedeth|e1000e|e1000|e100|tg3|via-rhine|r8169|pcnet32"
  echo "modprobe usbhid" >/etc/modprobe.base
  grep modprobe /etc/netcard | grep -E "\$nwcardlist" \
    | sed 's/.* Cmd: "//;s/"//;s/modprobe/modprobe -qb/' \
    | sort -u >>/etc/modprobe.base
  # virtio hack
  if [ \$(grep -ic "virtio_pci" /etc/modprobe.base) -ge 1 ]; then
    echo "modprobe -q virtio_net" >>/etc/modprobe.base
  fi
  /bin/sh /etc/modprobe.base; mdev -s
  launch_interactive_shell
}
!

    cat <<! > $tempDirectory/usr/lib/initcpio/install/hwinfo
#!/bin/bash

build() {
    add_runscript
}

help() {
    cat <<HELPEOF
notForHumans
HELPEOF
}
!
    #endregion
  }

  function staticXorgConfiguration() {
    cat <<! > $tempDirectory/etc/X11/xorg.conf
Section "ServerFlags"
    Option          "AutoAddDevices" "False"
EndSection
!
  }
  #endregion
  #endregion
  #region local variables
  local squashfsFilePath=""
  local kernelFilePath=""
  local initramfsFilePath=""
  local archInstallWrapperFile="./archInstall.bash"
  local archInstallWrapperFunction=""
  local tempDirectory=$(mktemp --directory )
  #endregion

  makeSquashLinuxParseCommandLine "$@"
  # NOTE: the global "__NAME__" variable has to be restored to let
  # "archInstall" know that it should be executed instead of
  # beeing sourced.
  local name="$__NAME__"
  source ${archInstallWrapperFile}
  __NAME__="$name"

  archInstallWrapperFunction=`basename "$archInstallWrapperFile" .bash`
  if $archInstallWrapperFunction --load-environment\
    --output-system $tempDirectory ${archInstallWrapperOptions}
  then
    # NOTE: Per default this script will stop after any error from now on.
    # Commands expected to throw an error can be put into a subshell via
    # '(/bin/false; /bin/true)'.
    set -e
    if [ -d $tempDirectory/etc/X11 ]; then staticXorgConfiguration; fi
    cp --force /etc/resolv.conf "$tempDirectory/etc/resolv.conf"
    makeSquashLinuxConfigure
    archInstallLog 'info' \
      'Installing packages needed for generating kernel and initramfs.'
    # NOTE: We need a repeated call of pacman to make sure that
    # "mkinitcpio-nfs-utils" is available when building kernel
    # in the next step.
    archInstallChangeRootViaMount "$tempDirectory" /usr/bin/pacman \
      --arch "$_CPU_ARCHITECTURE" --sync --noconfirm --refresh --refresh\
      --needed squashfs-tools mkinitcpio-nfs-utils base-devel yaourt
    archInstallChangeRootViaMount "$tempDirectory" /usr/bin/yaourt \
      --arch "$_CPU_ARCHITECTURE" --sync --noconfirm --refresh linux-pf
    archInstallLog 'info' \
      'Copy kernel and initramfs to target-location.'
    # NOTE: Using "scp" instead of cp gives the possibility to use ssh-pathes
    # as arguments.
    scp "$tempDirectory/boot/initramfs-linux-pf.img" "$initramfsFilePath"
    scp "$tempDirectory/boot/vmlinuz-linux-pf" "$kernelFilePath"
    archInstallLog 'info' \
      'Removing kernel, initramfs and obsolete tools from generated system.'
    archInstallChangeRootViaMount "$tempDirectory" pacman --remove \
      --nodeps --nodeps --noconfirm linux mkinitcpio yaourt mkinitcpio-nfs-utils squashfs-tools
    rm -rf $tempDirectory/boot/{vmlinuz-linux-pf,initramfs-linux-pf.img}
    local tempSquashFsFile=`mktemp --dry-run`
    archInstallLog 'info' "Creating squashfs-file as \"$tempSquashFsFile\"."
    mksquashfs "$tempDirectory" "$tempSquashFsFile" -no-progress 1> /dev/null
    archInstallLog 'info' \
      "Moving squashfs-file to \"$squashfsFilePath\"."
    scp "$tempSquashFsFile" "$squashfsFilePath"
    rm -i "$tempSquashFsFile"
    archInstallLog 'info' \
      "Deleting working directory."
    rm --recursive --force "$tempDirectory"
    archInstallLog 'info' \
      "Finished without errors."
  elif [[ $? == 1 ]]; then
    echo
    makeSquashLinuxPrintHelpMessage "$@"
    echo
  else
    exit $?
  fi
}

if [[ "$0" == *${__NAME__}.bash ]]; then
  "$__NAME__" "$@"
  exit $?
fi
