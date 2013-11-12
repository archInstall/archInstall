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
#     wget https://raw.github.com/thaibault/installArchLinux/master/installArchLinux.bash \
#         -O installArchLinux.bash && chmod +x installArchLinux.bash && \
#         ./installArchLinux.bash --output-system /dev/sda1

#     # Call a global function (Configures your current system):
#     source installArchLinux.bash --load-environment && \
#         _MOUNTPOINT_PATH='/' _USER_NAMES='hans' \
#         _LOCAL_TIME='Europe/Berlin' installArchLinuxConfigure

# Note that you only get very necessary output until you provide "--verbose" as
# commandline options.

# Dependencies:

#     bash (or any bash like shell)
#     test - Check file types and compare values.
#     sed - Stream editor for filtering and transforming text.
#     wget - The non-interactive network downloader.
#     xz - Compress or decompress .xz and lzma files.
#     tar - The GNU version of the tar archiving utility.
#     mount - Filesystem mounter.
#     umount - Filesystem unmounter.
#     chroot - Run command or interactive shell with special root directory.
#     echo - Display a line of text.
#     ln - Make links between files.
#     touch - Change file timestamps or creates them.
#     grep - Searches the named input FILEs (or standard input if no files are
#            named, or if a single hyphen-minus (-) is given as file name) for
#            lines containing  a  match to the given PATTERN.  By default, grep
#            prints the matching lines.
#     shift - Shifts the command line arguments.
#     sync - Flushs file system buffers.
#     mktemp - Create a temporary file or directory.
#     cat - Concatenate files and print on the standard output.
#     blkid - Locate or print block device attributes.
#     uniq - Report or omit repeated lines.
#     uname - Prints system informations.

# Dependencies for blockdevice integation:

#     grub-bios - A full featured boot manager.
#     blockdev - Call block device ioctls from the command line.

# Optional dependencies:

#     arch-install-scripts - Little framework to generate a linux from scratch.
#     fakeroot - Run a command in an environment faking root privileges for
#                file manipulation.
#     fakechroot - Wrappes some c-lib functions to enable programs like
#                  "chroot" running without root privilegs.
#     os-prober - Detects presence of other operating systems.
#     mountpoint - See if a directory is a mountpoint.

__NAME__='installArchLinux'

# endregion

