#! /bin/bash

set -x
set -e

# This script expects the following environment variables to be set:
#
#  - PGCOPYDB_SOURCE_PGURI
#  - PGCOPYDB_TARGET_PGURI
#  - PGCOPYDB_TABLE_JOBS
#  - PGCOPYDB_INDEX_JOBS

# make sure source and target databases are ready
pgcopydb ping 

# copying roles needs superuser
# and we use the postgres database here still
pgcopydb copy roles 

psql -o /tmp/c.out -d ${PGCOPYDB_SOURCE_PGURI} -1 -f /usr/src/pgcopydb/rides.sql

copy="\COPY rides FROM nyc_data_rides.10k.csv CSV"
psql -d ${PGCOPYDB_SOURCE_PGURI} -1 -c "${copy}"

# take a snapshot using role tsdb on source database
coproc ( pgcopydb snapshot --debug )

sleep 1

# copy the extensions separately, needs superuser (both on source and target)
pgcopydb copy extensions

# now clone with superuser privileges, seems to be required for timescaledb
pgcopydb clone --skip-extensions --debug

kill -TERM ${COPROC_PID}
wait ${COPROC_PID}

s=/tmp/fares.out
t=/tmp/fares.out
psql -o $s -d ${PGCOPYDB_SOURCE_PGURI} -f /usr/src/pgcopydb/fares.sql
psql -o $t -d ${PGCOPYDB_TARGET_PGURI} -f /usr/src/pgcopydb/fares.sql

diff $s $t
