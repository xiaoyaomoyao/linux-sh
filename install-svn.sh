#!/bin/bash

. /etc/rc.d/init.d/functions

svndir='/var/svn/svnrepos'
svnconf='/var/svn/svnrepos/conf'

yum install -y subversion

if [ ! -d $svndir ];then
mkdir -p $svndir
fi
if [ -d $svndir ];then
/usr/bin/svnadmin create /var/svn/svnrepos
fi
echo -e "\033[32m this is backup conffile... \033[0m"
sudo /bin/cp $svnconf/authz{,.ori}
sudo /bin/cp $svnconf/passwd{,.ori}
sudo /bin/cp $svnconf/svnserve.conf{,.ori}
echo -e "\033[32m conf_file backup success! \033[0m"

echo -e "\033[32m start change authz,passwd,svnserve.conf file... \033[0m"
echo -e "[/]\nmyadmin=rw" >>$svnconf/authz
echo "myadmin=123456" >>$svnconf/passwd
sed -i "s@#anon-access = read@anon-access = read@g" $svnconf/svnserve.conf
sed -i "s@#auth-access = write@auth-access = write@g" $svnconf/svnserve.conf
sed -i "s@#password-db = passwd@password-db = passwd@g" $svnconf/svnserve.conf
sed -i "s@#authz-db = authz@authz-db = authz@g" $svnconf/svnserve.conf
sed -i "s@#realm=/var/svn/svnrepos@realm=/var/svn/svnrepos@g" $svnconf/svnserve.conf
echo -e "\033[32m file change success! \033[0m"

svnserve -d -r $svndir

if [ `netstat -antplu|grep :3690|wc -l` -eq 1 ];then
    action "svn-server:" /bin/true
else
    action "svn-server:" /bin/false
fi

iptables -A INPUT -m tcp -p tcp --dport 3690 -j ACCEPT


