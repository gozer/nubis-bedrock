$root_password = 'provisioner_password'
$db_name = 'bedrock'
$username = 'bedrock'
$password = 'provisioner_password'

class { '::mysql::server':
    root_password    => $::root_password,
    restart          => true,
    override_options => {
        'mysqld' => {
            'bind-address' => '0.0.0.0',
        }
    }
}

mysql_user { 'root@%':
  ensure => present,
  password_hash => mysql_password($::root_password)
}

::mysql::db { $::db_name:
    user     => $::username,
    password => $::password,
    host     => '%',
    grant    => ['ALL']
}

include mysql::client
class { 'mysql::bindings':
    python_enable => true
}
