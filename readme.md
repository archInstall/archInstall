<!-- #!/usr/bin/env markdown
-*- coding: utf-8 -*-

region header

Copyright Torben Sickert 16.12.2012

License
-------

This library written by Torben Sickert stand under a creative commons naming
3.0 unported license. see http://creativecommons.org/licenses/by/3.0/deed.de

endregion -->

<!--|deDE:Einsatz-->
Use case
--------

This script provides a full unnatted way to install ArchLinux from any live
environment. You can create your own linux distribution based on the rolling
released ArchLinux. A rock solid decorator pattern allows to automate a fully
unattended individual installation process.

<!--|deDE:Inhalt-->
Content
-------

<!--Place for automatic generated table of contents.-->
[TOC]

<!--|deDE:Einstieg-->
Quick-Start
-----------

Simply load the newest version from:
<!--deDE:
    Um die neuste Version zu erhalten sollte man das Bash-Script runterladen:
-->
[archInstall](https://raw.github.com/archInstall/archInstall/master/archInstall.bash)

```bash
>>> wget \
    https://raw.github.com/archInstall/archInstall/master/archInstall.bash \
    -O archInstall.bash && chmod +x archInstall.bash
```

archInstall ist das zentrale Module um eine Reihe von Aufgaben im Zuge der
Vorbereitung, Installation, Konfiguration oder Manipulieren eines
"Linux from Scratch" durchzuführen.

Das Module kann im einfachsten Fall (z.B. von einer beliebigen Life Linux
Umgebung) gestartet werden.

```bash
>>> ./archInstall.bash
```

In diesem Fall werden alle benötigten Informationen zur Einrichtung
(nur Hostname) des Systems vor Beginn des Installations Prozesses interaktiv
abgefragt. Zu Beachten ist: ohne zusätzliche Parameter gibt das Module keinen
Feedback über den aktuellen Zustand des Installations Vorgangs. Mit:

```bash
>>> ./archInstall.bash --verbose
```

bekommt man einen etwas geschwätzigeren Installationsvorgang.
Mit:

```bash
>>> ./archInstall.bash --verbose --debug
```

werden alle Ausgaben jeglicher verwendeten Subprogramme mit ausgegeben.

Alle Parameter wie Installations haben Standardwerte. So wird im obigen Fall
einfach in das aktuelle Verzeichnis ein Ordner mit dem Programmnamen erstellt
und darin das Betriebssystem installiert (./archInstall/). ill man lieber eine
unbeaufsichtigte Installation:

```bash
>>> ./archInstall.bash --host-name testSystem --auto-partitioning
```

<!--|deDE:Installation auf Blockgeräte-->
Install to blockdevice
----------------------

Im typischen Fall will man von einer Life-CD booten um das System auf einer
Festplatte oder Partition zu installieren. Hierbei müssen folgende Aufgaben
erfüllt werden.

* Einrichtung einer Internet Verbindung (siehe auch Abschnitt "Offline Installation")
* Partitionierung der Ziel Festplatte
* Formatierung der Ziel Partitionen
* Aufbauen der Dateisystemstruktur
* Konfiguration des Betriebssystems
* Installation und Einrichtung eines Boot-Loaders

Alle Aufgaben bis auf die Einrichtung der Internet Verbindung (wird in der
Regel von der Host Umgebung geregelt) könne mit archInstall automatisiert
durchgeführt werden. Will man z.B auf das Block Device "/dev/sdb" installieren
und sich nicht selber um die Partitionierung kümmern und den kompletten
verfügbaren Platz für das Haupt System verwenden (es soll also keine Swap- oder
Daten Partition erstellt werden).
sieht das z.B. so aus:

```bash
>>> ./archInstall.bash --output-system /dev/sdb --auto-partitioning
```

Auf diese Weise wird eine uefi Boot-Partition mit 512 MegaByte eingerichtet.
Der restliche Platz wird für die Systempartition eingesetzt. Sind noch weitere
Partitionen gewünscht kann man diese während der Installation durch weglassen
des entsprechenden Parameters selber konfigurieren. Die erste Partition wird
dann als Boot-Partition und die Zweite als Systempartition betrachtet. Weitere
Partitionen werden ignoriert. Manuelle Partitionierung:

```bash
>>> ./archInstall.bash --output-system /dev/sdb
```

An dieser Stelle sei noch erwähnt, dass archInstall alle erstellten Partition
automatisch mit Labels in der Partitionstabelle und auf der Partition selbst
versieht. Um dieses Verhalten zu individualisieren einfach folgende Optionen
nutzen:

```bash
>>> ./archInstall.bash --boot-partition-label uefiBoot \
    --system-partition-label system
```

<!--|deDE:Installation auf eine Partition-->
Install to partition
--------------------

Um z.B. aus einem Produktivsystem heraus eine alternative Linux Distribution
auf eine weitere Partition zu installieren kann einfach folgender Befehl
verwendet werden:

```bash
>>> ./archInstall.bash --output-system /dev/sdb2
```

Hier wird auf die zweite Partition des zweiten Block Devices installiert.
archInstall versucht bei der Installation auf ein Blockdevice stets einen
entsprechenden Uefi-Boot-Eintrag für den Kernel mit einem Standard Initramfs
und einem Ausweich-Initiramfs zu konfigurieren. Die folgenden Parameter
definieren dessen Label:

```bash
>>> ./archInstall.bash --output-system /dev/sdb2 --boot-entry-label archLinux \
    --fallback-boot-entry-label archLinuxFallback
```

<!--|deDE:Installation in Ordner-->
Install to folder
-----------------

Um archInstall für komplexere Szenarien zu verwenden oder nachträgliche
Manipulationen vorzunehmen ist es sinnvoll zunächst in einen Ordner zu
installieren. Siehe hierzu "archInstall with Decorator Pattern",
"makeXBMCLinux", "makeRamOnlyLinux" oder "makeSquashLinux" bzw. das Projekt
"archInstallWrapperTemplate".

Dieser Befehl installiert ein vollständiges System in den eigenen Home-Ordner
"test" (siehe auch Installation ohne root Rechte).

```bash
>>> ./archInstall.bash --output-system ~/test
```

<!--|deDE:Automatische Konfiguration-->
Automatic configuration
-----------------------

archInstall konfiguriert das neu eingerichtete System vollautomatisch.
Folgende Tasks wurden automatisiert:

* Tastaturlayout einstellen
* Einrichten der richtigen Zeit Zone
* Setzen des Hostnames
* Setzen des default root Passworts nach "root"
* Erstellen eines Benutzers bzw. Benutzerordner. Das Passwort wird initial wie
  der Name des Benutzers gesetzt.
* dhcp Dienst für alle Netzwerk-Interfaces einrichten (siehe automatisches
  Einrichten von Diensten)
* Installation der Basis Programme (siehe automatische Installation von
  Programmen)
* Einrichten der Signaturen für den Paketmanager "Pacman", um vertrauenswürdige
  Pakete erhalten zu können.
* Einrichten aller in der nähe liegenden Server um schnelle Packet Updates und
  Paketinstallationen zu gewährleisten.
* Einrichten der richtigen Paketquellen abhängig von der aktuellen CPU
  Architektur.

Will man hierauf selber Einfluss nehmen, gibt es folgende Möglichkeiten:

```bash
>>> ./archInstall.bash --host-name test --user-names test \
    --cpu-architecture x86_64 --local-time /Europe/London \
    --keyboard-layout de-latin1 --country-with-mirrors Germany \
    --prevent-using-pacstrap --additional-packages python vim \
    --needed-services sshd dhcpcd apache
```

Um die einzelnen Konfigurationsparameter zu verstehen empfiehlt sich ein Blick
auf:

```bash
>>> ./archInstall.bash --help
```

zu werfen.

<!--|deDE:Dekorator Muster-->
Decorator Pattern
-----------------

Um eigene Betriebssystem Module zu entwerfen bietet archInstall eine
Vielzahl von Schnittstellen um seine internen Mechanismen separate nach Außen
zugänglich zu machen (siehe hierzu die Decorator Implementierung
"installXBMCLinux", "makeRamOnlyLinux", "makeSquashLinux" oder
"installArchLinxDecoratorTemplate") und unsere Guidelines zum Erstellen eines
Wrappers.

Im einfachsten Fall würde der Code der archInstall sinnvoll erweitert so
aussehen:

    #!/usr/bin/env bash
    # -*- coding: utf-8 -*-

    # Program description...

    source "$(dirname "$(readlink --canonicalize "$0")")"archInstall.bash \
        --load-environment

    # Do your own stuff cli logic here..
    # All your functions and variables are separated from the archInstall
    # scope.

    # Call the main Function of archInstall and overwrite or add
    # additional command line options.
    archInstall "$@" --output-system initramfsTargetLocation

    # Prepare result ...

Beachte, dass trotz des laden von archInstall auf diese Weise keine Konflikte
zwischen dem Wrapper-Scope und dem archInstall-Scope entstehen können. Die
einzige globale Variable ist "archInstall" selbst.

Will man nun von den internen Features von archInstall partizipieren geht
das so:

```bash
>>> source archInstall.bash --load-environment
```

Jetzt haben wir den gesamten Scope auch im Decorator zur Verfügung. Alle
Methoden sind mit dem Prefix "archInstall" ausgestattet, um Namens Konflikte
und versehentlich überschreiben von Methoden zu vermeiden. Will man sich also
einen Überblick über alle verfügbaren Methoden machen, einfach in der shell
folgendes eintippen:

```bash
>>> source archInstall.bash --load-environment

>>> archInstall<TAB><TAB>
...
```

Siehe hierzu auch "archInstall API".

<!--|deDE:Applikations-Interface-->
Application Interface
---------------------

Viele nützlich Umgebungsvariablen und Funktionen können mit

```bash
>>> source archInstall.bash --load-environment
```

geladen werden. Um eine Übersicht zu erhalten sollte man sie die
API-Dokumentation anschauen.

<!--|deDE:Optionen-->
Options
-------

archInstall stellt ein Alphabet voller Optionen zur Verfügung. Während bisher
zum einfachen Verständnis immer sog. Long-Options verwendet wurden, gibt es für
jede Option auch einen Shortcut.

```bash
>>> ./archInstall.bash --user-names mustermann --host-name lfs
```

ist äquivalent zu:

```bash
>>> ./archInstall.bash -u mustermann -n lfs
```

Alle Optionen bis auf "--host-name" und "--auto-partitioning" haben
Standardwerte. Diese beiden werden sofern nicht von vorne herein angegeben
interaktiv abgefragt. Alle Standardwert können mit Hilfe von:

```bash
>>> ./archInstall.bash -h
```

oder

```bash
>>> ./archInstall.bash --help
```

oder

```bash
>>> ./archInstall.bash --keyboard-layout de-latin1 -h
```

eingesehen werden. Letzteres macht Sinn, da sich Standardwerte aufgrund schon
ermittelten Informationen verändern können. So wird der Standardwert von
"--key-map-configuration="KEYMAP=de-latin1\nFONT=Lat2-Terminus16\nFONT_MAP="
nach Eingabe von

```bash
>>> ./archInstall.bash --keyboard-layout us
```

zu: "--key-map-configuration="KEYMAP=us\nFONT=Lat2-Terminus16\nFONT_MAP=".

Der Standardwert von "--cpu-architecture" entspricht beispielsweise immer der
Architektur des aktuellen Systems, um Konfigurationsaufwand zu minimieren.

Man kann Optionen die mehrere Werte annehmen auch mehrfach referenzieren.
So hat:

```bash
>>> ./archInstall.bash --additional-packages ssh --additional-packages vim -f python
```

den gleichen Effekt wie:

```bash
>>> ./archInstall.bash --additional-packages ssh vim python
```

Dies ist im Decorator-Pattern nützlich. Bei einem Doppelt referenzierten Wert
überschreiben spätere Werte zuvor Definierte. Folgendes:

```bash
>>> ./archInstall.bash --host-name A --host-name B
```

entspricht:

```bash
>>> ./archInstall.bash --host-name B
```

Auf diese Weise kann man getrost folgendes tun:

    #!/usr/bin/env bash

    source archInstall.bash

    myTarget='/path/to/expected/result'

    archInstall "$@" --output-system $myTarget

    # Working with result in "$myTarget"

Selbst wenn der Wert von "--output-system" über die CLI gesetzt wurde ist sie
im Wrapper wieder überschrieben. Auf diese weise kann man exklusiven Zugriff
auf Parameter im Wrapper vornehmen.

<!--|deDE:Offline Installieren-->
Install offline
---------------

archInstall erstellt bei jeder Installation automatisch einen Paket-Cache, um
weitere Installationen zu beschleunigen. Ist dieser einmal erstellt oder wird
dieser zusammen mit dem archInstall (z.b. auf einem usb-stick) ausgeliefert
kann Offline installiert werden.

Selbst wenn mit einem bereits vorhandenem pacstrap installiert wird, wird
dieser temporär kopiert, gepatched und anschließend offlinefähig ausgeführt!

Bei Offline Installation müssen natürlich alle zusätzlich ausgewählten
Pakete im Package Cache vorhanden sein. Ist dies nicht der Fall wird
archInstall versuchen diese nach zu laden und im Offline-Fall einen Fehler
zurückgeben.

<!--|deDE:Installieren ohne root Rechte-->
Install without having root permissions
---------------------------------------

Prinzipiell ist es sogar möglich auch ohne root Rechte ein System aufzusetzen.
Hierbei werden jedoch folgende Einschnitte gemacht:

* Die Programm "fakeroot" und "fakechroot" müssen zusätzlich installiert sein.
* Ein bereits installiertes Pacstrap kann nicht eingesetzt werden
* Zusätzlich erstellten Benutzer kann während der Installation kein automatisch
  erstellter Home-Ordner geliefert werden, da die Rechte oder root nicht
  richtig gesetzt werden könnten.
* Es kann nur in "Ordner" (bzw. siehe nächsten Punkt) installiert werden.
* Das System wird in ein tar-Archiv ohne Speicherung entsprechender Datei
  Rechte Attribute gepackt.
* Das Tar Archiv muss als "root" entpackt werden bevor das Ergebnis verwendet
  oder fehlerfrei gebootet werden kann.

<!--|deDE:Nützliche Tipps und Fehlerbehebung-->
Useful tips and debugging informations
--------------------------------------

Während der Entwicklung haben sich eine Reihe von Optionen bewährt um Fehler
bei der Entwicklung von Wrappern zu finden.

Die Option "--prevent-using-pacstrap" oder "-p" verhindert ein bereits
installierten Pacman für die Installation zu verwenden. Dies ist notwendig wenn
man sein Pacman so konfiguriert hat, das z.B. Pakete wie der Kernel oder Pacman
von manipulierten User Repositories abhängen. Mit "--prevent-using-pacstrap"
wird eine neue Version von Pacman in einer Change-Root-Umgebung ausgeführt.

"--prevent-using-native-arch-chroot" oder "-y" ist sinnvoll wenn man Indexing
Dienste wie Ubuntu's "Zeitgeist" oder "Dropbox" verwendet, die das Unmounten
von Mountpoints während der Installation verhindern, da sie auf diesen noch
lesen/schreiben.

Installiert man von einer Live-CD auf ein Block Device bootet das System nach
erfolgreicher Installation automatisch in das neu generierte System. Will man
noch etwas nachbessern oder Überprüfen, bietet sich die selbsterklärende Option
"--no-reboot" bzw. "-r" an.

Möchte man die Pakete "base-devel", "sudo" und "python" haben, geht das mit
dem Shortcut: "--install-common-additional-packages" oder "-z".

Will man eine beliebige Liste von Paketen integrieren:

```bash
>>> ./archInstall.bash --additional-packages ssh python2 vim
```

Sollen Dienste schon beim ersten Start automatisch gestartet werden:

```bash
>>> ./archInstall.bash --needed-services sshd dhcpcd
```

Um die Installation zu beschleunigen kann auf ein zentral verwalteten
Paket Cache verwiesen werden:

```bash
>>> ./archInstall.bash --package-cache-path /var/cache/pacman/pkg/
```

Will man im Wrapper eine archInstall Option verstecken, weil man diese z.B.
selber setzten will, eignet sich folgender Pattern:

    #!/usr/bin/env bash

    cat << EOF
    Usage: $0 <initramfsFilePath> [options]

    $__NAME__ installs an arch linux into an initramfs file.

    Option descriptions:

    $(archInstallPrintCommandLineOptionDescriptions "$@" | \
        sed '/^ *-[a-z] --output-system .*$/,/^$/d')
    EOF

    myTarget="$(mktemp)"

    archInstall "$@" --output-system "$myTarget"

    # ...

<!-- region vim modline

vim: set tabstop=4 shiftwidth=4 expandtab:
vim: foldmethod=marker foldmarker=region,endregion:

endregion -->
