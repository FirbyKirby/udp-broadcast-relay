#!/bin/sh

# REQUIRE: NETWORKING
# PROVIDE: udp-broadcast-relay

# start/stop script for the github udp-redux/udp-broadcast-relay-redux

. /etc/rc.subr

# note that rcvar is in the /etc/rc.conf.local file to enable/disable the bouncer
name="udp-broadcast-relay"
rcvar="udp_broadcast_relay_enable"
start_cmd="udp_broadcast_relay_start"
stop_cmd="udp_broadcast_relay_stop"

pidfile="/var/run/${name}.pid"
cmd="/usr/local/bin/udp-broadcast-relay-redux"
conf_file="/usr/local/etc/udp-broadcast-relay-redux.conf"

load_rc_config ${name}

udp_broadcast_relay_start()
{
  if checkyesno ${rcvar}; then
    if [ ! -f "${conf_file}" ]; then
      echo "No ${conf_file} defined .. can't start"
      exit 1
    fi
    # get the settings line from the file
    . ${conf_file}

    if [ -z "${udp_vars}" ]; then
      echo "The \$udp_vars have not been set in the ${conf_file}"
      exit 1
    fi
    echo "Starting UDP Broadcast Relay Redux. "

    # The process will run until it is terminated. Although it has a fork option, it's
    # not possible to grab the pid and thus backgrounding it is more useful
    # So we start it in the background and stash the pid:
    ${cmd} ${udp_vars} &
    echo $! > $pidfile

  fi
}

udp_broadcast_relay_stop()
{

  if [ -f $pidfile ]; then
    echo -n "Stopping the UDP Broadcast Replay Redux ..."

    pid=`cat ${pidfile}`
    kill ${pid}

    echo " acknowledged."
    echo -n "Waiting for the UDP Broadcast Relay instance to stop ..."

    # ...then we wait until the service identified by the pid file goes away:
    while [ `pgrep $pid` ]; do
      echo -n "."
      sleep 1
    done

    # Remove the pid file:
    rm $pidfile

    echo " stopped.";
  else
    echo "There is no pid file. The controller may not be running."
  fi
}

run_rc_command "$1"
