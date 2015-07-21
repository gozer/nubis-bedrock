
exec { "apt-get update":
    command => "/usr/bin/apt-get update",
}

package {
  [
    'makepasswd',           # used by nubis
    'apg',                  # used by nubis
    'libxml2-dev',          # needed to build stuff in requirements.txt
    'libxslt-dev',          # needed to build stuff in requirements.txt
    'libz-dev',             # needed to build stuff in requirements.txt
    'nodejs',               # needed by manage.py
    'mysql-client',         # nice to have
    'newrelic-sysmond',     # nice to have, needed by in bin/migrate.sh
    'libmysqlclient-dev',   # needed to build stuff in requirements.txt
    'libmemcached-dev',     # needed to build stuff in requirements.txt
  ]:
    ensure => present,
    require  => Exec['apt-get update'],
}

class { 'python':
  version   => 'system',
  pip       => true,
  dev       => true,
  require   => Exec['apt-get update'],
}

python::requirements { '/data/www/bedrock/requirements/prod.txt':
  require => Class['python']
}

file { '/usr/bin/node':
    ensure  => 'link',
    target  => '/usr/bin/nodejs',
    require => Package['nodejs'],
}

# doesn't work, manage.py wants an /etc/nubis-config/bedrock.sh to exist :(
exec { "collect-static":
    command     => "/usr/bin/python /data/www/bedrock/manage.py collectstatic --noinput",
    environment => "DATABASE_URL=/tmp/bedrock-tmp.sql",
    user        => "root",
    require     => Python::Requirements['/data/www/bedrock/requirements/prod.txt'],
}


# Exec['apt-get update'] -> Class['python'] -> Python::Requirements['/data/www/bedrock/requirements/prod.txt'] -> Exec['collect-static']


include nubis_configuration

nubis::configuration{ 'bedrock':
  format => "sh",
  reload => "apache2ctl restart",
}


