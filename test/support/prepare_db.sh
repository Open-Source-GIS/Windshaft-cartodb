#!/bin/sh

# this script prepare database and redis instance to run accpetance test
#
# NOTE: assumes existance of a "template_postgis"
# NOTE2: use PG_* environment variables for authentication
#
# NOTE3: a side effect of the db preparation is the persistent creation
#        of two database roles which will be valid for the whole cluster
#        TODO: fix that
#

die() {
        msg=$1
        echo "${msg}" >&2
        exit 1
}

# This is the test database we create
TEST_DB="cartodb_test_user_1_db"

# This is where postgresql and redis parameters are read from
TESTENV=../../config/environments/test.js

PGSQL_CONF=`cat ${TESTENV} | sed -n '1h;1!H;${g;s/.*,postgres: {\([^}]*\)}.*/\1/;p}'`
#echo "PGSQL_CONF: " $PGSQL_CONF
#PGUSER=`echo $PGSQL_CONF | sed "s/.*user: '\([^']*\)'.*/\1/"`
#echo "PGUSER: [$PGUSER]"
PGHOST=`echo $PGSQL_CONF | sed "s/.*host: '\([^']*\)'.*/\1/"`
echo "PGHOST: [$PGHOST]"
PGPORT=`echo $PGSQL_CONF | sed "s/.*port: \([^,$]*\).*/\1/"`
echo "PGPORT: [$PGPORT]"

export PGHOST PGPORT

echo "preparing postgres..."
dropdb "${TEST_DB}"
createdb -Ttemplate_postgis -EUTF8 "${TEST_DB}" || die "Could not create test database"
psql "${TEST_DB}" < ./sql/windshaft.test.sql
psql "${TEST_DB}" < ./sql/gadm4.sql

REDIS_CONF=`cat ${TESTENV} | sed -n '1h;1!H;${g;s/.*,redis: {\([^}]*\)}.*/\1/;p}'`
# echo "REDIS_CONF: $REDIS_CONF"
REDIS_PORT=`echo $REDIS_CONF | sed "s/.*port: \([^,$]*\).*/\1/"`
echo "REDIS_PORT: [$REDIS_PORT]"

echo "preparing redis..."
echo "HSET rails:users:localhost id 1" | redis-cli -p ${REDIS_PORT} -n 5
echo 'HSET rails:users:localhost database_name "'"${TEST_DB}"'"' | redis-cli -p ${REDIS_PORT} -n 5
echo "SADD rails:users:localhost:map_key 1234" | redis-cli -p ${REDIS_PORT} -n 5
echo 'HSET rails:'"${TEST_DB}"':my_table infowindow "this, that, the other"' | redis-cli -p ${REDIS_PORT} -n 0


echo "Finished preparing data. Run tests with mocha."
