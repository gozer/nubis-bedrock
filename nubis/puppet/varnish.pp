# Setup a local varnish instance for caching

class {'varnish':
  varnish_listen_port	=> 80,
  storage_type          => 'file',
  varnish_storage_size	=> '90%',
  varnish_storage_file  => '/mnt/varnish_storage.bin',
}

class {'varnish::ncsa': }

class { 'varnish::vcl':
  backends => {}, # without this line you will not be able to redefine backend 'default'
#  cookiekeeps => [ 'mediawiki[^=]*' ],
  logrealip => true,
  honor_backend_ttl => true,
  x_forwarded_proto => true,
#  https_redirect => true,  # don't have a cert set up yet
  cond_requests => true,
}

varnish::probe {  'bedrock_homepage':
  url => '/en-US/',
  timeout => '10s',
}

varnish::backend { 'default':
  host  => '127.0.0.1',
  port  => '8080',
  probe => 'bedrock_homepage',
}

fluentd::configfile { 'varnish': }

fluentd::source { 'varnish_access':
  configfile => 'varnish',
  type       => 'tail',
  format     => 'apache2',
  tag        => 'forward.varnish.access',
  config     => {
    'path' => '/var/log/varnish/varnishncsa.log',
  },
}
