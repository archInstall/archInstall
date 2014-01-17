<!-- region vim modline

vim: set tabstop=4 shiftwidth=4 expandtab:
vim: foldmethod=marker foldmarker=region,endregion:

endregion -->

### MakeXBMCLinux

makeXBMCLinux ist ein Wrapper-Skript für archInstall, welches das gleiche Interface unterstützt. Neben dem Grundsystem wird dabei eine XBMC-Umgebung installiert, welche beim booten automatisch startet.

### Interface

Alle Optionen von archInstall werden unterstützt, allerdings werden alle nötigen Angaben mit Standard-Werten belegt, das Skript läuft also immer ohne Nutzer-Interaktion durch. Wenn kein Output-System ('--output-system') angegeben wird, wird das System in einen Ordner im aktuellen Verzeichnis installiert (von wo man es dann z.B. per rsync an den Zielort kopieren kann).
Das Skript kann z.B. von makeSquashLinux oder makeRamOnlyLinux eingebunden werden.

Zusätzliche Optionen:

    Usage: ./makeXBMCLinux.bash [Options]

        makeXBMCLinux installs an xbmc frontend with an underlying arch linux.

    Option descriptions:

        -R --ram-only <filename> Build an initramfs-file named 'filename'.

        -M --media-files <media-folder> Give a folder with media-files to copy into
            the system. This option doesn't work in combination with "--ram-only".
            (Hint: makeRamOnlyLinux.bash --wrapper makeXBMCLinux.bash --media-files)

        -W --wrapper <filename> Use wrapper in <filename> to generate the
            root-filesystem. This option doesn't work in combination with
            "--ram-only".

### Anwendungsfälle

Netzwerkboot-fähiges squashfs samt kernel und initramfs mit XBMC-Frontend und Media-Dateien bauen:

    ./makeSquashLinux.bash root.squash kernel initramfs --wrapper ../makeXBMCLinux/makeXBMCLinux.bash --media-files ~/Musik/Justin_Bieber

XBMC auf der lokalen Partition (/dev/sdz1) installieren:

    ./makeXBMCLinux/makeXBMCLinux.bash -o /dev/sdz1

XBMC auf der lokalen Festplatte (/dev/sdz) installieren:

    ./makeXBMCLinux/makeXBMCLinux.bash -o /dev/sdz
