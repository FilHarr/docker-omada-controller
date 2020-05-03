#!/bin/sh

set -e

# set environment variables
export TZ
TZ="${TZ:-Etc/UTC}"
SMALL_FILES="${SMALL_FILES:-false}"
HTTP_PORT="${HTTP_PORT:-8088}"
HTTPS_PORT="${HTTPS_PORT:-8043}"

# set default time zone and notify user of time zone
echo "INFO: Time zone set to '${TZ}'"

# append smallfiles if set to true
if [ "${SMALL_FILES}" = "true" ]
then
  echo "INFO: Enabling smallfiles"
  # shellcheck disable=SC2016
  sed -i 's#^eap.mongod.args=--port ${eap.mongod.port} --dbpath "${eap.mongod.db}" -pidfilepath "${eap.mongod.pid.path}" --logappend --logpath "${eap.home}/logs/mongod.log" --nohttpinterface --bind_ip 127.0.0.1#eap.mongod.args=--smallfiles --port ${eap.mongod.port} --dbpath "${eap.mongod.db}" -pidfilepath "${eap.mongod.pid.path}" --logappend --logpath "${eap.home}/logs/mongod.log" --nohttpinterface --bind_ip 127.0.0.1#' /opt/tplink/EAPController/properties/mongodb.properties
fi

# change port numbers if not default
if [ "$HTTP_PORT" != 8088 ] || [ "$HTTPS_PORT" != 8043 ]
then
  echo "Setting HTTP port to $HTTP_PORT and HTTPS port to $HTTPS_PORT"
  sed -i -e 's#^http.connector.port=8088#http.connector.port='$HTTP_PORT'#' -e 's#^https.connector.port=8043#https.connector.port='$HTTPS_PORT'#' /opt/tplink/EAPController/properties/jetty.properties
fi

# if port number =< 1024 touch and set ownership on authbind files
if [ "$HTTP_PORT" -le 1024 ] || [ "$HTTPS_PORT" -le 1024 ] 
then
  echo "Touching /etc/authbind/byport/$HTTP_PORT and /etc/authbind/byport/$HTTPS_PORT"
  touch /etc/authbind/byport/$HTTP_PORT
  touch /etc/authbind/byport/$HTTPS_PORT
  echo "Setting ownership/permissions on /etc/authbind/byport/$HTTP_PORT and /etc/authbind/byport/$HTTPS_PORT"
  chown 508:508 /etc/authbind/byport/$HTTP_PORT
  chmod 770 /etc/authbind/byport/$HTTP_PORT
  chown 508:508 /etc/authbind/byport/$HTTPS_PORT
  chmod 770 /etc/authbind/byport/$HTTPS_PORT
  USE_AUTHBIND="true"
  echo "Authbind will be used"
fi

# make sure permissions are set appropriately on each directory
for DIR in data work logs
do
  OWNER="$(stat -c '%u' /opt/tplink/EAPController/${DIR})"
  GROUP="$(stat -c '%g' /opt/tplink/EAPController/${DIR})"

  if [ "${OWNER}" != "508" ] || [ "${GROUP}" != "508" ]
  then
    # notify user that uid:gid are not correct and fix them
    echo "WARNING: owner or group (${OWNER}:${GROUP}) not set correctly on '/opt/tplink/EAPController/${DIR}'"
    echo "INFO: setting correct permissions"
    chown -R 508:508 "/opt/tplink/EAPController/${DIR}"
  fi
done

# check to see if there is a db directory; create it if it is missing
if [ ! -d "/opt/tplink/EAPController/data/db" ]
then
  echo "INFO: Database directory missing; creating '/opt/tplink/EAPController/data/db'"
  mkdir /opt/tplink/EAPController/data/db
  chown 508:508 /opt/tplink/EAPController/data/db
  echo "done"
fi

echo "INFO: Starting Omada Controller as user omada"

# run with autobind if necessary
if [ "$USE_AUTHBIND" = "true" ]
then
  exec gosu omada authbind "${@}"
else
  exec gosu omada "${@}"
fi
