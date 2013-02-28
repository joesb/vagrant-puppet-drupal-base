class xhprof::install {
  
  # XHProf requires graphviz
  $packagelist = ["graphviz", "graphviz-devel", "graphviz-doc", "graphviz-gd", "graphviz-graphs", "graphviz-guile", "graphviz-java", "graphviz-lua", "graphviz-perl", "graphviz-php", "graphviz-python", "graphviz-ruby", "graphviz-tcl.x86_64"]

    package { $packagelist:
        ensure => installed,
    }
  
  # Install xhprof

  exec { "pecl_install_xhprof":
    command => "wget http://pecl.php.net/get/xhprof-0.9.2.tgz ; tar xvf xhprof-0.9.2.tgz ; cd ./xhprof-0.9.2/extension/ ; phpize ; ./configure ; make ; make install; make test -s",
    path => ["/bin", "/usr/bin"],
    cwd => "/var/www",
    creates => "/usr/lib64/php/modules/xhprof.so",
    require => [
      Class["nginx::install"],
    ],
  }
  
}

class xhprof::conf {

  
  exec { "mk_xhprof_dir":
    command => "/bin/ln -s /var/www/xhprof-0.9.2/xhprof_html/ /var/www/html/xhprof_html",
    creates => "/var/www/html/xhprof_html",
    require => Class["xhprof::install"],
  }

  File {
    require => Class ["xhprof::install"],
    owner => "root",
    group => "root",
    mode => 777,
  }
  
  file { "/var/tmp/xhprof":
    ensure => directory
  }
  
  file { "/etc/php.d/graphviz.ini":
    source => "/vagrant/deployment/files/etc/php.d/graphviz.ini",
    mode => 644,
    notify => Class ["nginx::service"]
  }
}

class xhprof {
  include xhprof::install, xhprof::conf
}