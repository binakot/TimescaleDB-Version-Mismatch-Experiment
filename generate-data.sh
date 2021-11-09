#!/bin/sh
set -e

echo "Generate sample data and check cluster status..."
psql -v ON_ERROR_STOP=1 -h pg_access_node -U "$POSTGRES_USER" <<-EOSQL

INSERT INTO sensor_data (time, sensor_id, cpu, temperature)
SELECT
  time,
  sensor_id,
  random() AS cpu,
  random()*100 AS temperature
FROM generate_series(now() - interval '1 month', now(), interval '5 minute') AS g1(time), generate_series(1,100,1) AS g2(sensor_id);

SELECT * FROM timescaledb_information.data_nodes;
SELECT * FROM timescaledb_information.hypertables;
SELECT * FROM timescaledb_information.dimensions;
SELECT * FROM hypertable_detailed_size('sensor_data');

EOSQL
