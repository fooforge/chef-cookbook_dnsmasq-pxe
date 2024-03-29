#!/bin/sh
### BEGIN INIT INFO
# Provides:       dnsmasq
# Required-Start: $network $remote_fs $syslog
# Required-Stop:  $network $remote_fs $syslog
# Default-Start:  2 3 4 5
# Default-Stop:   0 1 6
# Description:    DHCP and DNS server
### END INIT INFO

set +e   # Don't exit on error status

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/sbin/dnsmasq
NAME=dnsmasq
DESC="DNS forwarder and DHCP server"

# Most configuration options in /etc/default/dnsmasq are deprecated
# but still honoured.
ENABLED=1
if [ -r /etc/default/$NAME ]; then
  . /etc/default/$NAME
fi

# Get the system locale, so that messages are in the correct language, and the
# charset for IDN is correct
if [ -r /etc/default/locale ]; then
        . /etc/default/locale
        export LANG
fi

test -x $DAEMON || exit 0

# Provide skeleton LSB log functions for backports which don't have LSB functions.
if [ -f /lib/lsb/init-functions ]; then
         . /lib/lsb/init-functions
else
         log_warning_msg () {
            echo "${@}."
         }

         log_success_msg () {
            echo "${@}."
         }

         log_daemon_msg () {
            echo -n "${1}: $2"
         }

   log_end_msg () {
            if [ $1 -eq 0 ]; then
              echo "."
            elif [ $1 -eq 255 ]; then
              /bin/echo -e " (warning)."
            else
              /bin/echo -e " failed!"
            fi
         }
fi

# RESOLV_CONF:
# If the resolvconf package is installed then use the resolv conf file
# that it provides as the default.  Otherwise use /etc/resolv.conf as
# the default.
#
# If IGNORE_RESOLVCONF is set in /etc/default/dnsmasq or an explicit
# filename is set there then this inhibits the use of the resolvconf-provided
# information.
#
# Note that if the resolvconf package is installed it is not possible to
# override it just by configuration in /etc/dnsmasq.conf, it is necessary
# to set IGNORE_RESOLVCONF=yes in /etc/default/dnsmasq.

#if [ ! "$RESOLV_CONF" ] &&
#   [ "$IGNORE_RESOLVCONF" != "yes" ] &&
#   [ -x /sbin/resolvconf ]
#then
#  RESOLV_CONF=/var/run/dnsmasq/resolv.conf
#fi

for INTERFACE in $DNSMASQ_INTERFACE; do
  DNSMASQ_INTERFACES="$DNSMASQ_INTERFACES -i $INTERFACE"
done

for INTERFACE in $DNSMASQ_EXCEPT; do
  DNSMASQ_INTERFACES="$DNSMASQ_INTERFACES -I $INTERFACE"
done

if [ ! "$DNSMASQ_USER" ]; then
   DNSMASQ_USER="dnsmasq"
fi

start()
{
        # Return
  #   0 if daemon has been started
  #   1 if daemon was already running
  #   2 if daemon could not be started

        # /var/run may be volatile, so we need to ensure that
        # /var/run/dnsmasq exists here as well as in postinst
        if [ ! -d /var/run/dnsmasq ]; then
           mkdir /var/run/dnsmasq || return 2
           chown dnsmasq:nogroup /var/run/dnsmasq || return 2
        fi

  start-stop-daemon --start --quiet --pidfile /var/run/dnsmasq/$NAME.pid --exec $DAEMON --test > /dev/null || return 1
  start-stop-daemon --start --quiet --pidfile /var/run/dnsmasq/$NAME.pid --exec $DAEMON -- \
    -x /var/run/dnsmasq/$NAME.pid \
          ${MAILHOSTNAME:+ -m $MAILHOSTNAME} \
    ${MAILTARGET:+ -t $MAILTARGET} \
    ${DNSMASQ_USER:+ -u $DNSMASQ_USER} \
    ${DNSMASQ_INTERFACES:+ $DNSMASQ_INTERFACES} \
    ${DHCP_LEASE:+ -l $DHCP_LEASE} \
    ${DOMAIN_SUFFIX:+ -s $DOMAIN_SUFFIX} \
    ${RESOLV_CONF:+ -r $RESOLV_CONF} \
    ${CACHESIZE:+ -c $CACHESIZE} \
          ${CONFIG_DIR:+ -7 $CONFIG_DIR} \
    ${DNSMASQ_OPTS:+ $DNSMASQ_OPTS} \
    || return 2
}

start_resolvconf()
{
# If interface "lo" is explicitly disabled in /etc/default/dnsmasq
# Then dnsmasq won't be providing local DNS, so don't add it to
# the resolvconf server set.
  for interface in $DNSMASQ_EXCEPT
  do
    [ $interface = lo ] && return
  done

#        if [ -x /sbin/resolvconf ] ; then
#    echo "nameserver 127.0.0.1" | /sbin/resolvconf -a lo.$NAME
#  fi
  return 0
}

