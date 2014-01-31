# composer via module
class { 'composer':
  command_name => 'composer',
  target_dir   => '/usr/local/bin',
  auto_update => true,
  user => 'root',
  require => Class["wget"]
}

class behat::install {
  
  file { "/root/composer.json":
    owner => "root",
    group => "root",
    source => "/vagrant/puppet/files/composer.json",
    require => Class["composer"]
  }
  
  exec { "composer-installer":
    creates => '/root/composer.phar',
    path => ["bin", "/usr/bin"],
    command => "curl -s https://getcomposer.org/installer | php",
    require => File["/root/composer.json"],
    user => 'root',
    cwd => '/root/'
  }
  
  exec { "composer-behat-install":
    creates => '/root/bin/behat',
    path => ["bin", "/usr/bin"],
    command => "php composer.phar install",
    require => Exec["composer-installer"],
    user => 'root',
    cwd => '/root/'
  }

}
class behat {
  include behat::install
}