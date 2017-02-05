#!/bin/bash
. /etc/init.d/functions

LANG=en
pwd="xxxxxx"
port=22
dsa_pub=`echo ~/.ssh/id_dsa.pub`
scri_dir=/server/scripts
app_dir=/application
app_tool=/application/tools
user=root
nfs_svr=/server/scripts/nfs-server
sync_svr=/server/scripts/sync-server
web_svr=/server/scripts/web-server
lb_svr=/server/scripts/lb
mysql_svr=/server/scripts/mysql
zb_svr=/server/scripts/zabbix

#安装expect
yum -y install expect &>/dev/null
if [ `echo $?` == 0 ];then
  action "yum expect" /bin/true
else
  action "yum expect" /bin/false
fi

#生成密钥对
if [ ! -f $dsa_pub ];then
  ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa >/dev/null 2>&1 &&\
  action "ssh-keygen is" /bin/true
else
  action "ssh-keygen is" /bin/true
fi

#将公钥分发到集群主机上
while read ipl
do
echo -e "\033[32m===========fen fa key to $ipl=================\033[0m"
expect << EOF
log_user 0
spawn ssh-copy-id -i $dsa_pub "-p$port $user@$ipl"
expect {
"yes/no" {send "yes\r";exp_continue}
"password" {send "$pwd\r"}
}
expect eof;
EOF
if [ `echo $?` == 0 ];then
  action "$ipl pub-key:" /bin/true
else
  action "$ipl pub-key:" /bin/false
fi
done <$scri_dir/ip.log

#创建统一脚本和应用存放目录
for ipl in `cat $scri_dir/ip.log`
do
echo -e "\033[32m===========mkdir $ipl $scri_dir=================\033[0m"
ssh -p$port $user@$ipl "if [ ! -d $scri_dir ];then mkdir -p $scri_dir;else echo "$scri_dir is exise";fi"
if [ `echo $?` == 0 ];then
  action "mkdir $ipl $scri_dir:" /bin/true
else
  action "mkdir $ipl $scri_dir:" /bin/false
fi
echo -e "\033[32m===========mkdir $ipl $app_tool=================\033[0m"
ssh -p$port $user@$ipl "if [ ! -d $app_tool ];then mkdir -p $app_tool;else echo "$app_tool is exise";fi"
if [ `echo $?` == 0 ];then
  action "mkdir $ipl $app_tool:" /bin/true
else
  action "mkdir $ipl $app_tool:" /bin/false
fi
done

nfs31(){
for ipl in `cat $scri_dir/ip.log`
do
  if [ $ipl == 172.16.1.31 ];then
  echo -e "\033[32m============nfs server=====================\033[0m"
  scp -P$port $nfs_svr/install-nfs.sh $user@$ipl:$scri_dir/ &>/dev/null &&\
  ssh -p$port $user@$ipl "/bin/sh $scri_dir/install-nfs.sh"
#安装sersync
  echo -e "\033[32m============nfs server's sersync=====================\033[0m"
  scp -P$port $nfs_svr/install-sersync.sh $user@$ipl:$scri_dir/ &>/dev/null &&\
  scp -P$port $nfs_svr/sersync_64.zip $user@$ipl:$app_dir/sersync.zip &>/dev/null &&\
  ssh -p$port $user@$ipl "sudo /bin/sh $scri_dir/install-sersync.sh"
  echo -e "\033[32m============nfs-keepalived=====================\033[0m"
  scp -P$port $lb_svr/nfs-lb.sh $user@$ipl:$scri_dir/ &>/dev/null &&\
  ssh -p$port $user@$ipl "/bin/sh $scri_dir/nfs-lb.sh"
  fi
done
}

backup41(){
for ipl in `cat $scri_dir/ip.log`
do
  if [ $ipl == 172.16.1.41 ];then
    echo -e "\033[32m============nfs-41backup-server=====================\033[0m"
    scp -P$port $nfs_svr/install-nfs.sh $user@$ipl:$scri_dir/ &>/dev/null &&\
    ssh -p$port $user@$ipl "/bin/sh $scri_dir/install-nfs.sh"
    echo -e "\033[32m============rsync server===================\033[0m"
    scp -P$port $sync_svr/install-rsync.sh $user@$ipl:$scri_dir/ &>/dev/null &&\
    ssh -p$port $user@$ipl "sudo /bin/sh $scri_dir/install-rsync.sh data /data/"
    ssh -p$port $user@$ipl "sudo /bin/sh $scri_dir/install-rsync.sh backup /backup/"
    ssh -p$port $user@$ipl "sudo /bin/sh $scri_dir/install-rsync.sh webs /webs/"
    echo -e "\033[32m============rsync server's cron+rsync server===================\033[0m"
    scp -P$port $sync_svr/chk2rsy-server.sh $user@$ipl:$scri_dir &>/dev/null &&\
    ssh -p$port $user@$ipl "echo -e '#check rsync all\n00 04 * * * /bin/sh $scri_dir/chk2rsy-server.sh' >>/var/spool/cron/root" &&\
    action "cron+rsync server" /bin/true
    echo -e "\033[32m============nfs-back-keepalived=====================\033[0m"
    scp -P$port $lb_svr/nfs-lb.sh $user@$ipl:$scri_dir/ &>/dev/null &&\
    ssh -p$port $user@$ipl "/bin/sh $scri_dir/nfs-lb.sh"
  fi
done
}

