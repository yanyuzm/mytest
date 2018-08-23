#!/bin/bash
#auto install zabbix
#by caomuzhong
#date:2018-06-30

#功能选择菜单
menu(){ 
echo
echo -e "\033[31;32m                                  Zabbix编译安装部署脚本                               \033[0m"
echo -e "\033[31;32m=======================================================================================\033[0m"
echo -e "\033[34m       本脚本在RHEL   7.5  CentOS  6.5  7.5上测试成功，其他版本未测！       \033[0m"
echo -e "\033[47;34m------------------------------zabbix 服务端信息如下------------------------------------\033[0m"
echo
echo "   服务端ip：192.168.10.205    数据库名：zabbix   数据库用户：zabbix    密码： 123456 "
echo -e "\033[31;32m  实际中，可在脚本中修改数据库名、用户和密码、服务端ip！   \033[0m"
echo
echo -e "\033[47;34m---------------------------------------------------------------------------------------\033[0m"
echo -e "\033[31;32m========================================================================================\033[0m"
echo "         zabbix安装目录：/usr/local/zabbix  "
echo -e "\033[34m————by author caomuzhong  博客:www.logmm.com\033[0m"
echo -e "\033[31;32m========================================================================================\033[0m"
echo -e "\033[31;32mzabbix服务端：必须有lamp或lnmp环境，zabbix的默认网站目录:/htdocs/zabbix  \033[0m"
echo -e "\033[34m部署zabbix服务端，若无lnmp环境，输入数字1即可部署lnmp环境！之后再部署zabbix服务端！\033[0m"
echo -e "\033[34m如果只部署agentd端，无需lamp或lnmp环境，输入数字3直接部署。\033[0m"
echo -e "\033[31;32m========================================================================================\033[0m"
echo
echo -e "\033[34m功能选项:\033[0m"
echo -e "\033[36m   1、编译安装部署lnmp环境        2、安装部署zabbix server和agent    \033[0m"
echo -e "\033[36m   3、只安装部署zabbix agent      4、退出脚本  \033[0m"
echo -e "\033[31;32m========================================================================================\033[0m"
echo
read -p "请输入数字:"   num
}

###########################################################################

#      *****************lnmp编译安装部署****************************

###########################################################################

