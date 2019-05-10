#!/bin/bash
#安装centos6.8+oracle11g-silent静默安装脚本

chmod -R 777 /usr/local/src/oracle11g-silent
#时间时区同步，修改主机名
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

ntpdate cn.pool.ntp.org
hwclock --systohc
echo "*/30 * * * * root ntpdate -s 3.cn.poop.ntp.org" >> /etc/crontab

sed -i 's|SELINUX=.*|SELINUX=disabled|' /etc/selinux/config
sed -i 's|SELINUXTYPE=.*|#SELINUXTYPE=targeted|' /etc/selinux/config
sed -i 's|SELINUX=.*|SELINUX=disabled|' /etc/sysconfig/selinux 
sed -i 's|SELINUXTYPE=.*|#SELINUXTYPE=targeted|' /etc/sysconfig/selinux 
setenforce 0 && service iptables stop && chkconfig iptables off

hostname oracle && export HOSTNAME=oracle
echo "`ifconfig|grep 'inet'|head -1|awk '{print $2}'|cut -d: -f2` oracle" >> /etc/hosts

rm -rf /var/run/yum.pid 
rm -rf /var/run/yum.pid

#准备本地yum源
#umount /dev/sr0 
#mount /dev/sr0 /mnt/ 
#cat >> /etc/yum.repos.d/local.repo <<EOF
#[local]
#name=RHEL6
#baseurl=file:///mnt
#enabled=1
#gpgcheck=0
#EOF

#安装oracle需要的软件包
#yum -y install make gcc libaio-devel compat-libstdc++-33 elfutils-libelf-devel gcc-c++ libstdc++-devel pdksh-5.2.14 
cd /usr/local/src/oracle11g-silent/rpm
chmod +x *.rpm
yum -y install *.rpm
#rpm -ivh *.rpm --force --nodeps

#创建oracle用户和组
groupadd -g 1001 oinstall
groupadd -g 1002 dba
useradd -u 10000 -g oinstall -G dba -d /home/oracle -s /bin/bash oracle
echo "Root123456" | passwd --stdin oracle
chown -R oracle:oinstall /home/oracle

#修改内核参数
cat >> /etc/sysctl.conf <<EOF
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.shmall = 2097152
#kernel.shmmax = 1052035072
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
EOF
#sed -i "s|kernel.shmmax = .*|kernel.shmmax = ` /usr/bin/free -m | sed -n '2p' | awk '{print $2*1024/4}'`|" /etc/sysctl.conf
sed -i "s|kernel.shmmax = .*|kernel.shmmax = `/usr/bin/free | sed -n '2p' | awk '{print $2*1024/2}'`|" /etc/sysctl.conf
sysctl -p

#修改用户限制
cat >> /etc/security/limits.conf <<EOF
oracle           soft    nproc           2047
oracle           hard    nproc           16384
oracle           soft    nofile          1024
oracle           hard    nofile          65536
oracle           soft    stack           10240
EOF

#修改用户验证选项
cat >> /etc/pam.d/login <<EOF
session    required     /lib64/security/pam_limits.so
session    required     pam_limits.so
EOF

#修改用户配置文件
cat >> /etc/profile <<EOF

if [ \$USER = "oracle" ]; then
    if [ \$SHELL = "/bin/ksh" ]; then
        ulimit -p 16384
        ulimit -n 65536 
    else
        ulimit -u 16384 -n 65536
    fi 
fi
EOF
source /etc/profile

#安装目录配置
mkdir -pv /home/oracle/app
chown -R oracle:oinstall /home/oracle/app
chmod -R 775 /home/oracle/app

