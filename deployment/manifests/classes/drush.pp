class drush::install {

  # Install Drush
  exec { "pear_channel_discover_pear_drush_org":
    command => "/usr/bin/pear channel-discover pear.drush.org",
    creates => "/usr/share/pear/.channels/pear.drush.org.reg",
  }

  exec { "pear_install_drush":
    command => "/usr/bin/pear install drush/drush",
    creates => "/usr/share/pear/drush/drush.php",
    require => Exec["pear_channel_discover_pear_drush_org"],
  }
  
  exec { "drush_console_table":
    command => "/usr/bin/wget --no-check-certificate -q http://download.pear.php.net/package/Console_Table-1.1.3.tgz ; tar -zxf Console_Table-1.1.3.tgz ; rm Console_Table-1.1.3.tgz ; mv Console_Table-1.1.3  /usr/share/pear/drush/lib",
    creates => "/usr/share/pear/drush/lib/Console_Table-1.1.3",
    require => [
        Exec["pear_install_drush"],
        Package['wget'],
    ]
  }
  
  exec { "drush_registry_rebuild":
    command => "/usr/bin/drush dl registry_rebuild",
    creates => "/root/.drush/registry_rebuild",
    require => Exec["drush_console_table"]
  }
  
}

class drush::conf {
  # Create a directory for the drushrc.php script
  file { "/etc/drush":
    ensure => directory,
    owner => "root",
    group => "root",
    mode => 0755,
    require => [
      Class["drush::install"],
    ],
  }

  # A drushrc.php (Drush runtime configure) file
  file { "/etc/drush/drushrc.php":
    mode => 0644,
    owner => root,
    group => root,
    source => "/vagrant/deployment/files/etc/drush/drushrc.php",
    require => [
      Class["drush::install"],
      File["/etc/drush"],
    ],
  }
}

class drush {
  include drush::install, drush::conf
}