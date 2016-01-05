<!-- -*- coding: utf-8 -*-

region header

Copyright Torben Sickert 16.12.2012

License
-------

This library written by Torben Sickert stand under a creative commons naming
3.0 unported license. see http://creativecommons.org/licenses/by/3.0/deed.de

endregion -->

### makeRamOnlyLinux

makeRamOnlyLinux.sh generiert ein ArchLinux-System (oder ein beliebiges auf
ArchLinux basierendes System, welches mit einem Script generiert werden kann,
welches Interface und API von archInstall bereitstellt) und packt es in
eine bootbare initramfs und stellt einen passenden Kernel dazu bereit.

#### Interface

Das Skript benötigt als Argument den Namen der zu erstellenden Initramfs-Datei.
Der passende Kernel wird an gleicher Stelle nur dem Suffix 'Kernel' erstellt.
Alle Optionen von archInstall werden unterstützt, es gibt keine
zusätzlichen Optionen. Neben der obligatorischen archInstall.sh benötigt
dieses Skript packcpio.sh, welches im selben Ordner liegen muss.

<!--|deDE:Beispiel-->
#### Example

Der folgende Befehl erzeugt ein Basis-ArchLinux-System in ein initramfs namens
"baseArchLinux.img" und kopiert einen dazu kompatiblen Kernel nach
"baseArchLinux.imgKernel".

```bash
>>> ./makeRamOnlyLinux baseArchLinux.img
```

<!-- region vim modline

vim: set tabstop=4 shiftwidth=4 expandtab:
vim: foldmethod=marker foldmarker=region,endregion:

endregion -->