stop()
{
  # Return
  #   0 if daemon has been stopped
  #   1 if daemon was already stopped
  #   2 if daemon could not be stopped
  #   other if a failure occurred
  start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile /var/run/dnsmasq/$NAME.pid --name $NAME
  RETVAL="$?"
  [ "$RETVAL" = 2 ] && return 2
  return "$RETVAL"
}

stop_resolvconf()
{
  if [ -x /sbin/resolvconf ] ; then
    /sbin/resolvconf -d lo.$NAME
  fi
  return 0
}

status()
{
  # Return
  #   0 if daemon is running
  #   1 if daemon is dead and pid file exists
  #   3 if daemon is not running
  #   4 if daemon status is unknown
  start-stop-daemon --start --quiet --pidfile /var/run/dnsmasq/$NAME.pid --exec $DAEMON --test > /dev/null
  case "$?" in
    0) [ -e "/var/run/dnsmasq/$NAME.pid" ] && return 1 ; return 3 ;;
    1) return 0 ;;
    *) return 4 ;;
  esac
}

case "$1" in
  start)
  test "$ENABLED" != "0" || exit 0
  log_daemon_msg "Starting $DESC" "$NAME"
  start
  case "$?" in
    0)
      log_end_msg 0
      start_resolvconf
      exit 0
      ;;
    1)
      log_success_msg "(already running)"
      exit 0
      ;;
    *)
      log_end_msg 1
      exit 1
      ;;
  esac
  ;;
  stop)
  stop_resolvconf
  if [ "$ENABLED" != "0" ]; then
             log_daemon_msg "Stopping $DESC" "$NAME"
  fi
  stop
        RETVAL="$?"
  if [ "$ENABLED" = "0" ]; then
      case "$RETVAL" in
         0) log_daemon_msg "Stopping $DESC" "$NAME"; log_end_msg 0 ;;
            esac
      exit 0
  fi
  case "$RETVAL" in
    0) log_end_msg 0 ; exit 0 ;;
    1) log_warning_msg "(not running)" ; exit 0 ;;
    *) log_end_msg 1; exit 1 ;;
  esac
  ;;
  restart|force-reload)
  test "$ENABLED" != "0" || exit 1
  $DAEMON --test ${CONFIG_DIR:+ -7 $CONFIG_DIR} ${DNSMASQ_OPTS:+ $DNSMASQ_OPTS} >/dev/null 2>&1
  if [ $? -ne 0 ]; then
      NAME="configuration syntax check"
      RETVAL="2"
  else
      stop_resolvconf
      stop
      RETVAL="$?"
        fi
  log_daemon_msg "Restarting $DESC" "$NAME"
  case "$RETVAL" in
    0|1)
            sleep 2
      start
      case "$?" in
        0)
          log_end_msg 0
          start_resolvconf
          exit 0
          ;;
              *)
          log_end_msg 1
          exit 1
          ;;
      esac
      ;;
    *)
      log_end_msg 1
      exit 1
      ;;
  esac
  ;;
  status)
  log_daemon_msg "Checking $DESC" "$NAME"
  status
  case "$?" in
    0) log_success_msg "(running)" ; exit 0 ;;
    1) log_success_msg "(dead, pid file exists)" ; exit 1 ;;
    3) log_success_msg "(not running)" ; exit 3 ;;
    *) log_success_msg "(unknown)" ; exit 4 ;;
  esac
  ;;
  dump-stats)
        kill -s USR1 `cat /var/run/dnsmasq/$NAME.pid`
  ;;
  systemd-start-resolvconf)
  start_resolvconf
  ;;
  systemd-stop-resolvconf)
  stop_resolvconf
  ;;
  systemd-exec)
#  --pid-file without argument disables writing a PIDfile, we don't need one with sytemd.
# Enable DBus by default because we use DBus activation with systemd.
  exec $DAEMON --keep-in-foreground --pid-file --enable-dbus \
      ${MAILHOSTNAME:+ -m $MAILHOSTNAME} \
      ${MAILTARGET:+ -t $MAILTARGET} \
      ${DNSMASQ_USER:+ -u $DNSMASQ_USER} \
      ${DNSMASQ_INTERFACES:+ $DNSMASQ_INTERFACES} \
      ${DHCP_LEASE:+ -l $DHCP_LEASE} \
      ${DOMAIN_SUFFIX:+ -s $DOMAIN_SUFFIX} \
      ${RESOLV_CONF:+ -r $RESOLV_CONF} \
      ${CACHESIZE:+ -c $CACHESIZE} \
      ${CONFIG_DIR:+ -7 $CONFIG_DIR} \
      ${DNSMASQ_OPTS:+ $DNSMASQ_OPTS}
  ;;
  *)
  echo "Usage: /etc/init.d/$NAME {start|stop|restart|force-reload|dump-stats|status}" >&2
  exit 3
  ;;
esac

exit 0
