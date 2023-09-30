#!/bin/env sh

# pin packages to known good revisions

pin_package () {

    VERSIONS=$(rpm -q --queryformat "%{VERSION}\n" --whatprovides "${1}")

    if [ "${VERSIONS}" = "${1}" ]; then
        echo "Pin"
        #rpm-ostree override replace https://koji.fedoraproject.org/koji/buildinfo?buildID="${1}"
    fi
}

# podman 4.6.2
pin_package "2288447"
