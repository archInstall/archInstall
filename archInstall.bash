#!/usr/bin/env bash
# -*- coding: utf-8 -*-

# region vim modline

# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:

# endregion

# region header

# Copyright Torben Sickert 16.12.2012

# License
# -------

# This library written by Torben Sickert stand under a creative commons naming
# 3.0 unported license. see http://creativecommons.org/licenses/by/3.0/deed.de

# archInstall provides a generic way to install an arch linux from any linux
# environment without maintaining the install process.

# Examples
# --------

# Start install progress command (Assuming internet is available):
# >>> wget \
# ... https://raw.github.com/archInstall/archInstall/master/archInstall.bash \
# ...     -O archInstall.bash && chmod +x archInstall.bash && \
# ... ./archInstall.bash --output-system /dev/sda1
# ...

# Call a global function (Configures your current system):
# >>> source archInstall.bash --load-environment && \
# ...     _MOUNTPOINT_PATH='/' _USER_NAMES='hans' \
# ...     _LOCAL_TIME='Europe/Berlin' archInstallConfigure

# Note that you only get very necessary output until you provide "--verbose" as
# commandline options.

# Dependencies
# ------------

# - bash (or any bash like shell)
# - test       - Check file types and compare values (part of the shell).
# - shift      - Shifts the command line arguments (part of the shell).
# - mount      - Filesystem mounter (part of util-linux).
# - umount     - Filesystem unmounter (part of util-linux).
# - mountpoint - See if a directory is a mountpoint (part of util-linux).
# - blkid      - Locate or print block device attributes (part of util-linux).
# - chroot     - Run command or interactive shell with special root directory
#                (part of coreutils).
# - echo       - Display a line of text (part of coreutils).
# - ln         - Make links between files (part of coreutils).
# - touch      - Change file timestamps or creates them (part of coreutils).
# - sync       - Flushs file system buffers (part of coreutils).
# - mktemp     - Create a temporary file or directory (part of coreutils).
# - cat        - Concatenate files and print on the standard output (part of
#                coreutils).
# - uniq       - Report or omit repeated lines (part of coreutils).
# - uname      - Prints system informations (part of coreutils).
# - rm         - Remove files or directories (part of coreutils).
# - sed        - Stream editor for filtering and transforming text.
# - wget       - The non-interactive network downloader.
# - xz         - Compress or decompress .xz and lzma files.
# - tar        - The GNU version of the tar archiving utility.
# - grep       - Searches the named input files (or standard input if no files
#                are named, or if a single hyphen-minus (-) is given as file
#                name) for lines containing a match to the given PATTERN. By
#                default, grep prints the matching lines.
# - which      - Shows the full path of (shell) commands.

# Dependencies for blockdevice integration
# ----------------------------------------

# - blockdev   - Call block device ioctls from the command line (part of
#                util-linux).
# - efibootmgr - Manipulate the EFI Boot Manager (part of efibootmgr).
# - gdisk      - Interactive GUID partition table (GPT) manipulator (part of
#                gptfdisk).
# - btrfs      - Control a btrfs filesystem (part of btrfs-progs).

# Optional dependencies
# ---------------------

# for smart dos filesystem labeling, installing without root permissions or
# automatic network configuration.

# - dosfslabel  - Handle dos file systems (part of dosfstools).
# - arch-chroot - Performs an arch chroot with api file system binding (part
#                 of arch-install-scripts).
# - fakeroot    - Run a command in an environment faking root privileges for
#                 file manipulation.
# - fakechroot  - Wraps some c-lib functions to enable programs like "chroot"
#                 running without root privileges.
# - os-prober   - Detects presence of other operating systems.
# - ip          - Determines network adapter (part of iproute2).

__NAME__='archInstall'

# endregion

