#!/bin/sh -e

# overwrite /etc/fuse.conf to allow other users to access the mounted filesystem from outside the container
cat <<EOF> /etc/fuse.conf
# Allow non-root users to specify the 'allow_other' or 'allow_root'
# mount options.
user_allow_other
EOF

MOUNTPATH=${MOUNTPATH:-/media}
# set env for ACDCLI
CONFIGPATH=${CONFIGPATH:-/cache}
CACHEPATH=${CACHEPATH:-/cache}
if [ ! -d "$CONFIGPATH" ]; then mkdir -p $CONFIGPATH; fi
if [ ! -d "$CACHEPATH" ]; then mkdir -p $CACHEPATH; fi

export ACD_CLI_CACHE_PATH=$CACHEPATH
export ACD_CLI_SETTINGS_PATH=$CONFIGPATH
export HTTPS_PROXY="$PROXY"
export HTTP_PROXY="$PROXY"

# set ID docker run
auid=${auid:-767}
agid=${agid:-$auid}
auser=${auser:-user}

if [[ "$auid" = "0" ]] || [[ "$aguid" == "0" ]]; then
  echo "Run in ROOT user"
else
  echo "Run in $auser"
  if [ ! -d "/home/$auser" ]; then
  addgroup -g ${agid} $auser && \
  adduser -D -u ${auid} -G $auser $auser && \
  mkdir -p /home/$auser/.cache/acd_cli #no need
  ln -sf $CACHEPATH /home/$auser/.cache/acd_cli #no need
  chown -R $auid:$agid /home/$auser #no need
  chown -R $auid:$agid $CONFIGPATH $CACHEPATH
  # fix su command user
  sed -i '$ d' /etc/passwd
  echo "$auser:x:$auid:$agid:Linux User:/home/$auser:/bin/sh" >> /etc/passwd
  fi
  su - $auser
fi

# help
echo "use acdcli command"
echo "---"
acdcli -h

# create startup run
if [ ! -f "$CONFIGPATH/startup.sh" ]; then
# create
cat <<EOF>> $CONFIGPATH/startup.sh
#!/bin/sh
# your startup command
EOF
  chmod +x $CONFIGPATH/startup.sh
else
# run
  $CONFIGPATH/startup.sh
fi

# ssh
[ -f /runssh.sh ] && /runssh.sh

# wait /media mount
while [ -z "`ls /media`" ]
do
  echo "wait mount /media"
  sleep 10
done
echo "mount completed! Plex starting..."

# Legacy environment variables support.
if [ -n "$PLEX_USERNAME" ]; then
    echo "WARNING: 'PLEX_USERNAME' has been deprecated and is now called 'PLEX_LOGIN'."
    PLEX_LOGIN="$PLEX_USERNAME"
    unset PLEX_USERNAME
fi

if [ -n "$PLEXPASS_LOGIN" ]; then
    echo "WARNING: 'PLEXPASS_LOGIN' has been deprecated and is now called 'PLEX_LOGIN'."
    PLEX_LOGIN="$PLEXPASS_LOGIN"
    unset PLEXPASS_LOGIN
fi

if [ -n "$PLEXPASS_PASSWORD" ]; then
    echo "WARNING: 'PLEXPASS_PASSWORD' has been deprecated and is now called 'PLEX_PASSWORD'."
    PLEX_PASSWORD="$PLEXPASS_PASSWORD"
    unset PLEXPASS_PASSWORD
fi

if [ -n "$PLEX_EXTERNALPORT" ]; then
    echo "WARNING: 'PLEXEXTERNALPORT' has been deprecated and is now called 'PLEX_EXTERNAL_PORT'."
    PLEX_EXTERNAL_PORT="$PLEXPASS_EXTERNALPORT"
    unset PLEXPASS_EXTERNALPORT
fi

# Delete PID file (we don't use that)
if [ -f /config/Plex\ Media\ Server/plexmediaserver.pid ]; then
    rm -f /config/Plex\ Media\ Server/plexmediaserver.pid
fi

# Get plex token if Plex username and password are defined.
if [ -n "$PLEX_LOGIN" ] && [ -n "$PLEX_PASSWORD" ]; then
    export X_PLEX_TOKEN=$(retrieve-plex-token "$PLEX_LOGIN" "$PLEX_PASSPWORD")
fi
unset PLEX_LOGIN
unset PLEX_PASSWORD

PLEX_PREFERENCES="/config/Plex Media Server/Preferences.xml"

# Default Preferences.
if [ ! -f /config/Plex\ Media\ Server/Preferences.xml ]; then
    mkdir -p /config/Plex\ Media\ Server
    cp /Preferences.xml "$PLEX_PREFERENCES"
fi

update_preferences_attribute() {
    attr="$1"
    value="$2"
    if [ $(xmlstarlet select -T -t -m "/Preferences" -v "@$attr" -n "$PLEX_PREFERENCES") ]; then
        xmlstarlet edit --inplace --update "/Preferences/@$attr" -v "$value" "$PLEX_PREFERENCES"
    else
        xmlstarlet edit --inplace --insert "Preferences" --type attr -n "$attr" -v "$value" "$PLEX_PREFERENCES"
    fi
}

# Sets PlexOnlineToken in Preferences.xml if provided.
if [ -n "$X_PLEX_TOKEN" ]; then
    update_preferences_attribute PlexOnlineToken "$X_PLEX_TOKEN"
fi

# Sets ManualPortMappingPort in Preferences.xml if provided.
if [ -n "$PLEX_EXTERNAL_PORT" ]; then
    update_preferences_attribute ManualPortMappingMode 1
    update_preferences_attribute ManualPortMappingPort $PLEX_EXTERNAL_PORT
fi

# Unset any environment variable we used (just for safety as we don't need them anymore).
unset PLEX_EXTERNAL_PORT
unset X_PLEX_TOKEN

# Output logs to stdout.
if [ ! -f '/config/Plex Media Server/Logs/Plex Media Server.log' ]; then
    mkdir -p '/config/Plex Media Server/Logs'
    touch '/config/Plex Media Server/Logs/Plex Media Server.log'
fi
tail -Fn 0 '/config/Plex Media Server/Logs/Plex Media Server.log' &

# Set the stack size
ulimit -s $PLEX_MAX_STACK_SIZE

export DNSSERVER=${DNSSERVER:-8.8.8.8}
# Set DNS Server to localhost
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

exec "$@"