web08(){
for ipl in `cat $scri_dir/ip.log`
do
  if [ $ipl == 172.16.1.8 ];then
    echo -e "\033[32m============install LNMP=====================\033[0m"
    ssh -p$port $user@$ipl "yum install -y lnmp &>/dev/null"
    if [ `echo $?` == 0 ];then
      action "yum install LNMP" /bin/true
    else
      action "yum install LNMP" /bin/false
    fi
    echo -e "\033[32m============web server's cron+rsync client=====================\033[0m"
    scp -P$port $sync_svr/rsy-cli.sh $user@$ipl:$scri_dir/ &>/dev/null &&\
    ssh -p$port $user@$ipl "/bin/sh $scri_dir/rsy-cli.sh"
    scp -P$port $web_svr/loc2rsy-clients.sh $user@$ipl:$scri_dir/ &>/dev/null &&\
    ssh -p$port $user@$ipl "echo -e '#check to 41\n00 00 * * * /bin/sh $scri_dir/loc2rsy-clients.sh' >>/var/spool/cron/root" &&\
    action "cron+rsync client" /bin/true
    echo -e "\033[32m============lb08-realweb=====================\033[0m"
    scp -P$port $lb_svr/lb-real.sh $user@$ipl:$scri_dir/ &>/dev/null &&\
    ssh -p$port $user@$ipl "/bin/sh $scri_dir/lb-real.sh"
    echo -e "\033[32m============chk-mountfs=====================\033[0m"
    scp -P$port $web_svr/chk_mountfs $user@$ipl:$scri_dir/ &>/dev/null &&\
    scp -P$port $web_svr/chk_on.sh $user@$ipl:$scri_dir/ &>/dev/null &&\
    ssh -p$port $user@$ipl "/bin/sh $scri_dir/chk_on.sh"
  fi
done
}

web07(){
for ipl in `cat $scri_dir/ip.log`
do
  if [ $ipl == 172.16.1.7 ];then
    echo -e "\033[32m============install LAMP=====================\033[0m"
    ssh -p$port $user@$ipl "yum install -y lamp &>/dev/null"
    if [ `echo $?` == 0 ];then
      action "yum install LAMP" /bin/true
    else
      action "yum install LAMP" /bin/false
    fi
    echo -e "\033[32m============web server's cron+rsync client=====================\033[0m"
    scp -P$port $sync_svr/rsy-cli.sh $user@$ipl:$scri_dir/ &>/dev/null &&\
    ssh -p$port $user@$ipl "/bin/sh $scri_dir/rsy-cli.sh"
    scp -P$port $web_svr/loc2rsy-clients.sh $user@$ipl:$scri_dir/ &>/dev/null &&\
    ssh -p$port $user@$ipl "echo -e '#check to 41\n00 00 * * * /bin/sh $scri_dir/loc2rsy-clients.sh' >>/var/spool/cron/root" &&\
    action "cron+rsync client" /bin/true
    echo -e "\033[32m============lb07-realweb=====================\033[0m"
    scp -P$port $lb_svr/lb-real.sh $user@$ipl:$scri_dir/ &>/dev/null &&\
    ssh -p$port $user@$ipl "/bin/sh $scri_dir/lb-real.sh"
    echo -e "\033[32m============chk-mountfs=====================\033[0m"
    scp -P$port $web_svr/chk_mountfs $user@$ipl:$scri_dir/ &>/dev/null &&\
    scp -P$port $web_svr/chk_on.sh $user@$ipl:$scri_dir/ &>/dev/null &&\
    ssh -p$port $user@$ipl "/bin/sh $scri_dir/chk_on.sh"
  fi
done
}

