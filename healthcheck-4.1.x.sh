#!/bin/sh

MANAGE_HTTPS_PORT=$MANAGE_HTTPS_PORT

# check if MANAGE_HTTPS_PORT variable has been set. If not use default HTTPS port for healthcheck, otherwise use set port.

if [ -z "$MANAGE_HTTPS_PORT" ]
then
  wget --quiet --tries=1 --no-check-certificate http://127.0.0.1:8043 || exit 1
else
  wget --quiet --tries=1 --no-check-certificate -O /dev/null --server-response --timeout=5 https://127.0.0.1:$MANAGE_HTTPS_PORT || exit 1
fi