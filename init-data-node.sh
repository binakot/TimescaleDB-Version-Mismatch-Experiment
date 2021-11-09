#!/bin/sh
set -e

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -c "SHOW config_file"
sed -ri "s!^#?(max_prepared_transactions)\s*=.*!\1 = 150!" /var/lib/postgresql/data/postgresql.conf
grep "max_prepared_transactions" /var/lib/postgresql/data/postgresql.conf
sed -ri "s!^#?(statement_timeout)\s*=.*!\1 = 0!" /var/lib/postgresql/data/postgresql.conf
grep "statement_timeout" /var/lib/postgresql/data/postgresql.conf
