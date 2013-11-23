<!-- region vim modline

vim: set tabstop=4 shiftwidth=4 expandtab:
vim: foldmethod=marker foldmarker=region,endregion:

endregion

region header

Copyright Torben Sickert 16.12.2012

License
   This library written by Torben Sickert stand under a creative commons
   naming 3.0 unported license.
   see http://creativecommons.org/licenses/by/3.0/deed.de

endregion -->

Use case<!--deDE:Einsatz-->
---------------------------

This script provides a full unnatted way to install ArchLinux from any live
environment. You can create your own linux distribution based on the rolling
released ArchLinux. A rock solid decorator pattern allows to automate a fully
unattended individual installation process.

Content<!--deDE:Inhalt-->
-------------------------

<!--Place for automatic generated table of contents.-->
[TOC]

Quick-Start<!--deDE:Einstieg-->
-------------------------------

Simply load the newest version from:
<!--deDE:
    Um die neuste Version zu erhalten sollte man das Bash-Script runterladen:
-->
[installArchLinux](https://raw.github.com/archInstall/archInstall/master/installArchLinux.bash)

```bash
>>> wget \
    https://raw.github.com/thaibault/installArchLinux/master/installArchLinux.bash \
    -O installArchLinux.bash && chmod +x installArchLinux.bash
```

InstallArchLinux ist das zentrale Module um eine Reihe von Aufgaben im Zuge der
Vorbereitung, Installation, Konfiguration oder Manipulieren eines
"Linux from Scratch" durchzuführen.

Das Module kann im einfachsten Fall (z.B. von einer beliebigen Life Linux
Umgebung) gestartet werden.

```bash
>>> ./installArchLinux.bash
```

In diesem Fall werden alle benötigten Informationen zur Einrichtung
(nur Hostname) des Systems vor Beginn des Installations Prozesses interaktiv
abgefragt.
Zu Beachten ist: ohne zusätzliche Parameter gibt das Module keinen Feedback über den
aktuellen Zustand des Installations Vorgangs.
Mit:

```bash
>>> ./installArchLinux.bash --verbose
```

bekommt man einen etwas geschwätzigeren Installations Vorgang.
Mit:

```bash
>>> ./installArchLinux.bash --verbose --debug
```

werden alle Ausgaben jeglicher verwendeten Subprogramme mit ausgegeben.

Alle wichtigen Parameter wie Installations Ort haben Standardwerte.
So Wird im obigen Fall einfach auf das erste gefundene Block Device installiert
(/dev/sda).
Will man lieber eine unbeaufsichtigte Installation:

```bash
>>> ./installArchLinux.bash --host-name testSystem --auto-partitioning
```

Installation auf ein Block Device
---------------------------------

Im typischen Fall will man von einer Life-CD booten um das System auf
einer Festplatte zu installieren. Hierbei müssen folgende Aufgaben erfüllt
werden.

* Einrichtung einer Internet Verbindung (siehe auch Abschnitt "Offline Installation")
* Partitionierung der Ziel Festplatte
* Formatierung der Ziel Partitionen
* Konfiguration des Betriebssystems
* Installation und Einrichtung eines Boot-Loaders

Alle Aufgaben bis auf die Einrichtung der Internet Verbindung (wird in der Regel
von der Host Umgebung geregelt) könne mit installArchLinux automatisiert
durchgeführt werden. Will man z.B auf das Block Device "/dev/sdb" installieren
und sich nicht selber um die Partitionierung kümmern und den kompletten
verfügbaren Platz für das Haupt System verwenden (es soll also keine Swap- oder
Daten Partition erstellt werden).
sieht das z.B. so aus:

```bash
>>> ./installArchLinux.bash --output-system /dev/sdb --auto-partitioning \
    --minimal-boot-space-in-procent 100
```

Möchte man eine System-, Daten- und Swap Partition haben, installiert folgender
Befehl:

```bash
>>> ./installArchLinux.bash --output-system /dev/sdb --auto-partitioning
```

diese in einem "sinnvollen" Verhältnis. Es wird versucht den Swap genauso groß
wie den installierten RAM auszulegen um für spätere "Suspend to Disk"
Szenarien vorbereitet zu sein.
Standardmäßig werden jedoch nicht mehr als 20% für die Swap Partition eingesetzt.
Die Systempartition nimmt in aller Regel mindestens 40% des verfügbaren Platzes
ein. Der Rest wird dann für die Daten Partition eingesetzt. Will man dieses
Verhalten individualisieren:

```bash
>>> ./installArchLinux.bash --needed-boot-space-in-byte 500000000 \
    --minimal-boot-space-in-procent 50 --maximal-swap-space-in-procent 10 \
    --output-system /dev/sdb --auto-partitioning
```

So werden in jedem Fall mindestens ca. 466 MB für das System reserviert und
mindestens 50% des Festplattenplatz für das System eingesetzt. Der Swap-space
ist wenn möglich so groß wie der RAM jedoch nicht mehr als 10% des Block Devices
"/dev/sdb". Der Rest wird für die Daten Partition (also maximal 40%) eingesetzt.

Möchte man die Partitionierung nicht voll automatisch (oder wie eben
beschrieben halbautomatische) vornehmen. Erreicht man durch weglassen des
Parameters "--auto-partitioning" eine ncurses basierte Oberfläche, die das
manuelle Konfiguration des Systems erlaubt.

```bash
>>> ./installArchLinux.bash --output-system /dev/sdb
```

InstallArchLinux nimmt dann die erste Partition als System Partition.
Ist noch eine weitere Vorhanden, wird diese als Swap Space verwendet. Wenn auch
eine dritte erkannt wird, detektiert installArchLinux diese als Daten Partition.
Alle weiteren Partitionen bleiben unberührt.

An dieser Stelle sei noch erwähnt, dass installArchLinux alle erstellten
Partition automatisch mit Labels versieht. Um dieses Verhalten zu
individualisieren einfach folgende Optionen nutzen:

```bash
>>> ./installArchLinux.bash --boot-partition-label boot \
    --swap-partition-label auslagerung --data-partition-label stuff
```

Installation auf eine Partition
-------------------------------

Um z.B. aus einem Produktivsystem heraus eine alternative Linux Distribution
auf eine weitere Partition zu installieren kann einfach folgender Befehl
verwendet werden:

```bash
>>> ./installArchLinux.bash --output-system /dev/sdb2
```

Hier wird auf die zweite Partition des zweiten Block Devices installiert.
Sofern "grub2" auf dem Hostsystem installiert ist und installArchLinux mit
ausreichend Rechten ausgeführt wurde, integriert installArchLinux die
alternative Installation in grub boot menu. Dieses Feature funktioniert jedoch
nur wenn "os-prober" installiert ist. Sonst muss man hier von Hand nachbessern.
Um die alternative Linux Version auch booten zu können.

Installation in einen Ordner
----------------------------

Um installArchLinux für komplexere Szenarien zu verwenden oder nachträgliche
Manipulationen vorzunehmen ist es sinnvoll zunächst in einen Ordner zu
installieren. Siehe hierzu "installArchLinux with Decorator Pattern",
"makeXBMCLinux", "makeRamOnlyLinux" oder "makeSquashLinux" bzw. das Projekt
"installArchLinuxWrapperTemplate".

Dieser Befehl installiert ein vollständiges System in den eigenen Home-Ordner
"test" (siehe auch Installation ohne root Rechte).

```bash
>>> ./installArchLinux.bash --output-system ~/test
```

Automatische Konfiguration
--------------------------

InstallArchLinux konfiguriert das neu eingerichtete System vollautomatisch.
Folgende Taske wurden automatisiert:

* Tastaturlayout einstellen
* Einrichten der richtigen Zeit Zone
* Setzen des Hostnames
* Setzen des default root Passworts nach "root"
* Erstellen eines Benutzers bzw. Benutzerordner.
  Das Passwort wird initial wie der Benutzer gesetzt.
* dhcp Dienst einrichten (siehe automatisches Einrichten von Diensten)
* Installation der Basis Programme (siehe automatische Installation von Programmen)
* Einrichten der Signaturen für den Paketmanager "Pacman", um vertrauenswürdige
  Pakete erhalten zu können.
* Einrichten aller in der nähe liegenden Server um schnelle Packet Updates und
  Paket Installationen zu gewährleisten.
* Einrichten der richtigen Paketquellen abhängig von der aktuellen CPU
  Architektur.

Will man hierauf selber Einfluss nehmen, gibt es folgende Möglichkeiten:

```bash
>>> ./installArchLinux.bash --host-name test --user-names test \
    --cpu-architecture x86_64 --local-time /Europe/London \
    --key-map-configuration \
    KEYMAP="de-latin1\nFONT=Lat2-Terminus16\nFONT_MAP=" \
    --keyboard-layout de-latin1 --country-with-mirrors Germany \
    --prevent-using-pacstrap --additional-packages python vim \
    --needed-services sshd dhcpcd apache
```

Um die einzelnen Konfigurationsparameter zu verstehen empfiehlt sich ein Blick
auf:

```bash
>>> ./installArchLinux.bash --help
```

zu werfen.

InstallArchLinux im Decorator Pattern
-------------------------------------

Um eigene Betriebssystem Module zu entwerfen bietet installArchLinux eine
Vielzahl von Schnittstellen um seine internen Mechanismen separate nach Außen
zugänglich zu machen (siehe hierzu die Decorator Implementierung
"installXBMCLinux", "makeRamOnlyLinux", "makeSquashLinux" oder
"installArchLinxDecoratorTemplate") und unsere Guidelines zum Erstellen eines
Wrappers.

Im einfachsten Fall würde der Code der installArchLinux sinnvoll erweitert so
aussehen:

    #!/usr/bin/env bash

    source installArchLinux.bash

    # Do your own stuff cli logic here..
    # All your functions and variables are separated from the installArchLinux
    # scope.

    # Call the main Function of installArchLinux and overwrite or add
    # additional command line options.
    installArchLinux "$@" --output-system initramfsTargetLocation

    # Prepare result ...

Beachte, dass trotz des sourcen von installArchLinux auf diese Weise keine
Konflikte zwischen dem Wrapper-Scope und dem installArchLinux-Scope entstehen
können. Die Einzige globale Variable ist "installArchLinux" selbst.

Will man nun von den internen Features von installArchLinux partizipieren geht
das so:

```bash
>>> source installArchLinux.bash --load-environment
```

Jetzt haben wir den gesamten Scope auch im Decorator zur Verfügung.
Alle Methoden sind mit dem Prefix "installArchLinux" ausgestattet, um
Namens Konflikte und versehentlich überschreiben von Methoden zu vermeiden.
Will man sich also einen Überblick über alle verfügbaren Methoden machen,
einfach in der shell folgendes eintippen:

```bash
>>> source installArchLinux.bash --load-environment

>>> installArchLinux<TAB><TAB>
...
```

Siehe hierzu auch "installArchLinux API".

InstallArchLinux API
--------------------

Folgende Umgebungsvariablen können mit:

```bash
>>> source installArchLinux.bash --load-environment
```

geladen werden:

```bash
# Name des Moduls installArchLinux.
__NAME__
# "local" oder "export" je nachdem ob mit "--load-environment" geladen
# wurde.
_SCOPE
# Abbilder der CLI-Parameter.
_VERBOSE, _HOSTNAME, _USER_NAMES, _VERBOSE, _AUTO_PARTITIONING,
_INSTALL_COMMON_ADDITIONAL_PACKAGES, _LOAD_ENVIRONMENT,
_CPU_ARCHITECTURE, _AUTOMATIC_REBOOT, _KEYBOARD_LAYOUT, _OUTPUT_SYSTEM,
_COUNTRY_WITH_MIRRORS, _BOOT_PARTITION_LABEL, _SWAP_PARTITION_LABEL,
_DATA_PARTITION_LABEL, _ADDITIONAL_PACKAGES, _NEEDED_SERVICES,
_NEEDED_BOOT_SPACE_IN_BYTE, _MAXIMAL_SWAP_SPACE_IN_PROCENT,
_MINIMAL_BOOT_SPACE_IN_PROCENT, _KEY_MAP_CONFIGURATION_FILE_CONTENT,
_LOCAL_TIME, _MOUNTPOINT_PATH, _IGNORE_UNKNOWN_ARGUMENTS,
_PREVENT_USING_PACSTRAP, _PREVENT_USING_NATIVE_ARCH_CHANGE_ROOT

# Sinnvolle Umgebungsvariablen deren Wert z.T. zur Laufzeit ermittelt wurde.
_NEEDED_PACKAGES, _PACKAGE_SOURCE_URLS, _BASIC_PACKAGES,
_COMMON_ADDITIONAL_PACKAGES, _PACKAGES, _UNNEEDED_FILE_LOCATIONS,
_STANDARD_OUTPUT, _ERROR_OUTPUT, _NEEDED_MOUNTPOINTS
```

Diese Methoden können von außen geladen und verwendet werden:

```bash
# Startet den installArchLinux Controller. Initiiert das Hauptprogramm.
installArchLinux()

# Liefert eine Beschreibung wie das Program verwendet werden kann.
# Wenn die Variable "__NAME__" auf den Namen des Wrappers zeigt kann diese
# Methode im Decorator Pattern Attraktiv sein.
installArchLinuxPrintUsageMessage()

# Liefert Beispiele wie das Program ausgeführt werden soll.
# Werden im Decorator Pattern die Variablen durch gereicht und die
# "__NAME__" Variable gesetzt, macht das Sinn.
installArchLinuxPrintUsageExamples()

# Liefert eine Beschreibung allen verfügbaren Optionen.
installArchLinuxPrintCommandLineOptionDescriptions()

# Vereinigt die Ausgabe der letzten drei Methoden.
installArchLinuxPrintHelpMessage()

# Parset Kommandozeilen-Eingaben und liefert aussagekräftige Fehler, wie
# "No such, file or directory!" :-). Ne Spass.
installArchLinuxCommandLineInterface()

# Liefert eine einfache Methode zum Loggen. Wenn zwei Argumente übergeben
# wurde, wird der erste als Loglevel interpretiert. Loglevel wie "critical"
# oder "error" werden auch ohne cli flag "--verbose" angezeigt.
# "error" führt zusätzlich zum Abbruch des Programms mit Fehlercode 1.
#
# >>> installArchLinuxLog <LOG_NACHRICHT>
# >>> installArchLinuxLog <LOG_LEVEL> <LOG_NACHRICHT>
# >>> installArchLinuxLog <LOG_LEVEL> <LOG_NACHRICHT> <STRING_VOR_DER_NACHRICHT>
#
installArchLinuxLog()

# Installiert das Betriebssystem dorthin wo "_MOUNPOINT_PATH" hin zeigt.
# "_MOUNPOINT_PATH=test installArchLinuxWithPacstrap" ist also eine
# sinnvolle Verwendung.
installArchLinuxWithPacstrap()

# Diese Funktion erstellt in "_MOUNTPOINT_PATH" ein basis Linux (siehe).
# Sie benötigt außer posix konforme System Schnittstellen keinerlei
# zusätzliche Anwendungen wie "pacman".
installArchLinuxGenericLinuxSteps()

# Diese Methode dient als Wrapper for "installArchLinuxChangeRoot".
# Sie ist äquivalent zu dem Aufruf "InstallArchLinux $_MOUNPOINT_PATH".
#
# >>> installArchLinuxChangeRootToMountPoint <ARGUMENTE>*
#
installArchLinuxChangeRootToMountPoint()

# Diese Funktion unterstützt das gleiche Interface wie "chroot" nur werden
# abhängig von verfügbaren tools wie die "arch-install-scripts" möglichst
# viele API-Dateisystem zum darunter liegenden System bereitgestellt.
# Sollte kein "arch-chroot" wird sichergestellt, dass auf jeden Fall (siehe
# "_NEEDED_MOUNTPOINTS") diese Orte in der neuen Umgebung bereitgestellt
# werden:
# "/proc", "/sys", "/dev", "/dev/pts", "/dev/shm", "/run", "/tmp",
# "/etc/resolv.conf"
#
# >>> installArchLinuxChangeRoot <CHROOT_ARGUMENTE>*
#
installArchLinuxChangeRoot()

# (wird von "installArchLinuxChangeRoot()" aufgerufen) Diese Funktion wird
# verwendet, wenn "arch-chroot" nicht zur Verfügung steht oder die Flag
# "--prevent-using-native-arch-chroot" gesetzt ist.
#
# >>> installArchLinuxChangeRoot <CHROOT_ARGUMENTE>*
#
installArchLinuxChangeRootViaMount()

# Hier wird das linux native "chroot" oder "fakechroot" Program gewrappt.
# Sind keine root Rechte vorhanden "fakeroot" und "fakechroot" installiert.
# wird statt "chroot $@", "fakeroot fakechroot chroot $@" aufgerufen.
#
# >>> installArchLinuxChangeRoot <CHROOT_ARGUMENTE>*
#
installArchLinuxPerformChangeRoot()

# Erledigt den meisten Linux typischen Konfigurationsaufwand wie
# Erstellen eines Hostnamen oder des Tastaturlayouts.
installArchLinuxConfigure()

# Alle benötigten Dienste (siehe "--needed-services" werden aktiviert.
installArchLinuxEnableServices()

# Nicht benötigte Orte werden aufgeräumt (siehe "_UNNEEDED_LOCATIONS").
installArchLinuxTidyUpSystem()

# Erstellt eine Basisliste an verfügbaren Quellen um die ersten Pakete zu
# beziehen (siehe "_PACKAGE_SOURCE_URLS").
installArchLinuxAppendTemporaryInstallMirrors()

# Verpackt ein erfolgreich erstelltes Linux in ein tar-Archiv.
installArchLinuxPackResult()

# Ermittelt eine aktuelle Liste aller Pakete aus den core Repositories von
# pacman. Sie enthält die konkrete Url zu jeder Paket bzw. deren neusten
# Version.
installArchLinuxCreatePackageUrlList()

# Ermittelt die aktuellen Abhängigkeiten von pacman.
installArchLinuxDeterminePacmansNeededPackages()

# Liest die Datenbank Dateien von Pacman und ermittelt welche Abhängigkeiten
# notwendig sind um das übergebene Programm installieren zu können.
# In installArchLinux wird diese Funktion nur verwendet um "pacman" selbst
# lauffähig zu bekommen. Ab da übernimmt dieser das Auflösen von Abhängigkeiten.
# Im Decorator Pattern kann diese Funktion jedoch sehr wertvoll werden, um
# beliebige Abhängigkeiten zu ermitteln.
#
# >>> installArchLinuxDeterminePackageDependencies <PAKET> <DATENBANK_DATEI>
#
installArchLinuxDeterminePackageDependencies()

# Ermittelt den Namen eines Paketordner in den Datenbankarchiven von
# Pacman zu einem Program
#
# >>> installArchLinuxDeterminePackageDirectoryName <PROGRAMM_NAME>
#
installArchLinuxDeterminePackageDirectoryName()

# Installiert die neuste pacman Version.
#
# >>> installArchLinuxDownloadAndExtractPacman <LISTE_ALLER_URLS_ZU_ALLEN_PAKETEN>
#
installArchLinuxDownloadAndExtractPacman()

# Partitioniert ein Block Device "_OUTPUT_SYSTEM" nach einer sinnvollen
# Heuristik. Siehe hierzu "Installation auf ein Block Device".
installArchLinuxMakePartitions()

# Erstellt autmatisch eine bootfähiger fstab Konfigurationsdatei in 
# "_MOUNTPOINT_PATH/etc/fstab".
installArchLinuxGenerateFstabConfigurationFile()

# Konfiguriert Grub2, so dass alle vorhanden Betriebssysteme im Bootmenu
# angezeigt werden.
installArchLinuxHandleBootLoader()

# Unmounted "_MOUNTPOINT_PATH".
installArchLinuxUnmountInstalledSystem()

# Macht einen Neustart wenn die Installation erfolgreich war und die Flag
# "--no-reboot" nicht gesetzt ist.
installArchLinuxPrepareNextBoot()

# Schreibt pacmans config so um, dass Paketsignaturüberprüfung
# übersprungen werden. Dies ist notwendig wenn pacman ohne ein bereits
# installiertes Pacman initial installiert werden soll.
installArchLinuxConfigurePacman()

# Ermittelt ob der Benutzer automatische Partitionierung wünscht.
# So wird unbeabsichtigt Löschen von Daten verhindert.
installArchLinuxDetermineAutoPartitioning()

# Generert sinnvollen Inhalt für "/etc/hosts".
#
# >>> installArchLinuxGetHostsContent <HOST_NAME>
#
installArchLinuxGetHostsContent()

# Bereitet das Installations block device vor. Erstellt Partitionen und
# vergibt Labels.
installArchLinuxPrepareBlockdevices()

# Bereitet die boot Partition vor. Erstellt ein Dateisystem.
installArchLinuxPrepareBootPartition()

# Bereitet die swap Partition vor. Erstellt ein Dateisystem.
installArchLinuxPrepareSwapPartition()

# Bereitet die Daten-Partition vor. Erstellt ein Dateisystem.
installArchLinuxPrepareDataPartition()

# Formatiert alle notwendigen Partitionen.
installArchLinuxFormatPartitions()

# Installiert "grub2" als Bootloader.
installArchLinuxIntegrateBootLoader()

# Bereitet den Paket Cache vor der von pacman während der Installation
# verwendet werden kann.
installArchLinuxLoadCache()

# Speichert alle bisher geladenen Pakete aus dem aktuell verwendeten Pacman
# im Paket Cache (siehe "_PACKAGE_CACHE_PATH").
installArchLinuxCache()

# Erstellt sofern nicht vorhanden den Paket Cache und bereinigt das
# Installations Ziel.
installArchLinuxPrepareInstallation()
```

InstallArchLinux Options
------------------------

InstallArchLinux stellt ein Alphabet voller Optionen zur Verfügung.
Während bisher zum einfachen Verständnis immer sog. Long-Options verwendet
wurden, gibt es für jede Option auch einen Shortcut.

```bash
>>> ./installArchLinux.bash --user-names mustermann --host-name lfs
```

ist äquivalent zu:

```bash
>>> ./installArchLinux.bash -u mustermann -n lfs
```

Alle Optionen bis auf "--host-name" und "--auto-partitioning"
haben Standardwerte. Alle Standardwert können mit Hilfe von:

```bash
>>> ./installArchLinux.bash -h
```

oder

```bash
>>> ./installArchLinux.bash --help
```

oder

```bash
>>> ./installArchLinux.bash --keyboard-layout de-latin1 -h
```

angesehen werden. Letzteres macht Sinn, da sich Standardwerte aufgrund schon
ermittelten Informationen verändern können.
So wird der Standardwert von
"--key-map-configuration="KEYMAP=de-latin1\nFONT=Lat2-Terminus16\nFONT_MAP="
nach Eingabe von 

```bash
>>> ./installArchLinux.bash --keyboard-layout us
```

zu: "--key-map-configuration="KEYMAP=us\nFONT=Lat2-Terminus16\nFONT_MAP=".

Der Standardwert von "--cpu-architecture" entspricht beispielsweise immer der
Architektur des aktuellen Systems, um Konfigurationsaufwand zu minimieren.

Man kann Optionen die mehrere Werte annehmen auch mehrfach referenzieren.
So hat:

```bash
>>> ./installArchLinux.bash --additional-packages ssh --additional-packages vim -f python
```

den gleichen Effekt wie:

```bash
>>> ./installArchLinux.bash --additional-packages ssh vim python
```

Dies ist im Decorator-Pattern nützlich. Bei einem Doppelt referenzierten Wert
überschreiben spätere Werte zuvor Definierte. Folgendes:

```bash
>>> ./installArchLinux.bash --host-name A --host-name B
```

entspricht:

```bash
>>> ./installArchLinux.bash --host-name B
```

Auf diese Weise kann man getrost folgendes tun:

    #!/usr/bin/env bash

    source installArchLinux.bash

    myTarget='/path/to/expected/result'

    installArchLinux "$@" --output-system $myTarget

    # Working with result in "$myTarget"

Selbst wenn der Wert von "--output-system" über die CLI gesetzt wurde ist sie
im Wrapper wieder überschrieben werden.

Offline Installieren
--------------------

installArchLinux erstellt bei jeder Installation automatisch einen Paket-Cache
um weitere Installationen zu beschleunigen. Ist dieser einmal erstellt oder
wird dieser zusammen mit dem installArchLinux (z.b. auf einem usb-stick)
ausgeliefert kann auch Offline installiert werden.

Selbst wenn mit einem bereits vorhandenem pacstrap installiert wird, wird
dieser temporär kopiert, gepatched und anschließend offlinefähig ausgeführt!

Bei Offline Installation müssen natürlich alle zusätzlich ausgewählten
Pakete im Package Cache vorhanden sein. Ist dies nicht der Fall wird
installArchLinux versuchen diese nach zu laden und im Offline-Fall einen Fehler
zurückgeben.

Installieren ohne root Rechte
-----------------------------

Prinzipiell ist es sogar möglich auch ohne root Rechte ein System aufzusetzen.
Hierbei werden jedoch folgende Einschnitte gemacht:

* Die Programm "tar", "fakeroot" und "fakechroot" müssen installiert sein.
* Ein bereits installiertes Pacstrap kann nicht eingesetzt werden
* Dem zusätzlich erstellten Benutzer kann während der Installation kein
  Home-Ordner erstellt werden, da die Rechte nicht richtig gesetzt werden
  könnten.
* Es kann nur in "Ordner" (bzw. siehe nächsten Punkt) installiert werden.
* Das System wird in ein tar-Archiv ohne Speicherung entsprechende Datei Rechte
  Attribute gepackt.
* Das Tar Archiv muss als "root" entpackt werden bevor das Ergebnis verwendet
  oder fehlerfrei gebootet werden kann.

Nützliches, Tipps, Debugging
----------------------------

Während der Entwicklung haben sich eine Reihe von Optionen bewährt um Fehler
bei der Entwicklung von Wrappern zu finden.

Die Option "--prevent-using-pacstrap" oder "-p" verhindert ein bereits
installierten Pacman für die Installation zu verwenden.
Dies ist notwendig wenn man sein Pacman so konfiguriert hat, das z.B. Pakete
wie der Kernel oder Pacman von manipulierten User Repositories abhängen. Mit
"--prevent-using-pacstrap" wird eine neue Version von Pacman in einer
\u201cChangeRoot\u201d Umgebung ausgeführt.

"--prevent-using-native-arch-chroot" oder "-y" ist sinnvoll wenn man Indexing
Dienste wie Ubuntu's "Zeitgeist" oder "Dropbox" verwendet, die das Unmounten
von Mountpoints während der Installation verhindern, da sie auf diesen noch
lesen/schreiben.

Installiert man von einer Life-CD auf ein Block Device bootet das System nach
erfolgreicher Installation automatisch in das neu generierte System.
Will man noch etwas nachbessern oder Überprüfen, bietet sich die
selbsterklärende Option "--no-reboot" bzw. "-r" an.

Möchte man die Pakete "base-devel", "sudo" und "python" haben, geht das mit
dem Shortcut: "--install-common-additional-packages" oder "-z".

Will man eine beliebige Liste von Paketen integrieren:

```bash
>>> ./installArchLinux.bash --additional-packages ssh python2 vim
```

Sollen Dienste schon beim ersten Start automatisch gestartet werden:

```bash
>>> ./installArchLinux.bash --needed-services sshd dhcpcd
```

Um die Installation zu beschleunigen kann auf ein zentral verwalteten
Paket Cache verwiesen werden:

```bash
>>> ./installArchLinux.bash --package-cache-path /var/cache/pacman/pkg/
```

Will man im Wrapper eine installArchLinux Option verstecken, weil man diese z.B.
selber setzten will, eignet sich folgender Pattern:

    #!/usr/bin/env bash

    cat << EOF
    Usage: $0 <initramfsFilePath> [options]

    $__NAME__ installs an arch linux into an initramfs file.

    Option descriptions:

    $(installArchLinuxPrintCommandLineOptionDescriptions "$@" | \
        sed '/^ *-[a-z] --output-system .*$/,/^$/d')
    EOF

    myTarget="$(mktemp)"

    installArchLinux "$@" --output-system "$myTarget"

    # ...

Abhängigkeiten
--------------

* bash (or any bash like shell)
* test - Check file types and compare values.
* sed - Stream editor for filtering and transforming text.
* wget - The non-interactive network downloader.
* xz - Compress or decompress .xz and lzma files.
* tar - The GNU version of the tar archiving utility.
* mount - Filesystem mounter.
* umount - Filesystem unmounter.
* chroot - Run command or interactive shell with special root directory.
* echo - Display a line of text.
* ln - Make links between files.
* touch - Change file timestamps or creates them.
* grep - Searches the named input files (or standard input if no files are
         named, or if a single hyphen-minus (-) is given as file name) for
         lines containing  a  match to the given PATTERN.  By default, grep
         prints the matching lines.
* shift - Shifts the command line arguments.
* sync - Flushs file system buffers.
* mktemp - Create a temporary file or directory.
* cat - Concatenate files and print on the standard output.
* blkid - Locate or print block device attributes.
* uniq - Report or omit repeated lines.
* uname - Prints system informations.

Abhängigkeiten für Block Device Integration
------------------------------------------

* grub-bios - A full featured boot manager.
* blockdev - Call block device ioctls from the command line.

Optionale Abhängigkeiten
------------------------

* arch-install-scripts - Little framework to generate a linux from scratch.
* fakechroot - Wraps some c-lib functions to enable programs like
               "chroot" running without root privilegs.
* os-prober - Detects presence of other operating systems.
* mountpoint - See if a directory is a mountpoint.
