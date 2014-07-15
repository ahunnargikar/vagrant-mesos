# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "trusty"
  config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"
  config.vm.provision :shell, :path => "bootstrap.sh"

  #host-only networking
  config.vm.network "private_network", ip: "192.168.56.101", :adapter => 2

  #Default RAM/CPU config
  config.vm.provider "virtualbox" do |v|
   v.customize ["modifyvm", :id, "--memory", "4096", "--cpus", "8", "--ioapic", "on", "--name", "mesos1"]
  end
end