# Provides the main module scope.
function installArchLinux() {

# region configuration 

    # region private properties

        # region command line arguments

    local _SCOPE='local'
    if [[ $(echo "\"$@\"" | grep --extended-regexp \
        '(^"| )(-l|--load-environment)("$| )') != '' ]]
    then
        local _SCOPE='export'
    fi
    "$_SCOPE" _PACKAGE_CACHE_PATH="${__NAME__}PackageCache"
    # NOTE: Only initialize environment if current scope wasn't set yet.
    if [ "$_VERBOSE" == '' ]; then
        "$_SCOPE" _HOSTNAME=''
        local userNames=()
        "$_SCOPE" _USER_NAMES="${userNames[*]}"
        "$_SCOPE" _VERBOSE='no'
        "$_SCOPE" _AUTO_PARTITIONING=''
        "$_SCOPE" _INSTALL_COMMON_ADDITIONAL_PACKAGES='no'
        "$_SCOPE" _LOAD_ENVIRONMENT='no'
        # NOTE: Possible constant values are "i686" or "x86_64".
        "$_SCOPE" _CPU_ARCHITECTURE=$(uname -m) # Possible: x86_64, i686, arm, any
        "$_SCOPE" _AUTOMATIC_REBOOT='yes'
        "$_SCOPE" _KEYBOARD_LAYOUT='de-latin1'
        "$_SCOPE" _OUTPUT_SYSTEM="$__NAME__"
        # NOTE: Each value which is present in "/etc/pacman.d/mirrorlist" is ok.
        "$_SCOPE" _COUNTRY_WITH_MIRRORS='Germany'
        "$_SCOPE" _BOOT_PARTITION_LABEL='system'
        "$_SCOPE" _SWAP_PARTITION_LABEL='swap'
        "$_SCOPE" _DATA_PARTITION_LABEL='data'
        local additionalPackages=()
        "$_SCOPE" _ADDITIONAL_PACKAGES="${additionalPackages[*]}"
        local neededServices=()
        "$_SCOPE" _NEEDED_SERVICES="${neededServices[*]}"
        "$_SCOPE" _NEEDED_BOOT_SPACE_IN_BYTE=524288000 # 500 MegaByte
        "$_SCOPE" _MAXIMAL_SWAP_SPACE_IN_PROCENT=20
        "$_SCOPE" _MINIMAL_BOOT_SPACE_IN_PROCENT=40
        # NOTE: This property isn't needed in the future.
        "$_SCOPE" _KEY_MAP_CONFIGURATION_FILE_CONTENT="KEYMAP=${_KEYBOARD_LAYOUT}\nFONT=Lat2-Terminus16\nFONT_MAP="
        "$_SCOPE" _LOCAL_TIME='Europe/Berlin'
        # Define where to mount temporary new filesystem.
        # NOTE: Path has to be end with a system specified delimiter.
        "$_SCOPE" _MOUNTPOINT_PATH='/mnt/'
        "$_SCOPE" _IGNORE_UNKNOWN_ARGUMENTS='no'
        "$_SCOPE" _PREVENT_USING_PACSTRAP='no'
        "$_SCOPE" _PREVENT_USING_NATIVE_ARCH_CHANGE_ROOT='no'

        # endregion

        # After determining dependencies a list like this will be stored:
        #     acl attr bzip2 curl expat glibc gpgme libarchive libassuan
        #     libgpg-error libssh2 openssl pacman xz zlib pacman-mirrorlist
        #     coreutils bash grep gawk file tar ncurses readline libcap util-linux
        #     pcre arch-install-scripts filesystem lzo2
        local neededPackages=()
        "$_SCOPE" _NEEDED_PACKAGES="${neededPackages[*]}"
        local packagesSourceUrls=(
            'http://mirror.de.leaseweb.net/archlinux' \
            'http://archlinux.limun.org' 'http://mirrors.kernel.org/archlinux')
        "$_SCOPE" _PACKAGE_SOURCE_URLS="${packagesSourceUrls[*]}"
        local basicPackages=(base)
        "$_SCOPE" _BASIC_PACKAGES="${basicPackages[*]}"
        local commonAdditionalPackages=(base-devel sudo python)
        "$_SCOPE" _COMMON_ADDITIONAL_PACKAGES="${commonAdditionalPackages[*]}"
        local packages=()
        "$_SCOPE" _PACKAGES="${packages[*]}"
        local unneededFileLocations=(.INSTALL .PKGINFO var/cache/pacman)
        "$_SCOPE" _UNNEEDED_FILE_LOCATIONS="${unneededFileLocations[*]}"
        "$_SCOPE" _STANDARD_OUTPUT=/dev/null
        "$_SCOPE" _ERROR_OUTPUT=/dev/null
        # This list should be in the order they should be mounted after use.
        # NOTE: Mount binds has to be declared as absolute paths.
        local neededMountpoints=(proc sys dev dev/pts run run/shm tmp \
            /etc/resolv.conf)
        "$_SCOPE" _NEEDED_MOUNTPOINTS="${neededMountpoints[*]}"
    fi

    # endregion

# endregion

# region functions

    # region command line interface

    # Prints a description about how to use this program.
    function installArchLinuxPrintUsageMessage() {
        cat << EOF
    $__NAME__ installs a linux from scratch by the arch way. You will end up in
    ligtweigth linux with pacman as packetmanager.
    You can directly install into a given blockdevice, partition or
    any directory (see command line option "--output-system").
    Note that every needed information which isn't given via command line
    will be asked interactivly on start. This script is as unnatted it could
    be, which means you can relax after providing all needed informations in
    the beginning till your new system is ready to boot.
EOF
    }

    # Prints a description about how to use this program by providing examples.
    function installArchLinuxPrintUsageExamples() {
        cat << EOF
    # Start install progress command on first found blockdevice:
    >>> $0 --output-system /dev/sda

    # Install directly into a given partition with verbose output:
    >>> $0 --output-system /dev/sda1 --verbose

    # Install directly into a given directory with addtional packages included:
    >>> $0 --output-system /dev/sda1 --verbose -f vim net-tools
EOF
    }

    # Prints descriptions about each available command line option.
    function installArchLinuxPrintCommandLineOptionDescriptions() {
        # NOTE; All letters are used for short options.
        # NOTE: "-k" and "--key-map-configuration" isn't needed in the future.
        cat << EOF
    -h --help Shows this help message.

    -v --verbose Tells you what is going on (default: "$_VERBOSE").

    -g --debug Gives you any output from all tools which are used
        (default: "$_DEBUG").

    -l --load-environment Simple load the install arch linux scope without
        doing anything else.


    -u --user-names [USER_NAMES [USER_NAMES ...]], Defines user names for new
         system (default: "${_USER_NAMES[*]}").

    -n --host-name HOST_NAME Defines name for new system
        (default: "$_HOSTNAME").


    -c --cpu-architecture CPU_ARCHITECTURE Defines architecture
        (default: "$_CPU_ARCHITECTURE").

    -o --output-system OUTPUT_SYSTEM Defines where to install new operating
        system. You can provide a full disk or patition via blockdevice such as
        "/dev/sda" or "/dev/sda1". You can also provide a diretory path such as
        "/tmp/lifesystem" (default: "$_OUTPUT_SYSTEM").


    -x --local-time LOCAL_TIME Local time for you system
        (default: "$_LOCAL_TIME").

    -k --key-map-configuration FILE_CONTENT Keyboard map configuration
        (default: "$_KEY_MAP_CONFIGURATION_FILE_CONTENT").

    -b --keyboard-layout LAYOUT Defines needed keyboard layout
        (default: "$_KEYBOARD_LAYOUT").

    -m --country-with-mirrors COUNTRY Country for enabling servers to get
        packages from (default: "$_COUNTRY_WITH_MIRRORS").


    -r --no-reboot Prevents to reboot after finishing installation.

    -p --prevent-using-pacstrap Ignores presence of pacstrap to use it for
        install operating system (default: "$_PREVENT_USING_PACSTRAP").

    -y --prevent-using-native-arch-chroot Ignores presence of "arch-chroot"
        to use it for chroot into newly created operating system
        (default: "$_PREVENT_USING_NATIVE_ARCH_CHANGE_ROOT").

    -a --auto-paritioning Defines to do partitioning on founded block device
        automatic.


    -e --boot-partition-label LABEL Partition label for boot partition
        (default: "$_BOOT_PARTITION_LABEL").

    -s --swap-partition-label LABEL Partition label for swap partition
        (default: "$_SWAP_PARTITION_LABEL").

    -d --data-partition-label LABEL Partition label for data partition
        (default: "$_DATA_PARTITION_LABEL").


    -w --needed-boot-space-in-byte NUMBER_OF_BYTES In case if selected auto
        partitioning you can define the minimum space needed for your boot
        partition (default: "$_NEEDED_BOOT_SPACE_IN_BYTE byte").

    -q --minimal-boot-space-in-procent PROCENT Define how much space should
        be at least used for your boot (system and program) partition.
        Other space will be used for your data partition
        (default: "$_MINIMAL_BOOT_SPACE_IN_PROCENT%").

    -i --maximal-swap-space-in-procent PROCENT Define how much procent you
        want to immolate for swap space
        (default: "$_MAXIMAL_SWAP_SPACE_IN_PROCENT%").
        Note that $__NAME__ will try to take the same space as your installed
        memory provides to support hibernation.


    -z --install-common-additional-packages,
        If present the following packages will be installed:
        "${_COMMON_ADDITIONAL_PACKAGES[*]}".

    -f --additional-packages [PACKAGES [PACKAGES ...]], You can give a list
        with additional available packages (default: "${_ADDITIONAL_PACKAGES[*]}").

    -j --needed-services [SERVICES [SERVICES ...]], You can give a list
        with additional available services (default: "${_NEEDED_SERVICES[*]}").

    -t --package-cache-path PATH Define where to load and save downloaded
        packages (default: "$_PACKAGE_CACHE_PATH").
EOF
    }

    # Provides a help message for this module.
    function installArchLinuxPrintHelpMessage() {
        echo -e "\nUsage: $0 [options]\n"
        installArchLinuxPrintUsageMessage "$@"
        echo -e '\nExamples:\n'
        installArchLinuxPrintUsageExamples "$@"
        echo -e '\nOption descriptions:\n'
        installArchLinuxPrintCommandLineOptionDescriptions "$@"
        echo
    }

    # Provides the command line interface and interactive questions.
    function installArchLinuxCommandLineInterface() {
        while true; do
            case "$1" in
                -h|--help)
                    shift
                    installArchLinuxPrintHelpMessage "$0"
                    exit 0
                    ;;
                -v|--verbose)
                    shift
                    _VERBOSE='yes'
                    ;;
                -g|--debug)
                    shift
                    _STANDARD_OUTPUT=/dev/stdout
                    _ERROR_OUTPUT=/dev/stderr
                    ;;
                -l|--load-environment)
                    shift
                    _LOAD_ENVIRONMENT='yes'
                    ;;

                -u|--user-names)
                    shift
                    while [[ "$1" =~ ^[^-].+$ ]]; do
                        _USER_NAMES+=" $1"
                        shift
                    done
                    ;;
                -n|--host-name)
                    shift
                    _HOSTNAME="$1"
                    shift
                    ;;

                -c|--cpu-architecture)
                    shift
                    _CPU_ARCHITECTURE="$1"
                    shift
                    ;;
                -o|--output-system)
                    shift
                    _OUTPUT_SYSTEM="$1"
                    shift
                    ;;

                -x|--local-time)
                    shift
                    _LOCAL_TIME="$1"
                    shift
                    ;;
                -k|--key-map-configuation)
                    shift
                    _KEY_MAP_CONFIGURATION_FILE_CONTENT="$1"
                    shift
                    ;;
                -b|--keyboard-layout)
                    shift
                    _KEYBOARD_LAYOUT="$1"
                    shift
                    ;;
                -m|--country-with-mirrors)
                    shift
                    _COUNTRY_WITH_MIRRORS="$1"
                    shift
                    ;;

                -r|--no-reboot)
                    shift
                    _AUTOMATIC_REBOOT='no'
                    ;;
                -a|--auto-partitioning)
                    shift
                    _AUTO_PARTITIONING='yes'
                    ;;
                -p|--prevent-using-pacstrap)
                    shift
                    _PREVENT_USING_PACSTRAP='yes'
                    ;;
                -y|--prevent-using-native-arch-chroot)
                    shift
                    _PREVENT_USING_NATIVE_ARCH_CHANGE_ROOT='yes'
                    ;;

                -e|--boot-partition-label)
                    shift
                    _BOOT_PARTITION_LABEL="$1"
                    shift
                    ;;
                -s|--swap-partition-label)
                    shift
                    _SWAP_PARTITION_LABEL="$1"
                    shift
                    ;;
                -d|--data-partition-label)
                    shift
                    _DATA_PARTITION_LABEL="$1"
                    shift
                    ;;

                -w|--needed-boot-space-in-byte)
                    shift
                    _NEEDED_BOOT_SPACE_IN_BYTE="$1"
                    shift
                    ;;
                -q|--minimal-boot-space-in-procent)
                    shift
                    _MINIMAL_BOOT_SPACE_IN_PROCENT="$1"
                    shift
                    ;;
                -i|--maximal-swap-space-in-procent)
                    shift
                    _MAXIMAL_SWAP_SPACE_IN_PROCENT="$1"
                    shift
                    ;;

                -z|--install-common-additional-packages)
                    shift
                    _INSTALL_COMMON_ADDITIONAL_PACKAGES='no'
                    ;;
                -f|--additional-packages)
                    shift
                    while [[ "$1" =~ ^[^-].+$ ]]; do
                        _ADDITIONAL_PACKAGES+=" $1"
                        shift
                    done
                    ;;
                -j|--needed-services)
                    shift
                    while [[ "$1" =~ ^[^-].+$ ]]; do
                        _NEEDED_SERVICES+=" $1"
                        shift
                    done
                    ;;
                -t|--package-cache-path)
                    shift
                    _PACKAGE_CACHE_PATH="$1"
                    shift
                    ;;

                '')
                    shift
                    break
                    ;;
                *)
                    installArchLinuxLog 'critical' \
                        "Given argument: \"$1\" is not available." '\n'
                    if [[ "$_SCOPE" == 'local' ]]; then
                        installArchLinuxPrintHelpMessage "$0"
                    fi
                    return 1
            esac
        done
        if [[ "$UID" != '0' ]] && ! (
            hash fakeroot 1>"$_STANDARD_OUTPUT" 2>/dev/null && \
            hash fakechroot 1>"$_STANDARD_OUTPUT" 2>/dev/null && \
            ([ -e "$_OUTPUT_SYSTEM" ] && [ -d "$_OUTPUT_SYSTEM" ]))
        then
            installArchLinuxLog 'critical' \
                "You have to run this script as \"root\" not as \"${USER}\". You can alternatively install \"fakeroot\", \"fakechroot\" and install into a directory."
            exit 2
        fi
        if [[ "$0" == *"${__NAME__}.bash" ]]; then
            if [ ! "$_HOSTNAME" ]; then
                while true; do
                    echo -n 'Please set hostname for new system: '
                    read _HOSTNAME
                    if [[ $(echo "$_HOSTNAME" |\
                          tr '[A-Z]' '[a-z]') != '' ]]; then
                        break
                    fi
                done
            fi
        fi
    }

    # Handles logging messages. Returns non zero and exit on log level error to
    # support chaining the message into toolchain.
    function installArchLinuxLog() {
        local loggingType='info'
        local message="$1"
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

    # region install arch linux steps.

    # Installs arch linux via pacstrap.
    function installArchLinuxWithPacstrap() {
        installArchLinuxLoadCache
        installArchLinuxLog \
            'Patch pacstrap to handle offline installations.' && \
        cat $(which pacstrap) | sed --regexp-extended \
            's/(pacman.+-(S|-sync))(y|--refresh)/\1/g' \
            1>${_PACKAGE_CACHE_PATH}/patchedOfflinePacman.bash \
            2>"$_STANDARD_OUTPUT" && \
        chmod +x "${_PACKAGE_CACHE_PATH}/patchedOfflinePacman.bash" \
            1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
        installArchLinuxLog 'Update package databases.' && \
        (pacman --arch "$_CPU_ARCHITECTURE" --sync --refresh \
            --root "$_MOUNTPOINT_PATH" 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT" || true) && \
        local neededPackages=$(echo "${_PACKAGES[*]}" | sed -e 's/^ *//g' -e 's/ *$//g')
        installArchLinuxLog \
            "Install needed packages \"$neededPackages\" in new operating system located at \"$_MOUNTPOINT_PATH\"." && \
        # NOTE: "${_PACKAGES[*]}" shouldn't be in quotes to get pacstrap
        # working.
        "${_PACKAGE_CACHE_PATH}/patchedOfflinePacman.bash" -d \
            "$_MOUNTPOINT_PATH" ${_PACKAGES[*]} --force 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT" && \
        rm "${_PACKAGE_CACHE_PATH}/patchedOfflinePacman.bash" \
            1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        local returnCode=$?
        (installArchLinuxCache || installArchLinuxLog 'warning' \
            'Caching current downloaded packages and generated database failed.')
        return $returnCode
    }

    # This functions performs creating an arch linux system from any linux
    # system base.
    function installArchLinuxGenericLinuxSteps() {
        installArchLinuxLog 'Create a list with urls for needed packages.'
        (installArchLinuxDownloadAndExtractPacman \
            $(installArchLinuxCreatePackageUrlList)) && \
        # Create root filesystem only if not exists.
        (test -e "${_MOUNTPOINT_PATH}etc/mtab" 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT" || echo "rootfs / rootfs rw 0 0" \
            1>"${_MOUNTPOINT_PATH}etc/mtab" 2>"$_ERROR_OUTPUT") && \
        ((cp '/etc/resolv.conf' "${_MOUNTPOINT_PATH}etc/" 1>"$_STANDARD_OUTPUT" \
              2>"$_ERROR_OUTPUT" &&
          [[ "$_PREVENT_USING_NATIVE_ARCH_CHANGE_ROOT" == 'no' ]] && \
          hash arch-chroot 1>"$_STANDARD_OUTPUT" 2>/dev/null && \
          mv "${_MOUNTPOINT_PATH}etc/resolv.conf" \
              "${_MOUNTPOINT_PATH}etc/resolv.conf.old" 1>"$_STANDARD_OUTPUT" \
              2>/dev/null) || true) && \
        sed --in-place --quiet '/^[ \t]*CheckSpace/ !p' \
            "${_MOUNTPOINT_PATH}etc/pacman.conf" 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT" && \
        sed --in-place "s/^[ \t]*SigLevel[ \t].*/SigLevel = Never/" \
            "${_MOUNTPOINT_PATH}etc/pacman.conf" 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT" && \
        installArchLinuxAppendTemporaryInstallMirrors && \
        (installArchLinuxLoadCache || installArchLinuxLog \
             'No package cache was loaded.') && \
        installArchLinuxLog "Update package databases." && \
        (installArchLinuxChangeRootToMountPoint /usr/bin/pacman \
            --arch "$_CPU_ARCHITECTURE" --sync --refresh \
            1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" || true) && \
        local neededPackages=$(echo "${_PACKAGES[*]}" | sed -e 's/^ *//g' -e 's/ *$//g')
        installArchLinuxLog "Install needed packages \"$neededPackages\" to \"$_OUTPUT_SYSTEM\"." && \
        installArchLinuxChangeRootToMountPoint /usr/bin/pacman --arch \
            "$_CPU_ARCHITECTURE" --sync --force --needed --noconfirm \
            ${_PACKAGES[*]} 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        local returnCode=$?
        (installArchLinuxCache || installArchLinuxLog 'warning' \
            'Caching current downloaded packages and generated database failed.')
        test $returnCode && installArchLinuxConfigurePacman
        return $?
    }

    # endregion

    # region tools

        # region change root functions

    # This function performs a changeroot to currently set mountpoint path.
    function installArchLinuxChangeRootToMountPoint() {
        installArchLinuxChangeRoot "$_MOUNTPOINT_PATH" "$@"
        return $?
    }

    # This function emulates the arch linux native "arch-chroot" function.
    function installArchLinuxChangeRoot() {
        if [[ "$1" == '/' ]]; then
            shift
            "$@" 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
            return $?
        elif [ -b "$_OUTPUT_SYSTEM" ]; then
            if [[ "$_PREVENT_USING_NATIVE_ARCH_CHANGE_ROOT" == 'no' ]] && \
                hash arch-chroot 1>"$_STANDARD_OUTPUT" 2>/dev/null
            then
                arch-chroot "$@" 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
                return $?
            fi
            installArchLinuxChangeRootViaMount "$@"
            return $?
        fi
        installArchLinuxPerformChangeRoot "$@"
        return $?
    }

    # Performs a change root by mounting needed host locations in change root
    # environment.
    function installArchLinuxChangeRootViaMount() {
        local returnCode=0
        local mountpointPath
        for mountpointPath in ${_NEEDED_MOUNTPOINTS[*]}; do
            if [ ! -d "${_MOUNTPOINT_PATH}${mountpointPath}" ] && \
                [ ! -f ${mountpointPath} ]
            then
                mkdir --parents "${_MOUNTPOINT_PATH}${mountpointPath}" \
                    1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
                returnCode=$?
            fi
            # NOTE: "mount-bind" approach.
            #mount --options bind "/${mountpointPath}" \
            #    "${_MOUNTPOINT_PATH}${mountpointPath}" 1>"$_STANDARD_OUTPUT" \
            #    2>"$_ERROR_OUTPUT" || \
            if ! mountpoint -q "${_MOUNTPOINT_PATH}${mountpointPath}" && \
                test $returnCode
            then
                if [ "$mountpointPath" == 'proc' ]; then
                    mount "$mountpointPath" \
                        "${_MOUNTPOINT_PATH}${mountpointPath}" --types \
                        "$mountpointPath" --options nosuid,noexec,nodev \
                        1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
                elif [ "$mountpointPath" == 'sys' ]; then
                    mount "$mountpointPath" \
                        "${_MOUNTPOINT_PATH}${mountpointPath}" --types sysfs \
                        --options nosuid,noexec,nodev 1>"$_STANDARD_OUTPUT" \
                        2>"$_ERROR_OUTPUT"
                elif [ "$mountpointPath" == 'dev' ]; then
                    mount udev "${_MOUNTPOINT_PATH}${mountpointPath}" --types \
                        devtmpfs --options mode=0755,nosuid \
                        1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
                elif [ "$mountpointPath" == 'dev/pts' ]; then
                    mount devpts "${_MOUNTPOINT_PATH}${mountpointPath}" \
                        --types devpts --options \
                        mode=0620,gid=5,nosuid,noexec 1>"$_STANDARD_OUTPUT" \
                        2>"$_ERROR_OUTPUT"
                elif [ "$mountpointPath" == 'run/shm' ]; then
                    mount shm "${_MOUNTPOINT_PATH}${mountpointPath}" --types \
                        tmpfs --options mode=1777,nosuid,nodev \
                        1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
                elif [ "$mountpointPath" == 'run' ]; then
                    mount "$mountpointPath" \
                        "${_MOUNTPOINT_PATH}${mountpointPath}" --types tmpfs \
                        --options nosuid,nodev,mode=0755 \
                        1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
                elif [ "$mountpointPath" == 'tmp' ]; then
                    mount run "${_MOUNTPOINT_PATH}${mountpointPath}" --types \
                        tmpfs --options mode=1777,strictatime,nodev,nosuid \
                        1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
                elif [ -f "$mountpointPath" ]; then
                    mount "$mountpointPath" \
                        "${_MOUNTPOINT_PATH}${mountpointPath}" --bind
                else
                    installArchLinuxInfo 'error' \
                        "Mountpoint \"$mountpointPath\" couldn't be handled."
                fi
                returnCode=$?
            fi
        done
        test $returnCode && installArchLinuxPerformChangeRoot "$@"
        returnCode=$?
        # Reverse mountpoint list to unmount them in reverse order.
        local reverseNeededMountpoints
        for mountpointPath in ${_NEEDED_MOUNTPOINTS[*]}; do
            reverseNeededMountpoints="$mountpointPath ${reverseNeededMountpoints[*]}"
        done
        for mountpointPath in ${reverseNeededMountpoints[*]}; do
            if mountpoint -q "${_MOUNTPOINT_PATH}${mountpointPath}" || \
                [ -f ${mountpointPath} ]
            then
                # If unmounting doesn't work try to unmount in lazy mode
                # (when mountpoints are not needed anymore).
                umount "${_MOUNTPOINT_PATH}${mountpointPath}" \
                    1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" || \
                (installArchLinuxLog 'warning' "Unmounting \"${_MOUNTPOINT_PATH}${mountpointPath}\" fails so unmount it in force mode." && \
                 umount -f "${_MOUNTPOINT_PATH}${mountpointPath}" \
                     1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT") || \
                (installArchLinuxLog 'warning' "Unmounting \"${_MOUNTPOINT_PATH}${mountpointPath}\" in force mode fails so unmount it if mountpoint isn't busy anymore." && \
                 umount -l "${_MOUNTPOINT_PATH}${mountpointPath}" \
                     1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT")
                # NOTE: "returnCode" remaines with an error code if there was given
                # one in all iterations.
                if [[ $? != 0 ]]; then
                    returnCode=$?
                fi
            else
                installArchLinuxLog 'warning' \
                    "Location \"${_MOUNTPOINT_PATH}${mountpointPath}\" should be a mountpoint but isn't."
            fi
        done
        return $returnCode
    }

    # Perform the available change root program wich needs at least rights.
    function installArchLinuxPerformChangeRoot() {
        if [[ "$UID" == '0' ]]; then
            chroot "$@" 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        else
            fakeroot fakechroot chroot "$@" 1>"$_STANDARD_OUTPUT" \
                2>"$_ERROR_OUTPUT"
        fi
    }

        # endregion

    # Provides generic linux configuration mechanism. If an argument is given
    # new systemd like programs are used (they could have problems in change
    # root environment without and exclusive dbus connection.
    function installArchLinuxConfigure() {
        installArchLinuxLog "Make keyboard layout permanent to \"${_KEYBOARD_LAYOUT}\"."
        if [[ "$1" == true ]]; then
            installArchLinuxChangeRootToMountPoint localectl set-keymap \
                "$_KEYBOARD_LAYOUT" 1>"$_STANDARD_OUTPUT" \
                2>"$_ERROR_OUTPUT" && \
            installArchLinuxChangeRootToMountPoint localectl set-locale \
                LANG="en_US.utf8" 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        else
            echo -e "$_KEY_MAP_CONFIGURATION_FILE_CONTENT" 1>\
                "${_MOUNTPOINT_PATH}etc/vconsole.conf" 2>"$_ERROR_OUTPUT"
        fi
        installArchLinuxLog "Set localtime \"$_LOCAL_TIME\"."
        if [[ "$1" == true ]]; then
            installArchLinuxChangeRootToMountPoint timedatectl set-timezone \
                "$_LOCAL_TIME" 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        else
            ln --symbolic --force "/usr/share/zoneinfo/${_LOCAL_TIME}" \
                "${_MOUNTPOINT_PATH}etc/localtime" 1>"$_STANDARD_OUTPUT" \
                2>"$_ERROR_OUTPUT"
        fi
        installArchLinuxLog "Set hostname to \"$_HOSTNAME\"."
        if [[ "$1" == true ]]; then
            installArchLinuxChangeRootToMountPoint hostnamectl set-hostname \
                "$_HOSTNAME" 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        else
            echo -e "$_HOSTNAME" 1>"${_MOUNTPOINT_PATH}etc/hostname" \
                2>"$_ERROR_OUTPUT"
        fi
        installArchLinuxLog 'Set hosts.' && \
        installArchLinuxGetHostsContent "$_HOSTNAME" \
            1>"${_MOUNTPOINT_PATH}etc/hosts"  2>"$_ERROR_OUTPUT" && \
        installArchLinuxLog 'Set root password to "root".' && \
        installArchLinuxChangeRootToMountPoint /usr/bin/env bash -c \
            "echo root:root | \$(which chpasswd)" 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT" && \
        installArchLinuxEnableServices && \
        installArchLinuxLog "Add users: \"$(echo ${_USER_NAMES[*]} | sed \
            's/ /", "/g')\"." && \
        installArchLinuxLog \
            "Enable dhcp service on all found ethernet adapter." && \
        ln --symbolic --force '/usr/lib/systemd/system/netctl-auto@.service' \
            "${_MOUNTPOINT_PATH}etc/systemd/system/multi-user.target.wants/netctl-auto@wlp3s0.service" && \
        ln --symbolic --force '/usr/lib/systemd/system/netctl-ifplugd@.service' \
            "${_MOUNTPOINT_PATH}etc/systemd/system/multi-user.target.wants/netctl-ifplugd@enp0s25.service" && \
        local userName && \
        for userName in ${_USER_NAMES[*]}; do
            # NOTE: We could only create a home directory with right rights if
            # we are root.
            (installArchLinuxChangeRootToMountPoint useradd \
                 --home-dir "/home/$userName/" --groups users \
                 $([[ "$UID" == '0' ]] || echo '--no-create-home') \
                 --no-user-group --shell $(which bash) "$userName" \
                 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" || \
             (installArchLinuxLog 'warning' \
                  "Adding user \"$userName\" failed." && false)) && \
            installArchLinuxLog \
                "Set password for \"$userName\" to \"$userName\"." && \
            installArchLinuxChangeRootToMountPoint /usr/bin/env bash \
                -c "echo ${userName}:${userName} | \$(which chpasswd)" \
                1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        done
        return $?
    }

    # Enable all needed services.
    function installArchLinuxEnableServices() {
        local serviceName
        for serviceName in ${_NEEDED_SERVICES[*]}; do
            installArchLinuxLog "Enable \"$serviceName\" service."
            installArchLinuxChangeRootToMountPoint systemctl enable \
                "$serviceName".service 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
            if [[ $? != 0 ]]; then
                return $?
            fi
        done
    }

    # Deletes some unneeded locations in new installs operating system.
    function installArchLinuxTidyUpSystem() {
        local returnCode=0
        installArchLinuxLog 'Tidy up new build system.'
        local filePath
        for filePath in ${_UNNEEDED_FILE_LOCATIONS[*]}; do
            installArchLinuxLog \
                "Deleting \"${_MOUNTPOINT_PATH}$filePath\"."
            rm "${_MOUNTPOINT_PATH}$filePath" --recursive \
                --force 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
            if [[ $? != 0 ]]; then
                return $?
            fi
        done
    }

    # Appends temporary used mirrors to download missing packages during
    # installation.
    function installArchLinuxAppendTemporaryInstallMirrors() {
        local url
        for url in ${_PACKAGE_SOURCE_URLS[*]}; do
            echo "Server = $url/\$repo/os/$_CPU_ARCHITECTURE" \
                1>>"${_MOUNTPOINT_PATH}etc/pacman.d/mirrorlist" \
                2>"$_ERROR_OUTPUT"
            if [[ $? != 0 ]]; then
                return $?
            fi
        done
    }

    # Packs the resulting system to provide files owned by root without root
    # permissions.
    function installArchLinuxPackResult() {
        if [[ "$UID" != '0' ]]; then
            installArchLinuxLog "System will be packed into \"$_MOUNTPOINT_PATH.tar\" to provide root owned files. You have to extract this archiv as root."
            tar cvf "$_MOUNTPOINT_PATH".tar "$_MOUNTPOINT_PATH" --owner root 1>"$_STANDARD_OUTPUT" \
                2>"$_ERROR_OUTPUT" && \
            rm "$_MOUNTPOINT_PATH"* --recursive --force 1>"$_STANDARD_OUTPUT" \
                2>"$_ERROR_OUTPUT"
            return $?
        fi
    }

    # Generates all web urls for needed packages.
    function installArchLinuxCreatePackageUrlList() {
        local returnCode=0
        local listBufferFile=$(mktemp)
        local firstPackageSourceUrl=$(echo "$_PACKAGE_SOURCE_URLS" | \
            grep --extended-regexp --only-matching '^[^ ]+')
        local repositoryName
        for repositoryName in core community extra; do
            wget --quiet --output-document - \
                "$firstPackageSourceUrl/$repositoryName/os/$_CPU_ARCHITECTURE/" \
                2>"$_ERROR_OUTPUT" | sed --quiet \
                "s|.*href=\"\\([^\"]*\\).*|$firstPackageSourceUrl\\/$repositoryName\\/os\\/$_CPU_ARCHITECTURE\\/\\1|p" \
                2>"$_ERROR_OUTPUT" | grep --invert-match 'sig$' \
                2>"$_ERROR_OUTPUT" | uniq 1>>"$listBufferFile" \
                2>"$_ERROR_OUTPUT"
            # NOTE: "returnCode" remaines with an error code if there was given
            # one in all iterations.
            if [[ $? != 0 ]]; then
                returnCode=$?
            fi
        done
        echo "$listBufferFile"
        return $returnCode
    }

    # Reads pacmans database and determine pacman's dependencies.
    function installArchLinuxDeterminePacmansNeededPackages() {
        local coreDatabaseUrl=$(grep "core\.db" "$listBufferFile" | \
            head --lines 1)
        wget "$coreDatabaseUrl" --timestamping --directory-prefix \
            "${_PACKAGE_CACHE_PATH}/" 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        if [ -f "$_PACKAGE_CACHE_PATH/core.db" ]; then
            local databaseLocation=$(mktemp --directory)
            tar --gzip --extract --file "$_PACKAGE_CACHE_PATH/core.db" \
                --directory "$databaseLocation" 1>"$_STANDARD_OUTPUT" \
                2>"$_ERROR_OUTPUT" && \
            installArchLinuxDeterminePackageDependencies 'pacman' \
                "$databaseLocation"
        else
            installArchLinuxLog 'error' \
                "No database file (\"$_PACKAGE_CACHE_PATH/core.db\") available."
        fi
    }

    # Determines all package dependencies. Returns a list of needed
    # packages for given package determined by given database.
    function installArchLinuxDeterminePackageDependencies() {
        _NEEDED_PACKAGES+=" $1"
        local packageDirectoryPath=$(installArchLinuxDeterminePackageDirectoryName "$@")
        if [ "$packageDirectoryPath" ]; then
            local packageDescription
            for packageDependencyDescription in $(cat \
                "${packageDirectoryPath}depends" | grep --perl-regexp \
                --null-data --only-matching '%DEPENDS%(\n.+)+' | grep \
                --extended-regexp --invert-match '^%.+%$')
            do
                local packageName=$(echo "$packageDependencyDescription" | \
                    grep --extended-regexp --only-matching '^[-a-zA-Z0-9]+')
                echo "$_NEEDED_PACKAGES" 2>"$_ERROR_OUTPUT" | grep \
                    " $packageName " 1>/dev/null 2>/dev/null || \
                installArchLinuxDeterminePackageDependencies "$packageName" \
                    "$2" || \
                installArchLinuxLog 'warning' \
                    "Needed package \"$packageName\" for \"$1\" couldn't be found in \"$2\"."
            done
        else
            return 1
        fi
    }

    # Determines the package directory name from given package name in given
    # database.
    function installArchLinuxDeterminePackageDirectoryName() {
        local packageDirectoryPath=$(grep "%PROVIDES%\n(.+\n)*$1\n(.+\n)*\n" \
            --perl-regexp --null-data "$2" --recursive --files-with-matches | \
            grep --extended-regexp '/depends$' | sed 's/depends$//' | head \
            --lines 1)
        if [ ! "$packageDirectoryPath" ]; then
            local regexPattern
            for packageDirectoryPattern in \
                "^$1-([0-9a-zA-Z\.]+-[0-9a-zA-Z\.])$" \
                "^$1[0-9]+-([0-9a-zA-Z\.]+-[0-9a-zA-Z\.])$" \
                "^[0-9]+$1[0-9]+-([0-9a-zA-Z\.]+-[0-9a-zA-Z\.])$" \
                "^[0-9a-zA-Z]*acm[0-9a-zA-Z]*-([0-9a-zA-Z\.]+-[0-9a-zA-Z\.])$"
            do
                local packageDirectoryName=$(ls -1 "$2" | grep \
                    --extended-regexp "$packageDirectoryPattern")
                if [ "$packageDirectoryName" ]; then
                    break
                fi
            done
            if [ "$packageDirectoryName" ]; then
                packageDirectoryPath="$2/$packageDirectoryName/"
            fi
        fi
        echo "$packageDirectoryPath"
        return $?
    }

    # Downloads all packages from arch linux needed to run pacman.
    function installArchLinuxDownloadAndExtractPacman() {
        local listBufferFile="$1"
        if installArchLinuxDeterminePacmansNeededPackages "$listBufferFile"; then
            installArchLinuxLog \
                "Download and extract each package into our new system located in \"$_MOUNTPOINT_PATH\"."
            local packageName
            for packageName in ${_NEEDED_PACKAGES[*]}; do
                local packageUrl=$(grep "$packageName-[0-9]" \
                    "$listBufferFile" | head --lines 1)
                local fileName=$(echo $packageUrl \
                    | sed 's/.*\/\([^\/][^\/]*\)$/\1/')
                # If "fileName" couldn't be determined via server determine it
                # via current package cache.
                if [ ! "$fileName" ]; then
                    fileName=$(ls $_PACKAGE_CACHE_PATH \
                    | grep "$packageName-[0-9]" | head --lines 1)
                fi
                if [ "$fileName" ]; then
                    wget "$packageUrl" --timestamping --continue \
                        --directory-prefix "${_PACKAGE_CACHE_PATH}/" \
                        1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
                else
                    installArchLinuxLog \
                        'error' "A suitable file for package \"$packageName\" could not be determined."
                fi
                xz --decompress --to-stdout "$_PACKAGE_CACHE_PATH/$fileName" \
                    2>"$_ERROR_OUTPUT" | tar --extract --keep-old-files \
                    --directory "$_MOUNTPOINT_PATH" 1>"$_STANDARD_OUTPUT" \
                    2>"$_ERROR_OUTPUT"
                if [[ $? != 0 ]]; then
                    return $?
                fi
            done
        fi
        return $?
    }

    # Performs the auto partitioning.
    function installArchLinuxMakePartitions() {
        if [[ $(echo "$_AUTO_PARTITIONING" | tr '[A-Z]' '[a-z]') == 'yes' ]]
        then
            installArchLinuxLog 'Check for suitable device divisions.'
            local memorySpaceInByte=$(($(cat /proc/meminfo | grep --extended-regexp --only-matching 'MemTotal: +[0-9]+ kB' | sed --regexp-extended 's/[^0-9]+([0-9]+)[^0-9]+/\1/g') * 1024))
            local blockDeviceSpaceInByte=$(blockdev --getsize64 "$_OUTPUT_SYSTEM")
            local swapSpaceInProcent=$((100 * $memorySpaceInByte / $blockDeviceSpaceInByte))
            local neededBootSpaceInProcent=$((100 * $_NEEDED_BOOT_SPACE_IN_BYTE / $blockDeviceSpaceInByte))
            if [[ $swapSpaceInProcent -gt $_MAXIMAL_SWAP_SPACE_IN_PROCENT ]]
            then
                swapSpaceInProcent=$_MAXIMAL_SWAP_SPACE_IN_PROCENT
            fi
            if [[ $neededBootSpaceInProcent -lt $_MINIMAL_BOOT_SPACE_IN_PROCENT ]]
            then
                neededBootSpaceInProcent=$_MINIMAL_BOOT_SPACE_IN_PROCENT
            fi
            local let swapPlusBootSpaceInProcent=$(($swapSpaceInProcent + $neededBootSpaceInProcent))
            installArchLinuxLog 'Check block device size.'
            test $_NEEDED_BOOT_SPACE_IN_BYTE -le $blockDeviceSpaceInByte && \
            installArchLinuxLog 'Delete old partition table.' && \
            parted $_OUTPUT_SYSTEM mklabel msdos --script \
                1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
            installArchLinuxLog 'Delete first three partitions.' && \
            (parted "$_OUTPUT_SYSTEM" rm 1 1>"$_STANDARD_OUTPUT" 2>/dev/null \
                || true) && \
            (parted "$_OUTPUT_SYSTEM" rm 2 1>"$_STANDARD_OUTPUT" 2>/dev/null \
                || true) && \
            (parted "$_OUTPUT_SYSTEM" rm 3 1>"$_STANDARD_OUTPUT" 2>/dev/null \
                || true) && \
            installArchLinuxLog 'Create boot partition.' && \
            parted "$_OUTPUT_SYSTEM" mkpart primary ext4 2048s \
                ${neededBootSpaceInProcent}% --script set 1 boot on \
                1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
            if [[ ${_MINIMAL_BOOT_SPACE_IN_PROCENT} -lt 100 ]]; then
                installArchLinuxLog 'Create swap partition.' && \
                parted "$_OUTPUT_SYSTEM" mkpart primary linux-swap \
                    ${neededBootSpaceInProcent}% ${swapPlusBootSpaceInProcent}% \
                    --script 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
                installArchLinuxLog 'Create data partition.' && \
                parted "$_OUTPUT_SYSTEM" mkpart primary ext4 \
                    ${swapPlusBootSpaceInProcent}% 100% --script \
                    1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
            fi
        else
            installArchLinuxLog \
 l rt              "You have to create at least one partition. The first one will be used as boot partition labeled to \"${_BOOT_PARTITION_LABEL}\" and second one will be used as swap partition and labeled to \"${_SWAP_PARTITION_LABEL}\". The third will be used as data partition labeled to \"$_DATA_PARTITION_LABEL\" Press Enter to continue." && \
            read && \
            installArchLinuxLog \
                'Show blockdevices. Press Enter to continue.' && \
            lsblk 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
            read && \
            installArchLinuxLog 'Create partitions manually.' && \
            cfdisk 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        fi
        return $?
    }

    # Writes the fstab configuration file.
    function installArchLinuxGenerateFstabConfigurationFile() {
        installArchLinuxLog 'Generate fstab config.'
        if hash genfstab 1>"$_STANDARD_OUTPUT" 2>/dev/null; then
            # NOTE: Mountpoint shouldn't have a path separator at the end.
            genfstab -L -p "${_MOUNTPOINT_PATH%?}" \
                1>>"${_MOUNTPOINT_PATH}etc/fstab" 2>"$_ERROR_OUTPUT"
        else
            echo -e "# Added during installation\nLABEL=$_BOOT_PARTITION_LABEL / ext4 rw,relatime 0 1" \
                1>>"${_MOUNTPOINT_PATH}etc/fstab" 2>"$_ERROR_OUTPUT"
        fi
        return $?
    }

    # Reconfigures or installs a boot loader.
    function installArchLinuxHandleBootLoader() {
        if echo "$_OUTPUT_SYSTEM" | grep --quiet --extended-regexp \
            '[0-9]$'
        then
            installArchLinuxLog \
                'Update boot manager configuration on host system.'
            hash os-prober 1>"$_STANDARD_OUTPUT" 2>/dev/null || \
            installArchLinuxLog 'warning' \
                "Grub may not find your new installed system because \"os-prober\" isn't installed. If your system wasn't found install it and run \"grub-mkconfig -o /boot/grub/grub.cfg\"."
            grub-mkconfig --output /boot/grub/grub.cfg 1>"$_STANDARD_OUTPUT" \
                2>"$_ERROR_OUTPUT"
        else
            installArchLinuxIntegrateBootLoader
        fi
        return $?
    }

    # Unmount previous installed system.
    function installArchLinuxUnmountInstalledSystem() {
        installArchLinuxLog 'Unmount installed system.'
        sync 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
        cd / 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
        umount "$_MOUNTPOINT_PATH" 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        return $?
    }

    # Reboots into fresh installed system if previous defined.
    function installArchLinuxPrepareNextBoot() {
        if [ -b "$_OUTPUT_SYSTEM" ]; then
            installArchLinuxGenerateFstabConfigurationFile && \
            installArchLinuxHandleBootLoader && \
            installArchLinuxUnmountInstalledSystem
            returnCode=$?
            if [[ $returnCode == 0 ]] && \
               [[ $(echo "$_AUTOMATIC_REBOOT" | tr '[A-Z]' '[a-z]') != 'no' ]]
            then
                installArchLinuxLog 'Reboot into new operating system.'
                systemctl reboot 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" || \
                reboot 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
                return $?
            fi
            return $returnCode
        fi
    }

    # Disables signature checking for incoming packages.
    function installArchLinuxConfigurePacman() {
        installArchLinuxLog "Enable mirrors in \"$_COUNTRY_WITH_MIRRORS\"."
        local bufferFile=$(mktemp)
        local inArea=false
        local lineNumber=0
        local line
        while read line; do
            lineNumber=$(($lineNumber + 1))
            if [[ "$line" == "## $_COUNTRY_WITH_MIRRORS" ]]; then
                inArea=true
            elif [[ "$line" == '' ]]; then
                inArea=false
            elif $inArea && [[ ${line:0:1} == '#' ]]; then
                line=${line:1}
            fi
            echo "$line"
        done < "${_MOUNTPOINT_PATH}etc/pacman.d/mirrorlist" 1>"$bufferFile"
        cat "$bufferFile" 1>"${_MOUNTPOINT_PATH}etc/pacman.d/mirrorlist" \
            2>"$_ERROR_OUTPUT" && \
        installArchLinuxLog \
            "Change signature level to \"Never\" for pacman's packages." && \
        sed --regexp-extended --in-place 's/^(SigLevel *= *).+$/\1Never/g' \
            "${_MOUNTPOINT_PATH}etc/pacman.conf" 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT"
        return $?
    }

    # Determine weather we should perform our auto partitioning mechanism.
    function installArchLinuxDetermineAutoPartitioning() {
        if [ ! "$_AUTO_PARTITIONING" ]; then
            while true; do
                echo -n 'Do you want auto partioning? [yes|NO]: '
                read _AUTO_PARTITIONING
                if [[ "$_AUTO_PARTITIONING" == '' ]] || \
                   [[ $(echo "$_AUTO_PARTITIONING" | \
                      tr '[A-Z]' '[a-z]') == 'no' ]]; then
                    break
                elif [[ $(echo "$_AUTO_PARTITIONING" | \
                        tr '[A-Z]' '[a-z]') == 'yes' ]]; then
                    break
                fi
            done
        fi
    }

    # Provides the file content for the "/etc/hosts".
    function installArchLinuxGetHostsContent() {
        cat << EOF
#<IP-Adresse>  <Rechnername.Arbeitsgruppe>      <Rechnername>
127.0.0.1      localhost.localdomain            localhost $1
::1            ipv6-localhost                   ipv6-localhost ipv6-$1
EOF
    }

    # Prepares given block devices to make it ready for fresh installation.
    function installArchLinuxPrepareBlockdevices() {
        installArchLinuxLog \
            "Unmount needed devices and devices pointing to our temporary system mount point \"$_MOUNTPOINT_PATH\"."
        umount -f "${_OUTPUT_SYSTEM}"* 1>"$_STANDARD_OUTPUT" 2>/dev/null
        umount -f "$_MOUNTPOINT_PATH" 1>"$_STANDARD_OUTPUT" 2>/dev/null
        swapoff "${_OUTPUT_SYSTEM}"* 1>"$_STANDARD_OUTPUT" 2>/dev/null
        installArchLinuxLog \
            'Make partitions. Make a swap, data and boot partition.' && \
        installArchLinuxMakePartitions && \
        installArchLinuxLog 'Format partitions.' && \
        installArchLinuxFormatPartitions
        return $?
    }

    # Prepares the boot partition.
    function installArchLinuxPrepareBootPartition() {
        installArchLinuxLog 'Make boot partition.'
        local outputDevice="$_OUTPUT_SYSTEM"
        if [ -b "${_OUTPUT_SYSTEM}1" ]; then
            outputDevice="${_OUTPUT_SYSTEM}1"
        fi
        mkfs.ext4 "$outputDevice" -L "$_BOOT_PARTITION_LABEL" \
            1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
        installArchLinuxLog 'Mount boot partition.' && \
        mount "$outputDevice" "$_MOUNTPOINT_PATH" 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT"
        return $?
    }

    # Prepares the swap partition.
    function installArchLinuxPrepareSwapPartition() {
        if [ -b "${_OUTPUT_SYSTEM}2" ]; then
            installArchLinuxLog \
                "Make swap partition at \"${_OUTPUT_SYSTEM}2\"."
            mkswap "${_OUTPUT_SYSTEM}2" -L "$_SWAP_PARTITION_LABEL" \
                1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
            return $?
        fi
    }

    # Prepares the data partition.
    function installArchLinuxPrepareDataPartition() {
        if [ -b "${_OUTPUT_SYSTEM}3" ]; then
            installArchLinuxLog \
                "Make data partition at \"${_OUTPUT_SYSTEM}3\"."
            mkfs.ext4 "${_OUTPUT_SYSTEM}3" -L "$_DATA_PARTITION_LABEL" \
                1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
            return $?
        fi
    }

    # Performs formating part.
    function installArchLinuxFormatPartitions() {
        installArchLinuxPrepareBootPartition && \
        installArchLinuxPrepareSwapPartition && \
        installArchLinuxPrepareDataPartition
        return $?
    }

    # Installs "grub2" as bootloader.
    function installArchLinuxIntegrateBootLoader() {
        installArchLinuxLog 'Install boot manager.'
        installArchLinuxChangeRootToMountPoint grub-install \
            --target=i386-pc --recheck "$_OUTPUT_SYSTEM" \
            1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
        installArchLinuxLog 'Configure boot manager.' && \
        installArchLinuxChangeRootToMountPoint grub-mkconfig \
            --output /boot/grub/grub.cfg 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT"
        return $?
    }

    # Load previous downloaded packages and database.
    function installArchLinuxLoadCache() {
        installArchLinuxLog 'Load cached databases.' && \
        mkdir --parents \
            "$_MOUNTPOINT_PATH"var/lib/pacman/sync \
            1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
        cp --no-clobber --preserve "$_PACKAGE_CACHE_PATH"/*.db \
            "$_MOUNTPOINT_PATH"var/lib/pacman/sync/ \
            1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        installArchLinuxLog 'Load cached packages.' && \
        mkdir --parents "$_MOUNTPOINT_PATH"var/cache/pacman/pkg \
            1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
        cp --no-clobber --preserve "$_PACKAGE_CACHE_PATH"/*.pkg.tar.xz \
            "$_MOUNTPOINT_PATH"var/cache/pacman/pkg/ 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT"
        return $?
    }

    # Cache previous downloaded packages and database.
    function installArchLinuxCache() {
        installArchLinuxLog 'Cache loaded packages.'
        cp --force --preserve \
            "$_MOUNTPOINT_PATH"var/cache/pacman/pkg/*.pkg.tar.xz \
            "$_PACKAGE_CACHE_PATH"/ 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT" && \
        installArchLinuxLog 'Cache loaded databases.' && \
        cp --force --preserve \
            "$_MOUNTPOINT_PATH"var/lib/pacman/sync/*.db \
            "$_PACKAGE_CACHE_PATH"/ 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        return $?
    }

    # Deletes previous installed things in given output target. And creates a
    # package cache directory.
    function installArchLinuxPrepareInstallation() {
        mkdir --parents "$_PACKAGE_CACHE_PATH" 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT" && \
        installArchLinuxLog \
            "Clear previous installations in \"$_OUTPUT_SYSTEM\" and set right rights." && \
        rm "$_MOUNTPOINT_PATH"* --recursive --force 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT" && \
        chmod 755 "$_MOUNTPOINT_PATH" && \
        # Make a uniqe array.
        _PACKAGES=$(echo "${_PACKAGES[*]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
        return $?
    }

    # endregion

# endregion

# region controller

    if [[ "$0" == *"${__NAME__}.bash" ]]; then
        installArchLinuxCommandLineInterface "$@" || return $?
        _PACKAGES="${_BASIC_PACKAGES[*]} ${_ADDITIONAL_PACKAGES[*]}"
        if [ "$_INSTALL_COMMON_ADDITIONAL_PACKAGES" == 'yes' ]; then
            _PACKAGES+=' '${_COMMON_ADDITIONAL_PACKAGES[*]}
        fi
        if [ ! -e "$_OUTPUT_SYSTEM" ]; then
            mkdir --parents "$_OUTPUT_SYSTEM" 1>"$_STANDARD_OUTPUT" \
                2>"$_ERROR_OUTPUT"
        fi
        if [ -d "$_OUTPUT_SYSTEM" ]; then
            _MOUNTPOINT_PATH="$_OUTPUT_SYSTEM"
            if [[ ! "$_OUTPUT_SYSTEM" =~ .*/$ ]]; then
                _MOUNTPOINT_PATH="$_OUTPUT_SYSTEM"/
            fi
        elif [ -b "$_OUTPUT_SYSTEM" ]; then
            _PACKAGES+=' arch-install-scripts'
            if echo "$_OUTPUT_SYSTEM" | grep --quiet --extended-regexp '[0-9]$'
            then
                installArchLinuxPrepareBootPartition || \
                installArchLinuxLog 'error' 'Boot partition creation failed.'
            else
                _PACKAGES+=' grub-bios'
                if [ installArchLinuxDetermineAutoPartitioning ]; then
                    installArchLinuxPrepareBlockdevices || \
                    installArchLinuxLog 'error' \
                        'Preparing blockdevices failed.'
                else
                    installArchLinuxLog 'error' 'Autopartitioning failed.'
                fi
            fi
        else
            installArchLinuxLog 'error' \
                "Could not install into an existsing file \"$_OUTPUT_SYSTEM\"."
        fi
        installArchLinuxPrepareInstallation || \
        installArchLinuxLog 'error' 'Preparing installation failed.'
        if [[ "$UID" == 0 ]] && [[ "$_PREVENT_USING_PACSTRAP" == 'no' ]] && \
            hash pacstrap 1>"$_STANDARD_OUTPUT" 2>/dev/null
        then
            installArchLinuxWithPacstrap || \
            installArchLinuxLog 'error' 'Installation with pacstrap failed.'
        else
            installArchLinuxGenericLinuxSteps || \
            installArchLinuxLog 'error' \
                'Installation via generic linux steps failed.'
        fi
        installArchLinuxTidyUpSystem && \
        installArchLinuxConfigure || \
        installArchLinuxLog 'error' 'Configuring installed system failed.'
        installArchLinuxPrepareNextBoot || \
        installArchLinuxLog 'error' 'Preparing reboot failed.'
        installArchLinuxPackResult || \
        installArchLinuxLog 'error' \
            'Packing system into archiv with files owend by root failed.'
        installArchLinuxLog \
            "Generating operating system into \"$_OUTPUT_SYSTEM\" has successfully finished."
    fi

# endregion

}

# region footer

if [[ "$0" == *"${__NAME__}.bash" || $(echo "$@" | grep --extended-regexp \
    '(^| )(-l|--load-environment)($| )') ]]; then
    "$__NAME__" "$@"
fi

# endregion
