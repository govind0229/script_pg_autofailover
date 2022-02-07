#!/bin/bash
#############################################################################
#   Script for setup pgautofailover with pg_autoctl extentions              #
#   Author: Govind Sharma <govind_sharma@live.com>                          #
#                     GNU GENERAL PUBLIC LICENSE                            #
#                        Version 3, 29 June 2007                            #
#                                                                           #    
#  Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>     #
#  Everyone is permitted to copy and distribute verbatim copies             #
#  of this license document, but changing it is not allowed.                #
#                                                                           #
#                             Preamble                                      #
#                                                                           #
#   The GNU General Public License is a free, copyleft license for          #
# software and other kinds of works.                                        #
#                                                                           #
#############################################################################
# Colors
C='\033[0m'
R='\033[0;31m'          
G='\033[0;32m'        
Y='\033[0;33m'

#Globle variable;
HOST_IP=$(ip route get 1 | sed 's/^.*src \([^ ]*\).*$/\1/;q')
PGPath='/var/lib/pgsql/'
PGCTL_Path='/usr/pgsql-14/bin/'

if [ -f ".env" ]; then
    source ./.env 
else
    echo "File \".env\" not exists"
fi

function Install(){    
  #checking package installed or not! 
  PG=$(dnf list installed  pg-auto-failover16_14.x86_64 | awk 'NR>1{print $1}');

    if [[ -z "${PG}" ]]; then
        echo -e "${Y}Citusdata.com repo and rpm installation in process...${C}" 
        curl https://install.citusdata.com/community/rpm.sh | sudo bash  &>/dev/null
        #curl -s https://packagecloud.io/install/repositories/citusdata/community/script.rpm.sh | sudo bash &>/dev/null
        sudo dnf -y install pg-auto-failover16_14.x86_64 &>/dev/null
    else
       echo -e "Package ${G}${PG}${C} is already installed."
       return 1
    fi
}

if [[ "$1" == "monitor" ]]; then
    
    Install
    URI=$(sudo -u postgres ${PGCTL_Path}pg_autoctl show uri --pgdata ${PGPath}${monitor_pgdata} | grep monitor | awk '{print $5}')
    
    if [[ -z "${URI}" ]]; then
        echo "empty string"
        rm -rvf ${PGPath}${monitor_pgdata} ${PGPath}.config ${PGPath}.local &>/dev/null
  
        if [ -d "${PGPath}" ]; then
            echo "directory \"${PGPath}\" exists"
        else 
            echo "drectory creating"   
            install -d ${PGPath}
            chown -R postgres:postgres ${PGPath}
        fi

        echo -e "${Y}Monitor HA node installation in progress...${C}"
        
        #enable firewall port with configured port
        systemctl restart firewalld.service &>/dev/null
        firewall-cmd --add-port="${monitor_port}"/tcp --permanent
        firewall-cmd --add-port="${monitor_port}"/udp --permanent
        firewall-cmd --reload

        #Create monitor database intence 
        sudo -u postgres ${PGCTL_Path}pg_autoctl  create monitor --auth trust --ssl-self-signed --pgdata ${PGPath}${monitor_pgdata} --hostname ${HOST_IP} --pgctl ${PGCTL_Path}pg_ctl --pgport ${monitor_port}

        #Create pgautodialover service file
        sudo -u postgres ${PGCTL_Path}pg_autoctl -q show systemd --pgdata ${PGPath}${monitor_pgdata} | tee /usr/lib/systemd/system/pgautofailover-monitor.service &>/dev/null

        #start pgautofailover server
        systemctl daemon-reload
        systemctl start 'pgautofailover-monitor.service'
        systemctl enable 'pgautofailover-monitor.service' 

        echo -e "${G}PG autofailover monitor setup completed!${C}"
    else
        echo -e "${G}Monitor is already exists:${C} ${URI}"
    fi
fi

if [[ "$1" == "node" ]]; then

    Install
    URI=$(sudo -u postgres "${PGCTL_Path}"pg_autoctl show uri --pgdata ${PGPath}"${nodes_pgdata}" | grep monitor | awk '{print $5}')
    
    if [[ -z "${URI}" ]]; then
        echo "empty string"
        #rm -rvf ${PGPath}"${nodes_pgdata}" ${PGPath}.config ${PGPath}.local &>/dev/null
  
        if [ -d "${PGPath}" ]; then
            echo "directory \"${PGPath}\" exists"
        else 
            echo "drectory creating"   
            install -d ${PGPath}
            chown -R postgres:postgres ${PGPath}
        fi
        
        #enable firewall port with configured port
        systemctl restart firewalld.service &>/dev/null
        firewall-cmd --add-port="${nodes_port}"/tcp --permanent
        firewall-cmd --add-port="${nodes_port}"/udp --permanent
        firewall-cmd --reload

        echo -e "${Y}Nodes HA node installation in progress...${C}"       
        sudo -u postgres "${PGCTL_Path}"pg_autoctl create postgres --auth trust --ssl-self-signed --pgdata=${PGPath}${nodes_pgdata} --hostname "${HOST_IP}" --monitor "$monitor_uri" --pgctl "${PGCTL_Path}"pg_ctl --pgport "${nodes_port}"

        #Create pgautodialover service file
        sudo -u postgres "${PGCTL_Path}"pg_autoctl -q show systemd --pgdata ${PGPath}"${nodes_pgdata}" | tee /usr/lib/systemd/system/pgautofailover-node.service &>/dev/null

        #start pgautofailover server
        sudo systemctl daemon-reload
        sudo systemctl start 'pgautofailover-node.service'
        sudo systemctl enable 'pgautofailover-node.service' # use '--user' for user services
        
        echo -e "${G}PG autofailover postgres setup completed!${C}"
    else
       echo  -e "${G}Pg_autoctl is already running${C}"
    fi
fi


if [ "$1" == "delete" ]; then 

    read -P "Are you sure, want to dete the nodes: [y/n]" item
    case "${item}" in
        y|Y)
        systemctl stop pgautofailover-* &>/dev/null
            rm -rvf ${PGPath}/* ${PGPath}.config ${PGPath}.local &>/dev/null
            rm -f /usr/lib/systemd/system/pgautofailover-* &>/dev/null
            echo -e "\n${R}Node deleted successfully!${C}\n"
        ;;
        N|n)
        echo 'God Decision!'
        ;;
        *)
            echo 'Opps!'
        ;;
    esac
fi

if [ "$1"   ==  "watch" ]; then
    if [ -d "${PGPath}${monitor_pgdata}" ]; then
        sudo -u postgres ${PGCTL_Path}pg_autoctl show state --watch --pgdata ${PGPath}${monitor_pgdata}
    else
        sudo -u postgres ${PGCTL_Path}pg_autoctl show state --pgdata ${PGPath}${nodes_pgdata}
    fi
fi

if [[ -z "$1" ]]; then
    echo -e "\nUsage: $0 [monitor|node|delete|watch]\n"
    echo -e "monitor    -- Create a cluster monitor using $0 monitor."
    echo -e "node       -- Create a cluster nodes using $0 node."
    echo -e "delete     -- Delete pg_autoctl Cluster instances."
    echo -e "watch      -- Show cluster nodes state.\n"
fi
