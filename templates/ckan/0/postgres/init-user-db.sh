#!/bin/bash
set -e

# CKAN_USER=ckan_default
#     - CKAN_PASSWORD=ckan_pass
#     - CKAN_DB=ckan_default
#     - DATASTORE_USER=datastore_default
#     - DATASTORE_PASSWORD=datastore_pass
#     - DATASTORE_DB=datastore_default

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -c "CREATE USER $CKAN_USER WITH PASSWORD '$CKAN_PASSWORD';"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -c "CREATE DATABASE $CKAN_DB OWNER $CKAN_USER;"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -c "CREATE USER $DATASTORE_USER WITH PASSWORD '$DATASTORE_PASSWORD';"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -c "CREATE DATABASE $DATASTORE_DB OWNER $POSTGRES_USER;"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    /*
    This script configures the permissions for the datastore.

    It ensures that the datastore read-only user will only be able to select from
    the datastore database but has no create/write/edit permission or any
    permissions on other databases. You must execute this script as a database
    superuser on the PostgreSQL server that hosts your datastore database.

    For example, if PostgreSQL is running locally and the "postgres" user has the
    appropriate permissions (as in the default Ubuntu PostgreSQL install), you can
    run:

        paster datastore set-permissions | sudo -u postgres psql

    Or, if your PostgreSQL server is remote, you can pipe the permissions script
    over SSH:

        paster datastore set-permissions | ssh dbserver sudo -u postgres psql

    */

    -- Most of the following commands apply to an explicit database or to the whole
    -- 'public' schema, and could be executed anywhere. But ALTER DEFAULT
    -- PERMISSIONS applies to the current database, and so we must be connected to
    -- the datastore DB:
    \connect $DATASTORE_DB

    -- revoke permissions for the read-only user
    REVOKE CREATE ON SCHEMA public FROM PUBLIC;
    REVOKE USAGE ON SCHEMA public FROM PUBLIC;

    GRANT CREATE ON SCHEMA public TO $CKAN_USER;
    GRANT USAGE ON SCHEMA public TO $CKAN_USER;

    -- take connect permissions from main db
    REVOKE CONNECT ON DATABASE $CKAN_DB FROM $DATASTORE_USER;

    -- grant select permissions for read-only user
    GRANT CONNECT ON DATABASE $DATASTORE_DB TO $DATASTORE_USER;
    GRANT USAGE ON SCHEMA public TO $DATASTORE_USER;

    -- grant access to current tables and views to read-only user
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO $DATASTORE_USER;

    -- grant access to new tables and views by default
    ALTER DEFAULT PRIVILEGES FOR USER $CKAN_USER IN SCHEMA public
    GRANT SELECT ON TABLES TO $DATASTORE_USER;
EOSQL
   