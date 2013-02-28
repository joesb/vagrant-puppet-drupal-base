# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|

  config.vm.box = "centos63"

  # The url from where the 'config.vm.box' box
  # will be fetched if it doesn't already exist
  # on the user's system.
  config.vm.box_url = "http://bit.ly/centos63-puppet-box"
  
  # bump the memory and cpu allocation
  config.vm.customize [ "modifyvm", :id, "--memory", "2048", "--cpus", "2" ]
  
  # Boot with a GUI so you can see the screen. (Default is headless)
  # config.vm.boot_mode = :gui
  
  # set the host name
  config.vm.host_name = "my-vagrant-box.local"
  
  # Host-only network
  config.vm.network :hostonly, "192.168.30.20"
  
  # forward the webserver port 
  config.vm.forward_port 80, 8080, :auto => true
  
  # Main vagrant share folder, not the root of this directory as normal
  config.vm.share_folder "v-root", "/vagrant", "./vagrant", :nfs => false
  config.vm.share_folder "deployment", "/vagrant/deployment", "./deployment", :nfs => false
  
  # Mount webapp drive
  config.vm.share_folder "www.mydemosite.local", "/var/www/webapp", "./webapp", :nfs => false
  
  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "deployment/manifests"
    puppet.manifest_file  = "dev.pp"
    puppet.module_path = "deployment/modules"
  end

end
