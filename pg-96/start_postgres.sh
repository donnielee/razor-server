#!/bin/bash

#DB_NAME=${POSTGRES_DB:-}
#DB_USER=${POSTGRES_USER:-}
#DB_PASS=${POSTGRES_PASSWORD:-}
DB_NAME="razor_prd"
DB_USER="postgres"
DB_PASS="cloud000@"
PG_CONFDIR="/var/lib/pgsql/data"

__create_user() {
  #Grant rights

  #echo create user params:
  echo $DB_NAME
  echo $DB_USER
  echo $DB_PASS

  usermod -G wheel postgres

  # Check to see if we have pre-defined credentials to use
if [ -n "${DB_USER}" ]; then
  if [ -z "${DB_PASS}" ]; then
    echo ""
    echo "WARNING: "
    echo "No password specified for \"${DB_USER}\". Generating one"
    echo ""
    DB_PASS=$(pwgen -c -n -1 12)
    echo "Password for \"${DB_USER}\" created as: \"${DB_PASS}\""
  fi
    echo "Creating user \"${DB_USER}\"..."
    echo "CREATE ROLE ${DB_USER} with CREATEROLE login superuser PASSWORD '${DB_PASS}';" |
      sudo -u postgres -H /usr/pgsql-9.6/bin/postgres --single \
       -c config_file=${PG_CONFDIR}/postgresql.conf -D ${PG_CONFDIR}
  
fi

if [ -n "${DB_NAME}" ]; then
  echo "Creating database \"${DB_NAME}\"..."
  echo "CREATE DATABASE ${DB_NAME};" | \
    sudo -u postgres -H /usr/pgsql-9.6/bin/postgres --single \
     -c config_file=${PG_CONFDIR}/postgresql.conf -D ${PG_CONFDIR}

  if [ -n "${DB_USER}" ]; then
    echo "Granting access to database \"${DB_NAME}\" for user \"${DB_USER}\"..."
    echo "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} to ${DB_USER};" |
      sudo -u postgres -H /usr/pgsql-9.6/bin/postgres --single \
      -c config_file=${PG_CONFDIR}/postgresql.conf -D ${PG_CONFDIR}
  fi
fi
}


#__run_supervisor() {
#supervisord -n
#}

__run (){
 #echo configure pg_hba.conf:
 # not needet - done in dockerfile
 #sed -i -e 's/ident/trust/g' /var/lib/pgsql/data/pg_hba.conf
 #sed -i -e 's/md5/trust/g' /var/lib/pgsql/data/pg_hba.conf
 #sed -i -e 's/peer/trust/g' /var/lib/pgsql/data/pg_hba.conf

echo "export PGDATA=/var/lib/pgsql/data" >> /var/lib/pgsql/.pgsql_profile
mkdir -p /var/lib/pgsql/9.6/data
chmod 775 /var/lib/pgsql/9.6/data /var/lib/pgsql/9.6/data/*
cp /var/lib/pgsql/data/pg_hba.conf /var/lib/pgsql/9.6/data/pg_hba.conf
sed -i '1s/^/host  all   all 0.0.0.0\/0  trust\n/' /var/lib/pgsql/data/pg_hba.conf
sed -i '1s/^/host  all   all 0.0.0.0\/0  trust\n/' /var/lib/pgsql/9.6/data/pg_hba.conf
chown postgres:postgres /var/lib/pgsql/9.6/data/pg_hba.conf
echo configure postgresql.conf:
sed -itmp -e 's/#listen_addresses = \x27localhost\x27/listen_addresses = \x27*\x27/g' /var/lib/pgsql/data/postgresql.conf

echo run server:
su postgres -c '/usr/pgsql-9.6/bin/postgres -D /var/lib/pgsql/data'

}

# Call all functions

__create_user
__run

#__run_supervisor
