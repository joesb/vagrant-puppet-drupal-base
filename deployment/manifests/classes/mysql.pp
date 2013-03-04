class mysql::install {
  $packagelist = ["mysql", "mysql-server"]
  
  package { $packagelist:
    ensure => installed 
  }
}

class mysql::service {
  service { "mysqld":
    ensure => running
  }
}

class mysql::conf {
  File {
    require => Class ["mysql::install"],
    owner => "root",
    group => "root",
    mode => 644,
    notify => Class["mysql::service"]
  }

  # my.cnf for MySQL
  file { "/etc/my.cnf":
    source => "/vagrant/deployment/files/etc/my.cnf",
  }
  
  $mysql_password = "root"
  
  exec { "set-mysql-password":
    unless => "mysqladmin -uroot -p$mysql_password status",
    path => ["/bin", "/usr/bin"],
    command => "/usr/bin/mysqladmin -uroot password $mysql_password",
    require => [Class["mysql::service"]],
  }
}

class mysql {
  include mysql::install, mysql::service, mysql::conf
}