#! /usr/bin/env bash

cd $(dirname $0)

PGQD=../pgqd

export PGHOST="${PGHOST:-127.0.0.1}"
export PGPORT="${PGPORT:-5432}"
export LANG=C
export LC_ALL=C

LOGDIR=log

set -o pipefail

mkdir -p log
rm -f log/*

ulimit -c unlimited

echo "Creating databases"
for dbname in db1; do
    dropdb --if-exists $dbname
    createdb $dbname || exit 1
    psql -q -d $dbname -c "create extension pgq"
done

die() {
    echo $@
    exit 1
}

runtest() {
    local status

    printf "`date` running $1 ... "
    conf="${LOGDIR}/$1.ini"
    logfile="${LOGDIR}/$1.log"
    outfile="${LOGDIR}/$1.out"
    pidfile="${LOGDIR}/$1.pid"
    printf "[pgqd]\nlogfile=${logfile}\npidfile=${pidfile}\ncheck_period=3\nmaint_period=7\n" > "${conf}"
    eval "$1" "${conf}" "${logfile}" > ${outfile} 2>&1
    res=$?
    date >> ${outfile}
    if [ $res -eq 0 ]; then
        echo "ok"
    else
        echo "FAILED"
        cat ${outfile} | sed 's/^/out> /'
        if test -f "${logfile}"; then
            cat ${logfile} | sed 's/^/log> /'
        fi
    fi

    test -f "${pidfile}" && kill $(cat "${pidfile}")

    return $res
}

#
# testcases
#

test_version() {
    ln=$(${PGQD} -V)
    case "$ln" in
        *version*) res=0;;
        *) res=1;;
    esac
    return $res
}

test_show_ini() {
    ${PGQD} --ini | grep -q 'logfile'
    return $?
}

test_stop() {
    ${PGQD} -d $1 || return 1
    sleep 1
    ${PGQD} -s $1 || return 1
    sleep 1
    grep -q SIGINT $2
    return $?
}

test_reload() {
    ${PGQD} -d $1 || return 1
    sleep 1
    ${PGQD} -r $1 || return 1
    sleep 1
    grep -q SIGHUP $2
    res=$?
    ${PGQD} -s $1 || return 1
    sleep 1
    return $res
}

create_queue() {
    db="$1"
    qname="$2"
    psql -q -d "${db}" -c "select pgq.create_queue('${qname}')" \
        || die "queue creation failed"
    psql -q -d "${db}" -c "update pgq.queue set queue_rotation_period='10 seconds' where queue_name='${qname}'" \
        || die "queue setup failed"
}

test_ticker() {
    db="db1"
    qname="test1"
    create_queue "${db}" "${qname}"
    ${PGQD} -d "$1" || return 1
    sleep 3
    tick_id=$(psql -q -d "${db}" -At -c "select last_tick_id from pgq.get_queue_info('${qname}')")
    echo "tick_id=${tick_id}"
    test "${tick_id}" -gt 2 || return 1
    return 0
}

test_maint() {
    db="db1"
    qname="test2"
    create_queue "${db}" "${qname}"
    ${PGQD} -d "$1" || return 1
    sleep 15
    cur_tbl=$(psql -q -d "${db}" -At -c "select queue_cur_table from pgq.get_queue_info('${qname}')")
    echo "cur_tbl=${cur_tbl}"
    test "${cur_tbl}" -gt 0 || return 1
    return 0
}

testlist="
test_version
test_show_ini
test_stop
test_reload
test_ticker
test_maint
"

if [ $# -gt 0 ]; then
    testlist="$*"
fi

final=0
for testcase in $testlist; do
    runtest $testcase || final=1
done

exit $final

