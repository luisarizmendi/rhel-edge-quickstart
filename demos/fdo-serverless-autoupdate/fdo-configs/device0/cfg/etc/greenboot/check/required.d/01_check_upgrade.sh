#!/bin/bash

#
# This test fails if the current commit identifier is different
# than the original commit
#

function get_commit () {
  COMMITS=\$(rpm-ostree status | grep Commit | head -n1 | awk -F' ' '{ print \$2}')
  if [ \$(echo \$COMMITS | wc -w) -eq 1 ]
  then
    COMMIT=\$COMMITS
  else
    COMMIT=\$(echo \$COMMITS | awk '{print \$(NF)}')
  fi
  echo \$COMMIT
}

COMMIT=\$(get_commit)

if [ ! -f /etc/greenboot/orig.txt ]
then
  echo \$COMMIT > /etc/greenboot/orig.txt
fi

echo \$COMMIT > /etc/greenboot/current.txt

diff -s /etc/greenboot/orig.txt /etc/greenboot/current.txt
