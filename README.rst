
====
pgqd
====

--------------------------
Maintenance daemon for PgQ
--------------------------

:Manual section: 1

Synopsis
========

pgqd [-qvd] config

pgqd [-skr] config

pgqd --ini|-h|-V

Description
===========

Runs both ticker and periodic maintenence for all
databases in one PostgreSQL cluster.

Options
=======

-q      Do not log to stdout
-v      Verbose log
-d      Daemonize process
-s      Send SIGINT to running process to stop it
-k      Send SIGTERM to running process to stop it
-r      Send SIGHUP to running process to reload config
-h      Show help
-V      Show version
--ini   Show sample config

Configuration
=============

Config uses `ini` file syntax::

    [pgqd]
    logfile = ~/log/pgqd.log
    pidfile = ~/pid/pgqd.pid

Options:

logfile
    Filename to log to.
    Default: empty.

pidfile
    Filename to store pid, required when daemonizing.
    Default: empty.

base_connstr
    Connect string without dbname=
    Default: empty.

initial_database
    Startup db to query other databases.
    Default: template1

database_list
    Limit ticker to specific databases.
    Default: empty, which means all database.

syslog
    Whether to log into syslog.
    Default: 1

syslog_ident
    Name to use for syslog.
    Default: pgqd

check_period
    How often to check for new databases, in seconds.
    Default: 60.

retry_period
    How often to flush retry queue, in seconds.
    Default: 30

maint_period
    How often to do maintentance, in seconds.
    Default: 120

ticker_period
    How often to run ticker, in seconds.
    Default: 1


Install
=======

pgqd uses autoconf based build system::

    ./configure --prefix=/opt
    make
    make install

Dependencies: libevent, python3-docutils

