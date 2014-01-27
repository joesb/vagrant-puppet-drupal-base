Vagrant.configure("2") do |config|

  config.vm.box = "centos64"

  # The url from where the 'config.vm.box' box
  # will be fetched if it doesn't already exist
  # on the user's system.
  # config.vm.box_url = "http://bit.ly/centos63-puppet-box"
  config.vm.box_url = "http://packages.vstone.eu/vagrant-boxes/virtualbox/4.3.2/centos-6.x-64bit-puppet.3.x-chef.0.10.x-vbox.4.3.2-1.box"
  
  # set the host name
  # config.vm.hostname = "testing.local"
  
  # Host-only network
  config.vm.network :private_network, ip: "192.168.30.41"
  
  # forward the webserver port 
  config.vm.network :forwarded_port, guest: 80, host: 8080, auto_correct: true
  # and solr port 
  # config.vm.network :forwarded_port, guest: 8180, host: 8001, auto_correct: true
  
  # Main vagrant share folder, not the root of this directory as normal
  # switch the comments for these lines if you do/don't have NFS on your local machine
  # config.vm.synced_folder "puppet/", "/vagrant/puppet", :nfs => false
  config.vm.synced_folder "puppet/", "/vagrant/puppet", :nfs => false
  
  # Mount webapp drive
  # switch the comments for these lines if you do/don't have NFS on your local machine
  # config.vm.synced_folder "webapp/", "/var/www/webapp", :nfs => false
  config.vm.synced_folder "webapp/", "/var/www/webapp", :nfs => false
    
  # Boot with a GUI so you can see the screen. (Default is headless)
  # config.vm.boot_mode = :gui
  

  # Enable ssh key forwarding
  config.ssh.forward_agent = true
  
  # bump the memory and cpu allocation
  config.vm.provider :virtualbox do |vb|
    vb.customize [ "modifyvm", :id, "--memory", "2048", "--cpus", "2", "--cpuexecutioncap", "50" ]
  end
  
  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "puppet/manifests"
    puppet.manifest_file  = "dev.pp"
    puppet.module_path = "puppet/modules"
    puppet.options =  ["--verbose"]
  end

end