function archInstall() {
    # Provides the main module scope.

# region properties

    # region command line arguments

    local _SCOPE='local' && \
    if [[ $(echo "\"$@\"" | grep --extended-regexp \
        '(^"| )(-l|--load-environment)("$| )') != '' ]]
    then
        local _SCOPE='export'
    fi
    # NOTE: We have to reset this variable in wrapped context to set best
    # wrapper name prefixed default.
    "$_SCOPE" _PACKAGE_CACHE_PATH="${__NAME__}PackageCache" && \
    # NOTE: Only initialize environment if current scope wasn't set yet.
    if [ "$_VERBOSE" == '' ]; then
        "$_SCOPE" _VERBOSE='no'
        "$_SCOPE" _LOAD_ENVIRONMENT='no'

        local userNames=()
        "$_SCOPE" _USER_NAMES="${userNames[*]}"
        "$_SCOPE" _HOSTNAME=''

        # NOTE: Possible constant values are "i686" or "x86_64".
        "$_SCOPE" _CPU_ARCHITECTURE=$(uname -m) # Possible: x86_64, i686, arm, any
        "$_SCOPE" _OUTPUT_SYSTEM="$__NAME__"

        # NOTE: This properties aren't needed in the future with supporting
        # localectl program.
        "$_SCOPE" _LOCAL_TIME='Europe/Berlin'
        "$_SCOPE" _KEYBOARD_LAYOUT='de-latin1'
        "$_SCOPE" _KEY_MAP_CONFIGURATION_FILE_CONTENT="KEYMAP=${_KEYBOARD_LAYOUT}\nFONT=Lat2-Terminus16\nFONT_MAP="
        # NOTE: Each value which is present in "/etc/pacman.d/mirrorlist" is ok.
        "$_SCOPE" _COUNTRY_WITH_MIRRORS='Germany'

        "$_SCOPE" _AUTOMATIC_REBOOT='yes'
        "$_SCOPE" _PREVENT_USING_PACSTRAP='no'
        "$_SCOPE" _PREVENT_USING_NATIVE_ARCH_CHANGE_ROOT='no'
        "$_SCOPE" _AUTO_PARTITIONING=''

        "$_SCOPE" _BOOT_PARTITION_LABEL='uefiBoot'
        "$_SCOPE" _SYSTEM_PARTITION_LABEL='system'

        "$_SCOPE" _BOOT_ENTRY_LABEL='archLinux'
        "$_SCOPE" _FALLBACK_BOOT_ENTRY_LABEL='archLinuxFallback'

        # NOTE: A FAT32 partition has to be at least 512 MB large.
        "$_SCOPE" _BOOT_SPACE_IN_MEGA_BYTE=512
        "$_SCOPE" _NEEDED_SYSTEM_SPACE_IN_MEGA_BYTE=512

        "$_SCOPE" _INSTALL_COMMON_ADDITIONAL_PACKAGES='no'
        local additionalPackages=()
        "$_SCOPE" _ADDITIONAL_PACKAGES="${additionalPackages[*]}"
        local neededServices=()
        "$_SCOPE" _NEEDED_SERVICES="${neededServices[*]}"

    # endregion

        local dependencies=(bash test shift mount umount mountpoint blkid \
            chroot echo ln touch sync mktemp cat uniq uname rm sed wget xz \
            tar grep)
        "$_SCOPE" _DEPENDENCIES="${dependencies[*]}"
        local blockIntegrationDependencies=(blockdev efibootmgr gdisk btrfs)
        "$_SCOPE" _BLOCK_INTEGRATION_DEPENDENCIES="${blockIntegrationDependencies[*]}"
        # Define where to mount temporary new filesystem.
        # NOTE: Path has to be end with a system specified delimiter.
        "$_SCOPE" _MOUNTPOINT_PATH='/mnt/'
        # After determining dependencies a list like this will be stored:
        # "pacman", "bash", "readline", "glibc", "libarchive", "acl", "attr",
        # "bzip2", "expat", "lzo2", "openssl", "perl", "gdbm", "sh", "db",
        # "gcc-libs", "xz", "zlib", "curl", "ca-certificates", "run-parts",
        # "findutils", "coreutils", "pam", "cracklib", "libtirpc",
        # "libgssglue", "pambase", "gmp", "libcap", "sed", "krb5", "e2fsprogs",
        # "util-linux", "shadow", "libldap", "libsasl", "keyutils", "libssh2",
        # "gpgme", "libgpg-error", "pth", "awk", "mpfr", "gnupg", "libksba",
        # "libgcrypt", "libassuan", "pinentry", "ncurses", "dirmngr",
        # "pacman-mirrorlist", "archlinux-keyring"
        local neededPackages=(filesystem)
        "$_SCOPE" _NEEDED_PACKAGES="${neededPackages[*]}"
        local packagesSourceUrls=(
            'http://mirror.de.leaseweb.net/archlinux' \
            'http://archlinux.limun.org' 'http://mirrors.kernel.org/archlinux')
        "$_SCOPE" _PACKAGE_SOURCE_URLS="${packagesSourceUrls[*]}"
        local basicPackages=(base ifplugd)
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
        local neededMountpoints=(/proc /sys /sys/firmware/efi/efivars /dev \
            /dev/pts /dev/shm /run /tmp)
        "$_SCOPE" _NEEDED_MOUNTPOINTS="${neededMountpoints[*]}"
    fi

# endregion

# region functions

    # region command line interface

    function archInstallPrintUsageMessage() {
        # Prints a description about how to use this program.
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
    function archInstallPrintUsageExamples() {
        # Prints a description about how to use this program by providing examples.
        cat << EOF
    # Start install progress command on first found blockdevice:
    >>> $0 --output-system /dev/sda

    # Install directly into a given partition with verbose output:
    >>> $0 --output-system /dev/sda1 --verbose

    # Install directly into a given directory with addtional packages included:
    >>> $0 --output-system /dev/sda1 --verbose -f vim net-tools
EOF
    }
    function archInstallPrintCommandLineOptionDescription() {
        # Prints descriptions about each available command line option.
        # NOTE; All letters are used for short options.
        # NOTE: "-k" and "--key-map-configuration" isn't needed in the future.
        cat << EOF
    -h --help Shows this help message.

    -v --verbose Tells you what is going on (default: "$_VERBOSE").

    -d --debug Gives you any output from all tools which are used
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

    -b --keyboard-layout LAYOUT Defines needed keyboard layout
        (default: "$_KEYBOARD_LAYOUT").

    -k --key-map-configuration FILE_CONTENT Keyboard map configuration
        (default: "$_KEY_MAP_CONFIGURATION_FILE_CONTENT").

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


    -e --boot-partition-label LABEL Partition label for uefi boot partition
        (default: "$_BOOT_PARTITION_LABEL").

    -g --system-partition-label LABEL Partition label for system partition
        (default: "$_SYSTEM_PARTITION_LABEL").


    -i --boot-entry-label LABEL Boot entry label
        (default: "$_BOOT_ENTRY_LABEL").
    -s --fallback-boot-entry-label LABEL Fallback boot entry label
        (default: "$_FALLBACK_BOOT_ENTRY_LABEL").


    -w --boot-space-in-mega-byte NUMBER In case if selected auto partitioning
        you can define the minimum space needed for your boot partition
        (default: "$_BOOT_SPACE_IN_MEGA_BYTE MegaByte"). This partition
        is used for kernel and initramfs only.

    -q --needed-system-space-in-mega-byte NUMBER In case if selected auto
        partitioning you can define the minimum space needed for your system
        partition (default: "$_NEEDED_SYSTEM_SPACE_IN_MEGA_BYTE MegaByte").
        This partition is used for the whole operating system.


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
    function archInstallPrintHelpMessage() {
        # Provides a help message for this module.
        echo -e "\nUsage: $0 [options]\n"
        archInstallPrintUsageMessage "$@"
        echo -e '\nExamples:\n'
        archInstallPrintUsageExamples "$@"
        echo -e '\nOption descriptions:\n'
        archInstallPrintCommandLineOptionDescription "$@"
        echo
    }
    function archInstallCommandLineInterface() {
        # Provides the command line interface and interactive questions.
        while true; do
            case "$1" in
                -h|--help)
                    shift
                    archInstallPrintHelpMessage "$0"
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
                -b|--keyboard-layout)
                    shift
                    _KEYBOARD_LAYOUT="$1"
                    shift
                    ;;
                -k|--key-map-configuation)
                    shift
                    _KEY_MAP_CONFIGURATION_FILE_CONTENT="$1"
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
                -g|--system-partition-label)
                    shift
                    _SYSTEM_PARTITION_LABEL="$1"
                    shift
                    ;;

                -i|--boot-entry-label)
                    shift
                    _BOOT_ENTRY_LABEL="$1"
                    shift
                    ;;
                -s|--fallback-boot-entry-label)
                    shift
                    _FALLBACK_BOOT_ENTRY_LABEL="$1"
                    shift
                    ;;

                -w|--boot-space-in-mega-byte)
                    shift
                    _BOOT_SPACE_IN_MEGA_BYTE="$1"
                    shift
                    ;;
                -q|--needed-system-space-in-mega-byte)
                    shift
                    _NEEDED_SYSTEM_IN_MEGA_BYTE="$1"
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
                    archInstallLog 'critical' \
                        "Given argument: \"$1\" is not available." '\n' && \
                    if [[ "$_SCOPE" == 'local' ]]; then
                        archInstallPrintHelpMessage "$0"
                    fi
                    return 1
            esac
        done
        if [[ "$UID" != '0' ]] && ! (
            hash fakeroot 1>"$_STANDARD_OUTPUT" 2>/dev/null && \
            hash fakechroot 1>"$_STANDARD_OUTPUT" 2>/dev/null && \
            ([ -e "$_OUTPUT_SYSTEM" ] && [ -d "$_OUTPUT_SYSTEM" ]))
        then
            archInstallLog 'critical' \
                "You have to run this script as \"root\" not as \"${USER}\". You can alternatively install \"fakeroot\", \"fakechroot\" and install into a directory."
            exit 2
        fi
        if [[ "$0" == *"${__NAME__}.bash" ]]; then
            if [ ! "$_HOSTNAME" ]; then
                while true; do
                    echo -n 'Please set hostname for new system: ' && \
                    read _HOSTNAME
                    if [[ $(echo "$_HOSTNAME" |\
                          tr '[A-Z]' '[a-z]') != '' ]]; then
                        break
                    fi
                done
            fi
        fi
        return 0
    }
    function archInstallLog() {
        # Handles logging messages. Returns non zero and exit on log level
        # error to support chaining the message into toolchain.
        #
        # Examples:
        #
        # >>> archInstallLog test
        # info: test
        # >>> archInstallLog debug message
        # debug: message
        # >>> archInstallLog info message '\n'
        #
        # info: message
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
        return 0
    }

    # endregion

    # region install arch linux steps.

    function archInstallWithPacstrap() {
        # Installs arch linux via pacstrap.
        archInstallLoadCache
        archInstallLog \
            'Patch pacstrap to handle offline installations.' && \
        cat $(which pacstrap) | sed --regexp-extended \
            's/(pacman.+-(S|-sync))(y|--refresh)/\1/g' \
            1>${_PACKAGE_CACHE_PATH}/patchedOfflinePacman.bash \
            2>"$_STANDARD_OUTPUT" && \
        chmod +x "${_PACKAGE_CACHE_PATH}/patchedOfflinePacman.bash" \
            1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
        archInstallLog 'Update package databases.' && \
        (pacman --arch "$_CPU_ARCHITECTURE" --sync --refresh \
            --root "$_MOUNTPOINT_PATH" 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT" || true) && \
        archInstallLog \
            "Install needed packages \"$(echo "${_PACKAGES[*]}" | sed \
            --regexp-extended 's/(^ +| +$)//g' | sed \
            's/ /", "/g')\" to \"$_OUTPUT_SYSTEM\"."
        # NOTE: "${_PACKAGES[*]}" shouldn't be in quotes to get pacstrap
        # working.
        "${_PACKAGE_CACHE_PATH}/patchedOfflinePacman.bash" -d \
            "$_MOUNTPOINT_PATH" ${_PACKAGES[*]} --force 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT" && \
        rm "${_PACKAGE_CACHE_PATH}/patchedOfflinePacman.bash" \
            1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        local returnCode=$?
        (archInstallCache || archInstallLog 'warning' \
            'Caching current downloaded packages and generated database failed.')
        return $returnCode
    }
    function archInstallGenericLinuxSteps() {
        # This functions performs creating an arch linux system from any linux
        # system base.
        archInstallLog 'Create a list with urls for needed packages.' && \
        archInstallDownloadAndExtractPacman \
            $(archInstallCreatePackageUrlList) && \
        # Create root filesystem only if not exists.
        (test -e "${_MOUNTPOINT_PATH}etc/mtab" 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT" || echo "rootfs / rootfs rw 0 0" \
            1>"${_MOUNTPOINT_PATH}etc/mtab" 2>"$_ERROR_OUTPUT") && \
        # Copy systems resolv.conf to new installed system.
        # If the native "arch-chroot" is used it will mount the file into the
        # change root environment.
        cp '/etc/resolv.conf' "${_MOUNTPOINT_PATH}etc/" 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT" && \
        [[ "$_PREVENT_USING_NATIVE_ARCH_CHANGE_ROOT" == 'no' ]] && \
        hash arch-chroot 1>"$_STANDARD_OUTPUT" 2>/dev/null && \
        mv "${_MOUNTPOINT_PATH}etc/resolv.conf" \
            "${_MOUNTPOINT_PATH}etc/resolv.conf.old" 1>"$_STANDARD_OUTPUT" \
            2>/dev/null
        sed --in-place --quiet '/^[ \t]*CheckSpace/ !p' \
            "${_MOUNTPOINT_PATH}etc/pacman.conf" 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT" && \
        sed --in-place "s/^[ \t]*SigLevel[ \t].*/SigLevel = Never/" \
            "${_MOUNTPOINT_PATH}etc/pacman.conf" 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT" && \
        archInstallLog 'Create temporary mirrors to download new packages.' && \
        archInstallAppendTemporaryInstallMirrors && \
        (archInstallLoadCache || archInstallLog \
             'No package cache was loaded.') && \
        archInstallLog "Update package databases." && \
        (archInstallChangeRootToMountPoint /usr/bin/pacman \
            --arch "$_CPU_ARCHITECTURE" --sync --refresh \
            1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" || true) && \
        archInstallLog \
            "Install needed packages \"$(echo "${_PACKAGES[*]}" | sed \
            --regexp-extended 's/(^ +| +$)//g' | sed \
            's/ /", "/g')\" to \"$_OUTPUT_SYSTEM\"."
        archInstallChangeRootToMountPoint /usr/bin/pacman --arch \
            "$_CPU_ARCHITECTURE" --sync --force --needed --noconfirm \
            ${_PACKAGES[*]} 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        local returnCode=$? && \
        (archInstallCache || archInstallLog 'warning' \
            'Caching current downloaded packages and generated database failed.')
        [[ $returnCode == 0 ]] && archInstallConfigurePacman
        return $?
    }

    # endregion

    # region tools

        # region change root functions

    function archInstallPerformDependencyCheck() {
        # This function check if all given dependencies are present.
        #
        # Examples:
        #
        # >>> archInstallPerformDependencyCheck "mkdir pacstrap mktemp"
        # ...
        local dependenciesToCheck="$1" && \
        local result=0 && \
        local dependency && \
        for dependency in ${dependenciesToCheck[*]}; do
            if ! hash "$dependency" 1>"$_STANDARD_OUTPUT" 2>/dev/null; then
                archInstallLog 'critical' \
                    "Needed dependency \"$dependency\" isn't available." && \
                result=1
            fi
        done
        return $result
    }
    function archInstallChangeRootToMountPoint() {
        # This function performs a changeroot to currently set mountpoint path.
        archInstallChangeRoot "$_MOUNTPOINT_PATH" "$@"
        return $?
    }
    function archInstallChangeRoot() {
        # This function emulates the arch linux native "arch-chroot" function.
        if [[ "$1" == '/' ]]; then
            shift
            "$@" 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
            return $?
        else
            if [[ "$_PREVENT_USING_NATIVE_ARCH_CHANGE_ROOT" == 'no' ]] && \
                hash arch-chroot 1>"$_STANDARD_OUTPUT" 2>/dev/null
            then
                arch-chroot "$@" 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
                return $?
            fi
            archInstallChangeRootViaMount "$@"
            return $?
        fi
        return $?
    }
    function archInstallChangeRootViaMount() {
        # Performs a change root by mounting needed host locations in change
        # root environment.
        local mountpointPath && \
        for mountpointPath in ${_NEEDED_MOUNTPOINTS[*]}; do
            mountpointPath="${mountpointPath:1}" && \
            if [ ! -e "${_MOUNTPOINT_PATH}${mountpointPath}" ]; then
                mkdir --parents "${_MOUNTPOINT_PATH}${mountpointPath}" \
                    1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
            fi
            if ! mountpoint -q "${_MOUNTPOINT_PATH}${mountpointPath}"; then
                if [ "$mountpointPath" == 'proc' ]; then
                    mount "/${mountpointPath}" \
                        "${_MOUNTPOINT_PATH}${mountpointPath}" --types \
                        "$mountpointPath" --options nosuid,noexec,nodev \
                        1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
                elif [ "$mountpointPath" == 'sys' ]; then
                    mount "/${mountpointPath}" \
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
                elif [ "$mountpointPath" == 'dev/shm' ]; then
                    mount shm "${_MOUNTPOINT_PATH}${mountpointPath}" --types \
                        tmpfs --options mode=1777,nosuid,nodev \
                        1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
                elif [ "$mountpointPath" == 'run' ]; then
                    mount "/${mountpointPath}" \
                        "${_MOUNTPOINT_PATH}${mountpointPath}" --types tmpfs \
                        --options nosuid,nodev,mode=0755 \
                        1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
                elif [ "$mountpointPath" == 'tmp' ]; then
                    mount run "${_MOUNTPOINT_PATH}${mountpointPath}" --types \
                        tmpfs --options mode=1777,strictatime,nodev,nosuid \
                        1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
                elif [ -f "/${mountpointPath}" ]; then
                    mount "/${mountpointPath}" \
                        "${_MOUNTPOINT_PATH}${mountpointPath}" --bind
                else
                    archInstallLog 'warning' \
                        "Mountpoint \"/${mountpointPath}\" couldn't be handled."
                fi
            fi
        done
        archInstallPerformChangeRoot "$@"
        local returnCode=$?
        # Reverse mountpoint list to unmount them in reverse order.
        local reverseNeededMountpoints && \
        for mountpointPath in ${_NEEDED_MOUNTPOINTS[*]}; do
            reverseNeededMountpoints="$mountpointPath ${reverseNeededMountpoints[*]}"
        done
        for mountpointPath in ${reverseNeededMountpoints[*]}; do
            mountpointPath="${mountpointPath:1}" && \
            if mountpoint -q "${_MOUNTPOINT_PATH}${mountpointPath}" || \
                [ -f "/${mountpointPath}" ]
            then
                # If unmounting doesn't work try to unmount in lazy mode
                # (when mountpoints are not needed anymore).
                umount "${_MOUNTPOINT_PATH}${mountpointPath}" \
                    1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" || \
                (archInstallLog 'warning' "Unmounting \"${_MOUNTPOINT_PATH}${mountpointPath}\" fails so unmount it in force mode." && \
                 umount -f "${_MOUNTPOINT_PATH}${mountpointPath}" \
                     1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT") || \
                (archInstallLog 'warning' "Unmounting \"${_MOUNTPOINT_PATH}${mountpointPath}\" in force mode fails so unmount it if mountpoint isn't busy anymore." && \
                 umount -l "${_MOUNTPOINT_PATH}${mountpointPath}" \
                     1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT")
                # NOTE: "returnCode" remains with an error code if there was
                # given one in all iterations.
                [[ $? != 0 ]] && returnCode=$?
            else
                archInstallLog 'warning' \
                    "Location \"${_MOUNTPOINT_PATH}${mountpointPath}\" should be a mountpoint but isn't."
            fi
        done
        return $returnCode
    }
    function archInstallPerformChangeRoot() {
        # Perform the available change root program wich needs at least rights.
        if [[ "$UID" == '0' ]]; then
            chroot "$@" 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
            return $?
        fi
        fakeroot fakechroot chroot "$@" 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT"
        return $?
    }

        # endregion

    function archInstallConfigure() {
        # Provides generic linux configuration mechanism. If new systemd
        # programs are used (if first argument is "true") they could have
        # problems in change root environment without and exclusive dbus
        # connection.
        archInstallLog "Make keyboard layout permanent to \"${_KEYBOARD_LAYOUT}\"." && \
        if [[ "$1" == 'true' ]]; then
            archInstallChangeRootToMountPoint localectl set-keymap \
                "$_KEYBOARD_LAYOUT" 1>"$_STANDARD_OUTPUT" \
                2>"$_ERROR_OUTPUT" && \
            archInstallChangeRootToMountPoint localectl set-locale \
                LANG="en_US.utf8" 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
            archInstallChangeRootToMountPoint locale-gen set-keymap \
                "$_KEYBOARD_LAYOUT" 1>"$_STANDARD_OUTPUT" \
                2>"$_ERROR_OUTPUT"
        else
            echo -e "$_KEY_MAP_CONFIGURATION_FILE_CONTENT" 1>\
                "${_MOUNTPOINT_PATH}etc/vconsole.conf" 2>"$_ERROR_OUTPUT"
        fi
        archInstallLog "Set localtime \"$_LOCAL_TIME\"." && \
        if [[ "$1" == 'true' ]]; then
            archInstallChangeRootToMountPoint timedatectl set-timezone \
                "$_LOCAL_TIME" 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        else
            ln --symbolic --force "/usr/share/zoneinfo/${_LOCAL_TIME}" \
                "${_MOUNTPOINT_PATH}etc/localtime" 1>"$_STANDARD_OUTPUT" \
                2>"$_ERROR_OUTPUT"
        fi
        archInstallLog "Set hostname to \"$_HOSTNAME\"." && \
        if [[ "$1" == 'true' ]]; then
            archInstallChangeRootToMountPoint hostnamectl set-hostname \
                "$_HOSTNAME" 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        else
            echo -e "$_HOSTNAME" 1>"${_MOUNTPOINT_PATH}etc/hostname" \
                2>"$_ERROR_OUTPUT"
        fi
        archInstallLog 'Set hosts.' && \
        archInstallGetHostsContent "$_HOSTNAME" \
            1>"${_MOUNTPOINT_PATH}etc/hosts" 2>"$_ERROR_OUTPUT" && \
        if [[ "$1" != 'true' ]]; then
            archInstallLog 'Set root password to "root".' && \
            archInstallChangeRootToMountPoint /usr/bin/env bash -c \
                "echo root:root | \$(which chpasswd)" 1>"$_STANDARD_OUTPUT" \
                2>"$_ERROR_OUTPUT"
        fi
        archInstallEnableServices && \
        local userName && \
        for userName in ${_USER_NAMES[*]}; do
            archInstallLog "Add user: \"$userName\"." && \
            # NOTE: We could only create a home directory with right rights if
            # we are root.
            (archInstallChangeRootToMountPoint useradd \
                 --home-dir "/home/$userName/" --groups users \
                 $([[ "$UID" == '0' ]] || echo '--no-create-home') \
                 --no-user-group --shell $(which bash) "$userName" \
                 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" || \
             (archInstallLog 'warning' \
                  "Adding user \"$userName\" failed." && false)) && \
            archInstallLog \
                "Set password for \"$userName\" to \"$userName\"." && \
            archInstallChangeRootToMountPoint /usr/bin/env bash \
                -c "echo ${userName}:${userName} | \$(which chpasswd)" \
                1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        done
        return $?
    }
    function archInstallEnableServices() {
        # Enable all needed services.
        local networkDeviceName && \
        for networkDeviceName in $(ip addr | grep --extended-regexp \
            --only-matching '^[0-9]+: .+: ' | sed --regexp-extended \
            's/^[0-9]+: (.+): $/\1/g')
        do
            if [[ ! "$(echo "$networkDeviceName" | grep --extended-regexp \
                  '^(lo|loopback|localhost)$')" ]]; then
                local serviceName='dhcpcd' && \
                local connection='ethernet' && \
                local description='A basic dhcp connection' && \
                local additionalProperties='' && \
                if [[ "${networkDeviceName:0:1}" == 'e' ]]; then
                    archInstallLog \
                        "Enable dhcp service on wired network device \"$networkDeviceName\"." && \
                    serviceName='netctl-ifplugd' && \
                    connection='ethernet' && \
                    description='A basic ethernet dhcp connection'
                elif [[ "${networkDeviceName:0:1}" == 'w' ]]; then
                    archInstallLog \
                        "Enable dhcp service on wireless network device \"$networkDeviceName\"." && \
                    serviceName='netctl-auto' && \
                    connection='wireless' && \
                    description='A simple WPA encrypted wireless connection' && \
                    additionalProperties="\nSecurity=wpa\nESSID='home'\nKey='home'"
                fi
            cat << EOF 1>"${_MOUNTPOINT_PATH}etc/netctl/${networkDeviceName}-dhcp" 2>"$_ERROR_OUTPUT"
Description='${description}'
Interface=${networkDeviceName}
Connection=${connection}
IP=dhcp
## for DHCPv6
#IP6=dhcp
## for IPv6 autoconfiguration
#IP6=stateless${additionalProperties}
EOF
                ln --symbolic --force \
                    "/usr/lib/systemd/system/${serviceName}@.service" \
                    "${_MOUNTPOINT_PATH}etc/systemd/system/multi-user.target.wants/${serviceName}@${networkDeviceName}.service" \
                    1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
            fi
        done
        local serviceName && \
        for serviceName in ${_NEEDED_SERVICES[*]}; do
            archInstallLog "Enable \"$serviceName\" service."
            archInstallChangeRootToMountPoint systemctl enable \
                "$serviceName".service 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
            [[ $? != 0 ]] && return $?
        done
        return 0
    }
    function archInstallTidyUpSystem() {
        # Deletes some unneeded locations in new installs operating system.
        local returnCode=0 && \
        archInstallLog 'Tidy up new build system.' && \
        local filePath && \
        for filePath in ${_UNNEEDED_FILE_LOCATIONS[*]}; do
            archInstallLog \
                "Deleting \"${_MOUNTPOINT_PATH}$filePath\"." && \
            rm "${_MOUNTPOINT_PATH}$filePath" --recursive \
                --force 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
            [[ $? != 0 ]] && return $?
        done
        return 0
    }
    function archInstallAppendTemporaryInstallMirrors() {
        # Appends temporary used mirrors to download missing packages during
        # installation.
        local url && \
        for url in ${_PACKAGE_SOURCE_URLS[*]}; do
            echo "Server = $url/\$repo/os/$_CPU_ARCHITECTURE" \
                1>>"${_MOUNTPOINT_PATH}etc/pacman.d/mirrorlist" \
                2>"$_ERROR_OUTPUT"
            [[ $? != 0 ]] && return $?
        done
        return 0
    }
    function archInstallPackResult() {
        # Packs the resulting system to provide files owned by root without
        # root permissions.
        if [[ "$UID" != '0' ]]; then
            archInstallLog "System will be packed into \"$_MOUNTPOINT_PATH.tar\" to provide root owned files. You have to extract this archiv as root."
            tar cvf "$_MOUNTPOINT_PATH".tar "$_MOUNTPOINT_PATH" --owner root \
                1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
            rm "$_MOUNTPOINT_PATH"* --recursive --force 1>"$_STANDARD_OUTPUT" \
                2>"$_ERROR_OUTPUT"
            return $?
        fi
        return 0
    }
    function archInstallCreatePackageUrlList() {
        # Generates all web urls for needed packages.
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
            [[ $? != 0 ]] && returnCode=$?
        done
        echo "$listBufferFile"
        return $returnCode
    }
    function archInstallDeterminePacmansNeededPackages() {
        # Reads pacmans database and determine pacman's dependencies.
        local coreDatabaseUrl=$(grep "core\.db" "$listBufferFile" | \
            head --lines 1)
        wget "$coreDatabaseUrl" --timestamping --directory-prefix \
            "${_PACKAGE_CACHE_PATH}/" 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT" && \
        if [ -f "$_PACKAGE_CACHE_PATH/core.db" ]; then
            local databaseLocation=$(mktemp --directory)
            tar --gzip --extract --file "$_PACKAGE_CACHE_PATH/core.db" \
                --directory "$databaseLocation" 1>"$_STANDARD_OUTPUT" \
                2>"$_ERROR_OUTPUT" && \
            archInstallDeterminePackageDependencies 'pacman' \
                "$databaseLocation"
            return $?
        else
            archInstallLog 'error' \
                "No database file (\"$_PACKAGE_CACHE_PATH/core.db\") available."
        fi
    }
    function archInstallDeterminePackageDependencies() {
        # Determines all package dependencies. Returns a list of needed
        # packages for given package determined by given database.
        # NOTE: We append and prepend always a whitespace to simply identify
        # duplicates without using extended regular expression and packname
        # escaping.
        _NEEDED_PACKAGES+=" $1 " && \
        _NEEDED_PACKAGES="$(echo "$_NEEDED_PACKAGES" | sed --regexp-extended \
            's/ +/ /g')" && \
        local returnCode=0 && \
        local \
            packageDirectoryPath=$(archInstallDeterminePackageDirectoryName \
            "$@") && \
        if [ "$packageDirectoryPath" ]; then
            local packageDependencyDescription && \
            for packageDependencyDescription in $(cat \
                "${packageDirectoryPath}depends" | grep --perl-regexp \
                --null-data --only-matching '%DEPENDS%(\n.+)+' | grep \
                --extended-regexp --invert-match '^%.+%$')
            do
                local packageName=$(echo "$packageDependencyDescription" | \
                    grep --extended-regexp --only-matching '^[-a-zA-Z0-9]+')
                if ! echo "$_NEEDED_PACKAGES" 2>"$_ERROR_OUTPUT" | grep \
                    " $packageName " 1>/dev/null 2>/dev/null
                then
                    archInstallDeterminePackageDependencies "$packageName" \
                        "$2" recursive || \
                    archInstallLog 'warning' \
                        "Needed package \"$packageName\" for \"$1\" couldn't be found in database in \"$2\"."
                fi
            done
        else
            returnCode=1
        fi
        # Trim resulting list.
        if [[ ! "$3" ]]; then
            _NEEDED_PACKAGES="$(echo "${_NEEDED_PACKAGES}" | sed \
                --regexp-extended 's/(^ +| +$)//g')"
        fi
        return $returnCode
    }
    function archInstallDeterminePackageDirectoryName() {
        # Determines the package directory name from given package name in
        # given database.
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
    function archInstallDownloadAndExtractPacman() {
        # Downloads all packages from arch linux needed to run pacman.
        local listBufferFile="$1" && \
        if archInstallDeterminePacmansNeededPackages "$listBufferFile"; then
            archInstallLog \
                "Needed packages are: \"$(echo "${_NEEDED_PACKAGES[*]}" | sed \
                's/ /", "/g')\"." && \
            archInstallLog \
                "Download and extract each package into our new system located in \"$_MOUNTPOINT_PATH\"." && \
            local packageName && \
            for packageName in ${_NEEDED_PACKAGES[*]}; do
                local packageUrl=$(grep "$packageName-[0-9]" \
                    "$listBufferFile" | head --lines 1)
                local fileName=$(echo $packageUrl \
                    | sed 's/.*\/\([^\/][^\/]*\)$/\1/')
                # If "fileName" couldn't be determined via server determine it
                # via current package cache.
                if [ ! "$fileName" ]; then
                    fileName=$(ls $_PACKAGE_CACHE_PATH | grep \
                        "$packageName-[0-9]" | head --lines 1)
                fi
                if [ "$fileName" ]; then
                    wget "$packageUrl" --timestamping --continue \
                        --directory-prefix "${_PACKAGE_CACHE_PATH}/" \
                        1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
                else
                    archInstallLog \
                        'error' "A suitable file for package \"$packageName\" could not be determined."
                fi
                archInstallLog "Install package \"$fileName\" manually." && \
                xz --decompress --to-stdout "$_PACKAGE_CACHE_PATH/$fileName" \
                    2>"$_ERROR_OUTPUT" | tar --extract --directory \
                    "$_MOUNTPOINT_PATH" 1>"$_STANDARD_OUTPUT" \
                    2>"$_ERROR_OUTPUT"
                local returnCode=$? && [[ $returnCode != 0 ]] && \
                    return $returnCode
            done
        else
            return $?
        fi
        return 0
    }
    function archInstallMakePartitions() {
        # Performs the auto partitioning.
        if [[ $(echo "$_AUTO_PARTITIONING" | tr '[A-Z]' '[a-z]') == 'yes' ]]
        then
            archInstallLog 'Check block device size.' && \
            local blockDeviceSpaceInMegaByte=$(($(blockdev --getsize64 \
                "$_OUTPUT_SYSTEM") * 1024 ** 2)) && \
            if [[ $(($_NEEDED_SYSTEM_SPACE_IN_MEGA_BYTE + \
                  $_BOOT_SPACE_IN_MEGA_BYTE)) -le \
                  $blockDeviceSpaceInMegaByte ]]; then
                archInstallLog 'Create boot and system partitions.' && \
                gdisk "$_OUTPUT_SYSTEM" << EOF \
                    1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
o
Y
n


${_BOOT_SPACE_IN_MEGA_BYTE}M
ef00
n




c
1
$_BOOT_PARTITION_LABEL
c
2
$_SYSTEM_PARTITION_LABEL
w
Y
EOF
            else
                archInstallLog 'error' "Not enough space on \"$_OUTPUT_SYSTEM\" (\"$blockDeviceSpaceInByte\" byte). We need at least \"$(($_NEEDED_SYSTEM_SPACE_IN_BYTE + $_BOOT_SPACE_IN_BYTE))\" byte."
            fi
        else
            archInstallLog \
                "At least you have to create two partitions. The first one will be used as boot partition labeled to \"${_BOOT_PARTITION_LABEL}\" and second one will be used as system partition and labeled to \"${_SYSTEM_PARTITION_LABEL}\". Press Enter to continue." && \
            read && \
            archInstallLog 'Show blockdevices. Press Enter to continue.' && \
            lsblk && \
            read && \
            archInstallLog 'Create partitions manually.' && \
            gdisk "$_OUTPUT_SYSTEM"
        fi
        return $?
    }
    function archInstallGenerateFstabConfigurationFile() {
        # Writes the fstab configuration file.
        archInstallLog 'Generate fstab config.' && \
        if hash genfstab 1>"$_STANDARD_OUTPUT" 2>/dev/null; then
            # NOTE: Mountpoint shouldn't have a path separator at the end.
            genfstab -L -p "${_MOUNTPOINT_PATH%?}" \
                1>>"${_MOUNTPOINT_PATH}etc/fstab" 2>"$_ERROR_OUTPUT"
        else
            cat << EOF 1>>"${_MOUNTPOINT_PATH}etc/fstab" 2>"$_ERROR_OUTPUT"
# Added during installation.
# <file system>                    <mount point> <type> <options>                                                                                            <dump> <pass>
# "compress=lzo" has lower compression ratio by better cpu performance.
PARTLABEL=$_SYSTEM_PARTITION_LABEL /             btrfs  relatime,ssd,discard,space_cache,autodefrag,inode_cache,subvol=root,compress=zlib                    0      0
PARTLABEL=$_BOOT_PARTITION_LABEL   /boot/        vfat   rw,relatime,fmask=0077,dmask=0077,codepage=437,iocharset=iso8859-1,shortname=mixed,errors=remount-ro 0      0
EOF
        fi
        return $?
    }
    function archInstallUnmountInstalledSystem() {
        # Unmount previous installed system.
        archInstallLog 'Unmount installed system.' && \
        sync 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
        cd / 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
        umount "${_MOUNTPOINT_PATH}/boot" 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT"
        umount "$_MOUNTPOINT_PATH" 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        return $?
    }
    function archInstallPrepareNextBoot() {
        # Reboots into fresh installed system if previous defined.
        if [ -b "$_OUTPUT_SYSTEM" ]; then
            archInstallGenerateFstabConfigurationFile && \
            archInstallAddBootEntries
            archInstallUnmountInstalledSystem
            local returnCode=$? && \
            if [[ $returnCode == 0 ]] && \
               [[ $(echo "$_AUTOMATIC_REBOOT" | tr '[A-Z]' '[a-z]') != 'no' ]]
            then
                archInstallLog 'Reboot into new operating system.'
                systemctl reboot 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" || \
                reboot 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
                return $?
            fi
            return $returnCode
        fi
        return $?
    }
    function archInstallConfigurePacman() {
        # Disables signature checking for incoming packages.
        archInstallLog "Enable mirrors in \"$_COUNTRY_WITH_MIRRORS\"."
        local bufferFile=$(mktemp)
        local inArea=false
        local lineNumber=0
        local line
        while read line; do
            lineNumber=$(($lineNumber + 1)) && \
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
        archInstallLog \
            "Change signature level to \"Never\" for pacman's packages." && \
        sed --regexp-extended --in-place 's/^(SigLevel *= *).+$/\1Never/g' \
            "${_MOUNTPOINT_PATH}etc/pacman.conf" 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT"
        return $?
    }
    function archInstallDetermineAutoPartitioning() {
        # Determine weather we should perform our auto partitioning mechanism.
        if [ ! "$_AUTO_PARTITIONING" ]; then
            while true; do
                echo -n 'Do you want auto partioning? [yes|NO]: ' && \
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
        return 0
    }
    function archInstallGetHostsContent() {
        # Provides the file content for the "/etc/hosts".
        cat << EOF
#<IP-Adress> <computername.workgroup> <computernames>
127.0.0.1    localhost.localdomain    localhost $1
::1          ipv6-localhost           ipv6-localhost ipv6-$1
EOF
    }
    function archInstallPrepareBlockdevices() {
        # Prepares given block devices to make it ready for fresh installation.
        archInstallLog \
            "Unmount needed devices and devices pointing to our temporary system mount point \"$_MOUNTPOINT_PATH\"."
        umount -f "${_OUTPUT_SYSTEM}"* 1>"$_STANDARD_OUTPUT" 2>/dev/null
        umount -f "$_MOUNTPOINT_PATH" 1>"$_STANDARD_OUTPUT" 2>/dev/null
        swapoff "${_OUTPUT_SYSTEM}"* 1>"$_STANDARD_OUTPUT" 2>/dev/null
        archInstallLog \
            'Make partitions. Make a boot and system partition.' && \
        archInstallMakePartitions && \
        archInstallLog 'Format partitions.' && \
        archInstallFormatPartitions
        return $?
    }
    function archInstallFormatSystemPartition() {
        # Prepares the system partition.
        local outputDevice="$_OUTPUT_SYSTEM" && \
        if [ -b "${_OUTPUT_SYSTEM}2" ]; then
            outputDevice="${_OUTPUT_SYSTEM}2"
        fi
        archInstallLog \
            "Make system partition at \"$outputDevice\"." && \
        mkfs.btrfs --force --label "$_SYSTEM_PARTITION_LABEL" "$outputDevice" \
            1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
        archInstallLog \
            "Creating a root sub volume in \"$outputDevice\"." && \
        mount PARTLABEL="$_SYSTEM_PARTITION_LABEL" "$_MOUNTPOINT_PATH" \
            1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
        btrfs subvolume create "${_MOUNTPOINT_PATH}root" \
            1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
        umount "$_MOUNTPOINT_PATH" 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        return $?
    }
    function archInstallFormatBootPartition() {
        # Prepares the boot partition.
        archInstallLog 'Make boot partition.' && \
        mkfs.vfat -F 32 "${_OUTPUT_SYSTEM}1" \
            1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
        if hash dosfslabel 1>"$_STANDARD_OUTPUT" 2>/dev/null; then
            dosfslabel "${_OUTPUT_SYSTEM}1" "$_BOOT_PARTITION_LABEL" \
                1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        else
            archInstallLog 'warning' \
                "\"dosfslabel\" doesn't seem to be installed. Creating a boot partition label failed."
        fi
        return $?
    }
    function archInstallFormatPartitions() {
        # Performs formating part.
        archInstallFormatSystemPartition && \
        archInstallFormatBootPartition
        return $?
    }
    function archInstallAddBootEntries() {
        # Creates an uefi boot entry.
        if hash efibootmgr 1>"$_STANDARD_OUTPUT" 2>/dev/null; then
            archInstallLog 'Configure efi boot manager.' && \
            cat << EOF 1>"${_MOUNTPOINT_PATH}/boot/startup.nsh" 2>"$_ERROR_OUTPUT"
\vmlinuz-linux initrd=\initramfs-linux.img root=PARTLABEL=${_SYSTEM_PARTITION_LABEL} rw rootflags=subvol=root quiet loglevel=2 acpi_osi="!Windows 2012"
EOF
            archInstallChangeRootToMountPoint efibootmgr --create --disk \
                "$_OUTPUT_SYSTEM" --part 1 -l '\vmlinuz-linux' --label \
                "$_FALLBACK_BOOT_ENTRY_LABEL" --unicode \
                'initrd=\initramfs-linux-fallback.img acpi_osi="!Windows 2012"' \
                1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" || \
            archInstallLog 'warning' \
                "Adding boot entry \"${_FALLBACK_BOOT_ENTRY_LABEL}\" failed."
            # NOTE: Boot entry to boot on next reboot should be added at last.
            archInstallChangeRootToMountPoint efibootmgr --create --disk \
                "$_OUTPUT_SYSTEM" --part 1 -l '\vmlinuz-linux' --label \
                "$_BOOT_ENTRY_LABEL" --unicode \
                "initrd=\initramfs-linux.img root=PARTLABEL=${_SYSTEM_PARTITION_LABEL} rw rootflags=subvol=root quiet loglevel=2 acpi_osi=\"!Windows 2012\"" \
                1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" || \
            archInstallLog 'warning' \
                "Adding boot entry \"${_BOOT_ENTRY_LABEL}\" failed."
        else
            archInstallLog 'warning' \
                "\"efibootmgr\" doesn't seem to be installed. Creating a boot entry failed."
        fi
        return $?
    }
    function archInstallLoadCache() {
        # Load previous downloaded packages and database.
        archInstallLog 'Load cached databases.' && \
        mkdir --parents \
            "$_MOUNTPOINT_PATH"var/lib/pacman/sync \
            1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
        cp --no-clobber --preserve "$_PACKAGE_CACHE_PATH"/*.db \
            "$_MOUNTPOINT_PATH"var/lib/pacman/sync/ \
            1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        archInstallLog 'Load cached packages.' && \
        mkdir --parents "$_MOUNTPOINT_PATH"var/cache/pacman/pkg \
            1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT" && \
        cp --no-clobber --preserve "$_PACKAGE_CACHE_PATH"/*.pkg.tar.xz \
            "$_MOUNTPOINT_PATH"var/cache/pacman/pkg/ 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT"
        return $?
    }
    function archInstallCache() {
        # Cache previous downloaded packages and database.
        archInstallLog 'Cache loaded packages.'
        cp --force --preserve \
            "$_MOUNTPOINT_PATH"var/cache/pacman/pkg/*.pkg.tar.xz \
            "$_PACKAGE_CACHE_PATH"/ 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT" && \
        archInstallLog 'Cache loaded databases.' && \
        cp --force --preserve \
            "$_MOUNTPOINT_PATH"var/lib/pacman/sync/*.db \
            "$_PACKAGE_CACHE_PATH"/ 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        return $?
    }
    function archInstallPrepareInstallation() {
        # Deletes previous installed things in given output target. And creates
        # a package cache directory.
        mkdir --parents "$_PACKAGE_CACHE_PATH" 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT" && \
        if [ -b "$_OUTPUT_SYSTEM" ]; then
            archInstallLog 'Mount system partition.' && \
            mount PARTLABEL="$_SYSTEM_PARTITION_LABEL" -o subvol=root \
                "$_MOUNTPOINT_PATH" 1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        fi
        archInstallLog \
            "Clear previous installations in \"$_MOUNTPOINT_PATH\"." && \
        rm "$_MOUNTPOINT_PATH"* --recursive --force 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT" && \
        if [ -b "$_OUTPUT_SYSTEM" ]; then
            archInstallLog \
                "Mount boot partition in \"${_MOUNTPOINT_PATH}boot/\"." && \
            mkdir --parents "${_MOUNTPOINT_PATH}boot/" && \
            mount PARTLABEL="$_BOOT_PARTITION_LABEL" \
                "${_MOUNTPOINT_PATH}boot/" 1>"$_STANDARD_OUTPUT" \
                2>"$_ERROR_OUTPUT" && \
            rm "${_MOUNTPOINT_PATH}boot/"* --recursive --force \
                1>"$_STANDARD_OUTPUT" 2>"$_ERROR_OUTPUT"
        fi
        archInstallLog 'Set filesystem rights.' && \
        chmod 755 "$_MOUNTPOINT_PATH" 1>"$_STANDARD_OUTPUT" \
            2>"$_ERROR_OUTPUT" && \
        local returnCode=$?
        # Make a uniqe array.
        _PACKAGES=$(echo "${_PACKAGES[*]}" | tr ' ' '\n' | sort -u | tr '\n' \
            ' ')
        return $returnCode
    }

    # endregion

# endregion

# region controller

    if [[ "$0" == *"${__NAME__}.bash" ]]; then
        archInstallPerformDependencyCheck "${_DEPENDENCIES[*]}" || \
            archInstallLog 'error' 'Satisfying main dependencies failed.'
        archInstallCommandLineInterface "$@" || return $?
        _PACKAGES="${_BASIC_PACKAGES[*]} ${_ADDITIONAL_PACKAGES[*]}" && \
        if [ "$_INSTALL_COMMON_ADDITIONAL_PACKAGES" == 'yes' ]; then
            _PACKAGES+=' '${_COMMON_ADDITIONAL_PACKAGES[*]}
        fi
        if [ ! -e "$_OUTPUT_SYSTEM" ]; then
            mkdir --parents "$_OUTPUT_SYSTEM" 1>"$_STANDARD_OUTPUT" \
                2>"$_ERROR_OUTPUT"
        fi
        if [ -d "$_OUTPUT_SYSTEM" ]; then
            _MOUNTPOINT_PATH="$_OUTPUT_SYSTEM" && \
            if [[ ! "$_MOUNTPOINT_PATH" =~ .*/$ ]]; then
                _MOUNTPOINT_PATH+='/'
            fi
        elif [ -b "$_OUTPUT_SYSTEM" ]; then
            _PACKAGES+=' efibootmgr' && \
            archInstallPerformDependencyCheck \
                "${_BLOCK_INTEGRATION_DEPENDENCIES[*]}" || \
            archInstallLog 'error' \
                'Satisfying block device dependencies failed.' && \
            if echo "$_OUTPUT_SYSTEM" | grep --quiet --extended-regexp '[0-9]$'
            then
                archInstallFormatSystemPartition || \
                archInstallLog 'error' 'System partition creation failed.'
            else
                archInstallDetermineAutoPartitioning && \
                archInstallPrepareBlockdevices || \
                archInstallLog 'error' 'Preparing blockdevices failed.'
            fi
        else
            archInstallLog 'error' \
                "Could not install into an existing file \"$_OUTPUT_SYSTEM\"."
        fi
        archInstallPrepareInstallation || \
        archInstallLog 'error' 'Preparing installation failed.'
        if [[ "$UID" == 0 ]] && [[ "$_PREVENT_USING_PACSTRAP" == 'no' ]] && \
            hash pacstrap 1>"$_STANDARD_OUTPUT" 2>/dev/null
        then
            archInstallWithPacstrap || \
            archInstallLog 'error' 'Installation with pacstrap failed.'
        else
            archInstallGenericLinuxSteps || \
            archInstallLog 'error' \
                'Installation via generic linux steps failed.'
        fi
        archInstallTidyUpSystem && \
        archInstallConfigure || \
        archInstallLog 'error' 'Configuring installed system failed.'
        archInstallPrepareNextBoot || \
        archInstallLog 'error' 'Preparing reboot failed.'
        archInstallPackResult || \
        archInstallLog 'error' \
            'Packing system into archiv with files owned by root failed.'
        archInstallLog \
            "Generating operating system into \"$_OUTPUT_SYSTEM\" has successfully finished."
    fi
    return 0

# endregion

}

# region footer

if [[ "$0" == *"${__NAME__}.bash" || $(echo "$@" | grep --extended-regexp \
    '(^| )(-l|--load-environment)($| )') ]]; then
    "$__NAME__" "$@"
fi

# endregion