#修改oracle用户环境变量
cat >> /home/oracle/.bash_profile <<EOF
export ORACLE_BASE=/home/oracle/app
export ORACLE_HOME=\$ORACLE_BASE/product/11.2.0/dbhome_1
export ORACLE_SID=orcl
export ORACLE_UNQNAME=orcl 
export PATH=\$ORACLE_HOME/bin:\$PATH:\$HOME/bin:\$ORACLE_HOME/lib:\$ORACLE_HOME/lib64
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib64
export ORA_NLS33=\$ORACLE_HOME/nls/data
export NLS_LANG=american_america.AL32UTF8 
export LANG=C
EOF
source /home/oracle/.bash_profile
sleep 2
# echo "export DISPLAY=`/usr/bin/xdpyinfo |awk '{print$4}' |head -1`" >> /home/oracle/.bash_profile 
source /home/oracle/.bash_profile

#拷贝解压执行oracle安装包
cd /usr/local/src/oracle11g-silent
unzip p13390677_112040_Linux-x86-64_1of7 -d /home/oracle
unzip p13390677_112040_Linux-x86-64_2of7 -d /home/oracle

su - oracle -c "mkdir -pv /home/oracle/app/fast_recovery_area"
su - oracle -c "mkdir -pv /home/oracle/app/oradata"

#静默安装oracle,修改安装配置文件
sed -i 's|oracle.install.option=|oracle.install.option=INSTALL_DB_SWONLY|' /home/oracle/database/response/db_install.rsp 
sed -i "s|ORACLE_HOSTNAME=|ORACLE_HOSTNAME=`hostname`|" /home/oracle/database/response/db_install.rsp 
sed -i 's|UNIX_GROUP_NAME=|UNIX_GROUP_NAME=oinstall|' /home/oracle/database/response/db_install.rsp 
sed -i 's|INVENTORY_LOCATION=|INVENTORY_LOCATION=/home/oracle/oraInventory/|' /home/oracle/database/response/db_install.rsp 
sed -i 's|ORACLE_HOME=|ORACLE_HOME=/home/oracle/app/product/11.2.0/dbhome_1/|' /home/oracle/database/response/db_install.rsp 
sed -i 's|ORACLE_BASE=|ORACLE_BASE=/home/oracle/app|' /home/oracle/database/response/db_install.rsp 
sed -i 's|oracle.install.db.InstallEdition=|oracle.install.db.InstallEdition=EE|'  /home/oracle/database/response/db_install.rsp 
sed -i 's|oracle.install.db.DBA_GROUP=|oracle.install.db.DBA_GROUP=dba|' /home/oracle/database/response/db_install.rsp 
sed -i 's|oracle.install.db.OPER_GROUP=|oracle.install.db.OPER_GROUP=oinstall|' /home/oracle/database/response/db_install.rsp 
sed -i 's|oracle.install.db.config.starterdb.type=|oracle.install.db.config.starterdb.type=GENERAL_PURPOSE|' /home/oracle/database/response/db_install.rsp
sed -i 's|oracle.install.db.config.starterdb.globalDBName=|oracle.install.db.config.starterdb.globalDBName=orcl|' /home/oracle/database/response/db_install.rsp
sed -i 's|oracle.install.db.config.starterdb.SID=|oracle.install.db.config.starterdb.SID=orcl|' /home/oracle/database/response/db_install.rsp
sed -i "s|oracle.install.db.config.starterdb.memoryLimit=|oracle.install.db.config.starterdb.memoryLimit=`free|sed -n '2p'|awk '{printf "%d",$2/1024/3}'`|" /home/oracle/database/response/db_install.rsp
sed -i 's|oracle.install.db.config.starterdb.password.ALL=|oracle.install.db.config.starterdb.password.ALL=Root123456|' /home/oracle/database/response/db_install.rsp
sed -i 's|oracle.install.db.config.starterdb.automatedBackup.enable=false|oracle.install.db.config.starterdb.automatedBackup.enable=true|' /home/oracle/database/response/db_install.rsp
sed -i 's|oracle.install.db.config.starterdb.automatedBackup.osuid=|oracle.install.db.config.starterdb.automatedBackup.osuid=10000|' /home/oracle/database/response/db_install.rsp
sed -i 's|oracle.install.db.config.starterdb.storageType=|oracle.install.db.config.starterdb.storageType=FILE_SYSTEM_STORAGE|' /home/oracle/database/response/db_install.rsp
sed -i 's|oracle.install.db.config.starterdb.fileSystemStorage.dataLocation=|oracle.install.db.config.starterdb.fileSystemStorage.dataLocation=/home/oracle/app/oradata/|' /home/oracle/database/response/db_install.rsp
sed -i 's|oracle.install.db.config.starterdb.fileSystemStorage.recoveryLocation=|oracle.install.db.config.starterdb.fileSystemStorage.recoveryLocation=/home/oracle/app/fast_recovery_area/|' /home/oracle/database/response/db_install.rsp
sed -i 's|SECURITY_UPDATES_VIA_MYORACLESUPPORT=|SECURITY_UPDATES_VIA_MYORACLESUPPORT=false|' /home/oracle/database/response/db_install.rsp
sed -i 's|DECLINE_SECURITY_UPDATES=|DECLINE_SECURITY_UPDATES=true|' /home/oracle/database/response/db_install.rsp
chmod -R +x /home/oracle/database/

