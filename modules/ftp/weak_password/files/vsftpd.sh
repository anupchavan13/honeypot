#!/bin/sh

set -e

DAEMON="/usr/sbin/vsftpd"
NAME="vsftpd"
PATH="/sbin:/bin:/usr/sbin:/usr/bin"
LOGFILE="/var/log/vsftpd.log"
CHROOT="/var/run/vsftpd/empty"

test -x "${DAEMON}" || exit 0

. /lib/lsb/init-functions

if [ ! -e "${LOGFILE}" ]
then
    touch "${LOGFILE}"
    chmod 640 "${LOGFILE}"
    chown root:adm "${LOGFILE}"
fi

if [ ! -d "${CHROOT}" ]
then
    mkdir -p "${CHROOT}"
fi

case "${1}" in
    start)
        log_daemon_msg "Starting FTP server" "${NAME}"

        if [ -e /etc/vsftpd.conf ] && ! egrep -iq "^ *listen(_ipv6)? *= *yes" /etc/vsftpd.conf
        then
            log_warning_msg "vsftpd disabled - listen disabled in config."
            exit 0
        fi

        start-stop-daemon --start --background -m --oknodo --pidfile /var/run/vsftpd/vsftpd.pid --exec ${DAEMON}
        sleep 1

        n=0
        while [ ${n} -le 5 ]
        do
            _PID="$(if [ -e /var/run/vsftpd/vsftpd.pid ]; then cat /var/run/vsftpd/vsftpd.pid; fi)"
            if ! ps -C vsftpd | grep -qs "${_PID}"
            then
                break
            fi
            sleep 1
            n=$(( $n + 1 ))
        done

        if ! ps -C vsftpd | grep -qs "${_PID}"
        then
            log_warning_msg "vsftpd failed - probably invalid config."
            exit 1
        fi

        log_end_msg 0
        ;;

    stop)
        log_daemon_msg "Stopping FTP server" "${NAME}"

        start-stop-daemon --stop --pidfile /var/run/vsftpd/vsftpd.pid --oknodo --exec ${DAEMON}
        rm -f /var/run/vsftpd/vsftpd.pid

        log_end_msg 0
        ;;

    restart)
        ${0} stop
        ${0} start
        ;;

    reload|force-reload)
        log_daemon_msg "Reloading FTP server configuration"

        start-stop-daemon --stop --pidfile /var/run/vsftpd/vsftpd.pid --signal 1 --exec $DAEMON

        log_end_msg "${?}"
        ;;

    status)
        status_of_proc "${DAEMON}" "FTP server"
        ;;

    *)
        echo "Usage: ${0} {start|stop|restart|reload|status}"
        exit 1
        ;;
esac

exit 0
