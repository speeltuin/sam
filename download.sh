#!/usr/bin/env bash

process_package() {
    local -r year=$1 package=$2 version=$3

    local zipfile url
    printf -v zipfile '%s.zip' $package
    printf -v url 'https://sqlite.org/%04d/%s' $year $zipfile

    wget --quiet $url
    if [[ ! -f $zipfile ]]; then
        printf 'Error: %s does not exist' $zipfile
    fi

    unzip -qq $zipfile
    commit_date=$(date -u -d "$(stat -c %y $package)" +"%Y-%m-%dT%H:%M:%SZ")
    rm $zipfile

    mv $package/* .
    rmdir $package

    git add *.[ch]

    GIT_AUTHOR_DATE=$commit_date \
    GIT_COMMITTER_DATE=$commit_date \
    git commit -q --signoff -m "chore: import sqlite release $version"
}

read_releases() {
    local date version
    while read -r date version; do
        local -i year major minor patch
        year=${date%%-*}
        IFS=. read major minor patch <<<"$version"
        local package url
        printf -v package 'sqlite-amalgamation-%d%02d%02d00' $major $minor $patch
        process_package $year $package $version
    done < releases.txt
}

read_releases
