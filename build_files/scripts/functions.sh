#!/bin/bash

function disable-repo() {
  sed -i 's/enabled=1/enabled=0/' "${1}"
}

function enable-repo() {
  sed -i 's/enabled=0/enabled=1/' "${1}"
}
