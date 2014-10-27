#!/bin/sh

echo "Boostrap postgres"
export PG_DB_USER=osmuser
export PG_DB_PASS=osmpass
export PG_DB_NAME=osm
export PG_VERSION=9.3

db_usage(){
    echo "Postgres DB accessible on:"
    echo "Port: 5432"
    echo "User: $PG_DB_USER"
    echo "Password: $PG_DB_PASS"
    echo "DB: $PG_DB_NAME"
}

db_install_postgres(){
    echo "Installing PG Routing and Postgis"
    sudo apt-add-repository -y ppa:georepublic/pgrouting
    sudo apt-get update -y -m
    sudo apt-get -y install postgresql-$PG_VERSION postgresql-$PG_VERSION-postgis-2.1 postgresql-contrib postgresql-$PG_VERSION-pgrouting
    echo "Updating pg_hba.conf to allow access postgres version $PG_VERSION"
    sudo sed -i "s/\#listen_addresses \=.*/listen_addresses ='10.0.0.4'/" /etc/postgresql/$PG_VERSION/main/postgresql.conf
}

db_create_db(){
    echo "Create user $PG_DB_USER"
    sudo -H -u postgres bash -c "createuser --no-superuser --no-createdb --no-createrole $PG_DB_USER"
    echo "Creating $PG_DB_NAME DB"
    sudo -H -u postgres bash -c "createdb --owner=$PG_DB_USER $PG_DB_NAME"
    echo "Creating password for osmuser user to osmpass"
    sudo -H -u postgres bash -c "psql --dbname $PG_DB_NAME --command=\"ALTER ROLE $PG_DB_USER WITH PASSWORD '$PG_DB_PASS'\""
    echo "Adding postgis extensions"
    sudo -H -u postgres bash -c "psql --dbname $PG_DB_NAME --command=\"CREATE EXTENSION postgis\""
    sudo -H -u postgres bash -c "psql --dbname $PG_DB_NAME --command=\"CREATE EXTENSION postgis_topology\""
    echo allow access to postgres $PG_VERSION
    sudo -H -E -u postgres bash -c 'echo "hostssl    $PG_DB_NAME      $PG_DB_USER             0.0.0.0/0          password" >> "/etc/postgresql/${PG_VERSION}/main/pg_hba.conf"'
}

db_clear_exports(){
    unset PG_DB_USER
    unset PG_DB_PASS
    unset PG_DB_NAME
    unset PG_VERSION
}

export PROVISIONED_ON=/etc/vm_provision_on_timestamp

if [ -f "$PROVISIONED_ON" ]
then
    echo "VM was already provisioned at: $(cat $PROVISIONED_ON)"
    echo "To run system updates manually login via 'vagrant ssh' and run 'apt-get update && apt-get upgrade'"
    echo ""
    db_usage
    exit
fi

#Install and setup
db_install_postgres
db_create_db
db_usage
db_clear_exports

# Tag the provision time:
sudo -E date > "$PROVISIONED_ON"
