class btsync (
  $binary         = '/usr/local/bin/btsync',
  $force_https    = true,
  $listen_address = '0.0.0.0',
  $listen_port    = '8888',
  $storage_path   = '/var/lib/btsync',
  $user           = 'btsync',
) {

  include ::systemd
  if ($::systemd_available) {
    $init_path      = "${::systemd::unit_path}/btsync.service"
    $init_source    = 'systemd.btsync.erb'

    file { $init_path:
      content => template("${module_name}/${init_source}"),
      require => File[$binary],
      notify  => Exec['systemd-daemon-reload'],
    }

  }
  else {
    $init_path      = '/etc/init.d/btsync.conf'
    $init_source    = 'init.btsync.erb'

    file { $init_path:
      content => template("${module_name}/${init_source}"),
      require => File[$binary],
    }

  }

  group { $user:
    ensure => present,
  } ->
  user { $user:
    groups => [$user],
    home   => $storage_path,
  } ->
  file { $storage_path:
    ensure  => directory,
    mode    => '0700',
    owner   => $user,
    group   => $user,
  }

  file { '/etc/btsync':
    ensure  => directory,
    mode    => '0755',
    owner   => $user,
    group   => $user,
    require => User[$user],
  } ->
  file { '/etc/btsync/btsync.conf':
    content => template("${module_name}/btsync.conf.erb"),
    owner   => $user,
    group   => $user,
    mode    => '0664',
    notify => Service['btsync'],
  }

  if ( $force_https ) {
    file { '/etc/btsync/btsync.crt':
      source  => "puppet:///modules/${module_name}/btsync.crt",
      owner   => $user,
      group   => $user,
      mode    => '0660',
      require => File['/etc/btsync/btsync.conf'],
      notify  => Service['btsync'],
    }

    file { '/etc/btsync/btsync.key':
      source  => "puppet:///modules/${module_name}/btsync.key",
      owner   => $user,
      group   => $user,
      mode    => '0660',
      require => File['/etc/btsync/btsync.conf'],
      notify  => Service['btsync'],
    }
  }

  file { $binary:
    source  => "puppet:///modules/${module_name}/btsync",
    require => File[$storage_path],
  }

  service { 'btsync':
    ensure  => running,
    enable  => true,
    require => File[$init_path],
  }

}
