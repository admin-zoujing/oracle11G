alter user sys identified by Root123456;
alter user system identified by Root123456;
shutdown immediate;
startup mount;
/*alter database archivelog;
alter system set db_recovery_file_dest_size=500G scope=both;
*/
select dbid,name,log_mode,platform_name from v$database;
alter database open;
alter system register;
alter system set processes=2000 scope=spfile; 
alter profile default limit password_life_time unlimited;
alter system set control_file_record_keep_time=45 scope=spfile;

/*
alter database logging datafile '/home/oracle/app/oradata/orcl/users01.dbf' resize 1024m autoextend on next 100m maxsize unlimited extent management local; 
alter database logging datafile '/home/oracle/app/oradata/orcl/system01.dbf' resize 1024m autoextend on next 100m maxsize unlimited extent management local; 
alter database logging datafile '/home/oracle/app/oradata/orcl/sysaux01.dbf' resize 1024m autoextend on next 100m maxsize unlimited extent management local; 
alter database logging datafile '/home/oracle/app/oradata/orcl/undotbs01.dbf' resize 1024m autoextend on next 100m maxsize unlimited extent management local; 
alter database add logfile group 4 ('/home/oracle/app/oradata/orcl/redo04.log') size 300m;
alter database add logfile group 5 ('/home/oracle/app/oradata/orcl/redo05.log') size 300m;
alter database add logfile group 6 ('/home/oracle/app/oradata/orcl/redo06.log') size 300m;
alter system switch logfile;
alter system switch logfile;
alter system switch logfile;
create tablespace TS_ELIB2 logging datafile '/home/oracle/app/oradata/orcl/TS_ELIB2.dbf' size 1024M autoextend on next 100m maxsize unlimited extent management local; 
create tablespace DIAMOND logging datafile '/home/oracle/app/oradata/orcl/DIAMOND.dbf' size 1024M autoextend on next 100m maxsize unlimited extent management local; 
create tablespace TT logging datafile '/home/oracle/app/oradata/orcl/TT.dbf' size 1024M autoextend on next 100m maxsize unlimited extent management local; 
create tablespace ECP logging datafile '/home/oracle/app/oradata/orcl/ECP.dbf' size 1024M autoextend on next 100m maxsize unlimited extent management local; 
CREATE USER TT IDENTIFIED BY tt ACCOUNT UNLOCK DEFAULT TABLESPACE TT;
GRANT CONNECT,RESOURCE TO TT;
GRANT DBA TO TT;
create directory dump as '/home/oracle/dump'; 
grant read,write on directory dump to TT;
select * from dba_directories;
impdp tt/tt@orcl directory=dump dumpfile=tt.dmp logfile=tt.log full=y;
*/



