# script_pg_autofailover for installation monitor and nodes instances 

## - New changes details;
Added host_IP for setup monitor and nodes instances.
Added Postgres port for monitor and node instances.
Added firewall according to setup monitor and nodes port in .env file.
Remove Option list for installing pg_auto_failover rpm in the machine.
Added Automatically check and install the latest pg_auto_failover rpm in the machine.
Added pgautofailover.server name with pgautofailover-monitor.service/pgautofailover-node.service. for run monitor and node instances on a single machine.

## Steps;
- edit .env file and update monitor variables with your current running machine.
monitor_address - update with a current running machine IP address. like '192.168.0.1'
monitor_port - if you are required to run monitor and node instance on the same machine, in this case, you need to set the port, default Postgres port is '5432' [it's only applicable for the testing environment]
monitor_uri - don't change it.
after setup .env file run below command to setup monitor instance. 

pg-auto-failover.sh comes with the below options; to create monitor and node instances;
monitor    -- Create a cluster monitor using ./pg-auto-failover.sh monitor.
node       -- Create a cluster nodes using ./pg-auto-failover.sh node.
delete     -- Delete pg_autoctl Cluster instances.
watch      -- Show cluster nodes state.

on the monitor machine;
- #sh pg-auto-failover.sh monitor - [ It will automatically install the latest version of pg_autofailover rpm and set up monitor instance.]

after completing the monitor instance copy the "script_pg_autofailover"  folder on nodes machines and run the below command for setup 
- #sh pg-auto-failover.sh node - [  It will automatically install the latest version of pg_autofailover rpm and set up node instance.]
