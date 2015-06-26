#!/bin/sh

cd /data/www/bedrock
./manage.py collectstatic --noinput
./manage.py update_externalfiles
./manage.py migrate
./manage.py update_product_details

sudo chown -R www-data /data/www/bedrock
