# `Pg_autofailover` for installation monitor and nodes instances with `Xinetd`

## New changes details;

- Added `host_IP` for setup monitor and nodes instances.

- Added Postgres `port` for monitor and node instances.

- Added `firewall` according to setup monitor and nodes port in `.env` file.

- Remove Option list for installing `pg_auto_failover` rpm in the machine.

- Added Automatically check and install the latest `pg_auto_failover` rpm in the machine.

- Added ``pgautofailover`` service file name manage with like below to  run monitor and node instances on a single machine.

        monitor - pgautofailover-monitor.service
        node    - pgautofailover-node.service

## Steps;

- edit `.env` file and update monitor variables with your current running machine.

- `monitor_address` - update with a current running machine IP address. like '192.168.0.1'

- `monitor_port` - if you are required to run monitor and node instance on the same machine, in this case, you need to set monitor node port, like `5434` [ it's only applicable for the testing environment ]

- Default PostgreSQL port is `5432` 

- `monitor_uri` - don't change it.

- after setup .env file run below command to setup monitor instance. 


#### `pg-auto-failover.sh` script comes with the below options; to create monitor and node instances;

    monitor    -- Create a cluster monitor using `./pg-auto-failover.sh monitor`.

    node       -- Create a cluster nodes using `./pg-auto-failover.sh node`.

    delete     -- Delete pg_autoctl Cluster instances.

    watch      -- Show cluster nodes state.


##### On the monitor machine; 

- [ It will automatically install the latest version of pg_autofailover rpm and set up monitor instance.]

```sh
    ./pg-auto-failover.sh monitor 
```
    
##### After completing the monitor instance copy the "script_pg_autofailover"  folder on nodes machines and run the below command for setup 
 
 - [  It will automatically install the latest version of pg_autofailover package and set up node instance.]

```sh
    ./pg-auto-failover.sh node
```

### For verifying the cluster to run watch on monitor node

```sh
    ./pg-auto-failover.sh watch
```

### Xinetd Installation script for Haproxy monitor nodes status

- In computer networking, xinetd (Extended Internet Service Daemon) is an open-source super-server daemon that manages Internet-based connectivity on numerous Unix-like platforms.
It is a more secure alternative to inetd ("the Internet daemon").

- Details;

        Package -   xinetd 
        Port    -   23260/tcp

