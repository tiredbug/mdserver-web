#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

# RED='\e[1;31m'    # 红色
# GREEN='\e[1;32m'  # 绿色
# YELLOW='\e[1;33m' # 黄色
# BLUE='\e[1;34m'   # 蓝色
# PURPLE='\e[1;35m' # 紫色
# CYAN='\e[1;36m'   # 蓝绿色
# WHITE='\e[1;37m'  # 白色
# NC='\e[0m' # 没有颜色

if grep -Eq "Debian" /etc/*-release; then
    ln -sf /bin/bash /bin/sh
fi

apt update -y


apt install -y wget curl lsof unzip
apt install -y python3-pip
apt install -y python3-dev
apt install -y python3-venv
apt install -y cron

apt install -y locate
locale-gen en_US.UTF-8
localedef -v -c -i en_US -f UTF-8 en_US.UTF-8

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


#fix zlib1g-dev fail
echo -e "\e[0;32mfix zlib1g-dev install question start\e[0m"
Install_TmpFile=/tmp/debian-fix-zlib1g-dev.txt
apt install -y zlib1g-dev > ${Install_TmpFile}
if [ "$?" != "0" ];then
	ZLIB1G_BASE_VER=$(cat ${Install_TmpFile} | grep zlib1g | awk -F "=" '{print $2}' | awk -F ")" '{print $1}')
	ZLIB1G_BASE_VER=`echo ${ZLIB1G_BASE_VER} | sed "s/^[ \s]\{1,\}//g;s/[ \s]\{1,\}$//g"`
	# echo "1${ZLIB1G_BASE_VER}1"
	echo -e "\e[1;31mapt install zlib1g=${ZLIB1G_BASE_VER} zlib1g-dev\e[0m"
	echo "Y" | apt install zlib1g=${ZLIB1G_BASE_VER}  zlib1g-dev
fi
rm -rf ${Install_TmpFile}
echo -e "\e[0;32mfix zlib1g-dev install question end\e[0m"


#fix libunwind-dev fail
echo -e "\e[0;32mfix libunwind-dev install question start\e[0m"
Install_TmpFile=/tmp/debian-fix-libunwind-dev.txt
apt install -y libunwind-dev > ${Install_TmpFile}
if [ "$?" != "0" ];then
	liblzma5_BASE_VER=$(cat ${Install_TmpFile} | grep liblzma-dev | awk -F "=" '{print $2}' | awk -F ")" '{print $1}')
	liblzma5_BASE_VER=`echo ${liblzma5_BASE_VER} | sed "s/^[ \s]\{1,\}//g;s/[ \s]\{1,\}$//g"`
	echo -e "\e[1;31mapt install liblzma5=${liblzma5_BASE_VER} libunwind-dev\e[0m"
	echo "Y" | apt install liblzma5=${liblzma5_BASE_VER} libunwind-dev
fi
rm -rf ${Install_TmpFile}
echo -e "\e[0;32mfix libunwind-dev install question end\e[0m"


apt install -y libvpx-dev
apt install -y libxpm-dev
apt install -y libwebp-dev
apt install -y libfreetype6-dev

cd /home/slemp/server/panel/scripts && bash lib.sh
chmod 755 /home/slemp/server/panel/data



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