su - oracle -c "/home/oracle/database/./runInstaller -silent -responseFile /home/oracle/database/response/db_install.rsp"

while true; do
installRes=`tail -1 /home/oracle/oraInventory/logs/installActions*.log`
   if   [[ "${installRes}" = "INFO: Shutdown Oracle Database 11g Release 2 Installer" ]];then
            echo "oracle11g-silent install successfully."
            sleep 30
            break
   elif [[ "${installRes}" = "INFO: Unloading Setup Driver" ]];then
            echo "oracle11g-silent install successfully."
            sleep 30
            break
   else
         sleep 30
         continue
   fi
done

rm -rf /var/run/yum.pid 
rm -rf /var/run/yum.pid

/home/oracle/oraInventory/orainstRoot.sh
/home/oracle/app/product/11.2.0/dbhome_1/root.sh

#配置oracle监听
#sed -i 's|INSTALL_TYPE=""typical""|INSTALL_TYPE=""custom""|' /home/oracle/database/response/netca.rsp
su - oracle -c "/home/oracle/app/product/11.2.0/dbhome_1/bin/netca /silent /responseFile /home/oracle/app/product/11.2.0/dbhome_1/assistants/netca/netca.rsp"
netstat -tlnp
sleep 15

#创建oracle数据库单实例
cp -rfp /home/oracle/app/product/11.2.0/dbhome_1/assistants/dbca/templates/General_Purpose.dbc /home/oracle/app/product/11.2.0/dbhome_1/assistants/dbca/templates/General_Purpose.dbc.back
sed -i 's|<archiveLogMode>false</archiveLogMode>|<archiveLogMode>true</archiveLogMode>|' /home/oracle/app/product/11.2.0/dbhome_1/assistants/dbca/templates/General_Purpose.dbc
#sed -i 's|<Name id="1" Tablespace="SYSTEM" Contents="PERMANENT" Size="740" autoextend="true" blocksize="8192    ">{ORACLE_BASE}/oradata/{DB_UNIQUE_NAME}/system01.dbf</Name>|<Name id="1" Tablespace="SYSTEM" Contents="PERMANENT" Size="1024" autoextend="true" blocksize="8192    ">{ORACLE_BASE}/oradata/{DB_UNIQUE_NAME}/system01.dbf</Name>|' /home/oracle/app/product/11.2.0/dbhome_1/assistants/dbca/templates/General_Purpose.dbc
#sed -i 's|<Name id="2" Tablespace="SYSAUX" Contents="PERMANENT" Size="470" autoextend="true" blocksize="8192    ">{ORACLE_BASE}/oradata/{DB_UNIQUE_NAME}/sysaux01.dbf</Name>|<Name id="2" Tablespace="SYSAUX" Contents="PERMANENT" Size="1024" autoextend="true" blocksize="8192    ">{ORACLE_BASE}/oradata/{DB_UNIQUE_NAME}/sysaux01.dbf</Name>|' /home/oracle/app/product/11.2.0/dbhome_1/assistants/dbca/templates/General_Purpose.dbc
#sed -i 's|<Name id="3" Tablespace="UNDOTBS1" Contents="UNDO" Size="25" autoextend="true" blocksize="8192">{O    RACLE_BASE}/oradata/{DB_UNIQUE_NAME}/undotbs01.dbf</Name>| <Name id="3" Tablespace="UNDOTBS1" Contents="UNDO" Size="2048" autoextend="true" blocksize="8192">{O    RACLE_BASE}/oradata/{DB_UNIQUE_NAME}/undotbs01.dbf</Name>|' /home/oracle/app/product/11.2.0/dbhome_1/assistants/dbca/templates/General_Purpose.dbc
#sed -i 's|<Name id="4" Tablespace="USERS" Contents="PERMANENT" Size="5" autoextend="true" blocksize="8192">{    ORACLE_BASE}/oradata/{DB_UNIQUE_NAME}/users01.dbf</Name>|<Name id="4" Tablespace="USERS" Contents="PERMANENT" Size="2048" autoextend="true" blocksize="8192">{    ORACLE_BASE}/oradata/{DB_UNIQUE_NAME}/users01.dbf</Name>|' /home/oracle/app/product/11.2.0/dbhome_1/assistants/dbca/templates/General_Purpose.dbc
sed -i 's|<fileSize unit="KB">51200</fileSize>|<fileSize unit="KB">512000</fileSize>|' /home/oracle/app/product/11.2.0/dbhome_1/assistants/dbca/templates/General_Purpose.dbc
#sed -i '94i \      <RedoLogGroupAttributes id="4">' /home/oracle/app/product/11.2.0/dbhome_1/assistants/dbca/templates/General_Purpose.dbc
#sed -i '95i \       <reuse>false</reuse>' /home/oracle/app/product/11.2.0/dbhome_1/assistants/dbca/templates/General_Purpose.dbc
#sed -i '96i \       <fileSize unit="KB">512000</fileSize>' /home/oracle/app/product/11.2.0/dbhome_1/assistants/dbca/templates/General_Purpose.dbc
#sed -i '97i \       <Thread>1</Thread>' /home/oracle/app/product/11.2.0/dbhome_1/assistants/dbca/templates/General_Purpose.dbc
#sed -i '98i \       <member ordinal="0" memberName="redo04.log" filepath="{ORACLE_BASE}/oradata/{DB_UNIQUE_NAME}/"/>' /home/oracle/app/product/11.2.0/dbhome_1/assistants/dbca/templates/General_Purpose.dbc
#sed -i '99i \      </RedoLogGroupAttributes>' /home/oracle/app/product/11.2.0/dbhome_1/assistants/dbca/templates/General_Purpose.dbc
#sed -i '100i \      <RedoLogGroupAttributes id="5">' /home/oracle/app/product/11.2.0/dbhome_1/assistants/dbca/templates/General_Purpose.dbc
#sed -i '101i \       <reuse>false</reuse>' /home/oracle/app/product/11.2.0/dbhome_1/assistants/dbca/templates/General_Purpose.dbc
#sed -i '102i \       <fileSize unit="KB">512000</fileSize>' /home/oracle/app/product/11.2.0/dbhome_1/assistants/dbca/templates/General_Purpose.dbc
#sed -i '103i \       <Thread>1</Thread>' /home/oracle/app/product/11.2.0/dbhome_1/assistants/dbca/templates/General_Purpose.dbc
#sed -i '104i \       <member ordinal="0" memberName="redo05.log" filepath="{ORACLE_BASE}/oradata/{DB_UNIQUE_NAME}/"/>' /home/oracle/app/product/11.2.0/dbhome_1/assistants/dbca/templates/General_Purpose.dbc
#sed -i '105i \      </RedoLogGroupAttributes>' /home/oracle/app/product/11.2.0/dbhome_1/assistants/dbca/templates/General_Purpose.dbc

