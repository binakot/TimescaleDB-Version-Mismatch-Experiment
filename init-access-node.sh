#!/bin/sh
set -e

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -c "SHOW config_file"
sed -ri "s!^#?(enable_partitionwise_aggregate)\s*=.*!\1 = on!" /var/lib/postgresql/data/postgresql.conf
grep "enable_partitionwise_aggregate" /var/lib/postgresql/data/postgresql.conf
sed -ri "s!^#?(jit)\s*=.*!\1 = off!" /var/lib/postgresql/data/postgresql.conf
grep "jit" /var/lib/postgresql/data/postgresql.conf

echo "Waiting for data nodes..."
until PGPASSWORD=$POSTGRES_PASSWORD psql -h pg_data_node_1 -U "$POSTGRES_USER" -c '\q'; do
    sleep 5s
done
until PGPASSWORD=$POSTGRES_PASSWORD psql -h pg_data_node_2 -U "$POSTGRES_USER" -c '\q'; do
    sleep 5s
done
until PGPASSWORD=$POSTGRES_PASSWORD psql -h pg_data_node_3 -U "$POSTGRES_USER" -c '\q'; do
    sleep 5s
done
until PGPASSWORD=$POSTGRES_PASSWORD psql -h pg_data_node_4 -U "$POSTGRES_USER" -c '\q'; do
    sleep 5s
done
until PGPASSWORD=$POSTGRES_PASSWORD psql -h pg_data_node_5 -U "$POSTGRES_USER" -c '\q'; do
    sleep 5s
done

echo "Connect data nodes to cluster and create distributed hypertable..."
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" <<-EOSQL

SELECT * FROM add_data_node('data_node_1', host => 'pg_data_node_1');
SELECT * FROM add_data_node('data_node_2', host => 'pg_data_node_2');
SELECT * FROM add_data_node('data_node_3', host => 'pg_data_node_3');
SELECT * FROM add_data_node('data_node_4', host => 'pg_data_node_4');
SELECT * FROM add_data_node('data_node_5', host => 'pg_data_node_5');

CREATE TABLE sensor_data (
  time TIMESTAMPTZ NOT NULL,
  sensor_id INTEGER,
  temperature DOUBLE PRECISION,
  cpu DOUBLE PRECISION
);

SELECT * FROM create_distributed_hypertable('sensor_data', 'time', 'sensor_id');

EOSQL
