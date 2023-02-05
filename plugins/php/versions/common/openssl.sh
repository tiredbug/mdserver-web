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

actionType=$1
version=$2

LIBNAME=openssl
LIBV=0

LIB_PATH_NAME=lib/php
if [ -d $serverPath/php/${version}/lib64 ];then
	LIB_PATH_NAME=lib64
fi

NON_ZTS_FILENAME=`ls $serverPath/php/${version}/${LIB_PATH_NAME}/extensions | grep no-debug-non-zts`
extFile=$serverPath/php/${version}/${LIB_PATH_NAME}/extensions/${NON_ZTS_FILENAME}/${LIBNAME}.so

sysName=`uname`
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
	
	# cd ${rootPath}/plugins/php/lib && /bin/bash openssl_10.sh
	if [ "$version" -lt "81" ];then
		cd ${rootPath}/plugins/php/lib && /bin/bash openssl_10.sh
	fi

	if [ "$sysName" == "Darwin" ] ;then 
		LIB_DEPEND_DIR=`brew info openssl@1.1 | grep /usr/local/Cellar/openssl | cut -d \  -f 1 | awk 'END {print}'`
		export PKG_CONFIG_PATH=$LIB_DEPEND_DIR/lib/pkgconfig
	fi

	if [ ! -f "$extFile" ];then

		if [ ! -d $sourcePath/php${version}/ext ];then
			cd ${rootPath}/plugins/php && /bin/bash install.sh install ${version}
		fi

		cd $sourcePath/php${version}/ext/${LIBNAME}

		if [ ! -f "config.m4" ];then
			mv config0.m4 config.m4
		fi
		
		# openssl_version=`pkg-config openssl --modversion`
		# export PKG_CONFIG_PATH=$serverPath/lib/openssl10/lib/pkgconfig
		if [ "$version" -lt "81" ];then
			export PKG_CONFIG_PATH=$serverPath/lib/openssl10/lib/pkgconfig
		fi

		$serverPath/php/$version/bin/phpize
		./configure --with-php-config=$serverPath/php/$version/bin/php-config \
		--with-openssl
		make clean && make && make install && make clean
		
	fi

	if [ ! -f "$extFile" ];then
		echo "ERROR!"
		return
	fi

    echo "" >> $serverPath/php/$version/etc/php.ini
	echo "[${LIBNAME}]" >> $serverPath/php/$version/etc/php.ini
	echo "extension=${LIBNAME}.so" >> $serverPath/php/$version/etc/php.ini
	if [ -f "/etc/ssl/certs/ca-certificates.crt" ];then
		echo "openssl.cafile=/etc/ssl/certs/ca-certificates.crt" >> $serverPath/php/$version/etc/php.ini
	elif [ -f "/etc/pki/tls/certs/ca-bundle.crt" ];then
		echo "openssl.cafile=/etc/pki/tls/certs/ca-bundle.crt" >> $serverPath/php/$version/etc/php.ini
	fi
	
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
		return
	fi
	
	echo $serverPath/php/$version/etc/php.ini
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