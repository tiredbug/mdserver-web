#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

if grep -Eq "Ubuntu" /etc/*-release; then
    sudo ln -sf /bin/bash /bin/sh
    #sudo dpkg-reconfigure dash
fi


apt update -y

apt install -y wget curl lsof unzip
apt install -y python3-pip
apt install -y python3-venv
apt install -y python3-dev


apt install -y cron

if [ ! -d /root/.acme.sh ];then
	curl  https://get.acme.sh | sh
fi


if [ -f /usr/sbin/ufw ];then

	ufw allow 22/tcp
	ufw allow 80/tcp
	ufw allow 443/tcp
	ufw allow 888/tcp
	# ufw allow 7200/tcp
	# ufw allow 3306/tcp
	# ufw allow 30000:40000/tcp

fi


if [ -f /usr/sbin/ufw ];then
	ufw disable
fi

if [ ! -f /usr/sbin/ufw ];then
	apt install -y firewalld
	systemctl enable firewalld
	systemctl start firewalld

	firewall-cmd --permanent --zone=public --add-port=22/tcp
	firewall-cmd --permanent --zone=public --add-port=80/tcp
	firewall-cmd --permanent --zone=public --add-port=443/tcp
	firewall-cmd --permanent --zone=public --add-port=888/tcp
	# firewall-cmd --permanent --zone=public --add-port=7200/tcp
	# firewall-cmd --permanent --zone=public --add-port=3306/tcp
	# firewall-cmd --permanent --zone=public --add-port=30000-40000/tcp

	# fix:debian10 firewalld faq
	# https://kawsing.gitbook.io/opensystem/andoid-shou-ji/untitled/fang-huo-qiang#debian-10-firewalld-0.6.3-error-commandfailed-usrsbinip6tablesrestorewn-failed-ip6tablesrestore-v1.8
	sed -i 's#IndividualCalls=no#IndividualCalls=yes#g' /etc/firewalld/firewalld.conf

	firewall-cmd --reload
fi

#Does not turn on during installation时不开启
systemctl stop firewalld


cd /home/slemp/server/panel/scripts && bash lib.sh
chmod 755 /home/slemp/server/panel/data



# mysql8.0 在ubuntu22需要的库
apt install -y patchelf

VERSION_ID=`cat /etc/*-release | grep VERSION_ID | awk -F = '{print $2}' | awk -F "\"" '{print $2}'`
if [ "${VERSION_ID}" == "22.04" ];then
    pip3 install -U --force-reinstall --no-binary :all: gevent
fi

if [ ! -f /home/slemp/server/panel/bin/activate ];then
    cd /home/slemp/server/panel && python3 -m venv .
    cd /home/slemp/server/panel && source /home/slemp/server/panel/bin/activate
else
    cd /home/slemp/server/panel && source /home/slemp/server/panel/bin/activate
fi

if [ "${VERSION_ID}" == "22.04" ];then
    pip3 install -U --force-reinstall --no-binary :all: gevent
fi



cd /home/slemp/server/panel && ./cli.sh start
isStart=`ps -ef|grep 'gunicorn -c setting.py app:app' |grep -v grep|awk '{print $2}'`
n=0
while [[ ! -f /etc/init.d/slemp ]];
do
    echo -e ".\c"
    sleep 1
    let n+=1
    if [ $n -gt 20 ];then
    	echo -e "start slemp fail"
        exit 1
    fi
done

cd /home/slemp/server/panel && /etc/init.d/slemp stop
cd /home/slemp/server/panel && /etc/init.d/slemp start
cd /home/slemp/server/panel && /etc/init.d/slemp default
