#!/bin/sh

HTTP_PORT=$HTTP_PORT

# check if HTTP_PORT variable has been set. If not use default HTTP port for healthcheck, otherwise use set port.

if [ -z "$HTTP_PORT" ]
then
  wget --quiet --tries=1 --no-check-certificate http://127.0.0.1:8088 || exit 1
else
  wget --quiet --tries=1 --no-check-certificate http://127.0.0.1:$HTTP_PORT || exit 1
fi
