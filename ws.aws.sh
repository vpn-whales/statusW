#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: ServerStatus client + server
#	Version: Test v0.004
#	Author: Toyo,Modify by CokeMine
#=================================================

sh_ver="0.0.1"
filepath=$(cd "$(dirname "$0")"; pwd)
file_1=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')
file="/usr/local/ServerStatus"
client_file="/usr/local/ServerStatus/client_w"
client_log_file="/tmp/serverstatus_client_w.log"
jq_file="${file}/jq"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

#检查系统
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
}
check_installed_client_status(){
	if [[ ! -e "${client_file}/status-client-w.py" ]]; then
		if [[ ! -e "${file}/status-client-w.py" ]]; then
			echo -e "${Error} ServerStatus 客户端没有安装，请检查 !" && exit 1
		fi
	fi
}
check_pid_client(){
	PID=`ps -ef| grep "status-client-w.py"| grep -v grep| grep -v ".sh"| grep -v "init.d"| grep -v "service"| awk '{print $2}'`
}
Download_Server_Status_client(){
	cd "/tmp"
	wget -N --no-check-certificate "https://raw.githubusercontent.com/jonaess/statusW/master/status-client-w.py"
	[[ ! -e "status-client-w.py" ]] && echo -e "${Error} ServerStatus 客户端下载失败 !" && exit 1
	cd "${file_1}"
	[[ ! -e "${file}" ]] && mkdir "${file}"
	if [[ ! -e "${client_file}" ]]; then
		mkdir "${client_file}"
		mv "/tmp/status-client-w.py" "${client_file}/status-client-w.py"
	else
		if [[ -e "${client_file}/status-client-w.py" ]]; then
			mv "${client_file}/status-client-w.py" "${client_file}/status-client1-w.py"
			mv "/tmp/status-client-w.py" "${client_file}/status-client-w.py"
		else
			mv "/tmp/status-client-w.py" "${client_file}/status-client-w.py"
		fi
	fi
	if [[ ! -e "${client_file}/status-client-w.py" ]]; then
		echo -e "${Error} ServerStatus 客户端移动失败 !"
		[[ -e "${client_file}/status-client1.py" ]] && mv "${client_file}/status-client1.py" "${client_file}/status-client.py"
		rm -rf "/tmp/status-client-w.py"
		exit 1
	else
		[[ -e "${client_file}/status-client1-w.py" ]] && rm -rf "${client_file}/status-client1-w.py"
		rm -rf "/tmp/status-client-w.py"
	fi
}
Service_Server_Status_client(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate "https://raw.githubusercontent.com/jonaess/statusW/master/server_status_client_centos" -O /etc/init.d/status-client-w; then
			echo -e "${Error} ServerStatus 客户端服务管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/status-client-w
		chkconfig --add status-client-w
		chkconfig status-client-w on
	else
		if ! wget --no-check-certificate "https://raw.githubusercontent.com/jonaess/statusW/master/server_status_client_debian" -O /etc/init.d/status-client-w; then
			echo -e "${Error} ServerStatus 客户端服务管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/status-client-w
		update-rc.d -f status-client-w defaults
	fi
	echo -e "${Info} ServerStatus 客户端服务管理脚本下载完成 !"
}
Installation_dependency(){
	mode=$1
	[[ -z ${mode} ]] && mode="server"
	if [[ ${mode} == "server" ]]; then
		python_status=$(python --help)
		if [[ ${release} == "centos" ]]; then
			yum update
			if [[ -z ${python_status} ]]; then
				yum install -y python unzip vim make
				yum groupinstall "Development Tools" -y
			else
				yum install -y unzip vim make
				yum groupinstall "Development Tools" -y
			fi
		else
			apt-get update
			if [[ -z ${python_status} ]]; then
				apt-get install -y python unzip vim build-essential make
			else
				apt-get install -y unzip vim build-essential make
			fi
		fi
	else
		python_status=$(python --help)
		if [[ ${release} == "centos" ]]; then
			if [[ -z ${python_status} ]]; then
				yum update
				yum install -y python
			fi
		else
			if [[ -z ${python_status} ]]; then
				apt-get update
				apt-get install -y python
			fi
		fi
	fi
}
Read_config_client(){
	if [[ ! -e "${client_file}/status-client-w.py" ]]; then
		if [[ ! -e "${file}/status-client-w.py" ]]; then
			echo -e "${Error} ServerStatus 客户端文件不存在 !" && exit 1
		else
			client_text="$(cat "${file}/status-client-w.py"|sed 's/\"//g;s/,//g;s/ //g')"
			rm -rf "${file}/status-client-w.py"
		fi
	else
		client_text="$(cat "${client_file}/status-client-w.py"|sed 's/\"//g;s/,//g;s/ //g')"
	fi
	client_server="$(echo -e "${client_text}"|grep "SERVER="|awk -F "=" '{print $2}')"
	client_port="$(echo -e "${client_text}"|grep "PORT="|awk -F "=" '{print $2}')"
	client_user="$(echo -e "${client_text}"|grep "USER="|awk -F "=" '{print $2}')"
	client_password="$(echo -e "${client_text}"|grep "PASSWORD="|awk -F "=" '{print $2}')"
}
Set_server(){
# 	mode=$1
# 	[[ -z ${mode} ]] && mode="server"
# 	if [[ ${mode} == "server" ]]; then
# 		echo -e "请输入 ServerStatus 服务端中网站要设置的 域名[server]
# 默认为本机IP为域名，例如输入: toyoo.pw ，如果要使用本机IP，请留空直接回车"
# 		read -e -p "(默认: 本机IP):" server_s
# 		[[ -z "$server_s" ]] && server_s=""
# 	else
# 		echo -e "请输入 ServerStatus 服务端的 IP/域名[server]"
# 		read -e -p "(默认: 45.76.173.118):" server_s
# 		[[ -z "$server_s" ]] && server_s="45.76.173.118"
# 	fi
	
# 	echo && echo "	================================================"
# 	echo -e "	IP/域名[server]: ${Red_background_prefix} ${server_s} ${Font_color_suffix}"
# 	echo "	================================================" && echo
	server_s="sr1.wocao.one"
}
Set_server_port(){
	# while true
	# 	do
	# 	echo -e "请输入 ServerStatus 服务端监听的端口[1-65535]（用于服务端接收客户端消息的端口，客户端要填写这个端口）"
	# 	read -e -p "(默认: 6666):" server_port_s
	# 	[[ -z "$server_port_s" ]] && server_port_s="6666"
	# 	echo $((${server_port_s}+0)) &>/dev/null
	# 	if [[ $? -eq 0 ]]; then
	# 		if [[ ${server_port_s} -ge 1 ]] && [[ ${server_port_s} -le 65535 ]]; then
	# 			echo && echo "	================================================"
	# 			echo -e "	端口: ${Red_background_prefix} ${server_port_s} ${Font_color_suffix}"
	# 			echo "	================================================" && echo
	# 			break
	# 		else
	# 			echo "输入错误, 请输入正确的端口。"
	# 		fi
	# 	else
	# 		echo "输入错误, 请输入正确的端口。"
	# 	fi
	# done
	server_port_s="6666"
}
Set_username(){
	mode=$1
	[[ -z ${mode} ]] && mode="server"
	if [[ ${mode} == "server" ]]; then
		echo -e "请输入 ServerStatus 服务端要设置的用户名[username]（字母/数字，不可与其他账号重复）"
	else
		echo -e "请输入 ServerStatus 服务端中对应配置的用户名[username]（字母/数字，不可与其他账号重复）"
	fi
	read -e -p "(默认: 取消):" username_s
	[[ -z "$username_s" ]] && echo "已取消..." && exit 0
	echo && echo "	================================================"
	echo -e "	账号[username]: ${Red_background_prefix} ${username_s} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_password(){
	# mode=$1
	# [[ -z ${mode} ]] && mode="server"
	# if [[ ${mode} == "server" ]]; then
	# 	echo -e "请输入 ServerStatus 服务端要设置的密码[password]（字母/数字，可重复）"
	# else
	# 	echo -e "请输入 ServerStatus 服务端中对应配置的密码[password]（字母/数字）"
	# fi
	# read -e -p "(默认: doub.io):" password_s
	# [[ -z "$password_s" ]] && password_s="doub.io"
	# echo && echo "	================================================"
	# echo -e "	密码[password]: ${Red_background_prefix} ${password_s} ${Font_color_suffix}"
	# echo "	================================================" && echo
	password_s="doub.io"
}
Set_config_client(){
	Set_server "client"
	Set_server_port
	Set_username "client"
	Set_password "client"
}
Set_ServerStatus_client(){
	check_installed_client_status
	Set_config_client
	Read_config_client
	Del_iptables_OUT "${client_port}"
	Modify_config_client
	Add_iptables_OUT "${server_port_s}"
	Restart_ServerStatus_client
}
Modify_config_client(){
	sed -i 's/SERVER = "'"${client_server}"'"/SERVER = "'"${server_s}"'"/g' "${client_file}/status-client-w.py"
	sed -i "s/PORT = ${client_port}/PORT = ${server_port_s}/g" "${client_file}/status-client-w.py"
	sed -i 's/USER = "'"${client_user}"'"/USER = "'"${username_s}"'"/g' "${client_file}/status-client-w.py"
	sed -i 's/PASSWORD = "'"${client_password}"'"/PASSWORD = "'"${password_s}"'"/g' "${client_file}/status-client-w.py"
}
Install_ServerStatus_client(){
	[[ -e "${client_file}/status-client.py" ]] && echo -e "${Error} 检测到 ServerStatus 客户端已安装 !" && exit 1
	check_sys
	if [[ ${release} == "centos" ]]; then
		cat /etc/redhat-release |grep 7\..*|grep -i centos>/dev/null
		if [[ $? != 0 ]]; then
			echo -e "${Info} 检测到你的系统为 CentOS6，该系统自带的 Python2.6 版本过低，会导致无法运行客户端，如果你有能力升级为 Python2.7，那么请继续(否则建议更换系统)：[y/N]"
			read -e -p "(默认: N 继续安装):" sys_centos6
			[[ -z "$sys_centos6" ]] && sys_centos6="n"
			if [[ "${sys_centos6}" == [Nn] ]]; then
				echo -e "\n${Info} 已取消...\n"
				exit 1
			fi
		fi
	fi
	echo -e "${Info} 开始设置 用户配置..."
	Set_config_client
	echo -e "${Info} 开始安装/配置 依赖..."
	Installation_dependency "client"
	echo -e "${Info} 开始下载/安装..."
	Download_Server_Status_client
	echo -e "${Info} 开始下载/安装 服务脚本(init)..."
	Service_Server_Status_client
	echo -e "${Info} 开始写入 配置..."
	Read_config_client
	Modify_config_client
	echo -e "${Info} 开始设置 iptables防火墙..."
	Set_iptables
	echo -e "${Info} 开始添加 iptables防火墙规则..."
	Add_iptables_OUT "${server_port_s}"
	echo -e "${Info} 开始保存 iptables防火墙规则..."
	Save_iptables
	echo -e "${Info} 所有步骤 安装完毕，开始启动..."
	Start_ServerStatus_client
}
Start_ServerStatus_client(){
	check_installed_client_status
	check_pid_client
	[[ ! -z ${PID} ]] && echo -e "${Error} ServerStatus 正在运行，请检查 !" && exit 1
	/etc/init.d/status-client-w start
}
Stop_ServerStatus_client(){
	check_installed_client_status
	check_pid_client
	[[ -z ${PID} ]] && echo -e "${Error} ServerStatus 没有运行，请检查 !" && exit 1
	/etc/init.d/status-client-w stop
}
Restart_ServerStatus_client(){
	check_installed_client_status
	check_pid_client
	[[ ! -z ${PID} ]] && /etc/init.d/status-client-w stop
	/etc/init.d/status-client-w start
}
Uninstall_ServerStatus_client(){
	check_installed_client_status
	echo "确定要卸载 ServerStatus 客户端(如果同时安装了服务端，则只会删除客户端) ? [y/N]"
	echo
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_pid_client
		[[ ! -z $PID ]] && kill -9 ${PID}
		Read_config_client
		Del_iptables_OUT "${client_port}"
		Save_iptables
		if [[ -e "${server_file}/sergate" ]]; then
			rm -rf "${client_file}"
		else
			rm -rf "${file}"
		fi
		rm -rf /etc/init.d/status-client
		if [[ ${release} = "centos" ]]; then
			chkconfig --del status-client
		else
			update-rc.d -f status-client remove
		fi
		echo && echo "ServerStatus 卸载完成 !" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
}
View_ServerStatus_client(){
	check_installed_client_status
	Read_config_client
	clear && echo "————————————————————" && echo
	# IP \t: ${Green_font_prefix}${client_server}${Font_color_suffix}
  	# 端口 \t: ${Green_font_prefix}${client_port}${Font_color_suffix}
  	# 密码 \t: ${Green_font_prefix}${client_password}${Font_color_suffix}
	echo -e "  ServerStatus 客户端配置信息：
 

  账号 \t: ${Green_font_prefix}${client_user}${Font_color_suffix}
  
 
————————————————————"
}
View_client_Log(){
	[[ ! -e ${client_log_file} ]] && echo -e "${Error} 没有找到日志文件 !" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 终止查看日志" && echo -e "如果需要查看完整日志内容，请用 ${Red_font_prefix}cat ${client_log_file}${Font_color_suffix} 命令。" && echo
	tail -f ${client_log_file}
}
Add_iptables_OUT(){
	iptables_ADD_OUT_port=$1
	iptables -I OUTPUT -m state --state NEW -m tcp -p tcp --dport ${iptables_ADD_OUT_port} -j ACCEPT
	iptables -I OUTPUT -m state --state NEW -m udp -p udp --dport ${iptables_ADD_OUT_port} -j ACCEPT
}
Del_iptables_OUT(){
	iptables_DEL_OUT_port=$1
	iptables -D OUTPUT -m state --state NEW -m tcp -p tcp --dport ${iptables_DEL_OUT_port} -j ACCEPT
	iptables -D OUTPUT -m state --state NEW -m udp -p udp --dport ${iptables_DEL_OUT_port} -j ACCEPT
}
Add_iptables(){
	iptables_ADD_IN_port=$1
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${iptables_ADD_IN_port} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${iptables_ADD_IN_port} -j ACCEPT
}
Del_iptables(){
	iptables_DEL_IN_port=$1
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${iptables_DEL_IN_port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${iptables_DEL_IN_port} -j ACCEPT
}
Save_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
	else
		iptables-save > /etc/iptables.up.rules
	fi
}
Set_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
		chkconfig --level 2345 iptables on
	else
		iptables-save > /etc/iptables.up.rules
		echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
		chmod +x /etc/network/if-pre-up.d/iptables
	fi
}
Update_Shell(){
	sh_new_ver=$(wget --no-check-certificate -qO- -t1 -T3 "https://raw.githubusercontent.com/CokeMine/ServerStatus-Hotaru/master/status.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="github"
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 无法链接到 Github !" && exit 0
	if [[ -e "/etc/init.d/status-client" ]]; then
		rm -rf /etc/init.d/status-client
		Service_Server_Status_client
	fi
	if [[ -e "/etc/init.d/status-server" ]]; then
		rm -rf /etc/init.d/status-server
		Service_Server_Status_server
	fi
	wget -N --no-check-certificate "https://raw.githubusercontent.com/CokeMine/ServerStatus-Hotaru/master/status.sh" && chmod +x status.sh
	echo -e "脚本已更新为最新版本[ ${sh_new_ver} ] !(注意：因为更新方式为直接覆盖当前运行的脚本，所以可能下面会提示一些报错，无视即可)" && exit 0
}
menu_client(){
echo && echo -e "  ServerStatus 一键安装管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Toyo | doub.io/shell-jc3 --
  --    Modify by CokeMine    --
 ${Green_font_prefix} 0.${Font_color_suffix} 升级脚本
 ————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安装 客户端
 ${Green_font_prefix} 2.${Font_color_suffix} 更新 客户端
 ${Green_font_prefix} 3.${Font_color_suffix} 卸载 客户端
————————————
 ${Green_font_prefix} 4.${Font_color_suffix} 启动 客户端
 ${Green_font_prefix} 5.${Font_color_suffix} 停止 客户端
 ${Green_font_prefix} 6.${Font_color_suffix} 重启 客户端
————————————
 ${Green_font_prefix} 7.${Font_color_suffix} 设置 客户端配置
 ${Green_font_prefix} 8.${Font_color_suffix} 查看 客户端信息
 ${Green_font_prefix} 9.${Font_color_suffix} 查看 客户端日志
————————————
 ${Green_font_prefix}10.${Font_color_suffix} 切换为 服务端菜单" && echo
if [[ -e "${client_file}/status-client.py" ]]; then
	check_pid_client
	if [[ ! -z "${PID}" ]]; then
		echo -e " 当前状态: 客户端 ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
	else
		echo -e " 当前状态: 客户端 ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
	fi
else
	if [[ -e "${file}/status-client.py" ]]; then
		check_pid_client
		if [[ ! -z "${PID}" ]]; then
			echo -e " 当前状态: 客户端 ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
		else
			echo -e " 当前状态: 客户端 ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
		fi
	else
		echo -e " 当前状态: 客户端 ${Red_font_prefix}未安装${Font_color_suffix}"
	fi
fi
echo
read -e -p " 请输入数字 [0-10]:" num
case "$num" in
	0)
	Update_Shell
	;;
	1)
	Install_ServerStatus_client
	;;
	2)
	Update_ServerStatus_client
	;;
	3)
	Uninstall_ServerStatus_client
	;;
	4)
	Start_ServerStatus_client
	;;
	5)
	Stop_ServerStatus_client
	;;
	6)
	Restart_ServerStatus_client
	;;
	7)
	Set_ServerStatus_client
	;;
	8)
	View_ServerStatus_client
	;;
	9)
	View_client_Log
	;;
	10)
	menu_server
	;;
	*)
	echo "请输入正确数字 [0-10]"
	;;
esac
}
check_sys
menu_client
