#!/bin/bash
set -e

for arg in "$@" ; do
  if [[ $arg == "-p"* ]] ; then
    exec gosu nicehash /usr/local/bin/cpuminer "$@"
  elif [[ $arg == "-h"* ]] ; then
    exec gosu nicehash /usr/local/bin/cpuminer -h
  fi
done

password="$(< /dev/urandom tr -dc 'A-Z-a-z-0-99!#$%&()*+,-./:;<=>?@[\]^_{|}~' | head -c 64)"
exec gosu nicehash /usr/local/bin/cpuminer "$@" \
  -p "$password"
