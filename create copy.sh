#!/usr/bin/env bash

cd mesos3/
vagrant destroy --force
cd ..

cd mesos2/
vagrant destroy --force
cd ..

vagrant destroy --force