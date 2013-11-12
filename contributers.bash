#!/usr/bin/env bash

# Torben Sickert
# @thaibault, http://thaibault.github.io/website/

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
