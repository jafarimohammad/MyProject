#!/bin/bash

user=$(eval getent passwd {$(awk '/^UID_MIN/ {print $2}' /etc/login.defs)..$(awk '/^UID_MAX/ {print $2}' /etc/login.defs)} | cut -d: -f1 | sed ':a;N;$!ba;s/\n/ /g')
notremove="mohammad"
for str in ${user[@]}; do
  if [ "$str" != "$notremove" ]
  then
          deluser $str
  fi
done
