#!/usr/bin/env bash
# -*- coding: utf-8 -*-

# Copyright 2012-2013 Torben Sickert, Milan Oberkirch

__NAME__='packcpio'

function packcpio() {
    local rootPath="$1"
    local outputFilePath=$(readlink --canonicalize $2 2>/dev/null)

    touch "$outputFilePath" &> /dev/null
    if [ $# -ne 2 ] || [ ! -d "$rootPath" ] || [ ! -f "$outputFilePath" ]; then
        echo "Usage: $0 ROOT_DIRECTORY_PATH OUTPUT_FILE_PATH"
        return 1
    fi

    echo "Pack cpio archiv from \"$rootPath\" into \"$outputFilePath\"."
    cd "$rootPath" && \
    find . -print0 | cpio --null --create --format=newc | gzip --best 1>"$outputFilePath" && \
    cd - 1>/dev/null && echo done. || echo "packing failed :\\"
}

[[ "$0" == *${__NAME__}.sh ]] && "$__NAME__" "$@"

# region vim modline

# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:

# endregion
