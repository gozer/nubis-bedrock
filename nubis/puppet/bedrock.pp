class { 'python':
  version    => 'system',
  pip        => true,
  dev        => true,
}

python::requirements { '/data/www/bedrock/requirements/dev.txt':
  require => Class['python']
}

exec { "apt-get update":
    command => "/usr/bin/apt-get update",
}

package { 'makepasswd':
  ensure => '1.10-9',
  require  => Exec['apt-get update'],
}

package { 'apg':
  ensure => present,
  require  => Exec['apt-get update'],
}

package {
  [
    'libxml2-dev',
    'libxslt-dev',
    'libz-dev',
    'nodejs',
  ]:
    ensure => present,
    require  => Exec['apt-get update'],
}

file { '/usr/bin/node':
    ensure => 'link',
    target => '/usr/bin/nodejs',
}

include nubis_configuration

nubis::configuration{ 'bedrock':
  format => "sh",
  reload => "apache2ctl graceful",
}
