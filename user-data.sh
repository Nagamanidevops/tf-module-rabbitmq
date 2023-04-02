#!/bin/bash
labauto ansible

ansible-pull -i localhost, -U http://github.com/nagamanidevops/roboshop-ansiblenew roboshop.yml -e ROLE_NAME=${component} -e env=${env} | tee /opt/ansible.log

