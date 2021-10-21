#!/bin/bash


key_file="/home/<user>/.ssh/authorized_keys"
my_key="ssh-rsa AAAAB3NzaC1yc2EAA[...]bEfTEaCSXn26G/1PcZkL6gGaKzYVgEBrCwvcB+JJ <user>@<host>

present=`cat $key_file | grep "$my_key" | wc -l`

if [ $present -eq 0 ]
then
   echo `date "+%Y-%m-%d_%H-%M-%S"` "adding <user>@<host> key..."
   echo $my_key >> $key_file
else
   echo `date "+%Y-%m-%d_%H-%M-%S"` "<user>@<host> key already present."
fi
exit 0
