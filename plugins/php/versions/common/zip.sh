#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

curPath=`pwd`

appPath=$(dirname "$curPath")

rootPath=$(dirname "$curPath")
rootPath=$(dirname "$rootPath")
rootPath=$(dirname "$rootPath")
rootPath=$(dirname "$rootPath")
serverPath=$(dirname "$rootPath")
sourcePath=${serverPath}/source/php

actionType=$1
version=$2

LIBNAME=zip
LIBV=0


if [ "$version" -lt "73" ];then
	echo "not need"
	exit 1
fi

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

export PKG_CONFIG_PATH=/home/slemp/server/lib/libzip/lib/pkgconfig

Install_lib()
{

	isInstall=`cat $serverPath/php/$version/etc/php.ini|grep "${LIBNAME}.so"`
	if [ "${isInstall}" != "" ];then
		echo "php-$version ${LIBNAME} is installed, please select another version!"
		return
	fi

	if [ ! -f "$extFile" ];then

		if [ ! -d $sourcePath/php${version}/ext ];then
			cd ${rootPath}/plugins/php && /bin/bash install.sh install ${version}
		fi

		cd $sourcePath/php${version}/ext/${LIBNAME}

		$serverPath/php/$version/bin/phpize
		./configure --with-php-config=$serverPath/php/$version/bin/php-config \
		--with-zip

		make clean && make && make install && make clean

	fi

	if [ ! -f "$extFile" ];then
		echo "ERROR!"
		return
	fi

    echo "" >> $serverPath/php/$version/etc/php.ini
	echo "[${LIBNAME}]" >> $serverPath/php/$version/etc/php.ini
	echo "extension=${LIBNAME}.so" >> $serverPath/php/$version/etc/php.ini

	bash ${rootPath}/plugins/php/versions/lib.sh $version restart
	echo '==========================================================='
	echo 'successful!'
}


Uninstall_lib()
{
	if [ ! -f "$serverPath/php/$version/bin/php-config" ];then
		echo "php-$version is not installed, please select another version!"
		return
	fi

	if [ ! -f "$extFile" ];then
		echo "php-$version ${LIBNAME} is not installed, please select another version!"
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
