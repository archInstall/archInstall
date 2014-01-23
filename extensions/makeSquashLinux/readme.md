<!-- region vim modline

vim: set tabstop=4 shiftwidth=4 expandtab:
vim: foldmethod=marker foldmarker=region,endregion:

endregion

region header

Copyright Torben Sickert 16.12.2012

License
-------

   This library written by Torben Sickert stand under a creative commons
   naming 3.0 unported license.
   see http://creativecommons.org/licenses/by/3.0/deed.de

endregion -->

### MakeSquashLinux

MakeSquashLinux generiert ein ArchLinux-System (oder ein beliebiges auf
ArchLinux basierendes System, welches mit einem Script generiert werden kann,
welches Interface und API von archInstall bereitstellt), patched die
Konfiguration so, dass das booten aus dem Netzwerk ermöglicht wird und packt
dieses als squash-Dateisystem. Zusätzlich wird eine Netzwerk-Boot-fähige
initramfs erzeugt und ein für aufs gepatchter Kernel aus den Paket-Quellen
kopiert.

MakeSquashLinux kann nicht von Wrappern verwendet werden, welche nach dem
generieren des Grundsystems weitere Anpassungen vornehmen möchten. Da der
Download der squash-Datei ein paar Sekunden in Anspruch nimmt, wird beim
booten per 'plymouth' ein splash-screen angezeigt.

#### Interface

    Usage: ./makeSquashLinux.bash <squashfsFilePath> <kernelFilePath> <initramfsFilePath> [options]

    makeSquashLinux installs an arch linux into a squashfs file.

    Option descriptions:
        -W --wrapper <file>  Use wrapper in <file> to generate the root-Filesystem
        -X --xbmc Use "../makeXBMCLinux/makeXBMCLinux.bash" as wrapper.

Wrapper sind hier Skripte, welche den Standard-Setup von archInstall durch
weitere Konfiguration oder Programme ergänzen (makeSquashLinux ist also selbst
auch ein Wrapper).

Darüberhinaus können alle Optionen von archInstall verwendet werden. Als
Pfade werden lokale Dateinamen und scp-kompatible Pfade akzeptiert.
So ist es möglich die einzelnen Dateien auf verschiedenen Rechnern zu speichern
(mit den intitramfs-Optionen ist es sogar möglich das root-squashfs aus einem
mit dem Ort des Kernels oder tftp-Servers nicht verbundenen Netz zu laden).

scp-Pfade haben die Form "user@ssh-server:/pfad/zu/datei"

<!--|deDE:Initramfs-Parameter-->
#### Initramfs parameter

Um über das Netzwerk booten zu können müssen dem initramfs auf der
Kernel-Kommandozeile einige Informationen mitgegeben werden:

* Art der Netzwerkverbindung: `ip=<client-ip>::<gw-ip>:<netmask>:<hostname>:<device>:<autoconf>`
    Alle Parameter sind optional.
    `<client-ip>`: Statische IP-Adresse, die angefordert werden soll.
    `<gw-ip>`: IP-Adresse des Gateways.
    `<netmask>`: Netsmaske. Wenn leer wird diese aus der client-ip generiert und/oder durch die Antwort von DHCP/BOOTP überschrieben.
    `<hostname>`: Wenn leer wird die ASCI-codierte IP-Adresse verwendet. Kann durch DHCP-Antwort überschrieben werden.
    `<device>`: Netzwerkkarte, die verwendet werden soll (ermöglicht absurde Use-Cases). Wenn leer wird die erste Karte verwendet, auf der eine Antwort kommt.
    `<autoconf>`: Methode, die für den Verbindungsaufbau genutzt werden soll. Mögliche Parameter sind `rarp`, `bootp`, `dhcp`, `all` oder `static`. Wenn dieses Feld leer ist wird `all` verwendet, also alle Protokolle durchprobiert. Bei `static` kommt keines der Protokolle zum Einsatz und es wird eine Verbindung anhand der vorherigen Angaben hergestellt.
    Beispiel:  `ip=::::::`

* Ort des root-Dateisystems:
    Der 'url'-Parameter überschreibt 'nfsroot', unabhängig von der Reihenfolge.
    * Bei squashfs werden URLs mit den Protokollen http, https und ftp unterstützt (eine DNS-Auflösung findet nicht statt):
    `url="<protocol>://<server-ip>[:<port>]/<path-to-file>"`
    `<protocol>`: Es werden http, https und ftp unterstützt.
    `<server-ip>`: IP-Adresse des Hosts, auf dem die squashfs-Datei liegt.
    `[:<port>]`: Optional, Port auf dem der Host mit dem Angegebenen Protokoll erreicht werden kann.
    `<path-to-file>`: Pfad zur squashfs-Datei.
    * Bei nfs:
    `nfsroot=[<server-ip>:]<root-dir>[,<nfs-options>]`
    Beispiel: `url="http://192.0.43.10/example.squashfs"`
