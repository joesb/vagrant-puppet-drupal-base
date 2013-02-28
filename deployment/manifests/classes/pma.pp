class pma::install { 
  exec { "get_phpmyadmin":
    command => "/usr/bin/wget --no-check-certificate -q http://downloads.sourceforge.net/project/phpmyadmin/phpMyAdmin/3.5.2.2/phpMyAdmin-3.5.2.2-all-languages.tar.gz ; tar -zxf phpMyAdmin-3.5.2.2-all-languages.tar.gz; rm phpMyAdmin-3.5.2.2-all-languages.tar.gz; mv phpMyAdmin-3.5.2.2-all-languages /var/www/html/pma",
    creates => "/var/www/html/pma",
    require => [ 
      Package['wget'], 
      Package['git'] 
    ],
  }
  
}

class pma::conf {
  File {
    require => Class ["pma::install"],
    owner => "root",
    group => "root",
    mode => 755,
  }
  
  file { "/var/www/html/pma/config.inc.php":
    source => "/vagrant/deployment/files/var/www/html/pma/config.inc.php"
  }
}

class pma {
  include pma::install, pma::conf
}
