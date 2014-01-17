# makes sure git package and the github config are set up on the machine 
class github-config {

  package { "git": ensure => installed }

  # Install gitflow
  # exec { "get_git_flow":
  #   command => "/usr/bin/wget --no-check-certificate -q -O - https://github.com/nvie/gitflow/raw/develop/contrib/gitflow-installer.sh | sudo bash",
  #   creates => "/usr/local/bin/gitflow-common",
  #   require => [ 
  #     Package['wget'], 
  #     Package['git'] 
  #   ],
  # }
  
  # A user .gitconfig file
  file { "/home/vagrant/.gitconfig":
    mode => 0644,
    owner => vagrant,
    group => vagrant,
    source => "/vagrant/deployment/files/home/vagrant/.gitconfig",
    require => [
      Package["git"],
    ],
  }
  # A user .gitignore_global file
  file { "/home/vagrant/.gitignore_global":
    mode => 0644,
    owner => vagrant,
    group => vagrant,
    source => "/vagrant/deployment/files/home/vagrant/.gitignore_global",
    require => [
      Package["git"],
    ],
  }

} 
