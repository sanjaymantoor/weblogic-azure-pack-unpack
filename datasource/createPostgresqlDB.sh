#!/bin/bash

function usage()
{
  echo "$0 <RG_NAME> <DB_NAME>"
  echo "Example: $0 rg_postgresql_test myPGSQLDB"
  exit 1
}

function check_current_shell()
{
   if [ ${_} == ${1} ];
    then
       echo "Invalid command: Please use . $0 "
       echo "On Successful execution, the following environment variables will be set with Postgresql DB parameters"
       echo "DB_PUBLIC_HOSTNAME"
       echo "DB_USERNAME"
       echo "DB_PASSWD"
       echo "DB_PORT"
       echo "DB_JDBC_URL"
       exit 1
    fi
}

function validate_args()
{
    if [ $# != 2 ];
    then
      usage;
    fi

    RG_NAME="$1"
    DB_NAME="$2"

    if [[ ${DB_NAME} =~ ^[a-zA-Z]+$ ]]
    then
       n=${#DB_NAME}
       if [ $n -gt 12 ];
       then
           echo "Invalid DB_NAME DB_NAME has to be a string containing only alphabets with maximum of 12 characters"
           exit 1
       fi
    else
       echo "Invalid DB_NAME. DB_NAME has to be a string containing only alphabets with maximum of 12 characters"
       exit 1
    fi

    NEW_UUID=$(cat /dev/urandom | tr -dc 'a-z' | fold -w 4 | head -n 1)
    DB_NAME="${DB_NAME,,}"
    DB_SERVER="${NEW_UUID}${DB_NAME}server"
}

function create_resource_group()
{
    echo "creating resource group ${RG_NAME}"
    az group create --name ${RG_NAME} --location ${LOCATION}

    if [ "$?" != 0 ];
    then
     echo "Failure !! Error while creating resource group ${RG_NAME}"
     exit 1
    fi

}

function create_postgresql_db_server()
{
    echo "creating Postgresql DB Server ${DB_SERVER} in resource group ${RG_NAME}"
    echo az postgres flexible-server create \
							--resource-group ${RG_NAME} \
						 	--name ${DB_SERVER} \
						 	--location "${LOCATION}" \
						 	--version 14 \
						 	--admin-user ${DB_USERNAME} \
						 	--admin-password ${DB_PASSWD} \
						 	 --sku-name Standard_D2s_v3 \
						 	 --public-access All
						 	 
	az postgres flexible-server create \
							--resource-group ${RG_NAME} \
						 	--name ${DB_SERVER} \
						 	--location "${LOCATION}" \
						 	--version 14 \
						 	--admin-user ${DB_USERNAME} \
						 	--admin-password ${DB_PASSWD} \
						 	 --sku-name Standard_D2s_v3 \
						 	 --public-access All

    if [ "$?" != 0 ];
    then
     echo "Failure !! Error while creating Postgresql Database Server ${DB_SERVER}" 
     exit 1
    fi

  	DB_PUBLIC_HOSTNAME=$(az postgres flexible-server list --resource-group ${RG_NAME} -o json | grep pgsql12345 | head -1| cut -f2 -d":")
    echo "DB_PUBLIC_HOSTNAME: $DB_PUBLIC_HOSTNAME"

}

function configure_firewall_for_db_server()
{
    echo "configuring firewall for postgresql db server"
    RESULT=$(az postgres flexible-server firewall-rule create --resource-group ${RG_NAME} --name ${DB_SERVER} --rule-name allowip --start-ip-address $START_IP --end-ip-address $END_IP)

    if [ "$?" != 0 ];
    then
     echo "Failure !! Error while configuring firewall rules on Postgresql Database Server ${DB_SERVER} for opending db ports"
     exit 1
    fi

    echo "$RESULT"
}

function export_db_details_as_env_variables()
{
   sleep 10s
   
   export DB_PUBLIC_HOSTNAME="${DB_PUBLIC_HOSTNAME}"
   export DB_USERNAME="${DB_USERNAME}@${DB_SERVER}"
   export DB_PASSWD="${DB_PASSWD}"
   export DB_PORT="${DB_PORT}"
   export DB_JDBC_URL="jdbc:postgresql://${DB_PUBLIC_HOSTNAME}:${DB_PORT}/postgres;user=${DB_USERNAME}@${DB_SERVER}"
   export DB_NAME="postgres"

   echo "Use the following environment variables to connect to the oracle DB"
   echo "DB_NAME"
   echo "DB_PUBLIC_HOSTNAME"
   echo "DB_USERNAME"
   echo "DB_PASSWD"
   echo "DB_PORT"
   echo "DB_JDBC_URL"

}

#main

check_current_shell "${0}"

LOCATION="eastus"
DB_USERNAME="weblogicdb"
DB_PASSWD="Weblogic5678"
START_IP="0.0.0.0"
DB_PORT="5432"
END_IP="0.0.0.0"

validate_args "$@"

start=$(date +%s)

create_resource_group

create_postgresql_db_server

configure_firewall_for_db_server

export_db_details_as_env_variables

