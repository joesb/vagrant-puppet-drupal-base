class nginx::install {
  $epellist = ["nginx", "python-setuptools", "python-meld3", "php-mcrypt"]
  
  package { $epellist:
    require => Yumrepo["epel"],
    ensure => installed
  }
  
  $packagelist = [
    "php-cli",
    "php-mysql",
    "php-bcmath",
    "php-common",
    "php-devel",
    "php-gd",
    "php-ldap",
    "php-mbstring",
    "php-pdo",
    "php-pecl-apc",
    "php-xml"
  ]
  
  package { $packagelist:
    ensure => installed
  }
  
  # supervisord for managing PHP
  package { "supervisor": 
      provider => rpm, 
      ensure => installed, 
      source => "/root/supervisor-3.0-0.5.a10.el6.noarch.rpm",
      require => [
	      Exec["get_supervisor_package"],
        Package["python-setuptools"],
        Package["php-cli"],
      ],
  }

  exec { "get_supervisor_package":
    command =>  "/usr/bin/wget https://tily.s3.amazonaws.com/packages/supervisor-3.0-0.5.a10.el6.noarch.rpm -O /root/supervisor-3.0-0.5.a10.el6.noarch.rpm",
    creates  => "/root/supervisor-3.0-0.5.a10.el6.noarch.rpm",
	  require => [Package['wget']],
  }
  


}

class nginx::service {
  service { "nginx":
    ensure => true,
    enable => true,
    hasrestart => true,
    hasstatus => true,
    require => Class ["nginx::install"]
  }
  
  service { supervisord: 
   	ensure => running,
    require => Class ["nginx::install"]
  }
}

class nginx::conf {
  File {
    require => Class ["nginx::install"],
    owner => "root",
    group => "root",
    mode => 644,
    notify => Class ["nginx::service"]
  }
  
  
  file { "/etc/nginx/conf.d/default.conf":
    source => "/vagrant/deployment/files/etc/nginx/conf.d/default.conf"
  }
  
  # file { "/etc/nginx/conf.d/blogs.oxfam.local.conf":
  #   source => "/vagrant/deployment/files/etc/nginx/conf.d/blogs.oxfam.local.conf"
  # }
  # 
  # file { "/etc/nginx/conf.d/d6blogs.oxfam.local.conf":
  #   source => "/vagrant/deployment/files/etc/nginx/conf.d/d6blogs.oxfam.local.conf"
  # }
  
  file { "/etc/php.d/apc.ini":
    source => "/vagrant/deployment/files/etc/php.d/apc.ini",
  }
  
  # PHP for supervisord
  file { "/etc/supervisord.d/php-cgi.ini":
    source => "/vagrant/deployment/files/etc/supervisord.d/php-cgi.ini",
  }

  # PHP config 
  file { "/etc/php.ini":
    source => "/vagrant/deployment/files/etc/php.ini",
  }
  
  file { "/var/www/html/index.html":
    content => "<h1>Hello world</h1>",
  }
  
  file { "/var/www/html/info.php":
    content => "<?php phpinfo(); ?>",
  }
  file { "/var/www/html/status.php":
    content => "<?php print TRUE; ?>",
  }
  
  include pma
  
  # Find the nginx sites.
  $site_names_string = generate('/usr/bin/find', '-L', '/vagrant/sites/', '-maxdepth', '1', '-mindepth', '1', '-type', 'd', '-printf', '%f\0')
  $site_names = split($site_names_string, '\0')

  # Set up the cores
  define nginxSiteResource {
    # The file in conf.d.
    file {"/etc/nginx/conf.d/${name}.conf":
      ensure => 'file',
      content => template('/vagrant/deployment/files/templates/nginx/site.erb'),
      notify => Class["nginx::service"],
      require => Class ["nginx::install"],
      owner => 'root',
      group => 'root',
    }

    # Add this virtual host to the hosts file
    host { $name:
      ip => '127.0.0.1',
      comment => 'Added automatically by Puppet',
      ensure => 'present',
    }
    
    # add a mysql db per site
    $mysql_name = regsubst($name, '\.', '_', 'G')
    exec { "create-mysql-db-${mysql_name}":
      unless =>  "mysql -u${mysql_name} -p${mysql_name} ${mysql_name}",
      path => ["bin", "/usr/bin"],
      command => "mysql -uroot -proot -e \"CREATE DATABASE ${mysql_name} COLLATE = 'utf8_general_ci'; grant usage on *.* to ${mysql_name}@localhost identified by '${mysql_name}'; grant all privileges on ${mysql_name}.* to ${mysql_name}@localhost;\"",
      require => [Class["mysql::service"], Exec["set-mysql-password"]],
    }
    
    # add a settings.php for the site
    if file("/vagrant/sites/${name}/sites/default/default.settings.php", "/vagrant/deployment/files/not_found.txt") != 'not found' {
      file {"/vagrant/sites/${name}/sites/default/settings.php":
        ensure => 'file',
        content => template('/vagrant/deployment/files/templates/drupal/settings.erb'),
        owner => 'vagrant',
        group => 'vagrant',
        notify => [],
      }
      file {"/vagrant/sites/${name}/sites/default/files":
        ensure => 'directory',
        owner => 'vagrant',
        group => 'vagrant',
        notify => [],
      }
      
    }

  }
  # Puppet magically turns our array into lots of resources.
  nginxSiteResource { $site_names: }
  
}

class nginx {
  include nginx::install, nginx::service, nginx::conf
}