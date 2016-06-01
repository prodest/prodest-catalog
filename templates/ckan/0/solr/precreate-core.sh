#!/bin/bash
#
# A script that creates a core by copying config before starting solr.
#

echo "Creating config files"
CONFIG_SOURCE="/opt/solr/server/solr/configsets/basic_configs"
schema_url="https://raw.githubusercontent.com/ckan/ckan/ckan-2.5.2/ckan/config/solr/schema.xml"
#coresdir="/opt/solr/server/solr/mycores"
#mkdir -p $coresdir
#coredir="$coresdir/$SOLR_CKAN_CORE"
coredir="/opt/solr/server/solr/$SOLR_CKAN_CORE"

if [[ ! -f $coredir/conf/managed-schema ]]; then
    cp -r $CONFIG_SOURCE/. $coredir
    touch "$coredir/core.properties"
    wget -nv $schema_url -O $coredir/conf/managed-schema
    #
    ln -s $coredir/conf/managed-schema $coredir/conf/schema.xml
    echo "Created $SOLR_CKAN_CORE"
else
    echo "Core $SOLR_CKAN_CORE already exists"
    echo "Skipping creating $SOLR_CKAN_CORE"
fi

