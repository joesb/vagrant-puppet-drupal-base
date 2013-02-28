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
  
  # exec { "create-mysql-dbs":
  #   unless =>  "mysql -uoxfam -poxfam www_oxfam_d7",
  #   path => ["bin", "/usr/bin"],
  #   command => "mysql -uroot -p$mysql_password -e \"create database www_oxfam_d7; create database blogs_oxfam_d7; create database www_oxfam_d6; create database blogs_oxfam_d6; grant usage on *.* to oxfam@localhost identified by 'oxfam'; grant all privileges on www_oxfam_d7.* to oxfam@localhost; grant all privileges on blogs_oxfam_d7.* to oxfam@localhost; grant all privileges on www_oxfam_d6.* to oxfam@localhost; grant all privileges on blogs_oxfam_d6.* to oxfam@localhost;\"",
  #   require => [Class["mysql::service"], Exec["set-mysql-password"]],
  # }
}

class mysql {
  include mysql::install, mysql::service, mysql::conf
}