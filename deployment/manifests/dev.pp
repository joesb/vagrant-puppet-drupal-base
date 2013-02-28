##
## main vagrant file for dev box 

import "classes/*"

  group { "puppet":
    ensure => "present",
  }
  
 File { owner => 0, group => 0, mode => 0644 }
 
 file { '/etc/motd':
   content => "Welcome to vagrant dev box\n\nNo local changes - see deployment/manifests for configs\n\n"
 }

  yumrepo { "epel":
    enabled => 1,
  }

  # Install a basic developer webserver, which installs
  # - nginx
  # - varnish
  # - mysql
  # - git and keys
  # - drush
  # - xhprof
  include webserver
  
  # www.mydemosite.local server
  include mydemosite

   # tomcat server - auto installs a whole load of dependencies 
   # package { tomcat6: ensure => installed }
   # service { tomcat6: ensure => running }

  # a few useful tools 
  package { vim-enhanced: ensure => installed }
  package { tmux: ensure => installed }
  package { telnet: ensure => installed }
  package { mlocate: ensure => installed }
  package { lsof: ensure => installed }
  package { ngrep: ensure => installed, require => Yumrepo["epel"]  }
  package { wget: ensure => installed }
  package { cronolog: ensure => installed }
  
  # NFS for shared folders
  package { nfs-utils: ensure => installed }
  service { [ "nfs", "nfslock" ]:
    ensure => true,
    enable => true,
    require => Package["nfs-utils"],
  }
  
  

  

  ### SYSTEM FILES ###

  # A default .bashrc to format the commandline nicely
  file { "/home/vagrant/.bashrc":
    mode => 0644,
    owner => vagrant,
    group => vagrant,
    source => "/vagrant/deployment/files/home/vagrant/.bashrc",
  }
  