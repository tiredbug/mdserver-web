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

LIBNAME=ZendGuardLoader

sysName=`uname`
actionType=$1
version=$2

NON_ZTS_FILENAME=`ls $serverPath/php/${version}/lib/php/extensions | grep no-debug-non-zts`
extFile=$serverPath/php/${version}/lib/php/extensions/${NON_ZTS_FILENAME}/${LIBNAME}.so

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

		if [ $sysName == 'Darwin' ]; then
			wget -O $php_lib/zend-loader-php5.3.tar.gz http://downloads.zend.com/guard/5.5.0/ZendGuardLoader-php-5.3-darwin-i386.tar.gz
		else
			wget -O $php_lib/zend-loader-php5.3.tar.gz http://downloads.zend.com/guard/5.5.0/ZendGuardLoader-php-5.3-linux-glibc23-x86_64.tar.gz
		fi 

		cd $php_lib && tar xvf zend-loader-php5.3.tar.gz
		cd ZendGuardLoader-php* && cd php-5.3.x
		cp ZendGuardLoader.so $serverPath/php/$version/lib/php/extensions/no-debug-non-zts-20090626/

	fi
	
	if [ ! -f "$extFile" ];then
		echo "ERROR!"
		return
	fi

	echo  "" >> $serverPath/php/$version/etc/php.ini
	echo  "[Zend ZendGuard Loader]" >> $serverPath/php/$version/etc/php.ini
	echo  "zend_extension=$serverPath/php/$version/lib/php/extensions/no-debug-non-zts-20090626/ZendGuardLoader.so" >> $serverPath/php/$version/etc/php.ini
	echo  "zend_loader.enable=1" >> $serverPath/php/$version/etc/php.ini
	echo  "zend_loader.disable_licensing=0" >> $serverPath/php/$version/etc/php.ini
	echo  "zend_loader.obfuscation_level_support=3" >> $serverPath/php/$version/etc/php.ini
	echo  "zend_loader.license_path=" >> $serverPath/php/$version/etc/php.ini
	
	bash ${rootPath}/plugins/php/versions/lib.sh $version restart
	echo '==========================================================='
	echo 'successful!'
}


Uninstall_lib()
{
	if [ ! -f "$serverPath/php/$version/bin/php-config" ];then
		echo "php$version 未安装,请选择其它版本!"
		return
	fi

	if [ ! -f "$extFile" ];then
		echo "php-$version 未安装${LIBNAME},请选择其它版本!"
		return
	fi
	
	sed -i $BAK "/ZendGuardLoader.so/d"  $serverPath/php/$version/etc/php.ini
	sed -i $BAK "/zend_loader/d"  $serverPath/php/$version/etc/php.ini
	sed -i $BAK "/\[Zend ZendGuard Loader\]/d"  $serverPath/php/$version/etc/php.ini
		
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