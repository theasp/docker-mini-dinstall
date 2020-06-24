#!/bin/bash

# Sign the release file in the current directory.

set -e

rm -f Release.gpg.tmp
gpg --no-tty --batch --detach-sign --armor -o Release.gpg.tmp "$1"
mv Release.gpg.tmp Release.gpg
