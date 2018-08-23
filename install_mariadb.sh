#!/bin/bash
#源码包编译安装mariadb
#by caomuzhong
#date：2018-07-10
#blog：www.logmm.com

#菜单
menu(){ 
echo
echo -e "\033[31;32m                               源码编译mariadb安装脚本                           \033[0m"
echo -e "\033[31;32m==================================================================================\033[0m"
echo -e "\033[34m           数据库数据目录(datadir)：/mydata/mariadb/  \033[0m"
echo -e "\033[34m           数据库安装目录(basedir)：/usr/local/mysql/ \033[0m"
echo -e "\033[31;32m==================================================================================\033[0m"
echo "      mariadb版本: 10.3.8 如果要安装其他的版本，可以修改脚本中第101行的VERSION变量值"
echo "      相关依赖包：gnutls-devel gcc gcc-c++ cmake ncurses-devel bison-devel"
echo "              bison-devel bison libaio-devel libevent libxml2-devel"
echo -e "\033[31;32m=================================================================================\033[0m"
echo -e "\033[34m————by author caomuzhong  博客:www.logmm.com\033[0m"
echo -e "\033[31;32m==================================================================================\033[0m"
echo -e "\033[34m功能选项:\033[0m"
echo -e "\033[36m1、源码编译安装mariadb   2、退出脚本\033[0m"
echo -e "\033[31;32m==================================================================================\033[0m"
echo
read -p "请输入数字(1：源码编译安装mariadb  2：退出脚本):"   num
}

#正式编译安装
install_mariadb(){

    #0、安装相关包
        echo -e "\033[34m=========安装相关软件包===========\033[0m"
        yum install -y gnutls-devel gcc gcc-c++ cmake ncurses-devel bison-devel bison libaio-devel libevent libxml2-devel
    #1、创建mysql用户
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
        sleep 3
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
         cp /usr/local/mysql/support-files/mysql.server /etc/rc.d/init.d/mariadb
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
     #9、启动mariadb服务
         /etc/rc.d/init.d/mariadb start
         [ $? -eq 0 ] && echo -e "\033[34m  mariadb数据库编译安装成功，服务已启动。。。。\033[0m"  || echo -e "\033[34m  mariadb数据库启动失败。。。。\033[0m"      
}

#安装前的准备
begin_install(){
         cd
         VERSION=10.3.8 #定义安装的版本，如5.5.60、10.3.7等
     if [ -f mariadb-$VERSION.tar.gz ];then
         #编译安装mariadb
         install_mariadb 
     else
        #下载maridb
        cd
        echo -e "\033[34m=========下载maraidb源码包===========\033[0m"
        curl -O http://mirrors.tuna.tsinghua.edu.cn/mariadb//mariadb-$VERSION/source/mariadb-$VERSION.tar.gz  
        #、编译安装mariadb       
        echo 
        install_mariadb
    fi
}

#脚本运行入口
run_install(){
while true;do
menu
case $num in
  "1")
      #1、编译安装mariadb
      echo
      echo -e "\033[34m=========编译安装maraidb===========\033[0m"
      begin_install
      echo
      ;;
 "2")
     #2、退出脚本
      echo
      echo -e "\033[34m=========退出脚本===========\033[0m"
      exit 0
      ;;
  *)
      ;;
esac
done
}

#调用脚本运行入口
run_install
