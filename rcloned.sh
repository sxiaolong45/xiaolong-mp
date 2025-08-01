#!/bin/bash
### BEGIN INIT INFO
# Provides:          rclone
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start rclone at boot time
# Description:       Enable rclone by daemon.
### END INIT INFO
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
 
REMOTE='openlist:/'
LOCAL='/volume1/rclone'
CONFIG='/root/.config/rclone/rclone.conf'
DEMO='rclone'
 
[ -n "$REMOTE" ] || exit 1;
[ -x "$(which fusermount)" ] || exit 1;
[ -x "$(which $DEMO)" ] || exit 1;
 
case "$1" in
start)
  ps -ef |grep -v grep |grep -q "$REMOTE"
  [ $? -eq '0' ] && {
    DEMOPID="$(ps -C $DEMO -o pid= |head -n1 |grep -o '[0-9]\{1,\}')"
    [ -n "$DEMOPID" ] && echo "$DEMO already in running.[$DEMOPID]";
    exit 1;
  }
  fusermount -zuq $LOCAL >/dev/null 2>&1
  mkdir -p $LOCAL
  rclone mount $REMOTE $LOCAL --config $CONFIG --copy-links --no-gzip-encoding --no-check-certificate --allow-other --allow-non-empty --umask 000 >/dev/null 2>&1 &
  sleep 3;
  DEMOPID="$(ps -C $DEMO -o pid=|head -n1 |grep -o '[0-9]\{1,\}')"
  [ -n "$DEMOPID" ] && {
    echo -ne "$DEMO start running.[$DEMOPID]\n$REMOTE --> $LOCAL\n\n"
    echo 'ok' >/root/ok
    exit 0;
  } || {
    echo "$DEMO start fail! "
    exit 1;
  }
  ;;
stop)
  DEMOPID="$(ps -C $DEMO -o pid= |head -n1 |grep -o '[0-9]\{1,\}')"
  [ -z "$DEMOPID" ] && echo "$DEMO not running."
  [ -n "$DEMOPID" ] && kill -9 $DEMOPID >/dev/null 2>&1
  [ -n "$DEMOPID" ] && echo "$DEMO is stopped.[$DEMOPID]"
  fusermount -zuq $LOCAL >/dev/null 2>&1
  ;;
init)
  fusermount -zuq $LOCAL
  rm -rf $LOCAL;
  mkdir -p $LOCAL;
  chmod a+x $0;
  update-rc.d -f $(basename $0) remove;
  update-rc.d -f $(basename $0) defaults;
  rclone config;
  ;;
esac
 
exit 0
