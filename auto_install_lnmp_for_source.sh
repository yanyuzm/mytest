#!/bin/bash
#2018年3月23日
#auto install lnmp for zabbix
#by author caomuzhong
#Blog:www.logmm.com

#功能选择菜单
menu(){ 
        echo
        echo -e "\033[31;32m                              LNMP编译安装脚本                                 \033[0m"
        echo -e "\033[31;32m===============================================================================\033[0m"
        echo -e "\033[34m此脚本能直接在rhel7.5、Centos 7.5上成功执行\033[0m"
        echo "  安装包版本：  nginx:1.14.0   mariadb10.3.7   php7.2.7"
        echo "  相关依赖包：pcre-devel、gd-devel、openssl、openssl-devel、php-mysql、wget  "
        echo "              perl-devel、libxml2-devel bzip2-devel libcurl-devel   "
        echo -e "\033[47;34m------------安装需联网下载软件包，若下载地址失效，需自行更新下载地址------------\033[0m"
        echo -e "\033[31;32m================================================================================\033[0m"
        echo "   nginx安装目录：/usr/local/nginx   "
        echo "   maraidb安装目录：/usr/local/mysql，数据存放目录：/mydata/mariadb/  "
        echo "   php安装目录：/usr/local/php7   "
        echo -e "\033[47,34m————by author caomuzhong  博客:www.logmm.com\033[0m"
        echo -e "\033[31;32m================================================================================\033[0m"
        echo -e "\033[34m请选择:\033[0m"
        echo -e "\033[36m0、安装依赖包      1、安装nginx   2、源码编译安装mariadb   3、安装php  \033[0m"
        echo -e "\033[36m4、整合nginx和php  5、启动nginx、mariadb、php-fpm服务  \033[0m"
        echo -e "\033[36m6、一键安装并部署lnmp        7、退出脚本\033[0m"
        echo -e "\033[31;32m================================================================================\033[0m"
        echo
        read -p "请输入数字：0-5[单独安装]，6[一键安装]，7[退出脚本]:"   num
}
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
        DLOAD_PHP=http://cn.php.net/distributions/php-$PHPVERS.tar.gz
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
        cat>conf.d/server.conf<<"EOF"
        server {
            listen       80;
            server_name  localhost;
            location / {
                  root   /usr/local/nginx/html;
                  index  index.php index.html index.htm;
            }
            location ~ \.php$ {
                  root           /usr/local/nginx/html;
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
        #6、创建测试页，备份nginx默认的页面
        mv html/index.html html/index.html.bak
        mv html/50x.html html/50x.html.bak
        cat>html/index.php<<"EOF"
        <?php
                   $conn = new mysqli('127.0.0.1','root','');
                  if($conn)
                     echo "connect maraidb OK...";
                  else
                     echo "connect mariadb Fail...";
                  mysqli_close($conn);
                  phpinfo();
            ?>
EOF

        if [[ `echo $?` -eq 0 ]];then
               sleep 3
               echo -e "\033[36m=========整合nginx和php成功===========\033[0m"
           else 
               echo -e "\033[34m**********整合nginx和php失败*****请检查*****\033[0m"
              # exit 1
           fi
}
	#(5)启动nginx、mariadb、php-fpm服务
start_service(){
        /usr/local/nginx/sbin/nginx
        if [[ `echo $?` -eq 0 ]];then
              echo -e "\033[34m=========nginx服务启动成功===========\033[0m"
        else
              echo -e "\033[36m=========nginx服务启动失败===========\033[0m"
        fi
        #systemctl start mariadb  php-fpm  <---- rhel7可以使用此命令
        /etc/rc.d/init.d/mariadb start  &&  /etc/rc.d/init.d/php-fpm start
        if [[ `echo $?` -eq 0 ]];then
            sleep 3
            echo -e "\033[36m=========mariadb、php-fpm服务启动成功===========\033[0m"
            echo -e "\033[34m查看端口启用情况：\033[0m"
            ss -tnl
            echo -e "\033[34m端口：80、3306、9000已启动!\033[0m"
            echo -e "\033[36m======编译安装lnmp已完成======\033[0m"
            echo -e "\033[36m--------打开浏览器输入你的ip，看看测试页--------\033[0m"
        else
             echo -e "\033[36m=========mariadb、php-fpm服务启动失败===========\033[0m"
        fi
}
#脚本运行入口
run_install(){
        while true;do
        menu
        case $num in
        "0")
                #0、安装依赖包
                    echo -e "\033[34m=========安装依赖包===========\033[0m"
                    install_package
                    ;;
        "1")
                #1、编译安装nginx
                   echo -e "\033[34m=========编译安装nginx===========\033[0m"
                   install_nginx
                   ;;
        "2")
               #2、编译安装mariadb
                   echo -e "\033[34m=========编译安装mariadb===========\033[0m"
               install_mariadb
                   ;;
        "3")#3、编译安装php
                   echo -e "\033[34m=========编译安装php===========\033[0m"
                   install_php
                   ;;
        "4")#4、整合nginx和php
                   echo -e "\033[34m=========整合nginx和php===========\033[0m"
               congfig_lnmp
                   ;;
        "5")#5、启动nginx、mariadb、php-fpm服务
                   echo -e "\033[34m=========启动nginx、mariadb、php-fpm服务===========\033[0m"
                   start_service
                   ;;
        "6")#、一键编译安装lnmp
                   echo -e "\033[34m=========一键编译安装并配置lnmp===========\033[0m"
                   install_package
                   install_nginx
                   install_mariadb
                   install_php
                   congfig_lnmp
                   start_service
                   exit 0
                   ;;
        "7")#7、退出脚本
                   exit 0
                   ;;
          *)
                   ;;
        esac
        done
}
#调用脚本运行入口
run_install
