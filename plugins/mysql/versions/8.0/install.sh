# -*- coding: utf-8 -*-
#!/bin/bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#https://dev.mysql.com/downloads/mysql/5.7.html
#https://dev.mysql.com/downloads/file/?id=489855

curPath=`pwd`
rootPath=$(dirname "$curPath")
rootPath=$(dirname "$rootPath")
serverPath=$(dirname "$rootPath")
sysName=`uname`


install_tmp=${rootPath}/tmp/slemp_install.pl
mysqlDir=${serverPath}/source/mysql

_os=`uname`
echo "use system: ${_os}"
if [ ${_os} == "Darwin" ]; then
	OSNAME='macos'
elif grep -Eq "openSUSE" /etc/*-release; then
	OSNAME='opensuse'
	zypper refresh
elif grep -Eq "FreeBSD" /etc/*-release; then
	OSNAME='freebsd'
	pkg install -y wget unzip
elif grep -Eqi "Arch" /etc/issue || grep -Eq "Arch" /etc/*-release; then
	OSNAME='arch'
	echo y | pacman -Sy unzip
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
elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
	OSNAME='debian'
	apt update -y
	apt install -y devscripts
	apt install -y wget zip unzip
elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
	OSNAME='ubuntu'
	apt install -y wget zip unzip
else
	OSNAME='unknow'
fi

VERSION_ID=`cat /etc/*-release | grep VERSION_ID | awk -F = '{print $2}' | awk -F "\"" '{print $2}'`


VERSION=8.0.30
Install_mysql()
{
	mkdir -p ${mysqlDir}
	echo 'installing script file...' > $install_tmp


	if id mysql &> /dev/null ;then
	    echo "mysql UID is `id -u www`"
	    echo "mysql Shell is `grep "^www:" /etc/passwd |cut -d':' -f7 `"
	else
	    groupadd mysql
		useradd -g mysql mysql
	fi

	# ----- cpu start ------
	if [ -z "${cpuCore}" ]; then
    	cpuCore="1"
	fi

	if [ -f /proc/cpuinfo ];then
		cpuCore=`cat /proc/cpuinfo | grep "processor" | wc -l`
	fi

	MEM_INFO=$(free -m|grep Mem|awk '{printf("%.f",($2)/1024)}')
	if [ "${cpuCore}" != "1" ] && [ "${MEM_INFO}" != "0" ];then
	    if [ "${cpuCore}" -gt "${MEM_INFO}" ];then
	        cpuCore="${MEM_INFO}"
	    fi
	else
	    cpuCore="1"
	fi

	if [ "$cpuCore" -gt "1" ];then
		cpuCore=`echo "$cpuCore" | awk '{printf("%.f",($1)*0.8)}'`
	fi
	# ----- cpu end ------

	cd ${rootPath}/plugins/mysql/lib && /bin/bash rpcgen.sh

	INSTALL_CMD=cmake
	# check cmake version
	CMAKE_VERSION=`cmake -version | grep version | awk '{print $3}' | awk -F '.' '{print $1}'`
	if [ "$CMAKE_VERSION" -eq "2" ];then
		mkdir -p /var/log/mariadb
		touch /var/log/mariadb/mariadb.log
		INSTALL_CMD=cmake3
	fi

	if [ ! -f ${mysqlDir}/mysql-boost-${VERSION}.tar.gz ];then
		wget -O ${mysqlDir}/mysql-boost-${VERSION}.tar.gz --tries=3 https://cdn.mysql.com/archives/mysql-8.0/mysql-boost-${VERSION}.tar.gz
	fi

	#检测文件是否损坏.
	md5_mysql_ok=313d625fcaa932bd87b48f0cf9b40f1c
	if [ -f ${mysqlDir}/mysql-boost-${VERSION}.tar.gz ];then
		md5_mysql=`md5sum ${mysqlDir}/mysql-boost-${VERSION}.tar.gz  | awk '{print $1}'`
		if [ "${md5_mysql_ok}" == "${md5_mysql}" ]; then
			echo "mysql8.0 file  check ok"
		else
			# 重新下载
			rm -rf ${mysqlDir}/mysql-${VERSION}
			wget -O ${mysqlDir}/mysql-boost-${VERSION}.tar.gz --tries=3 https://cdn.mysql.com/archives/mysql-8.0/mysql-boost-${VERSION}.tar.gz
		fi
	fi

	if [ ! -d ${mysqlDir}/mysql-${VERSION} ];then
		 cd ${mysqlDir} && tar -zxvf  ${mysqlDir}/mysql-boost-${VERSION}.tar.gz
	fi

	OPTIONS=''
	##check openssl version
	OPENSSL_VERSION=`openssl version|awk '{print $2}'|awk -F '.' '{print $1}'`
	if [ "${OPENSSL_VERSION}" -ge "3" ];then
		#openssl version to high
		cd ${rootPath}/plugins/php/lib && /bin/bash openssl.sh
		export PKG_CONFIG_PATH=$serverPath/lib/openssl/lib/pkgconfig
		OPTIONS="-DWITH_SSL=${serverPath}/lib/openssl"
	fi

	WHERE_DIR_GCC=/usr/bin/gcc
	WHERE_DIR_GPP=/usr/bin/g++
	if [ "$OSNAME" == "centos" ] && [ "$VERSION_ID" == "7" ];then
		yum install -y libudev-devel
		yum install -y centos-release-scl
        yum install -y devtoolset-11-gcc devtoolset-11-gcc-c++ devtoolset-11-binutils

		gcc --version
		WHERE_DIR_GCC=/opt/rh/devtoolset-11/root/usr/bin/gcc
		WHERE_DIR_GPP=/opt/rh/devtoolset-11/root/usr/bin/g++
		echo $WHERE_DIR_GCC
		echo $WHERE_DIR_GPP
	fi

	if [ "$OSNAME" == "ubuntu" ] && [ "$VERSION_ID" == "18.04" ];then
		apt install -y libudev-dev
		apt install -y libtirpc-dev
		apt install -y libssl-dev
		apt install -y libgssglue-dev
		apt install -y software-properties-common
		add-apt-repository ppa:ubuntu-toolchain-r/test

		LIBTIRPC_VER=`pkg-config libtirpc --modversion`
		if [ ! -f ${mysqlDir}/libtirpc_1.2.5.orig.tar.bz2 ];then
			wget -O ${mysqlDir}/libtirpc_1.2.5.orig.tar.bz2 https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/libtirpc/1.2.5-1ubuntu0.1/libtirpc_1.2.5.orig.tar.bz2
			cd ${mysqlDir} && tar -jxvf libtirpc_1.2.5.orig.tar.bz2
			cd libtirpc-1.2.5 && ./configure
		fi

		export PKG_CONFIG_PATH=/usr/lib/pkgconfig
		apt install -y gcc-11 g++-11
		WHERE_DIR_GCC=/usr/bin/gcc-11
		WHERE_DIR_GPP=/usr/bin/g++-11
	fi


	if [ "$OSNAME" == "opensuse" ];then
		zypper install -y gcc11
		zypper install -y gcc11-c++


		WHERE_DIR_GCC=/usr/bin/gcc-11
		WHERE_DIR_GPP=/usr/bin/g++-11
	fi

	if [ ! -d $serverPath/mysql ];then
		# -DCMAKE_CXX_STANDARD=17 \
		cd ${mysqlDir}/mysql-${VERSION} && ${INSTALL_CMD} \
		-DCMAKE_INSTALL_PREFIX=$serverPath/mysql \
		-DMYSQL_USER=mysql \
		-DMYSQL_TCP_PORT=3306 \
		-DMYSQL_UNIX_ADDR=/var/tmp/mysql.sock \
		-DWITH_MYISAM_STORAGE_ENGINE=1 \
		-DWITH_INNOBASE_STORAGE_ENGINE=1 \
		-DWITH_MEMORY_STORAGE_ENGINE=1 \
		-DENABLED_LOCAL_INFILE=1 \
		-DWITH_PARTITION_STORAGE_ENGINE=1 \
		-DWITH_READLINE=1 \
		-DEXTRA_CHARSETS=all \
		-DDEFAULT_CHARSET=utf8mb4 \
		-DDEFAULT_COLLATION=utf8mb4_general_ci \
		-DDOWNLOAD_BOOST=1 \
		-DFORCE_INSOURCE_BUILD=1 \
		$OPTIONS \
		-DCMAKE_C_COMPILER=$WHERE_DIR_GCC \
		-DCMAKE_CXX_COMPILER=$WHERE_DIR_GPP \
		-DDOWNLOAD_BOOST=0 \
		-DWITH_BOOST=${mysqlDir}/mysql-${VERSION}/boost/
		make -j${cpuCore} && make install && make clean

		if [ -d $serverPath/mysql ];then
			echo '8.0' > $serverPath/mysql/version.pl
			echo 'The installation is complete' > $install_tmp
		else
			# rm -rf ${mysqlDir}/mysql-${VERSION}
			echo 'Installation failed' > $install_tmp
			echo 'install fail'>&2
			exit 1
		fi
	fi
}

Uninstall_mysql()
{
	rm -rf $serverPath/mysql
	echo 'Uninstall complete' > $install_tmp
}

action=$1
if [ "${1}" == "install" ];then
	Install_mysql
else
	Uninstall_mysql
fi
