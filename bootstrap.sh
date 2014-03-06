#!/usr/bin/env bash

apt-get update

#Set the hostname
hostname mesos1
echo "mesos1" > /etc/hostname
echo "192.168.56.101    mesos1 jenkins jenkins1 marathon marathon1 aurora aurora1 zookeeper1 nginx1 docker1" >> /etc/hosts
echo "192.168.56.102    mesos2 jenkins2 marathon2 aurora2 zookeeper2 nginx2 docker2" >> /etc/hosts
echo "192.168.56.103    mesos3 jenkins3 marathon3 aurora3 zookeeper3 nginx3 docker3" >> /etc/hosts

#Install base packages
echo "####################################"
echo "Installing base packages........"
echo "####################################"
apt-get -y install g++ python-dev zlib1g-dev libssl-dev libcurl4-openssl-dev libsasl2-modules python-setuptools libsasl2-dev make daemon
apt-get -y install curl git-core mlocate

#Clone Git repo containing config files
echo "###############################################################"
echo "Cloning https://github.com/ahunnargikar/vagrant-mesos........"
echo "###############################################################"
git clone https://github.com/ahunnargikar/vagrant-mesos

#Install Java & Maven
echo "####################################"
echo "Installing JDK7 & Maven........"
echo "####################################"
apt-get -y install default-jdk maven
java -version
mvn --version

#Install Docker
echo "####################################"
echo "Installing Docker........"
echo "####################################"
echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list
apt-get -y update
apt-get -y --force-yes install lxc-docker

#Install Docker Executor
echo "####################################"
echo "Installing the Docker Executor........"
echo "####################################"
mkdir -p /var/lib/mesos/executors
curl http://downloads.mesosphere.io/mesos-docker/mesos-docker --output /var/lib/mesos/executors/docker
chmod +x /var/lib/mesos/executors/docker

#Install Zookeeper
echo "####################################"
echo "Installing Zookeeper........"
echo "####################################"
apt-get -y install zookeeperd
echo "1" > /etc/zookeeper/conf/myid
cp vagrant-mesos/zookeeper/zoo.cfg /etc/zookeeper/conf/zoo.cfg

#Install Mesos
echo "####################################"
echo "Installing Mesos........"
echo "####################################"
cp -rf vagrant-mesos/mesos/mesos-master /etc/mesos-master
cp -rf vagrant-mesos/mesos/mesos-slave /etc/mesos-slave
wget http://downloads.mesosphere.io/master/ubuntu/13.10/mesos_0.17.0_amd64.deb
wget http://downloads.mesosphere.io/master/ubuntu/13.10/mesos_0.17.0_amd64.egg
dpkg -i mesos_0.17.0_amd64.deb
easy_install mesos_0.17.0_amd64.egg
sed -i '/--recover=cleanup/d' /usr/bin/mesos-init-wrapper
cp vagrant-mesos/mesos/mesos/zk /etc/mesos/zk

#Install protobuf 2.5.0
echo "####################################"
echo "Installing Protobuf 2.5.0......."
echo "####################################"
wget https://protobuf.googlecode.com/files/protobuf-2.5.0.tar.gz
tar -xzvf protobuf-2.5.0.tar.gz; cd protobuf-2.5.0/
./configure
make
#make check
make install
ldconfig
protoc --version
cd ..

#Install Jenkins
echo "####################################"
echo "Installing Jenkins........"
echo "####################################"
apt-get -y install jenkins
update-rc.d jenkins defaults
cp vagrant-mesos/jenkins/jenkins /etc/default/jenkins
mkdir -p /var/lib/jenkins/plugins
cp vagrant-mesos/mesos-plugin/mesos.hpi /var/lib/jenkins/plugins/mesos.hpi
chown -R jenkins:jenkins /var/lib/jenkins/plugins
usermod -g docker jenkins

