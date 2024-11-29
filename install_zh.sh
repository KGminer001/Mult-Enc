#!/bin/bash
# Author: KGminer001
# github: https://github.com/KGminer001

# 设置变量
setDownloadUrl=$1
setAppName=$2

# 配置变量
shell_version='1.0.0'
installfolder=/root/$setAppName/running
sofname='running'
sofnamekeep='MultiEnc'
AppFileName=$setAppName
AppName=$setAppName.tar.gz

# 下载地址
downloadUrl=$setDownloadUrl/$AppName

# 颜色
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

#检查当前下载的文件收有记录
if [ ! -f "$AppName" ]; then
    echo "\n"
else
    rm $AppName
fi

#停止主程序 使用 -A 用$1显示 使用-ef 用$2显示 -A可以找到隐藏程序
killProcess() {
    PROCESS=$(ps -A | grep $sofname|grep -v grep | grep -v PPID | awk '{ print $1}')
    for i in $PROCESS; do
        echo "Kill the $1 process [ $i ]"
        kill -9 $i
    done
    
    PROCESS=$(ps -A | grep $sofnamekeep|grep -v grep | grep -v PPID | awk '{ print $1}')
    for i in $PROCESS; do
        echo "Kill the $1 process [ $i ]"
        kill -9 $i
    done
}
# 检查程序
checkProcess() {
    COUNT=$(ps -A | grep $1 | grep -v "grep" | wc -l)
    if [ $COUNT -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

change_limit() {
    changeLimit="n"
    if [ $(grep -c "root soft nofile" /etc/security/limits.conf) -eq '0' ]; then
        echo "root soft nofile 65535" >>/etc/security/limits.conf
        echo "* soft nofile 65535" >>/etc/security/limits.conf
        changeLimit="y"
    fi

    if [ $(grep -c "root hard nofile" /etc/security/limits.conf) -eq '0' ]; then
        echo "root hard nofile 65535" >>/etc/security/limits.conf
        echo "* hard nofile 65535" >>/etc/security/limits.conf
        changeLimit="y"
    fi
    if [ $(grep -c "DefaultLimitNOFILE=65535" /etc/systemd/user.conf) -eq '0' ]; then
        echo "DefaultLimitNOFILE=65535" >>/etc/systemd/user.conf
        changeLimit="y"
    fi

    if [ $(grep -c "DefaultLimitNOFILE=65535" /etc/systemd/system.conf) -eq '0' ]; then
        echo "DefaultLimitNOFILE=65535" >>/etc/systemd/system.conf
        changeLimit="y"
    fi

    if [[ "$changeLimit" = "y" ]]; then
        echo "连接数限制已修改为65535,重启服务器后生效"
    else
        echo -n "当前连接数限制："
        ulimit -n
    fi
}

check_limit() {
    echo "当前系统连接数："
    ulimit -n
}

# 更新
update(){
  wget $downloadUrl
  if [ ! -f "$AppName" ]; then
    echo '更新失败，下载文件失败'
    rm $AppName
    return
  fi
  stop
  rm -rf $AppFileName
  tar -zxvf $AppName
  rm $AppName
  if [ ! -d "$AppFileName" ]; then
     echo '更新失败，解压失败'
     return
  fi
  cd $AppFileName
  setsid ./$sofname &
  sleep 1
  checkProcess "$sofname"
  if [ $? -eq 0 ]; then
    echo '启动失败'
    return
  fi  
  echo '启动成功'
}

# 安装
install() {
  if [ -f "$installfolder" ]; then
   echo '已经安装不要重复安装'
   return
  fi
  wget $downloadUrl
  if [ ! -f "$AppName" ]; then
    echo '安装失败，下载文件失败'
    rm $AppName
    return
  fi
  tar -zxvf $AppName
  rm $AppName
  if [ ! -d "$AppFileName" ]; then
     echo '安装失败，解压失败'
     return
  fi
  cd $AppFileName
  setsid ./$sofname &
  sleep 1
  checkProcess "$sofname"
  if [ $? -eq 0 ]; then
    echo '启动失败'
    return
  fi   
  change_limit
  auto_run_start
  echo '启动成功'
}

#卸载
uninstall(){
  killProcess
  rm -rf $AppFileName
}

#启动
start(){
  checkProcess "$sofname"
  if [ $? -eq 1 ]; then
    echo '已经启动不要重复启动'
    return
  fi      
  cd $AppFileName
  setsid ./$sofname &
  sleep 1
  checkProcess "$sofname"
  if [ $? -eq 0 ]; then
    echo '启动失败'
    return
  fi   
  echo '启动成功'
}

#停止
stop(){
  killProcess
  echo '停止成功'
}

# 重启
restart(){
  stop
  start
}

# 开机启动
auto_run_start(){
   crontab -l > /root/$AppFileName/crontab_auto 2>/dev/null
   echo "crontab 1"
   cat /root/$AppFileName/crontab_auto
   sed -i "/.*$AppFileName/d" /root/$AppFileName/crontab_auto
   echo "@reboot cd /root/ && cd $AppFileName/ && setsid ./$sofname &" >> /root/$AppFileName/crontab_auto
   #检查crontab_auto是否存在
   if [ ! -f "/root/$AppFileName/crontab_auto" ]; then
    echo "开机启动设置失败"
    return
   fi
   crontab /root/$AppFileName/crontab_auto
   echo "crontab 2"
   crontab -l
   echo '开机启动设置成功'
}

#关闭开机启动
auto_run_stop(){
    crontab -l > /root/$AppFileName/crontab_auto 2>/dev/null
    echo "crontab 1"
    cat /root/$AppFileName/crontab_auto
    sed -i "/.*$AppFileName/d" /root/$AppFileName/crontab_auto
    #检查crontab_auto是否存在
    if [ ! -f "/root/$AppFileName/crontab_auto" ]; then
    echo "开机启动关闭设置失败"
    return
    fi
    crontab /root/$AppFileName/crontab_auto
    echo "crontab 2"
    crontab -l
    echo '开机启动关闭设置成功'
}

check_install() {
    if [ ! -f "$installfolder" ]; then
        echo -e "             ${red}<<没有安装>>"
    else
        echo -e "             ${green}<<已经安装>>"
    fi
}

show_menu() {
    clear
    check_install
    echo -e "
     脚本版本: $shell_version 平台: $setAppName 
     ${green}0.${plain} 退出
     ${green}1.${plain} 安装
     ${green}2.${plain} 更新
     ${green}3.${plain} 卸载
     ${green}4.${plain} 启动
     ${green}5.${plain} 停止
     ${green}6.${plain} 重启
     ${green}7.${plain} 开启开机启动
     ${green}8.${plain} 关闭开机启动
     ${green}9.${plain} 设置最大连接数(重启生效,默认已经开启)
     ${green}10.${plain} 查看最大连接数
   "
    echo && read -p "请输入选择 [0-10]: " num
    case "${num}" in
    0)
        exit 0
        ;;
    1)
        install
        ;;
    2)
        update
        ;;
    3)
        uninstall
        ;;
    4)
        start
        ;;
    5)
        stop
        ;;
    6)
        restart
        ;;    
    7)
        auto_run_start
        ;;
    8)
        auto_run_stop
        ;;
    9)
        change_limit
        ;;
    10)
        check_limit
        ;;
    *)
        echo -e "${red}请输入正确的数字 [0-10]${plain}"
        ;;
    esac
}
show_menu
