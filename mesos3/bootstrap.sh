#!/usr/bin/env bash

#Set the hostname
hostname mesos3
echo "mesos3" > /etc/hostname

#Clone Git repo containing config files
echo "###############################################################"
echo "Cloning https://github.com/ahunnargikar/vagrant-mesos........"
echo "###############################################################"
git clone https://github.com/ahunnargikar/vagrant-mesos
cd vagrant-mesos
git pull
cd ..

#Copy over the slave-specific configs
cp -rf vagrant-mesos/mesos3/mesos/mesos-master/* /etc/mesos-master
cp -rf vagrant-mesos/mesos3/mesos/mesos-slave/* /etc/mesos-slave

#Zookeeper
echo "3" > /etc/zookeeper/conf/myid

#Nginx config
sed -i 's/mesos1/mesos3/g' /etc/nginx/app-servers.include

#Disable services
update-rc.d -f jenkins remove
update-rc.d -f marathon remove
echo "manual" >> /etc/init/marathon.conf
echo "manual" >> /etc/init/jenkins.conf
echo "manual" >> /etc/init/aurora.conf
echo "manual" >> /etc/init/thermos-observer.conf

echo "####################################"
echo "Rebooting........"
echo "####################################"
reboot