<!-- region vim modline

vim: set tabstop=4 shiftwidth=4 expandtab:
vim: foldmethod=marker foldmarker=region,endregion:

endregion -->

MakeRamOnlyLinux
----------------

makeRamOnlyLinux.bash generiert ein ArchLinux-System (oder ein beliebiges auf
ArchLinux basierendes System, welches mit einem Script generiert werden kann,
welches Interface und API von installArchLinux bereitstellt) und packt es in
eine bootbare initramfs und stellt einen passenden Kernel dazu bereit.

### Interface

Das Skript benötigt als Argument den Namen der zu erstellenden Initramfs-Datei.
Der passende Kernel wird an gleicher Stelle nur dem Suffix 'Kernel' erstellt.
Alle Optionen von installArchLinux werden unterstützt, es gibt keine
zusätzlichen Optionen. Neben der obligatorischen installArchLinux.bash benötigt
dieses Skript packcpio.sh, welches im selben Ordner liegen muss.

### Beispiel

Der folgende Befehl erzeugt ein Basis-ArchLinux-System in ein initramfs namens
"baseArchLinux.img" und kopiert einen dazu kompatiblen Kernel nach
"baseArchLinux.imgKernel".

```bash
>>> ./makeRamOnlyLinux baseArchLinux.img
```