#Install Marathon
echo "####################################"
echo "Installing Marathon........"
echo "####################################"
git clone https://github.com/mesosphere/marathon
cd marathon
sed -i 's/<mesos.version>0.15.0/<mesos.version>0.17.0/g' pom.xml
sed -i 's/<protobuf.version>2.4.1/<protobuf.version>2.5.0/g' pom.xml
protoc --java_out=src/main/java/ --proto_path=/usr/local/include/mesos/ --proto_path=src/main/proto/ src/main/proto/marathon.proto
mvn package
git status
cd ..
mv marathon /usr/local/marathon
mkdir -p /etc/marathon
cp vagrant-mesos/marathon/marathon.conf /etc/marathon/marathon.conf
cp vagrant-mesos/marathon/marathon.init /etc/init/marathon.conf


#Install & configure Aurora
echo "####################################"
echo "Installing Aurora........"
echo "####################################"
#Build the Aurora code
cd /usr/local
git clone http://git-wip-us.apache.org/repos/asf/incubator-aurora.git
cd incubator-aurora
sed -i 's/com.google.protobuf:protobuf-java:2.4.1/com.google.protobuf:protobuf-java:2.5.0/g' build.gradle
./gradlew distZip

#Place the Aurora binary under /usr/local
rm -rf /usr/local/aurora-scheduler*
unzip dist/distributions/aurora-scheduler-*.zip -d /usr/local
ln -nfs "$(ls -dt /usr/local/aurora-scheduler-* | head -1)" /usr/local/aurora-scheduler

#Place the Aurora config file under /etc/aurora
mkdir -p /etc/aurora
cat > /etc/aurora/clusters.json <<EOF
[{
  "name": "example",
  "zk": "192.168.56.101",
  "scheduler_zk_path": "/aurora/scheduler",
  "auth_mechanism": "UNAUTHENTICATED",
  "slave_run_directory": "latest",
  "slave_root": "/var/lib/mesos"
}]
EOF

#Install the Python binaries
./pants src/main/python/apache/aurora/client/bin:aurora_admin
./pants src/main/python/apache/aurora/client/bin:aurora_client

cp /home/vagrant/mesos_0.17.0_amd64.egg /usr/local/incubator-aurora/.pants.d/python/eggs/mesos-0.17.0-py2.7.egg
./pants src/main/python/apache/aurora/executor/bin:gc_executor
./pants src/main/python/apache/aurora/executor/bin:thermos_executor
./pants src/main/python/apache/aurora/executor/bin:thermos_runner
./pants src/main/python/apache/thermos/observer/bin:thermos_observer

#Additional Python configuration
python <<EOF
import contextlib
import zipfile
with contextlib.closing(zipfile.ZipFile('dist/thermos_executor.pex', 'a')) as zf:
  zf.writestr('apache/aurora/executor/resources/__init__.py', '')
  zf.write('dist/thermos_runner.pex', 'apache/aurora/executor/resources/thermos_runner.pex')
EOF

#Place the binaries under /usr/local/bin
install -m 755 dist/aurora_admin.pex /usr/local/bin/aurora_admin
install -m 755 dist/aurora_client.pex /usr/local/bin/aurora_client
install -m 755 dist/gc_executor.pex /usr/local/bin/gc_executor
install -m 755 dist/thermos_executor.pex /usr/local/bin/thermos_executor
install -m 755 dist/thermos_observer.pex /usr/local/bin/thermos_observer

#Launching the scheduler
cd /home/vagrant
cp vagrant-mesos/aurora/aurora.sh /usr/local/aurora.sh
chmod +x /usr/local/aurora.sh

#Install & configure Nginx
echo "####################################"
echo "Installing Nginx........"
echo "####################################"
apt-get -y install nginx
cp vagrant-mesos/nginx/app-servers.include /etc/nginx/app-servers.include
cp vagrant-mesos/nginx/nginx.conf /etc/nginx/nginx.conf
rm -rf /etc/nginx/sites-available
cp -rf vagrant-mesos/nginx/sites-available /etc/nginx/sites-available/
update-rc.d nginx defaults

# echo "####################################"
# echo "Rebooting........"
# echo "####################################"
# #reboot