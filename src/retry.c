
#include "pgqd.h"


static void close_retry(struct PgDatabase *db, double sleep_time)
{
	log_debug("%s: close_retry, %f", db->logname, sleep_time);
	pgs_reconnect(db->c_retry, sleep_time);
}

static void run_retry(struct PgDatabase *db)
{
	const char *q = "select * from pgq.maint_retry_events()";
	log_debug("%s: %s", db->logname, q);
	pgs_send_query_simple(db->c_retry, q);
}

static void parse_retry(struct PgDatabase *db, PGresult *res)
{
	if (PQntuples(res) == 1) {
		char *val = PQgetvalue(res, 0, 0);
		stats.n_retry += atoi(val);
		if (strcmp(val, "0") != 0) {
			run_retry(db);
			return;
		}
	}
	close_retry(db, cf.retry_period);
}

static void retry_handler(struct PgSocket *s, void *arg, enum PgEvent ev, PGresult *res)
{
	struct PgDatabase *db = arg;

	switch (ev) {
	case PGS_CONNECT_OK:
		log_debug("%s: starting retry event processing", db->logname);
		run_retry(db);
		break;
	case PGS_RESULT_OK:
		if (PQresultStatus(res) != PGRES_TUPLES_OK)
			close_retry(db, 20);
		else
			parse_retry(db, res);
		break;
	case PGS_TIMEOUT:
		log_debug("%s: retry timeout", db->logname);
		launch_retry(db);
		break;
	default:
		log_warning("%s: default reconnect", db->logname);
		pgs_reconnect(db->c_retry, 30);
		break;
	}
}

void launch_retry(struct PgDatabase *db)
{
	char *cstr;
	if (db->c_retry) {
		log_debug("%s: retry already initialized", db->logname);
	} else {
		log_debug("%s: launch_retry", db->logname);
		cstr = make_connstr(db->name);
		if (!cstr) {
			log_error("make_connstr: %s", strerror(errno));
			return;
		}
		db->c_retry = pgs_create(cstr, retry_handler, db, ev_base);
		free(cstr);
		if (!db->c_retry) {
			log_error("pgs_create: %s", strerror(errno));
			return;
		}
	}
	pgs_connect(db->c_retry);
}

