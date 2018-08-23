#!/bin/bash
#2018年5月16日
#auto install lamp
#by author caomuzhong
#Blog:www.logmm.com

#功能选择菜单
menu(){ 
echo
echo -e "\033[31;32m                              LAMP编译安装脚本                               \033[0m"
echo -e "\033[31;32m=============================================================================\033[0m"
echo -e "\033[34m此脚本能直接在RHEL 7.3、7.5  CentOS 6.5、7.4上成功执行，红帽其他版本未测试！\033[0m"
echo "  安装包版本：  httpd:2.4.33   mariadb10.2.14   php5.6.33"
echo "  相关依赖包：pcre-devel、gd-devel、openssl、openssl-devel、php-mysql、wget  "
echo "              perl-devel、libxml2-devel bzip2-devel libcurl-devel  gcc  gcc-c++  "
echo -e "\033[47;34m-----安装需联网，请确保网络正常,若安装包下载地址失效，请更新下载地址，并作对应修改-----\033[0m"
echo -e "\033[31;32m============================================================================\033[0m"
echo "   httpd安装目录：/usr/local/apache   网站目录：/usr/local/apache/htdocs"
echo "   maraidb安装目录：/usr/local/mysql，数据存放目录：/mydata/mariadb/  "
echo "   php安装目录：/usr/local/php5"
echo -e "\033[34m————by author caomuzhong  博客:www.logmm.com\033[0m"
echo -e "\033[31;32m============================================================================\033[0m"
echo -e "\033[34m请选择安装选项:\033[0m"
echo -e "\033[36m0、安装依赖包      1、安装httpd   2、安装mariadb   3、安装php  \033[0m"
echo -e "\033[36m4、整合httpd和php  5、启动httpd、mariadb、php-fpm服务  \033[0m"
echo -e "\033[36m6、一键安装并部署lamp   7、退出脚本\033[0m"
echo -e "\033[31;32m============================================================================\033[0m"
echo -e "\033[34m说明：你可以选择某一些安装[0-5选项]，也可以一键安装lamp[选择6]\033[0m"
echo
read -p "请输入数字(0-5:单独安装某一项，6:一键安装部署，7:退出脚本):"   num
}
#(0)安装依赖包
install_package(){
   yum  install wget bzip2-devel libxml2  bxml2-devel libexpat*  pcre pcre-devel openssl openssl-devel gcc  gcc-c++ -y
   yum  install expat-devel gd-devel   perl perl-devel php-mysql libxml2-devel libcurl-devel  make -y
#   yum  groupinstall  "Development  tools"  -y
#   yum  groupinstall  "Development Tools" -y
#wget http://mirror.bit.edu.cn/apache/apr/apr-1.6.3.tar.gz
#wget http://mirror.bit.edu.cn/apache/apr/apr-util-1.6.1.tar.gz
}
#(1)编译安装httpd
install_httpd(){
   cd #回到家目录
   echo -e "\033[36m *********编译安装httpd*********\033[0m"
   #编译安装apr apr-util
   wget http://mirrors.hust.edu.cn/apache/apr/apr-1.6.3.tar.gz
   wget http://mirrors.hust.edu.cn/apache/apr/apr-util-1.6.1.tar.gz
   tar xf apr-1.6.3.tar.gz
   tar xf apr-util-1.6.1.tar.gz
   cd  apr-1.6.3
   ./configure  --prefix=/usr/local/apr
   make  &&  make  install
   cd /root/apr-util-1.6.1
   ./configure  --prefix=/usr/local/apr-util  --with-apr=/usr/local/apr/
   make  &&  make  install

#1、下载httpd
   cd # 回到家目录
#wget http://mirrors.tuna.tsinghua.edu.cn/apache/httpd/httpd-2.4.29.tar.gz
   wget http://mirrors.hust.edu.cn/apache/httpd/httpd-2.4.33.tar.gz
#2、解压httpd
   tar xf httpd-2.4.33.tar.gz
#3、编译安装httpd
   cd httpd-2.4.33
   ./configure --prefix=/usr/local/apache\
   --sysconfdir=/etc/httpd24\
   --enable-so\
   --enable-ssl\
   --enable-cgi\
   --enable-rewrite\
   --with-zlib\
   --with-pcre\
   --with-apr=/usr/local/apr\
   --with-apr-util=/usr/local/apr-util/\
   --enable-modules=most\
   --enable-mpms-shared=all\
   --with-mpm=prefork     
   make  &&  make  install
#4、配置环境变量
   echo "export  PATH=/usr/local/apache/bin:$PATH" >>/etc/profile.d/httpd.sh
   chmod +x /etc/profile.d/httpd.sh
   source /etc/profile.d/httpd.sh
}
#(2)编译安装mariadb
install_mariadb(){
#1、下载mariadb
echo -e "\033[36m *********编译安装mariadb*********\033[0m"
   cd#回到家目录
#wget https://downloads.mariadb.com/MariaDB/mariadb-10.2.6/bintar-linux-glibc_214-x86_64/mariadb-10.2.6-linux-glibc_214-x86_64.tar.gz
   wget http://mirrors.tuna.tsinghua.edu.cn/mariadb//mariadb-10.2.14/bintar-linux-x86_64/mariadb-10.2.14-linux-x86_64.tar.gz
 #  wget http://ftp.hosteurope.de/mirror/archive.mariadb.org//mariadb-5.5.57/bintar-linux-x86_64/mariadb-5.5.57-linux-x86_64.tar.gz
#2、创建mysql用户和组
   groupadd -r -g 306 mysql
   useradd -r -g 306 -u 306 -s /sbin/nologin mysql
#3、创建创建数据库数据存放目录
   mkdir /mydata/mariadb -pv
   chown -R mysql.mysql /mydata/mariadb/
#4、解压maradb到/usr/local目录，并创建软连接名称为：mysql
   tar xf mariadb-10.2.14-linux-x86_64.tar.gz  -C /usr/local/
 #  tar xf mariadb-5.5.57-linux-x86_64.tar.gz -C /usr/local/
   cd /usr/local/
   ln -sv mariadb-10.2.14-linux-x86_64/ mysql
 #  ln -sv mariadb-5.5.57-linux-x86_64/ mysql
   cd mysql/
#5、修改属主属组
   chown -R root.mysql ./*
#6、数据库初始化安装
   ./scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql --datadir=/mydata/mariadb/
   if [[ `echo $?` -eq 0 ]];then
	       sleep 3
	       echo -e "\033[36mmariadb初始化安装成功。。。\033[0m"
      else 
           echo -e "\033[34mmaridb初始化安装失败****请检查****\033[0m"
          # exit 1
   fi
#7、数据库配置文件
   [[ -f /etc/my.cnf ]] && cp /etc/my.cnf /etc/my.cnf.bak
   cp  support-files/my-large.cnf /etc/my.cnf
   sed -i '/thread_concurrency = 8/adatadir = /mydata/mariadb\ninnodb_file_per = on\nskip_name_resolve = on' /etc/my.cnf
#8、服务脚本文件
   cp support-files/mysql.server /etc/rc.d/init.d/mariadb
   chmod +x /etc/rc.d/init.d/mariadb 
#9、将mariadb添加到系统管理
    chkconfig --add mariadb
#10、配置环境变量
   echo 'export PATH=/usr/local/mysql/bin:$PATH'>/etc/profile.d/mysql.sh
   chmod +x /etc/profile.d/mysql.sh
   source /etc/profile.d/mysql.sh
}
#(3)编译安装php
install_php(){ 
   echo -e "\033[36m *********编译安装php*********\033[0m"
   cd  #回到家目录
   useradd -s /sbin/nologin www
   #安装libmcrypt
   #wget http://iweb.dl.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz
   wget https://www.linuxprobe.com/Software/libmcrypt-2.5.8.tar.gz
   tar xf libmcrypt-2.5.8.tar.gz
   cd libmcrypt-2.5.8
   ./configure && make && make install
   #1、下载php5.6.33
   #wget http://tw2.php.net/distributions/php-5.6.33.tar.gz
   cd #回到root家目录
   #wget http://am1.php.net/distributions/php-7.2.5.tar.gz
   wget http://mirrors.sohu.com/php/php-5.6.33.tar.gz
   #2、解压
   tar xf php-5.6.33.tar.gz
   echo -e "\033[36m编译安装php需要很长时间，请慢慢等待。。。\033[0m"
   sleep 3
   cd php-5.6.33/
   #3、编译安装
   ./configure --prefix=/usr/local/php5\
   --with-mysql=mysqlnd\
   --with-pdo-mysql=mysqlnd\
   --with-mysqli=mysqlnd\
   --with-openssl\
   --enable-mbstring\
   --with-freetype-dir\
   --with-jpeg-dir\
   --with-png-dir\
   --with-zlib\
   --with-libxml-dir=/usr\
   --enable-xml\
   --enable-sockets\
   --enable-fpm\
   --with-mcrypt\
   --with-config-file-path=/etc/php5/\
   --with-config-file-scan-dir=/etc/php5.d\
   --with-fpm-user=www\
   --with-fpm-group=www\
   --with-bz2
   make  && make install
   if [[ `echo $?` -eq 0 ]];then
	       sleep 3
	       echo -e "\033[36mphp编译安装成功。。。\033[0m"
      else 
           echo -e "\033[34mphp编译安装失败****请检查****\033[0m"
          # exit 1
   fi
   #4、配置php-fpm服务文件
   mkdir /etc/php5{,.d}
   cp php.ini-production /etc/php5/php.ini
   cp sapi/fpm/init.d.php-fpm  /etc/rc.d/init.d/php-fpm
   chmod +x /etc/rc.d/init.d/php-fpm
   #5、将php-fpm添加到系统服务
   chkconfig --add php-fpm
   #6、php-fpm配置文件
   cd /usr/local/php5/etc/
   cp php-fpm.conf.default php-fpm.conf
}
#(4)整合httpd和php
congfig_lamp(){
  echo -e "\033[36m *********整合httpd和php*********\033[0m"
  #1、修改httpd主配置文件
  echo -e "\033[35m *********修改httpd主配置文件*********\033[0m"
  sed -i 's/^#\(ServerName www.example.com:80\)/\1/' /etc/httpd24/httpd.conf
  sed -i 's/#\(LoadModule proxy_module modules\/mod_proxy.so\)/\1/'  /etc/httpd24/httpd.conf
  sed -i 's/#\(LoadModule proxy_fcgi_module modules\/mod_proxy_fcgi.so\)/\1/'  /etc/httpd24/httpd.conf
  sed -i 's/DirectoryIndex index.html/DirectoryIndex index.php index.html/' /etc/httpd24/httpd.conf
  echo "Include  /etc/httpd24/extra/http_vhost.conf" >> /etc/httpd24/httpd.conf
  echo "AddType application/x-httpd-php   .php" >> /etc/httpd24/httpd.conf
  echo "AddType application/x-httpd-php-source   .phps" >> /etc/httpd24/httpd.conf
  #2、修改SELinux、情况防火墙
  echo -e "\033[35m *********修改防火墙和SELinux*********\033[0m"
  setenforce 1 && setsebool -P httpd_can_network_connect 1
  #setenforce 0
  iptables -I INPUT -p tcp --dport 80 -j ACCEPT
  iptables -I INPUT -p tcp --dport 3306 -j ACCEPT
  iptables -I INPUT -p tcp --dport 9000 -j ACCEPT
  #iptables -F && service iptables save
  #3、创建测试页
  echo -e "\033[35m *********创建测试页*********\033[0m"
   cat>>/usr/local/apache/htdocs/index.php<<"EOF"
   <?php
    $conn = mysql_connect('127.0.0.1','root','');
    if($conn)
      echo "connect Database OK…";
    else
      echo "connect Database Fail…";
    mysql_close();
    phpinfo();
?>
EOF
  #5、虚拟主机配置文件
  echo -e "\033[35m *********配置虚拟主机*********\033[0m"
  cat>>/etc/httpd24/extra/http_vhost.conf<<"EOF"
   <VirtualHost *:80>
    DocumentRoot "/usr/local/apache/htdocs"
    ServerName haha
    ProxyRequests Off
    ProxyPassMatch ^/(.*.php)$ fcgi://127.0.0.1:9000/usr/local/apache/htdocs/$1
  <Directory "/usr/local/apache/htdocs">
    AllowOVerride None
    Require all granted
  </Directory>
</VirtualHost>
EOF

if [[ `echo $?` -eq 0 ]];then
	       sleep 3
	       echo -e "\033[36m=========整合httpd和php成功===========\033[0m"
      else 
           echo -e "\033[34m**********整合httpd和php失败*****请检查*****\033[0m"
          # exit 1
fi
}
#(5)启动httpd、mariadb、php-fpm服务
start_service(){
    /usr/local/apache/bin/apachectl start
    if [[ `echo $?` -eq 0 ]];then
        echo -e "\033[34m=========httpd服务启动成功===========\033[0m"
     else
        echo -e "\033[36m=========httpd服务启动失败===========\033[0m"
     fi
     #systemctl start mariadb  php-fpm  <---- rhel7可以使用此命令
     /etc/rc.d/init.d/mariadb start  &&  /etc/rc.d/init.d/php-fpm start
     if [[ `echo $?` -eq 0 ]];then
            sleep 3
            echo -e "\033[36m=========mariadb、php-fpm服务启动成功===========\033[0m"
            echo -e "\033[34m查看端口启用情况：\033[0m"
            ss -tnl
            echo -e "\033[34m端口：80、3306、9000已启动!\033[0m"
            echo -e "\033[36m======编译安装lamp已完成======\033[0m"
            echo -e "\033[36m--------打开浏览器输入你的ip，看看测试页--------\033[0m"
     else
             echo -e "\033[36m=========mariadb、php-fpm服务启动失败===========\033[0m"
     fi
}
#脚本运行入口函数
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
      #1、编译安装httpd
      echo -e "\033[34m=========编译安装httpd===========\033[0m"
      install_httpd
      ;;
  "2")#2、编译安装mariadb
      echo -e "\033[34m=========编译安装mariadb===========\033[0m"
	  install_mariadb
      ;;
  "3")#3、编译安装php
       echo -e "\033[34m=========编译安装php===========\033[0m"
      install_php
      ;;
 "4")#4、整合httpd和php
      echo -e "\033[34m=========整合httpd和php===========\033[0m"
	  congfig_lamp
      ;;
 "5")#5、启动httpd、mariadb、php-fpm服务
      echo -e "\033[34m=========启动httpd、mariadb、php-fpm服务===========\033[0m"
      start_service
  ;;
 "6")#6、一键编译安装lamp
      echo -e "\033[34m=========一键编译安装并配置lamp===========\033[0m"
      install_package
      install_httpd
      install_mariadb
      install_php
      congfig_lamp
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
#调用脚本运行入口函数
run_install
