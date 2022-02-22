#!/bin/bash
# PG autofailover HA cluster with HAproxy, Xinetd 
# Govind Sharma <govind_sharma@live.com>
# install xinetd package

echo "Xinetd Installation in progress..."    
dnf -y install xinetd &>/dev/null

#Script to check postgreSQL health
cat > /etc/xinetd.d/pg_node.sh << 'EOF'
#!/bin/bash
# This script checks if a postgres server is healthy running on localhost. It will return:
# Govind Sharma <Govind_sharma@live.com>

PGBIN=/usr/pgsql-14/bin
PGSQL_HOST="localhost"
PGSQL_PORT="5432"
PGSQL_DATABASE="postgres"
PGSQL_USERNAME="postgres"

# We perform a simple query that should return a few results
VALUE=`${PGBIN}/psql -t -h ${PGSQL_HOST} -U ${PGSQL_USERNAME} -p ${PGSQL_PORT} -c "select pg_is_in_recovery()" 2> /dev/null`

if [ $VALUE == "t" ]; then
    /bin/echo -e "HTTP/1.1 206 OK\r\n"
    /bin/echo -e "Content-Type: Content-Type: text/plain\r\n"
    /bin/echo -e "\r\n"
    /bin/echo "Standby"
    /bin/echo -e "\r\n"
elif [ $VALUE == "f" ]; then
    /bin/echo -e "HTTP/1.1 200 OK\r\n"
    /bin/echo -e "Content-Type: Content-Type: text/plain\r\n"
    /bin/echo -e "\r\n"
    /bin/echo "Primary"
    /bin/echo -e "\r\n"
else
    /bin/echo -e "HTTP/1.1 503 Service Unavailable\r\n"
    /bin/echo -e "Content-Type: Content-Type: text/plain\r\n"
    /bin/echo -e "\r\n"
    /bin/echo "DB Down"
    /bin/echo -e "\r\n"
fi
EOF

chmod +x /etc/xinetd.d/pg_node.sh

# to add port in services
bash -c 'echo "pgsqlchk         23260/tcp           #pgsqlchk" >> /etc/services'

# to create pg_check xinetd service 
cat > /etc/xinetd.d/pg_check << 'EOF' 
service pgsqlchk
{
    flags           = REUSE
    socket_type     = stream
    port            = 23260
    wait            = no
    user            = nobody
    server          = /etc/xinetd.d/pg_node.sh
    log_on_failure  += USERID
    disable         = no
    only_from       = 0.0.0.0/0
    per_source      = UNLIMITED
}
EOF

#add firewall entry
firewall-cmd --state &>/dev/null
if [ $? -eq 0 ]; then
    firewall-cmd --add-port=23260/tcp --permanent &>/dev/null
    firewall-cmd --reload &>/dev/null
fi

#Start xinetd service
sudo sudo systemctl restart 'xinetd.service' # use '--user' for user services
sudo systemctl enable 'xinetd.service' # use '--user' for user services

if curl --output /dev/null --silent --head --fail  http://127.0.0.1:23260; then
   echo 'Xinetd is OK!'
else 
   echo 'Xinetd is Failed!'
fi