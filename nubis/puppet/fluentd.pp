class { 'fluentd':
  service_ensure => stopped
}

fluentd::configfile { 'apache': }

fluentd::source { 'apache_access':
  configfile => 'apache',
  type       => 'tail',
  format     => 'apache2',
  tag        => 'apache.access',
  config     => {
    'path' => '/var/log/apache2/*access*log',
  },
}

fluentd::source { 'apache_error':
  configfile => 'apache',
  type       => 'tail',
  format     => '/^\[[^ ]* (?<time>[^\]]*)\] \[(?<level>[^\]]*)\] \[pid (?<pid>[^\]]*)\] \[client (?<client>[^\]]*)\] (?<message>.*)$/',
  tag        => 'apache.error',
  config     => {
    'path' => '/var/log/apache2/error.log',
  },
}
