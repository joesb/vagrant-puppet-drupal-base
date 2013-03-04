class mydemosite::conf {
  File {
    require => [
      Class ["nginx::service"]
    ],
    ensure => present,
    owner => "501",
    group => "vagrant",
    mode => 0644,
  }
    
  file { "/var/www/webapp":
    ensure => directory,
    # owner => "501",
    # group => "vagrant",
    # mode => 0644,
    # require => Class ["nginx::service"]
  }
  file { "/var/www/webapp/sites":
    ensure => directory,
    # owner => "501",
    # group => "vagrant",
    # mode => 0644,
    require => File["/var/www/webapp"]
  }
  file { "/var/www/webapp/sites/default":
    ensure => directory,
    # owner => "501",
    # group => "vagrant",
    # mode => 0644,
    require => File["/var/www/webapp/sites"]
  }
  file { "/var/www/webapp/sites/default/files":
    ensure => directory,
    owner => "501",
    group => "vagrant",
    mode => 0777,
    require => File["/var/www/webapp/sites/default"]
  }
  
  file {"/var/www/webapp/sites/default/settings.php":
    source => "/vagrant/deployment/files/www.mydemosite.local/var/www/webapp/sites/default/settings.php",
    ensure => file,
    # owner => "501",
    # group => "vagrant",
    require => [ File["/var/www/webapp"], File["/var/www/webapp/sites/default"], Class ["nginx::service"] ]
  }
 
  file { "/etc/nginx/conf.d/www.dclondon.local.conf":
    source => "/vagrant/deployment/files/www.mydemosite.local/etc/nginx/conf.d/www.dclondon.local.conf",
    owner => "root",
    group => "root",
    # require => Class ["nginx::service"]
  }

  $mysql_password = "root"
  
  exec { "create-mysql-db":
    unless =>  "mysql -udemo -pdemo drupal_demo",
    path => ["bin", "/usr/bin"],
    command => "mysql -uroot -p$mysql_password -e \"CREATE DATABASE drupal_demo COLLATE = 'utf8_general_ci'; grant usage on *.* to demo@localhost identified by 'demo'; grant all privileges on drupal_demo.* to demo@localhost;\" ; mysql -uroot -p$mysql_password drupal_demo < /vagrant/deployment/database/drupal_demo.sql",
    require => [Class["mysql::service"], Exec["set-mysql-password"]],
  }
  
}

class mydemosite {
  include mydemosite::conf
}
