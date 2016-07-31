#!/bin/bash

. /etc/init.d/functions

USER=root
PASSWD=wuJIEtian1989
SOCKET=/var/data/3306/mysql.sock
MYLOGIN="mysql -u$USER -p$PASSWD -S$SOCKET"
errno=(1158 1159 1009 1007 1062)

sta=($($MYLOGIN -e "show slave status\G"|egrep "Seconds_Behind|_Running|Last_SQL_Errno"|awk '{print $NF}'))

if [ "${sta[0]}" -eq "Yes" -a "${sta[1]}" -eq "Yes" -a "${sta[2]}" -eq "0" ];then
  action "mysql slave status:" /bin/true
else
  for ((i=0;i<${#errno[*]};i++))
  do
    if [ "${error[i]}" == "${sta[3]}" ];then
       $MYLOGIN -e "stop slave;"
       $MYLOGIN -e "set global sql_slave_skip_counter = 1"
       $MYLOGIN -e "start slave;"
    fi
  done
  action "mysql slave status:" /bin/false
  echo "mysql slave status is flase!" > myslave_false.log
  mail -s "This is mysql false" 776310271@qq.com < myslave_false.log
fi
