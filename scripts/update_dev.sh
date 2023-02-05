#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
# LANG=en_US.UTF-8
is64bit=`getconf LONG_BIT`

startTime=`date +%s`

_os=`uname`
echo "use system: ${_os}"

if [ "$EUID" -ne 0 ]
  then echo "Please run as root!"
  exit
fi

if [ ${_os} != "Darwin" ] && [ ! -d /www/server/mdserver-web/logs ]; then
	mkdir -p /www/server/mdserver-web/logs
fi

{

if [ ${_os} == "Darwin" ]; then
	OSNAME='macos'
elif grep -Eq "openSUSE" /etc/*-release; then
	OSNAME='opensuse'
	zypper refresh
elif grep -Eq "FreeBSD" /etc/*-release; then
	OSNAME='freebsd'
elif grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
	OSNAME='centos'
	yum install -y wget zip unzip
elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release; then
	OSNAME='fedora'
	yum install -y wget zip unzip
elif grep -Eqi "Rocky" /etc/issue || grep -Eq "Rocky" /etc/*-release; then
	OSNAME='rocky'
	yum install -y wget zip unzip
elif grep -Eqi "AlmaLinux" /etc/issue || grep -Eq "AlmaLinux" /etc/*-release; then
	OSNAME='alma'
	yum install -y wget zip unzip
elif grep -Eqi "Amazon Linux" /etc/issue || grep -Eq "Amazon Linux" /etc/*-release; then
	OSNAME='amazon'
	yum install -y wget zip unzip
elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
	OSNAME='debian'
	apt install -y wget zip unzip
elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
	OSNAME='ubuntu'
	apt install -y wget zip unzip
elif grep -Eqi "Raspbian" /etc/issue || grep -Eq "Raspbian" /etc/*-release; then
	OSNAME='raspbian'
else
	OSNAME='unknow'
fi

cn=$(curl -fsSL -m 10 http://ipinfo.io/json | grep "\"country\": \"CN\"")
if [ ! -z "$cn" ];then
	curl -sSLo /tmp/dev.zip https://gitee.com/midoks/mdserver-web/repository/archive/dev.zip
else
	curl -sSLo /tmp/dev.zip https://github.com/midoks/mdserver-web/archive/refs/heads/dev.zip
fi

# wget -O /tmp/dev.zip https://github.com/midoks/mdserver-web/archive/refs/heads/dev.zip
cd /tmp && unzip /tmp/dev.zip

echo "update mdserver-web code start"
if [ -f /usr/bin/cp ];then
	/usr/bin/cp -rf /tmp/mdserver-web-dev/* /www/server/mdserver-web
elif [ -f /bin/cp ];then
	/bin/cp -rf /tmp/mdserver-web-dev/* /www/server/mdserver-web
else
	/usr/bin/cp -rf /tmp/mdserver-web-dev/* /www/server/mdserver-web
fi
echo "update mdserver-web code end"

rm -rf /tmp/dev.zip
rm -rf /tmp/mdserver-web-dev

#pip uninstall public
echo "use system version: ${OSNAME}"
cd /www/server/mdserver-web && bash scripts/update/${OSNAME}.sh

bash /etc/rc.d/init.d/mw restart
bash /etc/rc.d/init.d/mw default

if [ -f /usr/bin/mw ];then
	rm -rf /usr/bin/mw
fi

if [ ! -e /usr/bin/mw ]; then
	if [ ! -f /usr/bin/mw ];then
		ln -s /etc/rc.d/init.d/mw /usr/bin/mw
	fi
fi

endTime=`date +%s`
((outTime=($endTime-$startTime)/60))
echo -e "Time consumed:\033[32m $outTime \033[0mMinute!"

} 1> >(tee /www/server/mdserver-web/logs/mw-update.log) 2>&1