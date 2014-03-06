#!/usr/bin/env bash

#Set the hostname
hostname mesos3
echo "mesos3" > /etc/hostname
echo "192.168.56.101    mesos1 jenkins1 marathon1 aurora1 zookeeper1 nginx1 docker1" >> /etc/hosts
echo "192.168.56.102    mesos2 jenkins2 marathon2 aurora2 zookeeper2 nginx2 docker2" >> /etc/hosts
echo "192.168.56.103    mesos3 jenkins3 marathon3 aurora3 zookeeper3 nginx3 docker3" >> /etc/hosts

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

#Disable services
update-rc.d -f jenkins remove
update-rc.d -f marathon remove
echo manual >> /etc/init/marathon.conf
echo manual >> /etc/init/jenkins.conf

reboot