su - oracle -c "/home/oracle/app/product/11.2.0/dbhome_1/bin/dbca -silent -createDatabase -templateName General_Purpose.dbc -gdbname orcl -sid orcl -sysPassword Root123456 -systemPassword Root123456 -responseFile NO_VALUE -datafileDestination /home/oracle/app/oradata -recoveryAreaDestination /home/oracle/app/fast_recovery_area -characterSet AL32UTF8 -nationalcharacterset AL16UTF16 -memoryPercentage 40 -totalMemory `free -m|sed -n '2p'|awk '{printf "%d",$2*0.6}'` -databaseType OLTP -automaticmemorymanagement true -emConfiguration NONE"

sed -i 's|orcl:/home/oracle/app/product/11.2.0/dbhome_1:N|orcl:/home/oracle/app/product/11.2.0/dbhome_1:Y|' /etc/oratab
chmod -R 764 /etc/oratab 
chown oracle:oinstall /etc/oratab
sed -i 's|ORACLE_HOME_LISTNER=\$1|ORACLE_HOME_LISTNER=\$ORACLE_HOME|' /home/oracle/app/product/11.2.0/dbhome_1/bin/dbstart 
sed -i 's|ORACLE_HOME_LISTNER=\$1|ORACLE_HOME_LISTNER=\$ORACLE_HOME|' /home/oracle/app/product/11.2.0/dbhome_1/bin/dbshut
echo "su - oracle -c '/home/oracle/app/product/11.2.0/dbhome_1/bin/lsnrctl start'" >> /etc/rc.d/rc.local 
echo "su - oracle -c '/home/oracle/app/product/11.2.0/dbhome_1/bin/dbstart'" >> /etc/rc.d/rc.local
chmod -R 754 /etc/rc.d/rc.local

