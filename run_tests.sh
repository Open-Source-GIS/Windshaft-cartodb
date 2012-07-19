#!/bin/sh

cleanup() {
	echo "Cleaning up"
	kill ${PID_REDIS}
}

cleanup_and_exit() {
	cleanup
	exit
}

die() {
	msg=$1
	echo "${msg}" >&2
	cleanup
	exit 1
}

trap 'cleanup_and_exit' 1 2 3 5 9 13

TESTENV=config/environments/test.js
REDIS_CONF=`cat ${TESTENV} | sed -n '1h;1!H;${g;s/.*,redis: {\([^}]*\)}.*/\1/;p}'`
# echo "REDIS_CONF: $REDIS_CONF"
REDIS_PORT=`echo $REDIS_CONF | sed "s/.*port: \([^,$]*\).*/\1/"`
test -n "$REDIS_PORT" || die "Failed reading redis port from $TESTENV"

echo "Starting redis on port ${REDIS_PORT}"
echo "port ${REDIS_PORT}" | redis-server - > test.log &
PID_REDIS=$!

echo "Preparing the database"
cd test/support; sh prepare_db.sh || die "database preparation failure (see test.log)"; cd -;

PATH=node_modules/.bin/:$PATH

echo "Running tests"
mocha -u tdd \
  test/unit/cartodb/redis_pool.test.js \
  test/unit/cartodb/req2params.test.js \
  test/acceptance/cache_validator.js \
  test/acceptance/server.js


cleanup
