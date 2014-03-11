#!/usr/bin/env bash

rm mesos1.box
vagrant box remove mesos1
vagrant up
vagrant package --base mesos1 --output mesos1.box
vagrant box add mesos1 mesos1.box
vagrant box list
vagrant up

cd mesos2/
vagrant up
cd ..

cd mesos3/
vagrant up