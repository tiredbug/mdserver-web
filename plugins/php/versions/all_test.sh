#! /bin/sh
export PATH=$PATH:/opt/local/bin:/opt/local/sbin:/opt/local/share/man:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin
DIR=$(cd "$(dirname "$0")"; pwd)
ROOT_DIR=$(cd "$(dirname "$0")"; pwd)

# cd /www/server/mdserver-web/scripts/quick && bash debug.sh
# cd /www/server/mdserver-web/plugins/php/versions && /bin/bash all_test.sh

# cd /www/server/mdserver-web/plugins/php && bash install.sh install 55
# cd /www/server/mdserver-web/plugins/php/versions/common && bash gd.sh install 73
# cd /www/server/mdserver-web/plugins/php/versions/common && bash swoole.sh install 54


# PHP_VER=52
# echo "php${PHP_VER} -- start"
# cmd_ext=$(ls -l $DIR/versions/$PHP_VER/ |awk '{print $9}')
# cd $DIR && /bin/bash install.sh install $PHP_VER
# for ii in $cmd_ext
# do
# 	if [ "install.sh" == "$ii" ];then
# 		echo '' > /tmp/t.log
# 	else
# 		cd $DIR/versions/$PHP_VER &&  /bin/bash $ii install $PHP_VER
# 	fi 
# done
# echo "php${PHP_VER} -- end"


PHP_VER_LIST=(53 54 55 56 70 71 72 73 74 80 81 82)
# PHP_VER_LIST=(81)
for PHP_VER in ${PHP_VER_LIST[@]}; do
	echo "php${PHP_VER} -- start"
	if [ ! -d  /www/server/php/${PHP_VER} ];then
		cd /www/server/mdserver-web/plugins/php && bash install.sh install ${PHP_VER}
	fi
	echo "php${PHP_VER} -- end"
done

cd $DIR
PHP_VER_LIST=(53 54 55 56 70 71 72 73 74 80 81 82)
PHP_EXT_LIST=(ioncube ZendGuardLoader pdo mysqlnd sqlite3 openssl pcntl opcache mcrypt fileinfo \
	exif gd intl memcache memcached redis imagemagick xdebug xhprof \
	swoole yaf yar yac apc mongo mongodb solr seaslog mbstring iconv phalcon)

for PHP_VER in ${PHP_VER_LIST[@]}; do
	echo "php${PHP_VER} -- start"

	if [ ! -d /www/server/php/${PHP_VER} ];then
		echo "php${PHP_VER} is not install!"
		continue
	fi

	NON_ZTS_FILENAME=`ls /www/server/php/${PHP_VER}/lib/php/extensions | grep no-debug-non-zts`
	for EXT in ${PHP_EXT_LIST[@]}; do
		extFile=/www/server/php/${PHP_VER}/lib/php/extensions/${NON_ZTS_FILENAME}/${EXT}.so
		echo "${PHP_VER} ${EXT} start"
		if [ ! -f $extFile ];then
			bash common.sh  $PHP_VER  install ${EXT}
		fi
		echo "${PHP_VER} ${EXT} end"
	done
	
	echo "php${PHP_VER} -- end"
done

