class puppet::server::passenger {
  include apache::ssl
  include ::passenger

  if $::operatingsystem == 'centos' or $::operatingsystem == 'redhat' {
    file {'puppet_vhost':
      path    => "${puppet::params::apache_conf_dir}/puppet.conf",
      content => template('puppet/server/puppet-vhost.conf.erb'),
      mode    => '0644',
      notify  => Exec['reload-apache'],
    }

    exec {'restart_puppet':
      command     => "/bin/touch ${puppet::params::app_root}/tmp/restart.txt",
      refreshonly => true,
      cwd         => $puppet::params::app_root,
      path        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
      require     => [Class['puppet::server::install'],File["${puppet::params::app_root}/tmp"]],
    }

    file {
      [$puppet::params::app_root, "${puppet::params::app_root}/public", "${puppet::params::app_root}/tmp"]:
        ensure => directory,
        owner  => $puppet::params::user,
    }
    file {
      "${puppet::params::app_root}/config.ru":
        owner  => $puppet::params::user,
        source => 'puppet:///modules/puppet/config.ru',
        notify => Exec['restart_puppet'],
    }
  }

  if $::operatingsystem == 'debian' or $::operatingsystem == 'Ubuntu' {
    augeas { '/etc/default/puppetmaster':
      changes     => ["set /files/etc/default/puppetmaster/START no",],
      require => Package['puppetmaster'],
    }
    package { 'puppetmaster-passenger':
      ensure => installed,
    }
  }
}
