# ProxySQL + MySQL + Prometheus + Grafana using Docker

![Blank Diagram](https://user-images.githubusercontent.com/13511520/83347412-e2c4f280-a35f-11ea-8048-2b0645e99245.png)

## Configuration

- ProxySQL
   - `:6032` (admin, `user`: admin2, `pass`: pass2)
   - `:6033` (MySQL endpoint, `user`: root, `pass`: password)

- MySQL replication
  - master x 1
  - slave x 2
  - `user`: root, `pass`: password

- Prometheus
  - `:9090`
  - using `msqld-exporter` to obtain mysql metrics

- Grafana
  - `:3000`
  - `id`: admin
  - `password`: admin


## Getting Started

```
docker-compose up -d
```

```
                      Name                                     Command               State                       Ports
-------------------------------------------------------------------------------------------------------------------------------------------
proxysql-mysql-replication-master                   docker-entrypoint.sh mysqld      Up      0.0.0.0:3306->3306/tcp, 33060/tcp
proxysql-mysql-replication-mysqld-exporter-master   /bin/mysqld_exporter             Up      0.0.0.0:9104->9104/tcp
proxysql-mysql-replication-mysqld-exporter-slave1   /bin/mysqld_exporter             Up      0.0.0.0:9105->9104/tcp
proxysql-mysql-replication-mysqld-exporter-slave2   /bin/mysqld_exporter             Up      0.0.0.0:9106->9104/tcp
proxysql-mysql-replication-proxysql                 proxysql -f -D /var/lib/pr ...   Up      0.0.0.0:6032->6032/tcp, 0.0.0.0:6033->6033/tcp
proxysql-mysql-replication-slave1                   docker-entrypoint.sh mysqld      Up      0.0.0.0:3307->3306/tcp, 33060/tcp
proxysql-mysql-replication-slave2                   docker-entrypoint.sh mysqld      Up      0.0.0.0:3308->3306/tcp, 33060/tcp
proxysql-mysql-replication_grafana_1                /run.sh                          Up      0.0.0.0:3000->3000/tcp
proxysql-mysql-replication_prometheus_1             /bin/prometheus --config.f ...   Up      0.0.0.0:9090->9090/tcp
```

## Check status

- MySQL master

    ```
    $ docker-compose exec mysql-master sh -c "export MYSQL_PWD=password; mysql -u root sbtest -e 'show master status\G'"
    ```

- MySQL slave
    
    If slave fails to connect master, remove `{master,slave}/data` and restart master, then restart slave.

    ```
    $ docker-compose exec mysql-slave1 sh -c "export MYSQL_PWD=password; mysql -u root sbtest -e 'show slave status\G'"
    ```


- ProxySQL

  ```
  $ mysql -h 0.0.0.0 -P 6032 -u admin2 -p -e 'select * from mysql_servers'
  Enter password:
  +--------------+--------------+------+-----------+--------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
  | hostgroup_id | hostname     | port | gtid_port | status | weight | compression | max_connections | max_replication_lag | use_ssl | max_latency_ms | comment |
  +--------------+--------------+------+-----------+--------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
  | 10           | mysql-master | 3306 | 0         | ONLINE | 1      | 0           | 100             | 5                   | 0       | 0              |         |
  | 20           | mysql-slave1 | 3306 | 0         | ONLINE | 1      | 0           | 100             | 5                   | 0       | 0              |         |
  | 20           | mysql-slave2 | 3306 | 0         | ONLINE | 1      | 0           | 100             | 5                   | 0       | 0              |         |
  +--------------+--------------+------+-----------+--------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
  ```

## Run sysbench

1. prepare test data

```shell
❯ sysbench --db-driver=mysql \
        --mysql-host=0.0.0.0 \
        --mysql-port=6033 \
        --mysql-user=root \
        --mysql-password=password \
        --mysql-db=sbtest \
        --threads=10 \
        --tables=10 \
        --table-size=10000 \
        oltp_read_only \
        prepare
```

2. run benchmark

```shell
❯ sysbench --db-driver=mysql \
        --mysql-host=0.0.0.0 \
        --mysql-port=6033 \
        --mysql-user=root \
        --mysql-password=password \
        --mysql-db=sbtest \
        --threads=100 \
        --time=120 \
        oltp_read_only \
        run
```


## View DB metrics on Graphana

  1. Access `localhost:3000` and login. (`id`: admin, `pass`: admin)
  2. Go `Configuration > Add data source`
  3. Add Prometheus. (`URL`: http://prometheus:9090)
  4. Go `Create > Import` and import [MySQL Overview](https://github.com/percona/grafana-dashboards/blob/master/dashboards/MySQL_Overview.json) json.
  5. Go `Dashboards > Home > MysQL Overview`


  ![1 initial-status](https://user-images.githubusercontent.com/13511520/83347808-86170700-a362-11ea-98da-9b5f21db7ee7.png)
