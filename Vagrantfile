# -*- mode: ruby -*-
# vi: set ft=ruby :

# Author Fábio Dionathan Costa Depin <fabiodepin@gmail.com> 
# License MIT

Vagrant.configure(2) do |config|
  ### Base box.
  config.vm.box = "debian/bullseye64"
  config.vm.box_version = "11.20211018.1"

  ### Change vagrant SSH password
  config.vm.provision 'shell', inline: 'echo "vagrant:132567" | chpasswd'

  ### Hostname
  config.vm.hostname = "myWebServer.local"

  ######## VM Settings
  config.vm.provider "virtualbox" do |vb|
    ## Name
    vb.name = "WebServer"
    ## GUI vs. Headless
    vb.gui = true
    ## Memory and CPU settings
    vb.memory = 1024
    vb.cpus = 2
    vb.customize ["modifyvm", :id, "--ostype", "Debian_64"]
    vb.customize ["modifyvm", :id, "--audio", "none", "--usb", "off", "--usbehci", "off"]
    ## To removes unused network interfaces
    vb.destroy_unused_network_interfaces = true
  end

  ### Setting up machine's IP Address
  #config.vm.network "private_network", ip: "192.168.205.10"
  ### Provisioning with script.sh
  config.vm.provision :shell, path: "script.sh" 

  ### Use forward_port to redirect host port to guest port
  config.vm.network "forwarded_port", guest: 80, host: 8080   #apache
  config.vm.network "forwarded_port", guest: 443, host: 4343  #apache
  config.vm.network "forwarded_port", guest: 3306, host: 3306 #mariadb
  
  ### Sync local folder wwww with virtual machine
  config.vm.synced_folder "www", "/var/www"



end
