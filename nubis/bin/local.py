# This is an example settings/local.py file.
# Copy it and add your local settings here.

ADMINS = ('foo@bar.com',)
MANAGERS = ADMINS

DEBUG = TEMPLATE_DEBUG = False
DEV = True

# Settings for Download Firefox Facebook tab
#FACEBOOK_PAGE_NAMESPACE = ''
#FACEBOOK_APP_ID = ''

# Google Tag Manager ID Example: GTM-123456
GTM_CONTAINER_ID = ''

SESSION_COOKIE_SECURE = False

USE_GRUNT_LIVERELOAD = False

# Twitter apps' consumer key/secret and access token/secret
TWITTER_APP_KEYS = {
    'default': {
        'CONSUMER_KEY': '',
        'CONSUMER_SECRET': '',
        'ACCESS_TOKEN': '',
        'ACCESS_TOKEN_SECRET': ''
    },
}

import imp
nubis = imp.load_source('nubis', '/etc/nubis-config/bedrock.sh')

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': nubis.DBNAME,
        'USER': nubis.DBUSER,
        'PASSWORD': nubis.DBPASSWORD,
        'HOST': nubis.DBSERVER,
    }
}

CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
        'LOCATION': [
            nubis.MemCachedEndpoint + ':' + nubis.MemCachedPort,
        ],
        'KEY_PREFIX': 'bedrock'
    }
}
