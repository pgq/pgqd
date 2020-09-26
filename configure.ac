dnl Process this file with autoconf to produce a configure script.

AC_INIT(pgqd, 3.4rc1)
AC_CONFIG_SRCDIR(src/pgqd.c)
AC_CONFIG_HEADER(lib/usual/config.h)
AC_PREREQ([2.59])

dnl Find PostgreSQL pg_config
AC_ARG_WITH(pgconfig, [  --with-pgconfig=PG_CONFIG    path to pg_config (default: pg_config)],
[ AC_MSG_CHECKING(for pg_config)
  PG_CONFIG=$withval
  AC_MSG_RESULT($PG_CONFIG)],
[ AC_PATH_PROGS(PG_CONFIG, pg_config) ])
test -n "$PG_CONFIG" || AC_MSG_ERROR([Cannot continue without pg_config])

AC_USUAL_PORT_CHECK
AC_USUAL_PROGRAM_CHECK
AC_USUAL_HEADER_CHECK
AC_USUAL_TYPE_CHECK
AC_USUAL_FUNCTION_CHECK

dnl Postres headers on Solaris define incompat unsetenv without that
AC_CHECK_FUNCS(unsetenv)

dnl Require libevent
PKG_PROG_PKG_CONFIG
PKG_CHECK_MODULES(LIBEVENT, [libevent >= 2.0], [
CFLAGS="${CFLAGS} ${LIBEVENT_CFLAGS}"
LIBS="${LIBS} ${LIBEVENT_LIBS}"
], [AC_MSG_ERROR([pgqd requires libevent >= 2.0])])

dnl Needed on SmartOS (Solaris)
AC_SEARCH_LIBS([socket],[socket])

AC_USUAL_DEBUG
AC_USUAL_CASSERT

dnl Write result
AC_CONFIG_FILES([config.mak])
AC_OUTPUT
