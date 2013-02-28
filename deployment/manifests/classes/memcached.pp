class memcached::install {
  $packagelist = [
    "memcached",
    "php-pecl-memcache"
  ]

    package { $packagelist:
        ensure => installed,
    }
}

class memcached::service {
  service { "memcached":
    ensure => running,
    require => Class ["memcached::install"]
  }
}

class memcached::conf {
  File {
    require => Class ["memcached::install"],
    ensure => present,
    owner => "root",
    group => "root",
    mode => 0444,
    notify => Class ["memcached::service"]
  }

  file { "/etc/default/memcached":
    source => "/vagrant/deployment/files/etc/default/memcached"
  }

  file { "/etc/memcached.conf":
    source => "/vagrant/deployment//files/etc/memcached.conf"
  }
  
  # Start extra memcached servers for sessions and users
  exec { "memcache_extra_servers":
     command => "/usr/bin/memcached -m 24 -p 11212 -d -u memcached; /usr/bin/memcached -m 24 -p 11213 -d -u memcached",
     require => Class["memcached::service"],
   }
}

class memcached {
  include memcached::install, memcached::service, memcached::conf
}
