# TimescaleDB Version Mismatch Experiment

Experiment with setup of multi-node TimescaleDB cluster when nodes have different PostgreSQL and TimescaleDB versions.

The idea of the experiment appeared after a question at the `PgConf 2021 Moscow` conference: 
> how to update PostgreSQL and TimescaleDB extension in a running distributed cluster?

Everything is running via Docker with official Docker image from Docker Hub: 
[https://hub.docker.com/r/timescale/timescaledb](https://hub.docker.com/r/timescale/timescaledb/)

Dockerfiles can be found on GitHub: [https://github.com/timescale/timescaledb-docker](https://github.com/timescale/timescaledb-docker)

For the latest version `2.5.0`, compatibility only works with the previous minor version `2.4.x`.
The main reason is breaking changes in internal API: 
`function _timescaledb_internal.create_chunk(unknown, unknown, unknown, unknown, unknown) does not exist`.
This means that upgrading versions in a cluster requires testing and checking for compatible versions each time.

---

Run TimescaleDB cluster with `docker-compose`:

```bash
$ docker-compose pull
$ docker-compose up -d
```

Than generate sample data:

```bash
$ docker exec -i pg_access_node /bin/sh < ./generate-data.sh
```

Now you can check that cluster works (connect via `psql`, `pgadmin` and so on to `access node`):

```sql
SELECT
  time_bucket('1 day', time) AS period,
  AVG(temperature) AS avg_temp,
  AVG(cpu) AS avg_cpu
FROM sensor_data
GROUP BY period;

SELECT
  time_bucket('1 day', time) AS period,
  AVG(temperature) AS avg_temp,
  last(temperature, time) AS last_temp,
  AVG(cpu) AS avg_cpu
FROM sensor_data
GROUP BY period;
```

---

```text
Generate sample data and check cluster status...
INSERT 0 4
WARNING:  remote PostgreSQL instance has an outdated timescaledb extension version
DETAIL:  Access node version: 2.5.0, remote version: 2.0.2.
ERROR:  [data_node_1]: function _timescaledb_internal.create_chunk(unknown, unknown, unknown, unknown, unknown) does not exist
HINT:  No function matches the given name and argument types. You might need to add explicit type casts.

---

Generate sample data and check cluster status...
INSERT 0 4
WARNING:  remote PostgreSQL instance has an outdated timescaledb extension version
DETAIL:  Access node version: 2.5.0, remote version: 2.1.1.
ERROR:  [data_node_1]: function _timescaledb_internal.create_chunk(unknown, unknown, unknown, unknown, unknown) does not exist
HINT:  No function matches the given name and argument types. You might need to add explicit type casts.

---

Generate sample data and check cluster status...
INSERT 0 4
WARNING:  remote PostgreSQL instance has an outdated timescaledb extension version
DETAIL:  Access node version: 2.5.0, remote version: 2.2.1.
ERROR:  [data_node_1]: function _timescaledb_internal.create_chunk(unknown, unknown, unknown, unknown, unknown) does not exist
HINT:  No function matches the given name and argument types. You might need to add explicit type casts.

---

Generate sample data and check cluster status...
INSERT 0 4
WARNING:  remote PostgreSQL instance has an outdated timescaledb extension version
DETAIL:  Access node version: 2.5.0, remote version: 2.3.1.
ERROR:  [data_node_1]: function _timescaledb_internal.create_chunk(unknown, unknown, unknown, unknown, unknown) does not exist
HINT:  No function matches the given name and argument types. You might need to add explicit type casts.

---

Generate sample data and check cluster status...
WARNING:  remote PostgreSQL instance has an outdated timescaledb extension version
DETAIL:  Access node version: 2.5.0, remote version: 2.4.0.
WARNING:  remote PostgreSQL instance has an outdated timescaledb extension version
DETAIL:  Access node version: 2.5.0, remote version: 2.4.2.
WARNING:  remote PostgreSQL instance has an outdated timescaledb extension version
DETAIL:  Access node version: 2.5.0, remote version: 2.4.1.
WARNING:  remote PostgreSQL instance has an outdated timescaledb extension version
DETAIL:  Access node version: 2.5.0, remote version: 2.4.2.
INSERT 0 892900
  node_name  |  owner   |                     options                     
-------------+----------+-------------------------------------------------
 data_node_1 | postgres | {host=pg_data_node_1,port=5432,dbname=postgres}
 data_node_2 | postgres | {host=pg_data_node_2,port=5432,dbname=postgres}
 data_node_3 | postgres | {host=pg_data_node_3,port=5432,dbname=postgres}
 data_node_4 | postgres | {host=pg_data_node_4,port=5432,dbname=postgres}
 data_node_5 | postgres | {host=pg_data_node_5,port=5432,dbname=postgres}
(5 rows)

 hypertable_schema | hypertable_name |  owner   | num_dimensions | num_chunks | compression_enabled | is_distributed | replication_factor |                          data_nodes                           | tablespaces 
-------------------+-----------------+----------+----------------+------------+---------------------+----------------+--------------------+---------------------------------------------------------------+-------------
 public            | sensor_data     | postgres |              2 |         25 | f                   | t              |                  1 | {data_node_1,data_node_2,data_node_3,data_node_4,data_node_5} | 
(1 row)

 hypertable_schema | hypertable_name | dimension_number | column_name |       column_type        | dimension_type | time_interval | integer_interval | integer_now_func | num_partitions 
-------------------+-----------------+------------------+-------------+--------------------------+----------------+---------------+------------------+------------------+----------------
 public            | sensor_data     |                1 | time        | timestamp with time zone | Time           | 7 days        |                  |                  |               
 public            | sensor_data     |                2 | sensor_id   | integer                  | Space          |               |                  |                  |              5
(2 rows)

 table_bytes | index_bytes | toast_bytes | total_bytes |  node_name  
-------------+-------------+-------------+-------------+-------------
    13041664 |    13811712 |           0 |    26853376 | data_node_5
     8216576 |    10354688 |           0 |    18571264 | data_node_1
           0 |       16384 |           0 |       16384 | 
     9273344 |     9781248 |           0 |    19054592 | data_node_4
    13590528 |    18120704 |           0 |    31711232 | data_node_2
    10354688 |    14884864 |           0 |    25239552 | data_node_3
(6 rows)
```
