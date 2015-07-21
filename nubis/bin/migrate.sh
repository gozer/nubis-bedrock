#!/bin/bash
#
# This script is run on every ami change.
#+ This is the place to do things like database initilizations and migrations.
#
#set -x

INSTALL_ROOT='/data/www/bedrock'
LOGGER_BIN='/usr/bin/logger'

# Set up the logger command if the binary is installed
if [ ! -x $LOGGER_BIN ]; then
    echo "ERROR: 'logger' binary not found - Aborting"
    echo "ERROR: '$BASH_SOURCE' Line: '$LINENO'"
    exit 2
else
    LOGGER="$LOGGER_BIN --stderr --priority local7.info --tag migrate.sh"
fi

# Source the consul connection details from the metadata api
eval `curl -fq http://169.254.169.254/latest/user-data`

# Set up the consul url
CONSUL="http://localhost:8500/v1/kv/$NUBIS_STACK/$NUBIS_ENVIRONMENT/config"

# Grab the variables from consul
#+ If this is a new stack we need to wait for the values to be placed in consul
#+ We will test the first and sleep with a timeout
KEYS_UP=-1
COUNT=0
while [ "$KEYS_UP" != "0" ]; do
    # Try for 20 minutes (30 seconds * 40 attempts = 1200 seconds / 60 seconds = 20 minutes)
    if [ ${COUNT} -gt "40" ]; then
        $LOGGER "ERROR: Timeout while waiting for keys to be populated in consul."
        exit 1
    fi
    QUERY=`curl -s $CONSUL/DBSERVER?raw=1`

    if [ "$QUERY" == "" ]; then
        $LOGGER "Keys not ready yet. Sleeping 30 seconds before retrying..."
        sleep 30
        COUNT=${COUNT}+1
    else
        KEYS_UP=0
    fi
done

# Now we can safely gather the values
DBSERVER=`curl -s $CONSUL/DBSERVER?raw=1`
DBNAME=`curl -s $CONSUL/DBNAME?raw=1`
DBUSER=`curl -s $CONSUL/DBUSER?raw=1`

# Generate and set the secrets for the app
DBPASSWORD=`curl -s $CONSUL/DBPASSWORD?raw=1`
if [ "$DBPASSWORD" == "" ]; then
    DBPASSWORD=`makepasswd --minchars=12 --maxchars=16`
    curl -s -X PUT -d $DBPASSWORD $CONSUL/DBPASSWORD
fi

# Reset the database password on first run
# Create mysql defaults file
echo -e "[client]\npassword=$DBPASSWORD\nhost=$DBSERVER\nuser=$DBUSER" > .DBDEFAULTS
# Test the current password
TEST_PASS=`mysql --defaults-file=.DBDEFAULTS $DBNAME -e "show tables" 2>&1`
if [ `echo $TEST_PASS | grep -c 'ERROR 1045'` == 1 ]; then
    # Use the provisioner pasword to cange the password
    echo -e "[client]\npassword=provisioner_password\nhost=$DBSERVER\nuser=$DBUSER" > .DBDEFAULTS
    $LOGGER "Detected provisioner password, reseting database password."
    mysql --defaults-file=.DBDEFAULTS $DBNAME -e "SET PASSWORD FOR '$DBUSER'@'%' = password('$DBPASSWORD')"
    RV=$?
    if [ $RV != 0 ]; then
        $LOGGER "ERROR: Could not access mysql database ($RV), aborting."
        exit $RV
    fi
fi

# Clean up
rm -f .DBDEFAULTS


# Okay, finally... now we can do stuff.

. /etc/nubis-config/bedrock.sh

# New Relic is currently broken because the license key isn't in Consul, because it's public :(
# sudo sh -c "newrelic-admin generate-config $NEW_RELIC_LICENSE_KEY > /etc/newrelic.ini"
# sudo sed -i -r -e 's/^high_security = false$/high_security = true/' /etc/newrelic.ini
# sudo sed -i -r -e "s/^app_name = Python Application\$/app_name = ${NUBIS_STACK}-${NUBIS_ENVIRONMENT}/" /etc/newrelic.ini
#
# sudo sh -c "nrsysmond-config --set license_key=$NEW_RELIC_LICENSE_KEY"
# sudo sed -i -r -e "s/^#hostname=myhost/hostname=${NUBIS_STACK}-${NUBIS_ENVIRONMENT}-$(ec2metadata | grep 'instance-id' | cut -f2 -d' ')-$(ec2metadata | grep 'availability-zone' | cut -f2 -d' ')/" /etc/newrelic/nrsysmond.cfg
# sudo sed -i -r -e "s/^#disable_docker=false/disable_docker=true/" /etc/newrelic/nrsysmond.cfg
# sudo sed -i -r -e "s/^#labels=label_type:label_value/labels=Environment:${NUBIS_ENVIRONMENT};DataCenter:$(ec2metadata | grep 'availability-zone' | cut -f2 -d' ')/" /etc/newrelic/nrsysmond.cfg
# sudo service newrelic-sysmond restart
#
# sudo sh -c 'echo "export NEWRELIC_PYTHON_INI_FILE=/etc/newrelic.ini" >> /etc/apache2/envvars'

cd $INSTALL_ROOT
# sudo python ./manage.py collectstatic --noinput  # bedrock now can use the DATABASE_URL env var, so we can do this during AMI build with puppet
sudo python ./manage.py update_externalfiles
sudo python ./manage.py migrate
sudo python ./manage.py update_product_details
sudo chown -R www-data /data/www/bedrock

sudo service varnish stop
sudo service apache2 restart
sudo service varnish start
sleep 3
sudo service varnish start  # seems to take 2 times due to some kind of disk full error... I don't get it