#远程登录：
#echo 'SQLNET.ALLOWED_LOGON_VERSION=8' >> /home/oracle/app/product/11.2.0/dbhome_1/network/admin/sqlnet.ora 

chmod 777 /usr/local/src/oracle11g-silent/rlwrap-0.42-1.el6.x86_64.rpm
cd /usr/local/src/oracle11g-silent
yum -y install rlwrap-0.42-1.el6.x86_64.rpm 
cat >> /home/oracle/.bash_profile <<EOF
alias sqlplus='/usr/bin/rlwrap sqlplus'
alias rman='/usr/bin/rlwrap rman'
EOF

su - oracle -c 'sqlplus / as sysdba' < /usr/local/src/oracle11g-silent/mydb.sql

#mkdir /home/oracle/dump
#chmod 777 /home/oracle/dump/tt.dmp
#chown -R oracle:oinstall /home/oracle/dump/
#su - oracle -c 'impdp tt/tt@orcl directory=dump dumpfile=tt.dmp logfile=tt.log full=y;'
rm -rf /usr/local/src/oracle11g-silent
reboot
#删除数据库实例：alter database close; select status from v$instance; alter system enable restricted session;  drop database;
#systemctl list-units --type=service


# 实例应该被动态注册到监听程序了. 如果未被动态注册到监听程序, 则可以手工注册:
# SQL> alter system register;
# 改为归档模式并重启
# SQL> shutdown immediate;
# SQL> startup mount;
# SQL> alter database archivelog;
# SQL> alter database flashback on; (如果要启用数据库闪回功能则执行)
# SQL> alter database open;
# SQL> execute utl_recomp.recomp_serial(); (重新编译所有可能失效对象)
# SQL> alter system archive log current; (手工归档测试)

# cat /home/oracle/app/diag/rdbms/orcl/orcl/trace/alert_orcl.log 

