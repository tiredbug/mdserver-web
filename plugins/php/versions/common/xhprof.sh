#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

curPath=`pwd`

rootPath=$(dirname "$curPath")
rootPath=$(dirname "$rootPath")
rootPath=$(dirname "$rootPath")
rootPath=$(dirname "$rootPath")
serverPath=$(dirname "$rootPath")
sourcePath=${serverPath}/source/php

LIBNAME=xhprof
LIBV=2.3.7
sysName=`uname`
actionType=$1
version=$2

if [ "$version" -lt "70" ];then
	LIBV=0.9.4
fi

LIB_PATH_NAME=lib/php
if [ -d $serverPath/php/${version}/lib64 ];then
	LIB_PATH_NAME=lib64
fi

NON_ZTS_FILENAME=`ls $serverPath/php/${version}/${LIB_PATH_NAME}/extensions | grep no-debug-non-zts`
extFile=$serverPath/php/${version}/${LIB_PATH_NAME}/extensions/${NON_ZTS_FILENAME}/${LIBNAME}.so

if [ "$sysName" == "Darwin" ];then
	BAK='_bak'
else
	BAK=''
fi


Install_lib()
{
	isInstall=`cat $serverPath/php/$version/etc/php.ini|grep "${LIBNAME}.so"`
	if [ "${isInstall}" != "" ];then
		echo "php-$version 已安装${LIBNAME},请选择其它版本!"
		return
	fi
	
	if [ ! -f "$extFile" ];then
		php_lib=$sourcePath/php_lib
		mkdir -p $php_lib
		if [ ! -d $php_lib/${LIBNAME}-${LIBV} ];then
			wget -O $php_lib/${LIBNAME}-${LIBV}.tgz http://pecl.php.net/get/${LIBNAME}-${LIBV}.tgz
			cd $php_lib && tar xvf ${LIBNAME}-${LIBV}.tgz
		fi 
		cd $php_lib/${LIBNAME}-${LIBV}/extension

		$serverPath/php/$version/bin/phpize
		./configure --enable-xhprof \
		--with-php-config=$serverPath/php/$version/bin/php-config
		make clean && make && make install && make clean

	fi
	
	if [ ! -f "$extFile" ];then
		echo "ERROR!"
		return
	fi

	if [ ! -f /tmp/xhprof ];then
		mkdir -p /tmp/xhprof
		chown -R www:www /tmp/xhprof
	fi

	echo "" >> $serverPath/php/$version/etc/php.ini
	echo "[${LIBNAME}]" >> $serverPath/php/$version/etc/php.ini
	echo "extension=${LIBNAME}.so" >> $serverPath/php/$version/etc/php.ini
	echo "${LIBNAME}.output_dir=/tmp/xhprof" >> $serverPath/php/$version/etc/php.ini

	bash ${rootPath}/plugins/php/versions/lib.sh $version restart
	echo '==========================================================='
	echo 'successful!'
}


Uninstall_lib()
{
	if [ ! -f "$serverPath/php/$version/bin/php-config" ];then
		echo "php-$version 未安装,请选择其它版本!"
		return
	fi
	
	if [ ! -f "$extFile" ];then
		echo "php-$version 未安装${LIBNAME},请选择其它版本!"
		echo "php-$version not install ${LIBNAME}, Plese select other version!"
		return
	fi
	
	sed -i $BAK "/${LIBNAME}.so/d" $serverPath/php/$version/etc/php.ini
	sed -i $BAK "/${LIBNAME}/d" $serverPath/php/$version/etc/php.ini
		
	rm -f $extFile
	bash ${rootPath}/plugins/php/versions/lib.sh $version restart
	echo '==============================================='
	echo 'successful!'
}


if [ "$actionType" == 'install' ];then
	Install_lib
elif [ "$actionType" == 'uninstall' ];then
	Uninstall_lib
fi