#(0)安装依赖包
install_package(){
        cd;echo
        echo -e "\033[34m********yum安装依赖包********\033[0m"
        #yum groupinstall "Development Tools" -y
        yum install -y bzip2-devel openssl-devel gnutls-devel gcc gcc-c++ cmake ncurses-devel bison-devel libaio-devel openldap  openldap-devel 
        yum install -y autoconf bison libxml2-devel libcurl-devel libevent libevent-devel gd-devel curl expat-devel
        #curl -O https://nchc.dl.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz
        if [ ! -f libmcrypt-2.5.8.tar.gz ];then
            curl -O  http://iweb.dl.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz
        fi
        [ ! -d libmcrypt-2.5.8 ] && tar xf libmcrypt-2.5.8.tar.gz
        cd libmcrypt-2.5.8
        ./configure && make && make install
        if [[ `echo $?` -eq 0 ]];then
               sleep 3
               echo -e "\033[36m安装依赖包成功。。。\033[0m"
          else 
               echo -e "\033[34m安装依赖包失败****请检查****\033[0m"
        fi
}
#(1)编译安装nginx
install_nginx(){
        cd;echo
        echo -e "\033[34m********编译安装nginx********\033[0m"
        #1、新建nginx系统用户
        id nginx &> /dev/null
        [ $? -ne 0 ] && useradd -r -s /sbin/nologin nginx
        #2、新建nginx日志存放目录
        [ ! -d /mydata/logs/nginx/ ] &&  mkdir /mydata/logs/nginx/ -pv && chown -R  nginx.nginx /mydata/logs/nginx/
        #3、定义nginx安装的版本
        NGINX_VERS=nginx-1.14.0
        #4、下载nginx
        if [ ! -f $NGINX_VERS.tar.gz ];then
           echo -e "\033[36m*******正在下载nginx源码包。。。\033[0m"
           curl -O  http://nginx.org/download/$NGINX_VERS.tar.gz
        fi
        #5、解压下载包
        [ ! -d $NGINX_VERS ] && tar -xf $NGINX_VERS.tar.gz
        #6、进入nginx解压后的目录
        cd $NGINX_VERS
        #7、编译安装
        ./configure --prefix=/usr/local/nginx \
        --user=nginx \
        --group=nginx \
        --http-log-path=/mydata/logs/nginx/access.log \
        --error-log-path=/mydata/logs/nginx/error.log \
        --with-http_ssl_module \
        --with-http_realip_module \
        --with-http_flv_module \
        --with-http_mp4_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_image_filter_module \
        --with-http_stub_status_module &&  make && make install

        if [[ `echo $?` -eq 0 ]];then
               sleep 3
               echo -e "\033[36mnginx编译安装成功。。。\033[0m"
          else 
               echo -e "\033[34mnginx编译安装失败****请检查****\033[0m"
               exit 1
        fi
}
#(2)源码编译安装mariadb
install_mariadb(){
        cd;echo
        echo -e "\033[34m********编译安装mariadb********\033[0m"
        VERSION=10.3.7 #定义安装的版本，如5.5.60、10.3.7等
        if [ ! -f mariadb-$VERSION.tar.gz ];then
             #下载maridb
             echo -e "\033[34m=========下载maraidb源码包===========\033[0m"
             curl -O http://mirrors.tuna.tsinghua.edu.cn/mariadb//mariadb-$VERSION/source/mariadb-$VERSION.tar.gz  
        fi
   # 1、创建mysql用户
        id mysql &> /dev/null
        [ $? -ne 0 ] && useradd -r -s /sbin/nologin mysql
    #2、创建数据库数据存放目录、安装目录
        [ ! -d  /mydata/mariadb/ ] && mkdir  /mydata/mariadb/ -pv
        [ ! -d  /usr/local/mysql/ ] && mkdir /usr/local/mysql/ -pv
        chown -R mysql.mysql  /mydata/mariadb/
        chown -R mysql.mysql  /usr/local/mysql/
    #3、解压、编译、安装mriadb
        echo -e "\033[34m=========编译安装maraidb===========\033[0m"
        if [ ! -d  mariadb-$VERSION ];then
           tar xf mariadb-$VERSION.tar.gz
        fi
        cd  mariadb-$VERSION
        [ -f CMakeCache.txt ] && rm -f CMakeCache.txt
        echo -e "\033[34m**********编译安装即将开始，过程需要很长时间******** \033[0m"
        cmake . -DCMAKE_INSTALL_PREFIX=/usr/local/mysql  \
        -DMYSQL_UNIX_ADDR=/tmp/mysql.sock  \
        -DMYSQL_DATADIR=/mydata/mariadb  \
        -DSYSCONFDIR=/etc  \
        -DMYSQL_USER=mysql  \
        -DMYSQL_TCP_PORT=3306  \
        -DWITH_XTRADB_STORAGE_ENGINE=1  \
        -DWITH_INNOBASE_STORAGE_ENGINE=1  \
        -DWITH_PARTITION_STORAGE_ENGINE=1  \
        -DWITH_BLACKHOLE_STORAGE_ENGINE=1  \
        -DWITH_MYISAM_STORAGE_ENGINE=1  \
        -DWITH_READLINE=1  \
        -DENABLED_LOCAL_INFILE=1  \
        -DWITH_EXTRA_CHARSETS=all  \
        -DDEFAULT_CHARSET=utf8  \
        -DDEFAULT_COLLATION=utf8_general_ci  \
        -DEXTRA_CHARSETS=all  \
        -DWITH_BIG_TABLES=1  \
        -DWITH_DEBUG=0   &&  make -j 2 && make -j 2 install 
     #4、初始化
         if [ $? -eq 0 ];then
              echo -e "\033[34m   ******** 数据库初始化*******    \033[0m"
              cd /usr/local/mysql/
              ./scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql/  --datadir=/mydata/mariadb/
         else
              echo -e "\033[34m =======编译安装错误！初始化失败========\033[0m"
              exit 1
         fi
     #5、配置服务文件
         \cp /usr/local/mysql/support-files/mysql.server /etc/rc.d/init.d/mariadb
         chmod +x /etc/rc.d/init.d/mariadb
         chkconfig --add mariadb
     #6、配置环境变量
         echo 'export PATH=/usr/local/mysql/bin:$PATH'>/etc/profile.d/mysql.sh
         chmod +x /etc/profile.d/mysql.sh
         source /etc/profile.d/mysql.sh
         source /etc/profile.d/mysql.sh
     #7、配置数据库配置文件
         sed -i 's/datadir=.*/datadir=\/mydata\/mariadb/' /etc/my.cnf
         sed -i 's/socket=.*/socket=\/tmp\/mysql.sock/' /etc/my.cnf
     #8、创建日志目录、/var/run/mysqld/
         [ ! -d /var/log/mariadb/ ] && mkdir /var/log/mariadb/ && chown -R mysql.mysql /var/log/mariadb/
         [ ! -d /var/run/mysqld/ ] && mkdir /var/run/mysqld/ && chown -R mysql.mysql /var/run/mysqld/
     #9、复制mariadb安装后的库文件到/usr/lib目录
         \cp -r /usr/local/mysql/lib/*  /usr/lib/
}
#(3)编译安装php
install_php(){ 
        cd;echo
        PHPVERS=7.2.7  #PHP版本
        #DLOAD_PHP=http://mirrors.sohu.com/php/php-$PHPVERS.tar.gz  #PHP下载地址
        DLOAD_PHP=http://cn.php.net/distributions/php-$PHPVERS.tar.gz  #PHP下载地址
        #\cp -a /usr/lib64/libldap*  /usr/lib/
        #\cp -a /usr/lib64/liblber*  /usr/lib/
        #\cp -a /usr/lib64/libsqlite*  /usr/lib/
       #0 、创建php-fpm用户，用户名：php-fpm
        id php-fpm &> /dev/null
        [ $? -ne 0 ] && useradd -r -s /sbin/nologin php-fpm
        #1、下载php
        [ ! -f  php-$PHPVERS.tar.gz ] && echo -e "\033[36m*******正在下载php源码包。。。\033[0m"  && curl -O $DLOAD_PHP
        #2、解压
        [ ! -d php-$PHPVERS/ ] && tar xf php-$PHPVERS.tar.gz
        echo -e "\033[36m编译安装php需要很长时间，请慢慢等待。。。\033[0m"
        sleep 3
        cd php-$PHPVERS/
       #3、编译安装
        ./configure  --prefix=/usr/local/php7 \
        --with-config-file-path=/etc/php7 \
        --with-config-file-scan-dir=/etc/php7.d \
        --with-mysqli=mysqlnd  \
        --with-pdo-mysql=mysqlnd \
        --with-mysql-sock=/tmp/mysql.sock \
        --with-iconv-dir \
        --with-freetype-dir \
        --with-jpeg-dir \
        --with-png-dir \
        --with-zlib \
        --with-bz2 \
        --with-libxml-dir \
        --with-curl \
        --with-gd \
        --with-openssl \
        --with-mhash  \
        --with-xmlrpc \
        --with-pdo-mysql \
        --with-libmbfl \
        --with-onig \
        --with-pear \
        --enable-xml \
        --enable-bcmath \
        --enable-shmop \
        --enable-sysvsem \
        --enable-inline-optimization \
        --enable-mbregex \
        --enable-fpm \
        --enable-mbstring \
        --enable-pcntl \
        --enable-sockets \
        --enable-zip \
        --enable-soap \
        --enable-opcache \
        --enable-pdo \
        --enable-mysqlnd-compression-support \
        --enable-maintainer-zts  \
        --enable-session \
        --with-fpm-user=php-fpm \
        --with-fpm-group=php-fpm  && make -j 2 && make -j 2 install
        if [[ `echo $?` -eq 0 ]];then
               echo -e "\033[36mphp编译安装成功。。。\033[0m"
        else 
               echo -e "\033[34mphp编译安装失败****请检查****\033[0m"
               exit 1
        fi
        #4、配置php-fpm服务文件
        mkdir /etc/php7{,.d}
        \cp php.ini-production  /etc/php7/php.ini
        sed -i '/post_max_size/s/8/16/g;/max_execution_time/s/30/300/g;/max_input_time/s/60/300/g;s#\;date.timezone.*#date.timezone \= Asia/Shanghai#g' /etc/php7/php.ini
        \cp sapi/fpm/init.d.php-fpm  /etc/rc.d/init.d/php-fpm
        chmod +x /etc/rc.d/init.d/php-fpm
        #5、将php-fpm添加到系统服务
        chkconfig --add php-fpm
        #6、php-fpm配置文件
        cd /usr/local/php7/
        \cp etc/php-fpm.conf.default etc/php-fpm.conf
        \cp etc/php-fpm.d/www.conf.default etc/php-fpm.d/www.conf
        #7、编译ldap模块
        echo -e "\033[34m**********安装ldap模块**********\033[0m"
        cd /root/php-$PHPVERS/ext/ldap
        \cp -af /usr/lib64/libldap* /usr/lib/
        /usr/local/php7/bin/phpize
        [ $? -eq 0 ] && ./configure --with-php-config=/usr/local/php7/bin/php-config && make && make install
        sed -i '/\;extension=bz2/aextension=ldap.so' /etc/php7/php.ini
        #8、编译gettext模块
        echo -e "\033[34m**********安装ldap模块**********\033[0m"
        cd /root/php-$PHPVERS/ext/gettext
        \cp -af /usr/lib64/libldap* /usr/lib/
        /usr/local/php7/bin/phpize
        [ $? -eq 0 ] && ./configure --with-php-config=/usr/local/php7/bin/php-config && make && make install
        sed -i '/\;extension=bz2/aextension=gettext.so' /etc/php7/php.ini
        #[ $? -eq 0 ] && sed -i 's/\;\(extension=ldap\)/\1.so/g' /etc/php7/php.ini 
       
}
#(4)整合nginx和php
congfig_lnmp(){
        echo -e "\033[34m**********整合nginx与php***********\033[0m"
        cd /usr/local/nginx
        #1、删除nginx.conf注释、空白行,输出重定向为nginx.conf.swp
        grep -vE "#|^$" conf/nginx.conf>conf/nginx.conf.swp
        rm -f conf/nginx.conf
        \cp conf/nginx.conf.swp  conf/nginx.conf
        #2、将server配置段从nginx.conf分离出来
        sed -i '/server/,$d' conf/nginx.conf
        mkdir conf.d
        echo -e 'include /usr/local/nginx/conf.d/*.conf;\n}' >> conf/nginx.conf
        #3、创建conf.d/server.conf文件整合nginx与php
        mkdir /htdocs/zabbix/ -pv
        cat>conf.d/server.conf<<"EOF"
        server {
            listen       80;
            server_name  localhost;
            location / {
                  root   /htdocs/zabbix/;
                  index  index.php index.html index.htm;
            }
            location ~ \.php$ {
                  root           /htdocs/zabbix/;
                  fastcgi_pass   127.0.0.1:9000;
                  fastcgi_index  index.php;
                  fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
                  include        fastcgi_params;
                }
            }
EOF
  #4、修改conf/fastcgi_params
        >conf/fastcgi_params
        cat>conf/fastcgi_params<<"EOF"
        fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
        fastcgi_param  SERVER_SOFTWARE    nginx;
        fastcgi_param  QUERY_STRING       $query_string;
        fastcgi_param  REQUEST_METHOD     $request_method;
        fastcgi_param  CONTENT_TYPE       $content_type;
        fastcgi_param  CONTENT_LENGTH     $content_length;
        fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
        fastcgi_param  SCRIPT_NAME        $fastcgi_script_name;
        fastcgi_param  REQUEST_URI        $request_uri;
        fastcgi_param  DOCUMENT_URI       $document_uri;
        fastcgi_param  DOCUMENT_ROOT      $document_root;
        fastcgi_param  SERVER_PROTOCOL    $server_protocol;
        fastcgi_param  REMOTE_ADDR        $remote_addr;
        fastcgi_param  REMOTE_PORT        $remote_port;
        fastcgi_param  SERVER_ADDR        $server_addr;
        fastcgi_param  SERVER_PORT        $server_port;
        fastcgi_param  SERVER_NAME        $server_name;
EOF

        #5、修改SELinux、情况防火墙
        #setenforce 1 && setsebool -P httpd_can_network_connect 1
        setenforce 0
        iptables -I INPUT -p tcp --dport 80 -j ACCEPT
        iptables -I INPUT -p tcp --dport 3306 -j ACCEPT
        iptables -I INPUT -p tcp --dport 9000 -j ACCEPT
        #iptables -F && service iptables save
}
#(5)启动nginx、mariadb、php-fpm服务，创建zabbix数据库
start_service(){
        /usr/local/nginx/sbin/nginx &&/etc/rc.d/init.d/mariadb start  &&  /etc/rc.d/init.d/php-fpm start
        [ $? -eq 0 ] && echo -e "\033[36m=========lnmp环境搭建成功！===========\033[0m"
       echo
       echo -e "\033[36m=========下面即将创建zabbix的数据库及用户、密码===========\033[0m"
       echo
       /usr/local/mysql/bin/mysql -e "create database zabbix character set utf8 collate utf8_bin;"
       if [ $? -eq 0 ];then
          /usr/local/mysql/bin/mysql -e "grant all on zabbix.* to zabbix@localhost identified by '123456';" 
          /usr/local/mysql/bin/mysql -e "grant all on zabbix.* to zabbix@127.0.0.1 identified by '123456';"
          /usr/local/mysql/bin/mysql -e "flush privileges;"
          echo -e "\033[36mzabbix数据库创建成功，数据库名：zabbix 用户：zabbix   密码：123456 \033[0m"
          echo
          echo -e "\033[34m##################################################################################\033[0m"
          echo -e "\033[47;34m请根据实际情况创建zabbix数据库，这里创建的只是测试用！ \033[0m"
          echo -e "\033[34m##################################################################################\033[0m"
          echo
       else
          echo -e "\033[36m=========创建zabbix数据库失败===========\033[0m"
     fi
       
}


###########################################################################

#      *****************Zabbix编译安装部分****************************

###########################################################################

#zabbix版本：zabbix-3.4.11.tar.gz
    zabbix_soft=zabbix-3.4.11.tar.gz
#zabbix安装目录
    install_dir=/usr/local/zabbix/
#服务端ip，默认是192.168.10.205
    server_ip=192.168.10.205  #zabbix服务端的ip，根据实际情况修改
#获取本机ip
    local_ip=`ip addr | grep "\binet\b" | awk 'NR==2{print $2}'| sed 's#\/.*##'`
#zabbix下载地址
    zabbix_download="https://jaist.dl.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/3.4.11/zabbix-3.4.11.tar.gz"
#数据库名
    DBName=zabbix   #定义zabbix的数据库名，默认是：zabbix，可根据实际情况修改
#数据库用户
    DBUser=zabbix   #定义连接zabbix数据库的用户，默认是：zabbix，可根据实际情况修改
#密码： 
    DBPassword=123456  #定义连接zabbix数据库用户的密码，默认是：123456，可根据实际情况修改
#数据库安装目录
    DBDir=/usr/local/mysql/
##############################################################################

#zabbbix的server端和客户端安装部署
server_install(){
#1、安装相关依赖包
    echo -e "\033[34m*************安装相关依赖包*************\033[0m"
    yum install  gcc curl curl-devel libcurl-devel pcre-devel net-snmp-devel net-snmp -y
#2、下载zabbix
    cd
    echo
    echo -e "\033[34m*************下载zabbix*************\033[0m"
   if [ ! -e  $zabbix_soft ];then
       curl -O $zabbix_download
       [ $? -ne 0 ] && echo "网络异常，下载失败！" && exit 1
   fi
    echo
#3、创建zabbix用户
    id  zabbix &> /dev/null
    [ $? -ne 0 ] &&  useradd -r -s /sbin/nologin zabbix && echo -e "\033[34m******创建zabbix用户成功！*****\033[0m"
#4、解压编译安装zabbix
    echo -e "\033[34m*************编译安装配置zabbix*************\033[0m"
    [ ! -d `echo $zabbix_soft | sed  's/.tar.*//g'` ] && tar xf $zabbix_soft
    cd `echo $zabbix_soft | sed  's/.tar.*//g'`
    ./configure --prefix=$install_dir --enable-server --enable-agent --with-mysql=/usr/local/mysql/bin/mysql_config --enable-ipv6 --with-net-snmp --with-libcurl --with-libxml2 && make -j 2 && make -j 2 install
if [ $? -eq 0 ];then
#5、配置启动脚本
   \cp misc/init.d/fedora/core/* /etc/rc.d/init.d/
   sed -i 's#\(BASEDIR=/usr/local\)#\1/zabbix#' /etc/rc.d/init.d/zabbix_agentd
   sed -i 's#\(BASEDIR=/usr/local\)#\1/zabbix#' /etc/rc.d/init.d/zabbix_server
   chmod +x /etc/rc.d/init.d/zabbix_agentd
   chmod +x /etc/rc.d/init.d/zabbix_server
   chkconfig --add /etc/rc.d/init.d/zabbix_agentd
   chkconfig --add /etc/rc.d/init.d/zabbix_server 
#6、配置zabbix agentd配置文件
    rm -f $install_dir/etc/zabbix_agentd.conf.bak
    cp $install_dir/etc/zabbix_agentd.conf{,.bak}
    cat>$install_dir/etc/zabbix_agentd.conf<<EOF
    LogFile=/tmp/zabbix_agentd.log
    Server=$server_ip
    ServerActive=$server_ip
    Hostname=$local_ip
EOF
#7、配置zabbix server配置文件
    rm -f $install_dir/etc/zabbix_server.conf.bak
    cp $install_dir/etc/zabbix_server.conf{,.bak}
    cat>$install_dir/etc/zabbix_server.conf<<EOF
    LogFile=/tmp/zabbix_server.log
    DBHost=localhost
    DBName=zabbix
    DBUser=zabbix
    DBPassword=123456
    DBPort=3306
EOF
#8、添加防火墙规则
    echo
    echo -e "\033[34m*************配置防火墙规则，临时关闭selinux*************\033[0m"
    iptables -I INPUT -p tcp --dport 10051 -j ACCEPT
    iptables -I INPUT -p tcp --dport 10050 -j ACCEPT
#9、临时关闭selinux
    setenforce 0
#10、设置zabbix server(服务端)的网站目录：/htdocs/zabbix/
   [ ! -d /htdocs/zabbix/ ] &&  mkdir /htdocs/zabbix/ -pv
   cd && cd `echo $zabbix_soft | sed  's/.tar.*//g'`
   [ $? -ne 0 ] && exit 1
   cp -r frontends/php/* /htdocs/zabbix/
   chown -R zabbix.zabbix  /htdocs/
#11、导入zabbix数据
   cd && cd `echo $zabbix_soft | sed  's/.tar.*//g'`
   cd database/mysql/
   $DBDir/bin/mysql -u$DBUser -p$DBPassword $DBName < schema.sql
   $DBDir/bin/mysql -u$DBUser -p$DBPassword $DBName < images.sql
   $DBDir/bin/mysql -u$DBUser -p$DBPassword $DBName < data.sql
#12、启动zabbix agentd
    echo
    echo -e "\033[34m*************启动zabbix server和agentd服务*************\033[0m"
    #systemctl daemon-reload
    /etc/rc.d/init.d/zabbix_server   restart
    /etc/rc.d/init.d/zabbix_agentd   restart
    echo
    echo -e "\033[34m查看端口启用情况：\033[0m"
    ss -tnl
 else
     echo -e "\033[36m******编译安装失败，请根据错误信息排错******\033[0m"
     exit 1
fi
}
#zabbix客户端安装配置
agentd_install(){
#安装相关依赖包
   echo -e "\033[34m*************安装相关依赖包*************\033[0m"
    yum install  gcc curl curl-devel libcurl-devel pcre-devel net-snmp-devel net-snmp -y
#下载zabbix
    cd
    echo
    echo -e "\033[34m*************下载zabbix*************\033[0m"
    if [ ! -f  $zabbix_soft ];then
       curl -O $zabbix_download
       [ $? -ne 0 ] && echo "网络异常，下载失败！" && exit 1
    fi
    echo
#创建zabbix用户
    id  zabbix &> /dev/null
    [ $? -ne 0 ] &&  useradd -r -s /sbin/nologin zabbix && echo -e "\033[34m******创建zabbix用户成功！*****\033[0m"
#解压编译安装zabbix
    echo -e "\033[34m*************编译安装配置zabbix agent*************\033[0m"
    [ ! -d `echo $zabbix_soft | sed  's/.tar.*//g'` ] && tar xf $zabbix_soft
    cd `echo $zabbix_soft | sed  's/.tar.*//g'`
    ./configure --prefix=$install_dir --enable-agent && make && make install
if [ $? -eq 0 ];then
#配置启动脚本
   \cp misc/init.d/fedora/core/zabbix_agentd /etc/rc.d/init.d/
   sed -i 's#\(BASEDIR=/usr/local\)#\1/zabbix#' /etc/rc.d/init.d/zabbix_agentd
   chmod +x /etc/rc.d/init.d/zabbix_agentd
#配置zabbix agentd
    rm -f $install_dir/etc/zabbix_agentd.conf.bak
    cp $install_dir/etc/zabbix_agentd.conf{,.bak}
    cat>$install_dir/etc/zabbix_agentd.conf<<EOF
    LogFile=/tmp/zabbix_agentd.log
    Server=$server_ip
    ServerActive=$server_ip
    Hostname=$local_ip
EOF
#启动zabbix agentd
    echo
    echo -e "\033[34m*************启动zabbix agentd服务*************\033[0m"
    #systemctl daemon-reload
    /etc/rc.d/init.d/zabbix_agentd   start
#添加防火墙规则
    echo
    echo -e "\033[34m*************配置防火墙规则，临时关闭selinux*************\033[0m"
    iptables -I INPUT -p tcp --dport 10050 -j ACCEPT
#临时关闭selinux
    setenforce 0
    echo
    echo -e "\033[34m查看端口启用情况：\033[0m"
    ss -tnl
    echo -e "\033[34mzabbix agentd服务端口：10050  \033[0m"
    echo -e "\033[36m======编译安装zabbix_agentd已完成======\033[0m"
 else
     echo -e "\033[36m******编译安装失败，请根据错误信息排错******\033[0m"
     exit 1
fi
}

run_install(){
while true;do
menu
case $num in
  "1")
      #1、编译安装部署lnmp环境
      echo -e "\033[34m=========编译安装部署lnmp环境===========\033[0m"
      install_package
      install_nginx
      install_mariadb
      install_php
      congfig_lnmp
      start_service
      ;;
  "2")
      #1、编译安装zabbix
      echo -e "\033[34m=========编译安装部署zabbix server和agentd===========\033[0m"
      server_install
      ;;
  "3")
      #2、编译安装zabbix
      echo -e "\033[34m=========编译安装zabbix_agentd===========\033[0m"
      agentd_install
      ;;
 "4")#3、退出脚本
      exit 0
     ;;
  *)
     ;;
esac
done
}

#调用脚本运行入口
run_install
