#!/usr/bin/env bash
# -*- coding: utf-8 -*-

# Torben Sickert
# @thaibault, http://torben.website

# Milan Oberkirch
# @zvynar

developers=(thaibault zvynar)

for developer in ${developers[*]}; do
    git remote add "$developer" "git@github.com:$developer/archInstall.git"
    git fetch "$developer"
done

# Add in your .git/config Change "YOUR_NICKNAME" to your own.

# ...
# [remote "origin"]
#     ...
#     url = git@github.com:YOUR_NICKNAME/archInstall
# ...

# region vim modline

# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:

# endregion
