#!/bin/sh
### BEGIN INIT INFO
# Provides:          webxec
# Required-Start:    $network $local_fs $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: webexec WebRTC server
# Description:       Executing commands and streaming io over WebRTC
### END INIT INFO

# Author: Benny Daon <benny@tuzig.com>

# PATH should only include /usr/* if it runs after the mountnfs.sh script
PATH=/usr/bin:/sbin:/usr/sbin:/bin
DESC=webexec
NAME=webexec             # TURN Serverwebexec
PROCNAME=webexec                  # Binary name
DAEMON=/usr/local/bin/webexec
DAEMON_ARGS="start"             # Arguments to run the daemon with
# TODO: find a better location for the pid file
SCRIPTNAME=/etc/init.d/$NAME

# Exit if the package is not installed
[ -x $DAEMON ] || exit 0

# Read configuration variable file if it is present
if [ -r /etc/$NAME ];then
    . /etc/$NAME
else
    . /etc/default/$NAME
fi

PIDFILE_DIR=$( getent passwd "$USER" | cut -d: -f6 )/.config/webexec
PIDFILE=$PIDFILE_DIR/agent.pid

if [ ! -d "$PIDFILE_DIR" ];then
        mkdir -p "$PIDFILE_DIR"
    chown $USER:$USER "$PIDFILE_DIR"
fi

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.0-6) to ensure that this file is present.
. /lib/lsb/init-functions

#
# Function that starts the daemon/service
#
do_start()
{
	# Return
	#   0 if daemon has been started
	#   1 if daemon was already running
	#   2 if daemon could not be started
	start-stop-daemon --start --chuid $USER --quiet --pidfile $PIDFILE --exec $DAEMON --test > /dev/null \
		|| return 1
	start-stop-daemon --start --chuid $USER --quiet --pidfile $PIDFILE --exec $DAEMON -- \
		$DAEMON_ARGS \
		|| return 2
	# Add code here, if necessary, that waits for the process to be ready
	# to handle requests from services started subsequently which depend
	# on this one.  As a last resort, sleep for some time.
}

#
# Function that stops the daemon/service
#
do_stop()
{
	# Return
	#   0 if daemon has been stopped
	#   1 if daemon was already stopped
	#   2 if daemon could not be stopped
	#   other if a failure occurred
	start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile $PIDFILE --name ${PROCNAME}
	RETVAL="$?"
	[ "$RETVAL" = 2 ] && return 2
	# Wait for children to finish too if this is a daemon that forks
	# and if the daemon is only ever run from this initscript.
	# If the above conditions are not satisfied then add some other code
	# that waits for the process to drop all resources that could be
	# needed by services started subsequently.  A last resort is to
	# sleep for some time.
	start-stop-daemon --stop --quiet --oknodo --retry=0/30/KILL/5 --exec $DAEMON
	[ "$?" = 2 ] && return 2
	# Many daemons don't delete their pidfiles when they exit.
	rm -f $PIDFILE
	return "$RETVAL"
}

#
# Function that sends a SIGHUP to the daemon/service
#
do_reload() {
	#
	# TODO: HANDLE RELOAD BY  SENDING SIGHUP
	#
	start-stop-daemon --stop --signal 1 --quiet --pidfile $PIDFILE --name $PROCNAME
	return 0
}

case "$1" in
    start)
	
	    log_daemon_msg "Starting $DESC " "$PROCNAME"
	    do_start
	    case "$?" in
		0|1) log_end_msg 0 ;;
		2) log_end_msg 1 ;;
	    esac
	;;
    stop)
	log_daemon_msg "Stopping $DESC" "$PROCNAME"
	do_stop
	case "$?" in
	    0|1) log_end_msg 0 ;;
	    2) log_end_msg 1 ;;
	esac
	;;
    status)
	status_of_proc "$DAEMON" "$PROCNAME" && exit 0 || exit $?
	;;
    restart|force-reload)
	log_daemon_msg "Restarting $DESC" "$PROCNAME"
	do_stop
	case "$?" in
	    0|1)
		do_start
		case "$?" in
		    0) log_end_msg 0 ;;
		    1) log_end_msg 1 ;; # Old process is still running
		    *) log_end_msg 1 ;; # Failed to start
		esac
		;;
	    *)
	  	# Failed to stop
		log_end_msg 1
		;;
	esac
	;;
    *)
	#echo "Usage: $SCRIPTNAME {start|stop|restart|reload|force-reload}" >&2
	echo "Usage: $SCRIPTNAME {start|stop|status|restart|force-reload}" >&2
	exit 3
	;;
esac

exit 0
