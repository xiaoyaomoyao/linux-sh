#!/bin/bash
user=root
passwd=wuJIEtian1989
sock=/var/data/3306/mysql.sock
MYLOGIN="mysql -u$user -p$passwd -S$sock"
MYDUMP="mysqldump -u$user -p$passwd -S$sock"
database="$($MYLOGIN -e "show databases;"|egrep -vi "Data|mysql|schema")"

for dbname in $database
do
  table="$($MYLOGIN -e "use $dbname;show tables;"|sed "1d")"
    for tname in $table
      do
        MYDIR=/root/databackups/$dbname/${dbname}_$(date +%F)
        [ ! -d $MYDIR ] && mkdir -p $MYDIR
        $MYDUMP $dbname $tname |gzip >$MYDIR/${dbname}_${tname}_$(date +%F).sql.gz
      done
done
