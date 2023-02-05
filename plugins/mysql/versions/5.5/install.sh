#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#https://dev.mysql.com/downloads/mysql/5.5.html#downloads
#https://dev.mysql.com/downloads/file/?id=480541

curPath=`pwd`
rootPath=$(dirname "$curPath")
rootPath=$(dirname "$rootPath")
serverPath=$(dirname "$rootPath")
sysName=`uname`

install_tmp=${rootPath}/tmp/slemp_install.pl
mysqlDir=${serverPath}/source/mysql


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

	if [ "$sysName" != "Darwin" ];then
		mkdir -p /var/log/mariadb
		touch /var/log/mariadb/mariadb.log
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

	if [ ! -f ${mysqlDir}/mysql-5.5.62.tar.gz ];then
		wget -O ${mysqlDir}/mysql-5.5.62.tar.gz --tries=3 https://dev.mysql.com/get/Downloads/MySQL-5.5/mysql-5.5.62.tar.gz
	fi

	if [ ! -d ${mysqlDir}/mysql-5.5.62 ];then
		 cd ${mysqlDir} && tar -zxvf  ${mysqlDir}/mysql-5.5.62.tar.gz
	fi


	if [ ! -d $serverPath/mysql ];then
		cd ${mysqlDir}/mysql-5.5.62 && cmake \
		-DCMAKE_INSTALL_PREFIX=$serverPath/mysql \
		-DMYSQL_USER=mysql \
		-DMYSQL_TCP_PORT=3306 \
		-DMYSQL_UNIX_ADDR=/var/tmp/mysql.sock \
		-DWITH_MYISAM_STORAGE_ENGINE=1 \
		-DWITH_INNOBASE_STORAGE_ENGINE=1 \
		-DWITH_MEMORY_STORAGE_ENGINE=1 \
		-DENABLED_LOCAL_INFILE=1 \
		-DWITH_PARTITION_STORAGE_ENGINE=1 \
		-DEXTRA_CHARSETS=all \
		-DDEFAULT_CHARSET=utf8mb4 \
		-DDEFAULT_COLLATION=utf8mb4_general_ci \
		-DCMAKE_C_COMPILER=/usr/bin/gcc \
		-DCMAKE_CXX_COMPILER=/usr/bin/g++
		make -j${cpuCore} && make install && make clean

		if [ -d $serverPath/mysql ];then
			echo '5.5' > $serverPath/mysql/version.pl
			echo 'The installation is complete' > $install_tmp
		else
			# rm -rf ${mysqlDir}/mysql-5.5.62
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
