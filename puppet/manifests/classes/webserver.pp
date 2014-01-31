class webserver {
  
  Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

  #MySQL
  include mysql
  
  # Nginx
  include nginx
  
  # Varnish
  include varnish
  
  # Memcached
  include memcached
  
  # Git
  include github-config
  
  # Drush
  include drush
  
  # XHProf
  include xhprof
  
  # PHPMyAdmin
  include pma
  
  # behat
  include behat
}