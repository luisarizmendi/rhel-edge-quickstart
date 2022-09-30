#!/bin/bash

#
# This test fails if /root/mustfail file exist
#

#FILE=/root/mustfail
#if [ -f "$FILE" ]; then
#    echo "$FILE exists: Check FAILED!"
#    exit 1
#else
#    echo "$FILE does not exist: Check PASSED!"
#    exit 0
#fi

systemctl status sshd
rc=$?

if [ $rc -ne 0 ]
then
  logger -p auth.info "ERROR - SSH service not working"
fi

exit $rc