db51(){
for ipl in `cat $scri_dir/ip.log`
do
  if [ $ipl == 172.16.1.51 ];then
    echo -e "\033[32m============mysqldb-51=====================\033[0m"
    scp -P$port $mysql_svr/mysql-init.sh $user@$ipl:$scri_dir/ &>/dev/null &&\
    ssh -p$port $user@$ipl "/bin/sh $scri_dir/mysql-init.sh"
  fi
done
}

lb(){
for ipl in `cat $scri_dir/ip.log`
do
  if [ $ipl == 172.16.1.5 ];then
    echo -e "\033[32m============lb05-server=====================\033[0m"
#    scp -P$port $lb_svr/lb-serv.sh $user@$ipl:$scri_dir/ &>/dev/null &&\
#    ssh -p$port $user@$ipl "/bin/sh $scri_dir/lb-serv.sh"
    ssh -p$port $user@$ipl "yum install -y lb-nginx &>/dev/null" &&\
    if [ `echo $?` == 0 ];then
      action "yum install LB-NGINX" /bin/true
    else
      action "yum install LB-NGINX" /bin/false
    fi
  elif [ $ipl == 172.16.1.6 ];then
    echo -e "\033[32m============lb06-server=====================\033[0m"
#    scp -P$port $lb_svr/lb-serv.sh $user@$ipl:$scri_dir/ &>/dev/null &&\
#    ssh -p$port $user@$ipl "/bin/sh $scri_dir/lb-serv.sh"
    ssh -p$port $user@$ipl "yum install -y lb-nginx &>/dev/null" &&\
    if [ `echo $?` == 0 ];then
      action "yum install LB-NGINX" /bin/true
    else
      action "yum install LB-NGINX" /bin/false
    fi
  fi
done
}

sal(){
for ipl in `cat $scri_dir/ip.log`
do
  echo -e "\033[32m===========install $ipl salt-minion=================\033[0m"
  scp -P$port $zb_svr/sal-mini.sh $user@$ipl:$scri_dir/ &>/dev/null &&\
  ssh -p$port $user@$ipl "/bin/sh $scri_dir/sal-mini.sh"
done
}

zabbix(){
for ipl in `cat $scri_dir/ip.log`
do
  if [ $ipl == 172.16.1.81 ];then
    echo -e "\033[32m===========install $ipl zabbix-server=================\033[0m"
    echo -e "\033[32m============install ZABBIX-server=====================\033[0m"
    ssh -p$port $user@$ipl "yum install -y dz-zabbix &>/dev/null"
    if [ `echo $?` == 0 ];then
      action "yum install zabbix-server" /bin/true
    else
      action "yum install zabbix-server" /bin/false
    fi
  elif [ $ipl == 172.16.1.51 ];then
    echo -e "\033[32m===========install $ipl zabbix-db=================\033[0m"
     scp -P$port $zb_svr/*.sql $user@$ipl:$scri_dir/ &>/dev/null &&\
     scp -P$port $zb_svr/zbsql-init.sh $user@$ipl:$scri_dir/ &>/dev/null &&\
     ssh -p$port $user@$ipl "/bin/sh $scri_dir/zbsql-init.sh"
    echo -e "\033[32m===========install $ipl zabbix-agent=================\033[0m"
     scp -P$port $zb_svr/zb-agent.sh $user@$ipl:$scri_dir/ &>/dev/null &&\
     ssh -p$port $user@$ipl "/bin/sh $scri_dir/zb-agent.sh"
  else  
    echo -e "\033[32m===========install $ipl zabbix-agent=================\033[0m"
     scp -P$port $zb_svr/zb-agent.sh $user@$ipl:$scri_dir/ &>/dev/null &&\
     ssh -p$port $user@$ipl "/bin/sh $scri_dir/zb-agent.sh"
  fi
done
}

ntp(){
  for ipl in `cat $scri_dir/ip.log`
do
  echo -e "\033[32m===========crontab ntp from 61==============\033[0m"
  ssh -p$port $user@$ipl "echo -e '#ntp from 61\n*/5 * * * * /usr/sbin/ntpdate 172.16.1.61 &>/dev/null && hwclock -w &>/dev/null' >>/var/spool/cron/root" &&\
  action "cron ntp from 61" /bin/true
done
}

host(){
for ipl in `cat $scri_dir/ip.log`
do
  echo -e "\033[32m===========update $ipl /etc/hosts==========\033[0m"
  scp -P$port $zb_svr/host.sh $user@$ipl:$scri_dir/ &>/dev/null &&\
  ssh -p$port $user@$ipl "/bin/sh $scri_dir/host.sh"
done
}

#开始集群安装
main(){
nfs31
backup41
db51
web08
web07
lb
sal
zabbix
ntp
host
}

main $*
