#!/bin/bash
# 作者: 欧阳剑宇
# 日期: 2022-07-19

# 全局颜色
if ! which tput >/dev/null 2>&1;then
    _norm="\033[39m"
    _red="\033[31m"
    _green="\033[32m"
    _tan="\033[33m"     
    _cyan="\033[36m"
else
    _norm=$(tput sgr0)
    _red=$(tput setaf 1)
    _green=$(tput setaf 2)
    _tan=$(tput setaf 3)
    _cyan=$(tput setaf 6)
fi

_print() {
	printf "${_norm}%s${_norm}\n" "$@"
}
_info() {
	printf "${_cyan}➜ %s${_norm}\n" "$@"
}
_success() {
	printf "${_green}✓ %s${_norm}\n" "$@"
}
_warning() {
	printf "${_tan}⚠ %s${_norm}\n" "$@"
}
_error() {
	printf "${_red}✗ %s${_norm}\n" "$@"
}
_errornoblank() {
	printf "${_red}%s${_norm}\n" "$@"
}

_checkroot() {
	if [ $EUID != 0 ] || [[ $(grep "^$(whoami)" /etc/passwd | cut -d':' -f3) != 0 ]]; then
        _error "没有 root 权限，请运行 \"sudo su -\" 命令并重新运行该脚本"
		exit 1
	fi
}
_checkroot

# 变量名
# SH_NAME 值必须和脚本名完全相同，脚本名修改的话必须改这里
SH_NAME="multi-sync-backup"
EXEC_COMMON_LOGFILE=/var/log/${SH_NAME}/log/exec-"$(date +"%Y-%m-%d")".log
EXEC_ERROR_WARNING_SYNC_LOGFILE=/var/log/${SH_NAME}/log/exec-error-warning-sync-"$(date +"%Y-%m-%d")".log
EXEC_ERROR_WARNING_BACKUP_LOGFILE=/var/log/${SH_NAME}/log/exec-error-warning-backup-"$(date +"%Y-%m-%d")".log

SYNC_SOURCE_PATH=
SYNC_DEST_PATH=
BACKUP_SOURCE_PATH=
BACKUP_DEST_PATH=

SYNC_SOURCE_ALIAS=
SYNC_DEST_ALIAS=
BACKUP_SOURCE_ALIAS=
BACKUP_DEST_ALIAS=

SYNC_GROUP_INFO=
BACKUP_GROUP_INFO=
SYNC_TYPE=
BACKUP_TYPE=
SYNC_DATE_TYPE=
BACKUP_DATE_TYPE=
SYNC_OPERATION_NAME=
BACKUP_OPERATION_NAME=

OPERATION_CRON=
OPERATION_CRON_NAME=
LOG_CRON=

REMOVE_NODE_ALIAS=
REMOVE_OPERATION_NAME=
DEPLOY_NODE_ALIAS=

ALLOW_DAYS=

CHECK_DEP_SEP=0
DELETE_EXPIRED_LOG=0
CONFIRM_CONTINUE=0
HELP=0

if ! ARGS=$(getopt -a -o G:,g:,T:,t:,D:,d:,N:,n:,O:,o:,L:,l:,R:,s,e,y,h -l sync_source_path:,sync_dest_path:,backup_source_path:,backup_dest_path:,sync_source_alias:,sync_dest_alias:,backup_source_alias:,backup_dest_alias:,sync_group:,backup_group:,sync_type:,backup_type:,sync_operation_name:,backup_operation_name:,sync_date_type:,backup_date_type:,operation_cron:,operation_cron_name:,log_cron:,remove:,remove_operation_name:,deploy:,days:,check_dep_sep,deploy,delete_expired_log,yes,help -- "$@")
then
    _error "脚本中没有此无参选项或此选项为有参选项"
    exit 1
elif [ -z "$1" ]; then
    _error "没有设置选项"
    exit 1
elif [ "$1" == "-" ]; then
    _error "选项写法出现错误"
    exit 1
fi
eval set -- "${ARGS}"
while true; do
    case "$1" in
    # 始末端同步和备份路径
    --sync_source_path)
        if [ "$2" == "-" ]; then
            _error "这是有参选项，必须指定对应参数，否则不能使用该选项！"
            exit 1
        else
            SYNC_SOURCE_PATH="$2"
        fi
        shift
        ;;
    --sync_dest_path)
        if [ "$2" == "-" ]; then
            _error "这是有参选项，必须指定对应参数，否则不能使用该选项！"
            exit 2
        else
            SYNC_DEST_PATH="$2"
        fi
        shift
        ;;
    --backup_source_path)
        if [ "$2" == "-" ]; then
            _error "这是有参选项，必须指定对应参数，否则不能使用该选项！"
            exit 1
        else
            BACKUP_SOURCE_PATH="$2"
        fi
        shift
        ;;
    --backup_dest_path)
        if [ "$2" == "-" ]; then
            _error "这是有参选项，必须指定对应参数，否则不能使用该选项！"
            exit 2
        else
            BACKUP_DEST_PATH="$2"
        fi
        shift
        ;;

    # 始末端同步和备份节点别名
    --sync_source_alias)
        if [ "$2" == "-" ]; then
            _error "这是有参选项，必须指定对应参数，否则不能使用该选项！"
            exit 4
        else
            SYNC_SOURCE_ALIAS="$2"
        fi
        shift
        ;;
    --sync_dest_alias)
        if [ "$2" == "-" ]; then
            _error "这是有参选项，必须指定对应参数，否则不能使用该选项！"
            exit 4
        else
            SYNC_DEST_ALIAS="$2"
        fi
        shift
        ;;
    --backup_source_alias)
        if [ "$2" == "-" ]; then
            _error "这是有参选项，必须指定对应参数，否则不能使用该选项！"
            exit 4
        else
            BACKUP_SOURCE_ALIAS="$2"
        fi
        shift
        ;;
    --backup_dest_alias)
        if [ "$2" == "-" ]; then
            _error "这是有参选项，必须指定对应参数，否则不能使用该选项！"
            exit 4
        else
            BACKUP_DEST_ALIAS="$2"
        fi
        shift
        ;;

    # 同步或备份方案的节点组名    
    -G | --sync_group)
        if [ "$2" == "-" ]; then
            _error "这是有参选项，必须指定对应参数，否则不能使用该选项！"
            exit 5
        else
            SYNC_GROUP_INFO="$2"
        fi
        shift
        ;;
    -g | --backup_group)
        if [ "$2" == "-" ]; then
            _error "这是有参选项，必须指定对应参数，否则不能使用该选项！"
            exit 5
        else
            BACKUP_GROUP_INFO="$2"
        fi
        shift
        ;;

    # 同步或备份方案的指定内容类型（纯文件或纯文件夹）
    -T | --sync_type)
        if [ "$2" == "-" ]; then
            _error "这是有参选项，必须指定对应参数，否则不能使用该选项！"
            exit 5
        else
            SYNC_TYPE="$2"
        fi
        shift
        ;;
    -t | --backup_type)
        if [ "$2" == "-" ]; then
            _error "这是有参选项，必须指定对应参数，否则不能使用该选项！"
            exit 5
        else
            BACKUP_TYPE="$2"
        fi
        shift
        ;;

    # 同步或备份方案的指定日期格式
    -D | --sync_date_type)
        if [ "$2" == "-" ]; then
            _error "这是有参选项，必须指定对应参数，否则不能使用该选项！"
            exit 5
        else
            SYNC_DATE_TYPE="$2"
        fi
        shift
        ;;
    -d | --backup_date_type)
        if [ "$2" == "-" ]; then
            _error "这是有参选项，必须指定对应参数，否则不能使用该选项！"
            exit 5
        else
            BACKUP_DATE_TYPE="$2"
        fi
        shift
        ;;

    # 指定同步或备份方案各自的名称
    -N | --sync_operation_name)
        if [ "$2" == "-" ]; then
            _error "这是有参选项，必须指定对应参数，否则不能使用该选项！"
            exit 5
        else
            SYNC_OPERATION_NAME="$2"
        fi
        shift
        ;;
    -n | --backup_operation_name)
        if [ "$2" == "-" ]; then
            _error "这是有参选项，必须指定对应参数，否则不能使用该选项！"
            exit 5
        else
            BACKUP_OPERATION_NAME="$2"
        fi
        shift
        ;;

    # 同步或备份方案的指定定时方案
    -O | --operation_cron)
        if [ "$2" == "-" ]; then
            _error "这是有参选项，必须指定对应参数，否则不能使用该选项！"
            exit 5
        else
            OPERATION_CRON="$2"
        fi
        shift
        ;;
    -o | --operation_cron_name)
        if [ "$2" == "-" ]; then
            _error "这是有参选项，必须指定对应参数，否则不能使用该选项！"
            exit 5
        else
            OPERATION_CRON_NAME="$2"
        fi
        shift
        ;;
    -l | --log_cron)
        if [ "$2" == "-" ]; then
            _error "这是有参选项，必须指定对应参数，否则不能使用该选项！"
            exit 5
        else
            LOG_CRON="$2"
        fi
        shift
        ;;

    # 安装卸载相关选项
    -R | --remove)
        if [ "$2" == "-" ]; then
            _error "这是有参选项，必须指定对应参数，否则不能使用该选项！"
            exit 5
        else
            REMOVE_NODE_ALIAS="$2"
        fi
        shift
        ;;
    -r | --remove_operation_name)
        if [ "$2" == "-" ]; then
            _error "这是有参选项，必须指定对应参数，否则不能使用该选项！"
            exit 5
        else
            REMOVE_OPERATION_NAME="$2"
        fi
        shift
        ;;
    -L | --deploy)
        if [ "$2" == "-" ]; then
            _error "这是有参选项，必须指定对应参数，否则不能使用该选项！"
            exit 5
        else
            DEPLOY_NODE_ALIAS="$2"
        fi
        shift
        ;;

    # 允许的最长历史搜索天数
    --days)
        if [ "$2" == "-" ]; then
            _error "这是有参选项，必须指定对应参数，否则不能使用该选项！"
            exit 5
        else
            ALLOW_DAYS="$2"
        fi
        shift
        ;;
    
    # 其他选项
    -s | --check_dep_sep)
        CHECK_DEP_SEP=1
        ;;
    -e | --delete_expired_log)
        DELETE_EXPIRED_LOG=1
        ;;
    -y | --yes)
        CONFIRM_CONTINUE=1
        ;;
    -h | --help)
        HELP=1
        ;;
    --)
        shift
        break
        ;;
    esac
    shift
done

EnvCheck(){
    _info "环境自检中，请稍后"
    # 检查必要软件包安装情况(集成独立检测依赖功能)
    #_info "检查脚本使用的有关软件安装情况"
    appList="tput scp pwd basename sort tail tee md5sum ip ifconfig shuf column sha256sum dirname stat"
    appNotInstalled=""
    for i in ${appList}; do
        if which "$i" >/dev/null 2>&1; then
            [ "${CHECK_DEP_SEP}" == 1 ] && _success "$i 已安装"
        else
            [ "${CHECK_DEP_SEP}" == 1 ] && _error "$i 未安装"
            appNotInstalled="${appNotInstalled} $i"
        fi
    done
    if [ -n "${appNotInstalled}" ]; then
        _error "未安装的软件为: ${appNotInstalled}"
        _error "当前运行环境不支持部分脚本功能，为安全起见，此脚本在重新适配前运行都将自动终止进程"
        exit 1
    elif [ -z "${appNotInstalled}" ]; then
        [ "${CHECK_DEP_SEP}" == 1 ] && _success "脚本正常工作所需依赖全部满足要求" && exit 0
    fi
    # 此环节用于检测是否有人为修改免密节点组信息的情况，并且在存在这种情况的前提下尝试自动修复，/root/.ssh/config 文件中应该包含各种免密组的文件夹名，所以默认脚本均检测此文件内容
    # 为防止此文件被误删，在每个创建的免密组文件夹中均有一个创建该组时对 config 硬链接的文件，名字是 .backup_config
    
    # 自检流程：
    # 1. 如果 /root/.ssh/config 不存在，则遍历 /root/.ssh 下的所有文件夹，查找里面的 .backup_config，如果都不存在则表示环境被毁或没有用专用脚本做免密部署，直接报错退出，如果存在，则取找到的列表中的第一个直接做个硬链接成 /root/.ssh/config
    if [ ! -f /root/.ssh/config ]; then
        _warning "自动部署的业务节点免密组配置文件被人为删除，正在尝试恢复"
        mapfile -t BACKUP_CONFIG < <(find /root/.ssh -type f -name ".backup_config")
        if [ "${#BACKUP_CONFIG[@]}" -eq 0 ]; then
            _error "所有 ssh 业务节点免密组的配置文件均未找到，如果此服务器未使用本脚本作者所写免密部署脚本部署，请先使用免密部署工具进行预部署后再执行此脚本"
            _error "如果曾经预部署过，请立即人工恢复，否则所有此脚本作者所写的自动化脚本将全体失效"
            exit 1
        elif [ "${#BACKUP_CONFIG[@]}" -ne 0 ]; then
            ln "${BACKUP_CONFIG[0]}" /root/.ssh/config
            _success "业务节点免密组默认配置文件恢复"
        fi
    fi

    # 2. 如果 /root/.ssh/config 存在，则遍历 /root/.ssh/config 中保存的节点组名的配置对比 /root/.ssh 下的所有文件夹名，查找里面的 .backup_config，在 /root/.ssh/config 中存在但对应文件夹中不存在 .backup_config 则做个硬链接到对应文件夹，
    # 如果文件夹被删，则删除 config 中的配置并报错退出
    mapfile -t GROUP_NAME_IN_FILE < <(awk -F '[ /]' '{print $2}' /root/.ssh/config)
    for i in "${GROUP_NAME_IN_FILE[@]}"; do
        if [ ! -f /root/.ssh/"${i}"/.backup_config ]; then
            if [ ! -d /root/.ssh/"${i}" ]; then
                _error "业务节点免密组被人为删除，已从配置文件中删除此节点组引用，请重新运行免密部署脚本以添加需要的组"
                sed -i "/\ ${i}/d" /root/.ssh/config
                exit 1
            else
                _warning "${i} 业务节点免密组的备份配置被人为删除，正在恢复"
                ln /root/.ssh/config /root/.ssh/"${i}"/.backup_config
                _success "${i} 业务节点免密组默认配置文件恢复"
            fi
        fi
    done

    # 3. 遍历 /root/.ssh 中的所有子文件夹中的 .backup_config 文件，然后对比查看对应文件夹名在 config 文件中是否有相关信息（上一步的 GROUP_NAME_IN_FILE 数组），没有的话添加上
    # 如果出现 config 文件与免密组文件夹名对不上的情况，可以清空 config 文件中的内容，通过文件夹的方式重新生成
    mapfile -t DIR_GROUP_NAME < <(find /root/.ssh -type f -name ".backup_config"|awk -F '/' '{print $(NF-1)}')
    mapfile -t GROUP_NAME_IN_FILE < <(awk -F '[ /]' '{print $2}' /root/.ssh/config)
    for i in "${DIR_GROUP_NAME[@]}"; do
        MARK=0
        for j in "${GROUP_NAME_IN_FILE[@]}"; do
            if [ "$i" = "${j}" ]; then
                MARK=1
                break
            fi
        done
        if [ "${MARK}" -eq 0 ]; then
            if [ -f /root/.ssh/"${i}"/"${i}"-authorized_keys ] && [ -f /root/.ssh/"${i}"/"${i}"-key ] && [ -n "$(find /root/.ssh/"${i}" -type f -name "config-${i}-*")" ];then
                if [ "$(find /root/.ssh/"${i}" -name "*-authorized_keys"|wc -l)" -eq 1 ];then
                    _warning "默认配置文件中存在未添加的节点组信息，正在添加"
                    if [ -n "$(cat /root/.ssh/config)" ]; then
                        sed -i "1s/^/Include ${i}\/config-${i}-*\n/" /root/.ssh/config
                    else
                        echo -e "Include ${i}/config-${i}-*" >> /root/.ssh/config
                    fi
                else
                    _error "发现多个公钥，请自行检查哪个可用"
                    _error "这里不想适配了，哪能手贱成这样啊？？？自动部署的地方非要手动不按规矩改？？？"
                    exit 1
                fi
            else
                _warning "/root/.ssh/${i} 文件夹可能不是通过免密部署脚本实现的，将移除其中的 .backup_config 文件防止未来反复报错，其余文件请自行检查"
                rm -rf /root/.ssh/"${i}"/.backup_config
            fi
        fi
    done
    # 4. 将 .ssh 为开头的路径的数组对比 /etc/ssh/sshd_config，如果 ssh 配置文件不存在则添加上并重启 ssh
    [[ "$(grep "AuthorizedKeysFile" /etc/ssh/sshd_config)" =~ "#" ]] && sed -i 's/^#AuthorizedKeysFile/AuthorizedKeysFile/' /etc/ssh/sshd_config
    mapfile -t DIR_AUTHORIZED_KEYS_PATH < <(find /root/.ssh -type f -name "*-authorized_keys"|sed 's/\/root\///g')
    IFS=" " read -r -a SSHD_CONFIG_PATH <<< "$(grep "AuthorizedKeysFile" /etc/ssh/sshd_config|awk '$1=""; {print $0}')"
    IF_NEED_RESTART_SSHD=0
    for i in "${DIR_AUTHORIZED_KEYS_PATH[@]}"; do
        MARK=0
        for j in "${SSHD_CONFIG_PATH[@]}"; do
            if [ "${i}" = "${j}" ];then
                MARK=1
                break
            fi
        done
        if [ "${MARK}" -eq 0 ]; then
            IF_NEED_RESTART_SSHD=1
            _warning "sshd 配置文件缺少有关免密参数，正在修改"
            i=$(echo "$i"|sed 's/\//\\\//g')
            sed -i "/AuthorizedKeysFile/s/$/\ ${i}/g" /etc/ssh/sshd_config
        fi
    done
    [ "${IF_NEED_RESTART_SSHD}" -eq 1 ] && systemctl restart sshd
    _success "环境自检完成"
}

CheckExecOption(){
    # 只执行完就直接退出
    [ "${HELP}" -eq 1 ] && Help && exit 0
    [ "${DELETE_EXPIRED_LOG}" -eq 1 ] && DeleteExpiredLog && exit 0

    _info "开始检查传递的选项和参数"
    ################################################################
    # 仅运行同步备份或先同步再备份的所有选项
    if [ -n "${SYNC_SOURCE_PATH}" ] && [ -n "${SYNC_DEST_PATH}" ] && [ -n "${SYNC_SOURCE_ALIAS}" ] && [ -n "${SYNC_DEST_ALIAS}" ] && [ -n "${SYNC_GROUP_INFO}" ] && [ -n "${SYNC_TYPE}" ] && [ -n "${SYNC_DATE_TYPE}" ] && [ -n "${BACKUP_SOURCE_PATH}" ] && [ -n "${BACKUP_DEST_PATH}" ] && [ -n "${BACKUP_SOURCE_ALIAS}" ] && [ -n "${BACKUP_DEST_ALIAS}" ] && [ -n "${BACKUP_GROUP_INFO}" ] && [ -n "${BACKUP_TYPE}" ] && [ -n "${BACKUP_DATE_TYPE}" ] && [ -n "${ALLOW_DAYS}" ]; then
        :
    elif [ -n "${SYNC_SOURCE_PATH}" ] && [ -n "${SYNC_DEST_PATH}" ] && [ -n "${SYNC_SOURCE_ALIAS}" ] && [ -n "${SYNC_DEST_ALIAS}" ] && [ -n "${SYNC_GROUP_INFO}" ] && [ -n "${SYNC_TYPE}" ] && [ -n "${SYNC_DATE_TYPE}" ] && [ -z "${BACKUP_SOURCE_PATH}" ] && [ -z "${BACKUP_DEST_PATH}" ] && [ -z "${BACKUP_SOURCE_ALIAS}" ] && [ -z "${BACKUP_DEST_ALIAS}" ] && [ -z "${BACKUP_GROUP_INFO}" ] && [ -z "${BACKUP_TYPE}" ] && [ -z "${BACKUP_DATE_TYPE}" ] && [ -n "${ALLOW_DAYS}" ]; then
        :
    elif [ -n "${BACKUP_SOURCE_PATH}" ] && [ -n "${BACKUP_DEST_PATH}" ] && [ -n "${BACKUP_SOURCE_ALIAS}" ] && [ -n "${BACKUP_DEST_ALIAS}" ] && [ -n "${BACKUP_GROUP_INFO}" ] && [ -n "${BACKUP_TYPE}" ] && [ -n "${BACKUP_DATE_TYPE}" ] && [ -z "${SYNC_SOURCE_PATH}" ] && [ -z "${SYNC_DEST_PATH}" ] && [ -z "${SYNC_SOURCE_ALIAS}" ] && [ -z "${SYNC_DEST_ALIAS}" ] && [ -z "${SYNC_GROUP_INFO}" ] && [ -z "${SYNC_TYPE}" ] && [ -z "${SYNC_DATE_TYPE}" ] && [ -n "${ALLOW_DAYS}" ]; then
        :
    else
        _error "用户层面只有三种输入选项参数的组合方式，同步、备份、同步后备份，请仔细对比帮助信息并检查缺失的选项和参数"
        _warning "运行同步功能所需的八个有参选项(两个通用选项见下):"
        _errornoblank "
                       --sync_source_path 设置源同步路径
                       --sync_dest_path 设置目的同步路径
                       --sync_source_alias 设置源同步节点别名
                       --sync_dest_alias 设置目的同步节点别名
                       --sync_group 设置同步的节点组别名
                       --sync_type 设置同步的内容类型
                       --sync_date_type 设置同步的日期格式"|column -t
        echo ""
        _warning "运行备份功能所需的八个有参选项(两个通用选项见下):"
        _errornoblank "
                       --backup_source_path 设置源备份路径
                       --backup_dest_path 设置目的备份路径
                       --backup_source_alias 设置源备份节点别名
                       --backup_dest_alias 设置目的备份节点别名
                       --backup_group 设置备份的节点组别名
                       --backup_type 设置备份的内容类型
                       --backup_date_type 设置备份的日期格式"|column -t
        echo ""
        _error "运行任意一种功能均需设置最长查找历史天数的有参选项: --days"
        _warning "运行同步后备份的功能需要以上所有有参选项共十六个，三种组合方式中，任何选项均没有次序要求"
        exit 1
    fi

    mapfile -t GROUP_NAME_IN_FILE < <(awk -F '[ /]' '{print $2}' /root/.ssh/config)
    # 同步节点组名非空时，检查其他所有同步选项
    if [ -n "${SYNC_GROUP_INFO}" ]; then
        for i in "${GROUP_NAME_IN_FILE[@]}"; do
            MARK=0
            if [ "$i" = "${SYNC_GROUP_INFO}" ]; then
                MARK=1
                break
            fi
        done
        if [ "${MARK}" -eq 0 ]; then
            _error "请输入正确的同步免密节点组名称"
            _error "可用节点组如下:"
            for i in "${GROUP_NAME_IN_FILE[@]}"; do
                echo "${i}"
            done
            exit 1
        fi
        [[ ! "${SYNC_SOURCE_PATH}" =~ ^/ ]] && _error "设置的源同步节点路径必须为绝对路径，请检查" && exit 112
        [[ ! "${SYNC_DEST_PATH}" =~ ^/ ]] && _error "设置的目标同步节点路径必须为绝对路径，请检查" && exit 112

        mapfile -t HOST_ALIAS < <(cat /root/.ssh/"${SYNC_GROUP_INFO}"/config-"${SYNC_GROUP_INFO}"-*|awk '/Host / {print $2}')
        for i in "${HOST_ALIAS[@]}"; do
                MARK=0
            [ "${i}" = "${SYNC_SOURCE_ALIAS}" ] && MARK=1 && break
        done
        if [ "${MARK}" -eq 0 ]; then
            _error "源同步节点别名错误，请检查指定的免密节点组名中可用的源同步节点别名:"
            for i in "${HOST_ALIAS[@]}"; do
                echo "${i}"
            done
            exit 114
        fi

        for i in "${HOST_ALIAS[@]}"; do
            MARK=0
            [ "${i}" = "${SYNC_DEST_ALIAS}" ] && MARK=1 && break
        done
        if [ "${MARK}" -eq 0 ]; then
            _error "目标同步节点别名错误，请检查指定的免密节点组名中可用的目标同步节点别名:"
            for i in "${HOST_ALIAS[@]}"; do
                echo "${i}"
            done
            exit 114
        fi
        if [ ! "${SYNC_TYPE}" = "dir" ] && [ ! "${SYNC_TYPE}" = "file" ]; then
            _error "必须正确指定需要操作的内容类型参数: 按日期排序的文件或文件夹"
            _error "纯文件参数写法: dir"
            _error "纯文件夹参数写法: file"
            exit 1
        fi

        if [[ "${SYNC_DATE_TYPE}" =~ ^[0-9a-zA-Z]{4}-[0-9a-zA-Z]{2}-[0-9a-zA-Z]{2}+$ ]]; then
            SYNC_DATE_TYPE="YYYY-MMMM-DDDD"
        elif [[ "${SYNC_DATE_TYPE}" =~ ^[0-9a-zA-Z]{4}_[0-9a-zA-Z]{2}_[0-9a-zA-Z]{2}+$ ]]; then
            SYNC_DATE_TYPE="YYYY_MMMM_DDDD"
        else
            _error "同步日期格式不存在，格式举例: abcd-Mm-12 或 2000_0a_3F，年份四位，月和日均为两位字符"
            _error "格式支持大小写字母和数字随机组合，只检测连接符号特征，支持的格式暂时只有连字符和下划线两种"
            exit 1
        fi
    fi

    # 备份节点组名非空时，检查其他所有备份选项
    if [ -n "${BACKUP_GROUP_INFO}" ]; then
        for i in "${GROUP_NAME_IN_FILE[@]}"; do
            MARK=0
            if [ "$i" = "${BACKUP_GROUP_INFO}" ]; then
                MARK=1
                break
            fi
        done
        if [ "${MARK}" -eq 0 ]; then
            _error "请输入正确的免密节点组名称"
            _error "可用节点组如下:"
            for i in "${GROUP_NAME_IN_FILE[@]}"; do
                echo "${i}"
            done
            exit 1
        fi
        [[ ! "${BACKUP_SOURCE_PATH}" =~ ^/ ]] && _error "设置的源备份节点路径必须为绝对路径，请检查" && exit 112
        [[ ! "${BACKUP_DEST_PATH}" =~ ^/ ]] && _error "设置的目标备份节点路径必须为绝对路径，请检查" && exit 112
        
        mapfile -t HOST_ALIAS < <(cat /root/.ssh/"${BACKUP_GROUP_INFO}"/config-"${BACKUP_GROUP_INFO}"-*|awk '/Host / {print $2}')
        for i in "${HOST_ALIAS[@]}"; do
            MARK=0
            [ "${i}" = "${BACKUP_SOURCE_ALIAS}" ] && MARK=1 && break
        done
        if [ "${MARK}" -eq 0 ]; then
            _error "源备份节点别名错误，请检查指定的免密节点组名中可用的源备份节点别名:"
            for i in "${HOST_ALIAS[@]}"; do
                echo "${i}"
            done
            exit 114
        fi

        for i in "${HOST_ALIAS[@]}"; do
            MARK=0
            [ "${i}" = "${BACKUP_DEST_ALIAS}" ] && MARK=1 && break
        done
        if [ "${MARK}" -eq 0 ]; then
            _error "目标备份节点别名错误，请检查指定的免密节点组名中可用的目标备份节点别名:"
            for i in "${HOST_ALIAS[@]}"; do
                echo "${i}"
            done
            exit 114
        fi

        if [ ! "${BACKUP_TYPE}" = "dir" ] && [ ! "${BACKUP_TYPE}" = "file" ]; then
            _error "必须正确指定需要操作的内容类型参数: 按日期排序的文件或文件夹"
            _error "纯文件参数写法: dir"
            _error "纯文件夹参数写法: file"
            exit 1
        fi
        
        if [[ "${BACKUP_DATE_TYPE}" =~ ^[0-9a-zA-Z]{4}-[0-9a-zA-Z]{2}-[0-9a-zA-Z]{2}+$ ]]; then
            BACKUP_DATE_TYPE="YYYY-MMMM-DDDD"
        elif [[ "${BACKUP_DATE_TYPE}" =~ ^[0-9a-zA-Z]{4}_[0-9a-zA-Z]{2}_[0-9a-zA-Z]{2}+$ ]]; then
            BACKUP_DATE_TYPE="YYYY_MMMM_DDDD"
        else
            _error "同步日期格式不存在，格式举例: abcd-Mm-12 或 2000_0a_3F，年份四位字符，月和日均为两位字符"
            _error "格式支持大小写字母和数字随意组合，只检测连接符号特征，支持的格式暂时只有连字符和下划线两种"
            exit 1
        fi
    fi

    if [ -z "${ALLOW_DAYS}" ] || [[ ! "${ALLOW_DAYS}" =~ ^[0-9]+$ ]]; then
        _error "未设置允许搜索的最早日期距离今日的最大天数，请检查"
        _error "选项名为: --days  参数为非负整数"
        exit 116
    fi
    _success "所有参数选项指定正确"
}

CheckDeployOption(){
    # 检查部署选项
    _info "开始检查传递的选项和参数"
    if [ -n "${DEPLOY_NODE_ALIAS}" ]; then
        mapfile -t GROUP_NAME_IN_FILE < <(awk -F '[ /]' '{print $2}' /root/.ssh/config)
        for i in "${GROUP_NAME_IN_FILE[@]}"; do
            MARK=0
            if [ "$i" = "${SYNC_GROUP_INFO}" ]; then
                MARK=1
                break
            fi
        done
        if [ "${MARK}" -eq 0 ]; then
            _error "请输入正确的同步免密节点组名称"
            _error "可用节点组如下:"
            for i in "${GROUP_NAME_IN_FILE[@]}"; do
                echo "${i}"
            done
            exit 1
        fi
        mapfile -t HOST_ALIAS < <(cat /root/.ssh/"${SYNC_GROUP_INFO}"/config-"${SYNC_GROUP_INFO}"-*|awk '/Host / {print $2}')
        if [ -n "${DEPLOY_NODE_ALIAS}" ]; then
            for i in "${HOST_ALIAS[@]}"; do
                MARK=0
                [ "${i}" = "${DEPLOY_NODE_ALIAS}" ] && MARK=1 && break
            done
            if [ "${MARK}" -eq 0 ]; then
                _error "部署节点别名错误，请检查指定的免密节点组名中可用的部署节点别名:"
                for i in "${HOST_ALIAS[@]}"; do
                    echo "${i}"
                done
                exit 114
            fi
        fi
        if ssh -o BatchMode=yes "${DEPLOY_NODE_ALIAS}" "echo "">/dev/null 2>&1" >/dev/null 2>&1; then
            _success "部署节点 ${DEPLOY_NODE_ALIAS} 连接正常"
        else
            _error "部署节点 ${DEPLOY_NODE_ALIAS} 无法连接，请检查源部署节点硬件是否损坏"
            MARK=1
        fi

        if [ -n "${SYNC_OPERATION_NAME}" ] && [ -n "${BACKUP_OPERATION_NAME}" ] && [ -n "${LOG_CRON}" ] && [ -n "${OPERATION_CRON}" ] && [ -n "${OPERATION_CRON_NAME}" ]; then
            :
        elif [ -n "${SYNC_OPERATION_NAME}" ] && [ -n "${LOG_CRON}" ] && [ -n "${OPERATION_CRON}" ] && [ -n "${OPERATION_CRON_NAME}" ]; then
            :
        elif [ -n "${BACKUP_OPERATION_NAME}" ] && [ -n "${LOG_CRON}" ] && [ -n "${OPERATION_CRON}" ] && [ -n "${OPERATION_CRON_NAME}" ]; then
            :
        else
            _error "部署时用户层面只有三种输入选项参数的组合方式，除了需要以上执行同步、备份、同步后备份的操作的所有选项外，还需指定部署节点、删除过期日志定时、操作别名和操作定时，请仔细对比帮助信息并检查缺失的选项和参数"
            _warning "部署同步功能所需的五个有参选项(四个通用选项见下):"
            _errornoblank "
                           --sync_operation_name 设置同步操作的别名"|column -t
            echo ""
            _warning "部署备份功能所需的五个有参选项(四个通用选项见下):"
            _errornoblank "
                           --backup_operation_name 设置备份操作的别名"|column -t
            echo ""
            _warning "运行任意一种功能均需设置的四种通用有参选项: "
            _errornoblank "
                           --deploy 设置部署节点别名
                           --operation_cron 设置集合功能脚本启动定时
                           --operation_cron_name 设置集合功能脚本名
                           --log_cron 设置删除过期日志定时规则"|column -t
            _warning "启用同步后备份的功能需要以上所有有参选项共六个，三种组合方式中，任何选项均没有次序要求"
            exit 1
        fi

        # 参数传入规范检查
        if [[ ! "${LOG_CRON}" =~ ^[0-9\*,/[:blank:]-]*$ ]]; then
            _error "清理过期日志定时写法有错，请检查"
            exit 1
        fi
        if [[ ! "${OPERATION_CRON}" =~ ^[0-9\*,/[:blank:]-]*$ ]]; then
            _error "集合操作定时写法有错，请检查"
            exit 1
        fi
        if [[ ! "${OPERATION_CRON_NAME}" =~ ^[0-9a-zA-Z_-]*$ ]]; then
            _error "集合操作别名写法有错，只支持大小写字母、数字、下划线和连字符，请检查"
            exit 1
        fi
        if [ -n "${SYNC_OPERATION_NAME}" ]; then
            if [[ ! "${SYNC_OPERATION_NAME}" =~ ^[0-9a-zA-Z_-]*$ ]]; then
                _error "同步操作别名写法有错，只支持大小写字母、数字、下划线和连字符，请检查"
                exit 1
            fi
        fi
        if [ -n "${BACKUP_OPERATION_NAME}" ]; then
            if [[ ! "${BACKUP_OPERATION_NAME}" =~ ^[0-9a-zA-Z_-]*$ ]]; then
                _error "备份操作别名写法有错，只支持大小写字母、数字、下划线和连字符，请检查"
                exit 1
            fi
        fi

        mapfile -t OPERATION_CRON_NAME_FILE < <(ssh "${DEPLOY_NODE_ALIAS}" "find /var/log/${SH_NAME}/exec -maxdepth 1 -type f "*run-*"|awk -F '/' '{print \$NF}'")
        MARK=0
        for i in "${OPERATION_CRON_NAME_FILE[@]}"; do
            [ "$i" = "${OPERATION_CRON_NAME}" ] && MARK=1
        done

        MARK_SYNC_OPERATION_NAME=0
        MARK_BACKUP_OPERATION_NAME=0
        if [ "${MARK}" -eq 1 ]; then
            mapfile -t SYNC_OPERATION_NAME_LIST < <(ssh "${DEPLOY_NODE_ALIAS}" "grep -oP \"--sync_operation_name\s+\K\w+\" /var/log/${SH_NAME}/exec/${OPERATION_CRON_NAME}")
            mapfile -t BACKUP_OPERATION_NAME_LIST < <(ssh "${DEPLOY_NODE_ALIAS}" "grep -oP \"--backup_operation_name\s+\K\w+\" /var/log/${SH_NAME}/exec/${OPERATION_CRON_NAME}")
            SAME_SYNC_OPERATION_NAME_LIST=()
            SAME_BACKUP_OPERATION_NAME_LIST=()
            for i in "${SYNC_OPERATION_NAME_LIST[@]}"; do
                [ "$i" = "${SYNC_OPERATION_NAME}" ] && MARK_SYNC_OPERATION_NAME=1 && break
            done

            for i in "${BACKUP_OPERATION_NAME_LIST[@]}"; do
                [ "$i" = "${BACKUP_OPERATION_NAME}" ] && MARK_BACKUP_OPERATION_NAME=1 && break
            done
            
            mapfile -t -O "${#SAME_SYNC_OPERATION_NAME_LIST[@]}" SAME_SYNC_OPERATION_NAME_LIST < <(ssh "${DEPLOY_NODE_ALIAS}" "grep \"--sync_operation_name ${SYNC_OPERATION_NAME}\" /var/log/${SH_NAME}/exec/${OPERATION_CRON_NAME}")
            mapfile -t -O "${#SAME_BACKUP_OPERATION_NAME_LIST[@]}" SAME_BACKUP_OPERATION_NAME_LIST < <(ssh "${DEPLOY_NODE_ALIAS}" "grep \"--backup_operation_name ${BACKUP_OPERATION_NAME}\" /var/log/${SH_NAME}/exec/${OPERATION_CRON_NAME}")
            # 信息汇总
            _success "已收集所需信息，请检查以下汇总信息:"
            _success "部署节点 ${DEPLOY_NODE_ALIAS} 中存在集合功能脚本 /var/log/${SH_NAME}/exec/run-${OPERATION_CRON_NAME}"
            if [ "${MARK_SYNC_OPERATION_NAME}" -eq 1 ]; then
                _warning "发现同名同步执行功能，请自行辨认，如果功能重复或只是希望更新信息，则请手动删除无用的执行功能"
                _warning "如果确认部署的话将追加而非替换，以下是全部同名同步执行功能:"
                for i in "${SAME_SYNC_OPERATION_NAME_LIST[@]}"; do
                    echo "$i"
                done
            fi
            echo ""
            if [ "${MARK_BACKUP_OPERATION_NAME}" -eq 1 ]; then
                _warning "发现同名同步执行功能，请自行辨认，如果功能重复或只是希望更新信息，则请手动删除无用的执行功能"
                _warning "如果确认部署的话将追加而非替换，以下是全部同名同步执行功能:"
                for i in "${SAME_BACKUP_OPERATION_NAME_LIST[@]}"; do
                    echo "$i"
                done
            fi
            echo ""
            _warning "将向部署节点 ${DEPLOY_NODE_ALIAS} 中创建的 ${OPERATION_CRON_NAME} 集合功能脚本加入以下执行功能:"
            if [ -n "${SYNC_OPERATION_NAME}" ]; then
                echo "bash <(cat /var/log/${SH_NAME}/exec/${SH_NAME}) --days \"${ALLOW_DAYS}\" --sync_source_path \"${SYNC_SOURCE_PATH}\" --sync_dest_path \"${SYNC_DEST_PATH}\" --sync_source_alias \"${SYNC_SOURCE_ALIAS}\" --sync_dest_alias \"${SYNC_DEST_ALIAS}\" --sync_group \"${SYNC_GROUP_INFO}\" --sync_type \"${SYNC_TYPE}\" --sync_date_type \"${SYNC_DATE_TYPE}\" --sync_operation_name \"${SYNC_OPERATION_NAME}\" -y"
            fi
            if [ -n "${BACKUP_OPERATION_NAME}" ]; then
                echo "bash <(cat /var/log/${SH_NAME}/exec/${SH_NAME}) --days \"${ALLOW_DAYS}\" --backup_source_path \"${BACKUP_SOURCE_PATH}\" --backup_dest_path \"${BACKUP_DEST_PATH}\" --backup_source_alias \"${BACKUP_SOURCE_ALIAS}\" --backup_dest_alias \"${BACKUP_DEST_ALIAS}\" --backup_group \"${BACKUP_GROUP_INFO}\" --backup_type \"${BACKUP_TYPE}\" --backup_date_type \"${BACKUP_DATE_TYPE}\" --backup_operation_name \"${BACKUP_OPERATION_NAME}\" -y"
            fi
        else
            # 信息汇总
            _success "已收集所需信息，请检查以下汇总信息:"
            _warning "部署节点 ${DEPLOY_NODE_ALIAS} 中未找到集合功能脚本 /var/log/${SH_NAME}/exec/run-${OPERATION_CRON_NAME}，即将创建该文件"
            _warning "将向部署节点 ${DEPLOY_NODE_ALIAS} 中创建的 ${OPERATION_CRON_NAME} 集合功能脚本加入以下执行功能:"
            if [ -n "${SYNC_OPERATION_NAME}" ]; then
                echo "bash <(cat /var/log/${SH_NAME}/exec/${SH_NAME}) --days \"${ALLOW_DAYS}\" --sync_source_path \"${SYNC_SOURCE_PATH}\" --sync_dest_path \"${SYNC_DEST_PATH}\" --sync_source_alias \"${SYNC_SOURCE_ALIAS}\" --sync_dest_alias \"${SYNC_DEST_ALIAS}\" --sync_group \"${SYNC_GROUP_INFO}\" --sync_type \"${SYNC_TYPE}\" --sync_date_type \"${SYNC_DATE_TYPE}\" --sync_operation_name \"${SYNC_OPERATION_NAME}\" -y"
            fi
            if [ -n "${BACKUP_OPERATION_NAME}" ]; then
                echo "bash <(cat /var/log/${SH_NAME}/exec/${SH_NAME}) --days \"${ALLOW_DAYS}\" --backup_source_path \"${BACKUP_SOURCE_PATH}\" --backup_dest_path \"${BACKUP_DEST_PATH}\" --backup_source_alias \"${BACKUP_SOURCE_ALIAS}\" --backup_dest_alias \"${BACKUP_DEST_ALIAS}\" --backup_group \"${BACKUP_GROUP_INFO}\" --backup_type \"${BACKUP_TYPE}\" --backup_date_type \"${BACKUP_DATE_TYPE}\" --backup_operation_name \"${BACKUP_OPERATION_NAME}\" -y"
            fi
        fi

        # 部署流程末尾，无论是否确认，各自功能都会运行完成后退出
        if [ "${CONFIRM_CONTINUE}" -eq 1 ]; then
            Deploy
        else
            _info "如确认汇总的检测信息无误，请重新运行命令并添加选项 -y 或 --yes 以实现检测完成后自动执行工作"
            exit 0
        fi
    else
        if [ -n "${SYNC_CRON}" ] || [ -n "${BACKUP_CRON}" ] || [ -n "${SYNC_OPERATION_NAME}" ] || [ -n "${BACKUP_OPERATION_NAME}" ] || [ -n "${LOG_CRON}" ]; then
            _warning "以下五个选项均为部署时的独占功能，如果只是运行备份或同步功能的话不要加上这些选项中的任意一个或多个"
            _errornoblank "
                           --sync_operation_name 设置同步操作的别名
                           --sync_cron 设置同步操作定时规则
                           --backup_operation_name 设置备份操作的别名
                           --backup_cron 设置备份操作定时规则
                           --log_cron 设置删除过期日志定时规则"|column -t
            exit 1
        fi
    fi
}

CheckRemoveOption(){
    _info "开始检查传递的选项和参数"
    if [ -n "${REMOVE_NODE_ALIAS}" ]; then
        OPERATION_NAME_COLLECT=()
        mapfile -t -O "${#OPERATION_NAME_COLLECT[@]}" OPERATION_NAME_COLLECT < <(grep -oP "cc\s+\K\w+" /etc/crontab)
        
        Remove
        exit 0
    fi
}

CheckTransmissionStatus(){
    _info "测试节点连通性"
    MARK=0
    if [ -n "${SYNC_SOURCE_ALIAS}" ]; then
        if ssh -o BatchMode=yes "${SYNC_SOURCE_ALIAS}" "echo "">/dev/null 2>&1" >/dev/null 2>&1; then
            _success "源同步节点 ${SYNC_SOURCE_ALIAS} 连接正常"
        else
            _error "源同步节点 ${SYNC_SOURCE_ALIAS} 无法连接，请检查源同步节点硬件是否损坏"
            MARK=1
        fi
    fi

    if [ -n "${SYNC_DEST_ALIAS}" ]; then
        if ssh -o BatchMode=yes "${SYNC_DEST_ALIAS}" "echo "">/dev/null 2>&1" >/dev/null 2>&1; then
            _success "目标同步节点 ${SYNC_DEST_ALIAS} 连接正常"
        else
            _error "目标同步节点 ${SYNC_DEST_ALIAS} 无法连接，请检查目标同步节点硬件是否损坏"
            MARK=1
        fi
    fi

    if [ -n "${BACKUP_SOURCE_ALIAS}" ]; then
        if ssh -o BatchMode=yes "${BACKUP_SOURCE_ALIAS}" "echo "">/dev/null 2>&1" >/dev/null 2>&1; then
            _success "源备份节点 ${BACKUP_SOURCE_ALIAS} 连接正常"
        else
            _error "源备份节点 ${BACKUP_SOURCE_ALIAS} 无法连接，请检查源备份节点硬件是否损坏"
            MARK=1
        fi
    fi

    if [ -n "${BACKUP_DEST_ALIAS}" ]; then
        if ssh -o BatchMode=yes "${BACKUP_DEST_ALIAS}" "echo "">/dev/null 2>&1" >/dev/null 2>&1; then
            _success "目标备份节点 ${BACKUP_DEST_ALIAS} 连接正常"
        else
            _error "目标备份节点 ${BACKUP_DEST_ALIAS} 无法连接，请检查目标备份节点硬件是否损坏"
            MARK=1
        fi
    fi

    [ "${MARK}" -eq 1 ] && _error "节点连通性存在问题，请先检查节点硬件是否损坏" && exit 1
    _success "节点连通性检测通过"

    _info "开始同步/备份节点路径检查和处理"
    # 备份一下，忘了为什么之前会用这个写法，当时应该是能正常工作的，但现在无法工作： sed -e "s/'/'\\\\''/g"
    if [ -n "${SYNC_SOURCE_PATH}" ] && [ -n "${SYNC_DEST_PATH}" ]; then
        SYNC_SOURCE_PATH=$(echo "${SYNC_SOURCE_PATH}" | sed -e "s/\/$//g")
        if ssh "${SYNC_SOURCE_ALIAS}" "[ -d \"${SYNC_SOURCE_PATH}\" ]"; then
            _info "修正后的源同步节点路径: ${SYNC_SOURCE_PATH}"
        else
            _error "源同步节点路径不存在，请检查: ${SYNC_SOURCE_ALIAS}"
            exit 1
        fi
        SYNC_DEST_PATH=$(echo "${SYNC_DEST_PATH}" | sed -e "s/\/$//g")
        ssh "${SYNC_DEST_ALIAS}" "[ ! -d \"${SYNC_DEST_PATH}\" ] && echo \"目标同步节点路径不存在，将创建路径: ${SYNC_DEST_PATH}\" && mkdir -p \"${SYNC_DEST_PATH}\""
        _info "修正后的目标同步节点路径: ${SYNC_DEST_PATH}"
    fi
    if [ -n "${BACKUP_SOURCE_PATH}" ] && [ -n "${BACKUP_DEST_PATH}" ]; then
        BACKUP_SOURCE_PATH=$(echo "${BACKUP_SOURCE_PATH}" | sed -e "s/\/$//g")
        if ssh "${BACKUP_SOURCE_ALIAS}" "[ -d \"${BACKUP_SOURCE_PATH}\" ]"; then
            _info "修正后的源备份节点路径: ${BACKUP_SOURCE_PATH}"
        else
            _error "源备份节点路径不存在，请检查，退出中"
            exit 1
        fi
        BACKUP_DEST_PATH=$(echo "${BACKUP_DEST_PATH}" | sed -e "s/\/$//g")
        ssh "${BACKUP_DEST_ALIAS}" "[ ! -d \"${BACKUP_DEST_PATH}\" ] && echo \"目标备份节点路径不存在，将创建路径: ${BACKUP_DEST_PATH}\" && mkdir -p \"${BACKUP_DEST_PATH}\""
        _info "修正后的目标备份节点路径: ${BACKUP_DEST_PATH}"
    fi
    _success "节点路径检查和处理完毕"
}

SearchCondition(){
    export LANG=en_US.UTF-8
    if [ -n "${SYNC_SOURCE_PATH}" ] && [ -n "${SYNC_DEST_PATH}" ] && [ -n "${SYNC_SOURCE_ALIAS}" ] && [ -n "${SYNC_DEST_ALIAS}" ] && [ -n "${SYNC_GROUP_INFO}" ] && [ -n "${SYNC_TYPE}" ] && [ -n "${SYNC_DATE_TYPE}" ] && [ -n "${ALLOW_DAYS}" ]; then
        if [ "${SYNC_TYPE}" = "dir" ]; then
            SyncLocateFolders
        elif [ "${SYNC_TYPE}" = "file" ]; then
            SyncLocateFiles
        fi
    fi
    
    if [ -n "${BACKUP_SOURCE_PATH}" ] && [ -n "${BACKUP_DEST_PATH}" ] && [ -n "${BACKUP_SOURCE_ALIAS}" ] && [ -n "${BACKUP_DEST_ALIAS}" ] && [ -n "${BACKUP_GROUP_INFO}" ] && [ -n "${BACKUP_TYPE}" ] && [ -n "${BACKUP_DATE_TYPE}" ] && [ -n "${ALLOW_DAYS}" ]; then
        if [ "${BACKUP_TYPE}" = "dir" ]; then
            BackupLocateFolders
        elif [ "${BACKUP_TYPE}" = "file" ]; then
            BackupLocateFiles
        fi
    fi

    if [ "${CONFIRM_CONTINUE}" -eq 1 ]; then
        OperationCondition
    else
        _info "如确认汇总的检测信息无误，请重新运行命令并添加选项 -y 或 --yes 以实现检测完成后自动执行工作"
        exit 0
    fi
}

OperationCondition(){
    if [ -n "${SYNC_SOURCE_PATH}" ] && [ -n "${SYNC_DEST_PATH}" ] && [ -n "${SYNC_SOURCE_ALIAS}" ] && [ -n "${SYNC_DEST_ALIAS}" ] && [ -n "${SYNC_GROUP_INFO}" ] && [ -n "${SYNC_TYPE}" ] && [ -n "${SYNC_DATE_TYPE}" ] && [ -n "${ALLOW_DAYS}" ]; then
        SyncOperation
    fi
    
    if [ -n "${BACKUP_SOURCE_PATH}" ] && [ -n "${BACKUP_DEST_PATH}" ] && [ -n "${BACKUP_SOURCE_ALIAS}" ] && [ -n "${BACKUP_DEST_ALIAS}" ] && [ -n "${BACKUP_GROUP_INFO}" ] && [ -n "${BACKUP_TYPE}" ] && [ -n "${BACKUP_DATE_TYPE}" ] && [ -n "${ALLOW_DAYS}" ]; then
        BackupOperation
    fi
}

SyncLocateFolders(){
    MARK_SYNC_SOURCE_FIND_PATH=0
    MARK_SYNC_DEST_FIND_PATH=0
    JUMP=0
    days=0
    for((LOOP=0;LOOP<"${ALLOW_DAYS}";LOOP++));do
        # 将文件夹允许的格式字符串替换成真实日期
        YEAR_VALUE=$(date -d ${days}days +%Y)
        MONTH_VALUE=$(date -d ${days}days +%m)
        DAY_VALUE=$(date -d ${days}days +%d)
        SYNC_DATE=$(echo "${SYNC_DATE_TYPE}"|sed -e "s/YYYY/${YEAR_VALUE}/g; s/MMMM/${MONTH_VALUE}/g; s/DDDD/${DAY_VALUE}/g")
        mapfile -t SYNC_SOURCE_FIND_FOLDER_NAME_1 < <(ssh "${SYNC_SOURCE_ALIAS}" "cd \"${SYNC_SOURCE_PATH}\";find . -maxdepth 1 -type d -name \"*${SYNC_DATE}*\"|grep -v \"\.$\"|sed 's/^\.\///g'")
        mapfile -t SYNC_DEST_FIND_FOLDER_NAME_1 < <(ssh "${SYNC_DEST_ALIAS}" "cd \"${SYNC_DEST_PATH}\";find . -maxdepth 1 -type d -name \"*${SYNC_DATE}*\"|grep -v \"\.$\"|sed 's/^\.\///g'")

        SYNC_SOURCE_FIND_PATH=()
        for i in "${SYNC_SOURCE_FIND_FOLDER_NAME_1[@]}"; do
            mapfile -t -O "${#SYNC_SOURCE_FIND_PATH[@]}" SYNC_SOURCE_FIND_PATH < <(ssh "${SYNC_SOURCE_ALIAS}" "cd \"${SYNC_SOURCE_PATH}\";find . -type d|grep \"\./$i\"|sed 's/^\.\///g'")
        done
        
        SYNC_DEST_FIND_PATH=()
        for i in "${SYNC_DEST_FIND_FOLDER_NAME_1[@]}"; do
            mapfile -t -O "${#SYNC_DEST_FIND_PATH[@]}" SYNC_DEST_FIND_PATH < <(ssh "${SYNC_DEST_ALIAS}" "cd \"${SYNC_DEST_PATH}\";find . -type d|grep \"\./$i\"|sed 's/^\.\///g'")
        done
        
        SYNC_SOURCE_FIND_FILE=()
        for i in "${SYNC_SOURCE_FIND_FOLDER_NAME_1[@]}"; do
            mapfile -t -O "${#SYNC_SOURCE_FIND_FILE[@]}" SYNC_SOURCE_FIND_FILE < <(ssh "${SYNC_SOURCE_ALIAS}" "cd \"${SYNC_SOURCE_PATH}\";find . -type f|grep \"\./$i\"|sed 's/^\.\///g'")
        done
        
        SYNC_DEST_FIND_FILE=()
        for i in "${SYNC_DEST_FIND_FOLDER_NAME_1[@]}"; do
            mapfile -t -O "${#SYNC_DEST_FIND_FILE[@]}" SYNC_DEST_FIND_FILE < <(ssh "${SYNC_DEST_ALIAS}" "cd \"${SYNC_DEST_PATH}\";find . -type f|grep \"\./$i\"|sed 's/^\.\///g'")
        done
        
        [ "${#SYNC_SOURCE_FIND_PATH[@]}" -gt 0 ] && MARK_SYNC_SOURCE_FIND_PATH=1 && JUMP=1
        [ "${#SYNC_DEST_FIND_PATH[@]}" -gt 0 ] && MARK_SYNC_DEST_FIND_PATH=1 && JUMP=1
        [ "${JUMP}" -eq 1 ] && break
        days=$(( days - 1 ))
    done
        
    if [ "${MARK_SYNC_SOURCE_FIND_PATH}" -eq 1 ] && [ "${MARK_SYNC_DEST_FIND_PATH}" -eq 0 ]; then
        _warning "目标同步节点${SYNC_DEST_ALIAS}不存在指定日期格式${SYNC_DATE}的文件夹"
        ErrorWarningSyncLog
        echo "目标同步节点${SYNC_DEST_ALIAS}不存在指定日期格式${SYNC_DATE}的文件夹" >> "${EXEC_ERROR_WARNING_SYNC_LOGFILE}"
    elif [ "${MARK_SYNC_SOURCE_FIND_PATH}" -eq 0 ] && [ "${MARK_SYNC_DEST_FIND_PATH}" -eq 1 ]; then
        _warning "源同步节点${SYNC_SOURCE_ALIAS}不存在指定日期格式${SYNC_DATE}的文件夹"
        ErrorWarningSyncLog
        echo "源同步节点${SYNC_SOURCE_ALIAS}不存在指定日期格式${SYNC_DATE}的文件夹" >> "${EXEC_ERROR_WARNING_SYNC_LOGFILE}"
    elif [ "${MARK_SYNC_SOURCE_FIND_PATH}" -eq 1 ] && [ "${MARK_SYNC_DEST_FIND_PATH}" -eq 1 ]; then
        _success "源与目标同步节点均找到指定日期格式${SYNC_DATE}的文件夹"
    elif [ "${MARK_SYNC_SOURCE_FIND_PATH}" -eq 0 ] && [ "${MARK_SYNC_DEST_FIND_PATH}" -eq 0 ]; then
        _error "源与目标同步节点均不存在指定日期格式${SYNC_DATE}的文件夹，退出中"
        ErrorWarningSyncLog
        echo "源与目标同步节点均不存在指定日期格式${SYNC_DATE}的文件夹，退出中" >> "${EXEC_ERROR_WARNING_SYNC_LOGFILE}"
        exit 1
    fi

    # 锁定目的节点需创建的文件夹的相对路径并转换成绝对路径存进数组
    LOCATE_DEST_NEED_FOLDER=()
    for i in "${SYNC_SOURCE_FIND_PATH[@]}"; do
        MARK=0
        for j in "${SYNC_DEST_FIND_PATH[@]}"; do
            if [ "$i" = "$j" ]; then
                MARK=1
                break
            fi
        done
        if [ "${MARK}" -eq 0 ]; then
            mapfile -t -O "${#LOCATE_DEST_NEED_FOLDER[@]}" LOCATE_DEST_NEED_FOLDER < <(echo "\"${SYNC_DEST_PATH}/$i\"")
        fi
    done
    
    # 锁定源节点需创建的文件夹的相对路径并转换成绝对路径存进数组
    LOCATE_SOURCE_NEED_FOLDER=()
    for i in "${SYNC_DEST_FIND_PATH[@]}"; do
        MARK=0
        for j in "${SYNC_SOURCE_FIND_PATH[@]}"; do
            if [ "$i" = "$j" ]; then
                MARK=1
                break
            fi
        done
        if [ "${MARK}" -eq 0 ]; then
            mapfile -t -O "${#LOCATE_SOURCE_NEED_FOLDER[@]}" LOCATE_SOURCE_NEED_FOLDER < <(echo "\"${SYNC_SOURCE_PATH}/$i\"")
        fi
    done
    
    # 锁定始到末需传送的文件的绝对路径
    CONFILICT_FILE=()
    for i in "${SYNC_SOURCE_FIND_FILE[@]}"; do
        MARK=0
        for j in "${SYNC_DEST_FIND_FILE[@]}"; do
            if [ "$i" = "$j" ]; then
                if [[ ! $(ssh "${SYNC_SOURCE_ALIAS}" "sha256sum \"${SYNC_SOURCE_PATH}/$i\"|awk '{print \$1}'") = $(ssh "${SYNC_DEST_ALIAS}" "sha256sum \"${SYNC_DEST_PATH}/$j\"|awk '{print \$1}'") ]]; then
                    _warning "源节点: \"${SYNC_SOURCE_PATH}/$i\"，目的节点:\"${SYNC_DEST_PATH}/$j\" 文件校验值不同，请检查日志，同步时将跳过此文件"
                    CONFILICT_FILE+=("源节点: \"${SYNC_SOURCE_PATH}/$i\"，目的节点: \"${SYNC_DEST_PATH}/$j\"")
                else
                    _success "源节点: \"${SYNC_SOURCE_PATH}/$i\"，目的节点: \"${SYNC_DEST_PATH}/$j\" 文件校验值一致"
                fi
                MARK=1
                break
            fi
        done
        if [ "${MARK}" -eq 0 ]; then
            LOCATE_SOURCE_OUTGOING_FILE+=("\"${SYNC_SOURCE_PATH}/$i\"")
            LOCATE_DEST_INCOMING_FILE+=("\"${SYNC_DEST_PATH}/$i\"")
        fi
    done
    
    # 将同名不同内容的冲突文件列表写入日志
    ErrorWarningSyncLog
    echo "始末节点中的同名文件存在冲突，请检查" >> "${EXEC_ERROR_WARNING_SYNC_LOGFILE}"
    for i in "${CONFILICT_FILE[@]}"; do
        echo "$i" >> "${EXEC_ERROR_WARNING_SYNC_LOGFILE}"
    done

    # 锁定末到始需传送的文件的绝对路径
    for i in "${SYNC_DEST_FIND_FILE[@]}"; do
        MARK=0
        for j in "${SYNC_SOURCE_FIND_FILE[@]}"; do
            if [ "$i" = "$j" ]; then
                MARK=1
                break
            fi
        done
        if [ "${MARK}" -eq 0 ]; then
            LOCATE_DEST_OUTGOING_FILE+=("\"${SYNC_DEST_PATH}/$i\"")
            LOCATE_SOURCE_INCOMING_FILE+=("\"${SYNC_SOURCE_PATH}/$i\"")
        fi
    done
    
    # 信息汇总
    _success "已锁定需传送信息，以下将显示各类已锁定信息，请检查"
    _warning "源节点 —— 待创建文件夹绝对路径列表:"
    for i in "${LOCATE_SOURCE_NEED_FOLDER[@]}"; do
        echo "$i"
    done
    echo ""
    _warning "目的节点 —— 待创建文件夹绝对路径列表:"
    for i in "${LOCATE_DEST_NEED_FOLDER[@]}"; do
        echo "$i"
    done
    echo ""
    _warning "传输方向: 源节点 -> 目的节点 —— 源节点待传出-目的节点待传入文件绝对路径列表:"
    for i in "${!LOCATE_SOURCE_OUTGOING_FILE[@]}"; do
        echo "${LOCATE_SOURCE_OUTGOING_FILE[$i]} -> ${LOCATE_DEST_INCOMING_FILE[$i]}"
    done
    echo ""
    _warning "传输方向: 目的节点 -> 源节点 —— 目的节点待传出-源节点待传入文件绝对路径列表:"
    for i in "${!LOCATE_DEST_OUTGOING_FILE[@]}"; do
        echo "${LOCATE_DEST_OUTGOING_FILE[$i]} -> ${LOCATE_SOURCE_INCOMING_FILE[$i]}"
    done
    echo ""
    _warning "基于指定路径的始末节点存在冲突的文件绝对路径列表:"
    for i in "${CONFILICT_FILE[@]}"; do
        echo "$i"
    done
    echo ""
}

SyncLocateFiles(){
    MARK_SYNC_SOURCE_FIND_FILE_1=0
    MARK_SYNC_DEST_FIND_FILE_1=0
    JUMP=0
    days=0
    for ((LOOP=0;LOOP<"${ALLOW_DAYS}";LOOP++));do
        # 将文件夹允许的格式字符串替换成真实日期
        YEAR_VALUE=$(date -d ${days}days +%Y)
        MONTH_VALUE=$(date -d ${days}days +%m)
        DAY_VALUE=$(date -d ${days}days +%d)
        SYNC_DATE=$(echo "${SYNC_DATE_TYPE}"|sed -e "s/YYYY/${YEAR_VALUE}/g; s/MMMM/${MONTH_VALUE}/g; s/DDDD/${DAY_VALUE}/g")
        mapfile -t SYNC_SOURCE_FIND_FILE_1 < <(ssh "${SYNC_SOURCE_ALIAS}" "cd \"${SYNC_SOURCE_PATH}\";find . -maxdepth 1 -type f -name \"*${SYNC_DATE}*\"|sed 's/^\.\///g'")
        mapfile -t SYNC_DEST_FIND_FILE_1 < <(ssh "${SYNC_DEST_ALIAS}" "cd \"${SYNC_DEST_PATH}\";find . -maxdepth 1 -type f -name \"*${SYNC_DATE}*\"|sed 's/^\.\///g'")
        mapfile -t SYNC_SOURCE_FIND_FILE_PATH < <(ssh "${SYNC_SOURCE_ALIAS}" "find \"${SYNC_SOURCE_PATH}\" -maxdepth 1 -type f -name \"*${SYNC_DATE}*\"|sed 's/^\.\///g'")
        mapfile -t SYNC_DEST_FIND_FILE_PATH < <(ssh "${SYNC_DEST_ALIAS}" "find \"${SYNC_DEST_PATH}\" -maxdepth 1 -type f -name \"*${SYNC_DATE}*\"|sed 's/^\.\///g'")

        
        [ "${#SYNC_SOURCE_FIND_FILE_1[@]}" -gt 0 ] && MARK_SYNC_SOURCE_FIND_FILE_1=1 && JUMP=1
        [ "${#SYNC_DEST_FIND_FILE_1[@]}" -gt 0 ] && MARK_SYNC_DEST_FIND_FILE_1=1 && JUMP=1
        [ "${JUMP}" -eq 1 ] && break
        days=$(( days - 1 ))
    done
        
    if [ "${MARK_SYNC_SOURCE_FIND_FILE_1}" -eq 1 ] && [ "${MARK_SYNC_DEST_FIND_FILE_1}" -eq 0 ]; then
        _warning "目标同步节点${SYNC_DEST_ALIAS}不存在指定日期格式${SYNC_DATE}的文件"
        ErrorWarningSyncLog
        echo "目标同步节点${SYNC_DEST_ALIAS}不存在指定日期格式${SYNC_DATE}的文件" >> "${EXEC_ERROR_WARNING_SYNC_LOGFILE}"
    elif [ "${MARK_SYNC_SOURCE_FIND_FILE_1}" -eq 0 ] && [ "${MARK_SYNC_DEST_FIND_FILE_1}" -eq 1 ]; then
        _warning "源同步节点${SYNC_SOURCE_ALIAS}不存在指定日期格式${SYNC_DATE}的文件"
        ErrorWarningSyncLog
        echo "源同步节点${SYNC_SOURCE_ALIAS}不存在指定日期格式${SYNC_DATE}的文件" >> "${EXEC_ERROR_WARNING_SYNC_LOGFILE}"
    elif [ "${MARK_SYNC_SOURCE_FIND_FILE_1}" -eq 1 ] && [ "${MARK_SYNC_DEST_FIND_FILE_1}" -eq 1 ]; then
        _success "源与目标同步节点均找到指定日期格式${SYNC_DATE}的文件"
    elif [ "${MARK_SYNC_SOURCE_FIND_FILE_1}" -eq 0 ] && [ "${MARK_SYNC_DEST_FIND_FILE_1}" -eq 0 ]; then
        _error "源与目标同步节点均不存在指定日期格式${SYNC_DATE}的文件，退出中"
        ErrorWarningSyncLog
        echo "源与目标同步节点均不存在指定日期格式${SYNC_DATE}的文件，退出中" >> "${EXEC_ERROR_WARNING_SYNC_LOGFILE}"
        exit 1
    fi

    # 锁定始到末需传送的文件的绝对路径
    CONFILICT_FILE=()
    for i in "${SYNC_SOURCE_FIND_FILE_1[@]}"; do
        MARK=0
        for j in "${SYNC_DEST_FIND_FILE_1[@]}"; do
            if [ "$i" = "$j" ]; then
                if [[ ! $(ssh "${SYNC_SOURCE_ALIAS}" "sha256sum \"${SYNC_SOURCE_PATH}/$i\"|awk '{print \$1}'") = $(ssh "${SYNC_DEST_ALIAS}" "sha256sum \"${SYNC_DEST_PATH}/$j\"|awk '{print \$1}'") ]]; then
                    _warning "源节点: \"${SYNC_SOURCE_PATH}/$i\"，目的节点:\"${SYNC_DEST_PATH}/$j\" 文件校验值不同，请检查日志，同步时将跳过此文件"
                    CONFILICT_FILE+=("源节点: \"${SYNC_SOURCE_PATH}/$i\"，目的节点: \"${SYNC_DEST_PATH}/$j\"")
                else
                    _success "源节点: \"${SYNC_SOURCE_PATH}/$i\"，目的节点: \"${SYNC_DEST_PATH}/$j\" 文件校验值一致"
                fi
                MARK=1
                break
            fi
        done
        if [ "${MARK}" -eq 0 ]; then
            LOCATE_SOURCE_OUTGOING_FILE+=("\"${SYNC_SOURCE_PATH}/$i\"")
            LOCATE_DEST_INCOMING_FILE+=("\"${SYNC_DEST_PATH}/$i\"")
        fi
    done
    
    # 将同名不同内容的冲突文件列表写入日志
    ErrorWarningSyncLog
    echo "始末节点中的同名文件存在冲突，请检查" >> "${EXEC_ERROR_WARNING_SYNC_LOGFILE}"
    for i in "${CONFILICT_FILE[@]}"; do
        echo "$i" >> "${EXEC_ERROR_WARNING_SYNC_LOGFILE}"
    done

    # 锁定末到始需传送的文件的绝对路径
    for i in "${SYNC_DEST_FIND_FILE_1[@]}"; do
        MARK=0
        for j in "${SYNC_SOURCE_FIND_FILE_1[@]}"; do
            if [ "$i" = "$j" ]; then
                MARK=1
                break
            fi
        done
        if [ "${MARK}" -eq 0 ]; then
            LOCATE_DEST_OUTGOING_FILE+=("\"${SYNC_DEST_PATH}/$i\"")
            LOCATE_SOURCE_INCOMING_FILE+=("\"${SYNC_SOURCE_PATH}/$i\"")
        fi
    done
    
    # 信息汇总
    _success "已锁定需传送信息，以下将显示各类已锁定信息，请检查"
    _warning "传输方向: 源节点 -> 目的节点 —— 源节点待传出-目的节点待传入文件绝对路径列表:"
    for i in "${!LOCATE_SOURCE_OUTGOING_FILE[@]}"; do
        echo "${LOCATE_SOURCE_OUTGOING_FILE[$i]} -> ${LOCATE_DEST_INCOMING_FILE[$i]}"
    done
    echo ""
    _warning "传输方向: 目的节点 -> 源节点 —— 目的节点待传出-源节点待传入文件绝对路径列表:"
    for i in "${!LOCATE_DEST_OUTGOING_FILE[@]}"; do
        echo "${LOCATE_DEST_OUTGOING_FILE[$i]} -> ${LOCATE_SOURCE_INCOMING_FILE[$i]}"
    done
    echo ""
    _warning "基于指定路径的始末节点存在冲突的文件绝对路径列表:"
    for i in "${CONFILICT_FILE[@]}"; do
        echo "$i"
    done
    echo ""
}

BackupLocateFolders(){
    MARK_BACKUP_SOURCE_FIND_FOLDER_FULL_PATH=0
    JUMP=0
    days=0
    for((LOOP=0;LOOP<"${ALLOW_DAYS}";LOOP++));do
        # 将文件夹允许的格式字符串替换成真实日期
        YEAR_VALUE=$(date -d ${days}days +%Y)
        MONTH_VALUE=$(date -d ${days}days +%m)
        DAY_VALUE=$(date -d ${days}days +%d)
        BACKUP_DATE=$(echo "${BACKUP_DATE_TYPE}"|sed -e "s/YYYY/${YEAR_VALUE}/g; s/MMMM/${MONTH_VALUE}/g; s/DDDD/${DAY_VALUE}/g")
        mapfile -t BACKUP_SOURCE_FIND_FOLDER_FULL_PATH < <(ssh "${BACKUP_SOURCE_ALIAS}" "find \"${BACKUP_SOURCE_PATH}\" -maxdepth 1 -type d -name \"*${BACKUP_DATE}*\"|grep -v \"\.$\"")
        
        [ "${#BACKUP_SOURCE_FIND_FOLDER_FULL_PATH[@]}" -gt 0 ] && MARK_BACKUP_SOURCE_FIND_FOLDER_FULL_PATH=1 && JUMP=1
        [ "${JUMP}" -eq 1 ] && break
        days=$(( days - 1 ))
    done

    if [ "${MARK_BACKUP_SOURCE_FIND_FOLDER_FULL_PATH}" -eq 1 ]; then
        _success "源备份节点存在指定日期格式${BACKUP_DATE}的文件夹"
    elif [ "${MARK_BACKUP_SOURCE_FIND_FOLDER_FULL_PATH}" -eq 0 ]; then
        _error "源备份节点不存在指定日期格式${BACKUP_DATE}的文件夹，退出中"
        ErrorWarningBackupLog
        echo "源备份节点不存在指定日期格式${BACKUP_DATE}的文件夹，退出中" >> "${EXEC_ERROR_WARNING_BACKUP_LOGFILE}"
        exit 1
    fi
    
    # 信息汇总
    _success "已锁定需传送信息，以下将显示已锁定信息，请检查"
    _warning "源节点待备份文件夹绝对路径列表:"
    for i in "${!BACKUP_SOURCE_FIND_FOLDER_FULL_PATH[@]}"; do
        echo "${BACKUP_SOURCE_FIND_FOLDER_FULL_PATH[$i]}"
    done
    echo ""
}

BackupLocateFiles(){
    MARK_BACKUP_SOURCE_FIND_FILE_1=0
    JUMP=0
    days=0
    for ((LOOP=0;LOOP<"${ALLOW_DAYS}";LOOP++));do
        # 将文件夹允许的格式字符串替换成真实日期
        YEAR_VALUE=$(date -d ${days}days +%Y)
        MONTH_VALUE=$(date -d ${days}days +%m)
        DAY_VALUE=$(date -d ${days}days +%d)
        BACKUP_DATE=$(echo "${BACKUP_DATE_TYPE}"|sed -e "s/YYYY/${YEAR_VALUE}/g; s/MMMM/${MONTH_VALUE}/g; s/DDDD/${DAY_VALUE}/g")
        mapfile -t BACKUP_SOURCE_FIND_FILE_1 < <(ssh "${BACKUP_SOURCE_ALIAS}" "find \"${BACKUP_SOURCE_PATH}\" -maxdepth 1 -type f -name \"*${BACKUP_DATE}*\"")

        [ "${#BACKUP_SOURCE_FIND_FILE_1[@]}" -gt 0 ] && MARK_BACKUP_SOURCE_FIND_FILE_1=1 && JUMP=1
        [ "${JUMP}" -eq 1 ] && break
        days=$(( days - 1 ))
    done
        
    if [ "${MARK_BACKUP_SOURCE_FIND_FILE_1}" -eq 1 ]; then
        _success "源备份节点已找到指定日期格式${BACKUP_DATE}的文件"
    elif [ "${MARK_BACKUP_SOURCE_FIND_FILE_1}" -eq 0 ]; then
        _error "源节点不存在指定日期格式${BACKUP_DATE}的文件，退出中"
        ErrorWarningBackupLog
        echo "源与目标同步节点均不存在指定日期格式${BACKUP_DATE}的文件，退出中" >> "${EXEC_ERROR_WARNING_BACKUP_LOGFILE}"
        exit 1
    fi

    # 信息汇总
    _success "已锁定需传送信息，以下将显示已锁定信息，请检查"
    _warning "源节点待备份文件绝对路径列表:"
    for i in "${!BACKUP_SOURCE_FIND_FILE_1[@]}"; do
        echo "${BACKUP_SOURCE_FIND_FILE_1[$i]}"
    done
    echo ""
}

SyncOperation(){
    if [ "${SYNC_TYPE}" = "dir" ]; then
        # 源节点需创建的文件夹
        if [ "${#LOCATE_SOURCE_NEED_FOLDER[@]}" -gt 0 ]; then
            _info "开始创建源同步节点所需文件夹"
            # ssh "${SYNC_SOURCE_ALIAS}" "for i in \"${LOCATE_SOURCE_NEED_FOLDER[@]}\";do echo \"$i\";mkdir -p \"$i\";done"  # 这行可能会调用 CONFILICT_FILE 数组导致出错
            for i in "${LOCATE_SOURCE_NEED_FOLDER[@]}";do
                echo "正在创建文件夹: $i"
                ssh "${SYNC_SOURCE_ALIAS}" "mkdir -p \"$i\""
            done
            _info "源同步节点所需文件夹已创建成功"
        fi
        
        # 目的节点需创建的文件夹
        if [ "${#LOCATE_DEST_NEED_FOLDER[@]}" -gt 0 ]; then
            _info "开始创建目的同步节点所需文件夹"
            # ssh "${SYNC_DEST_ALIAS}" "for i in \"${LOCATE_DEST_NEED_FOLDER[@]}\";do echo \"$i\";mkdir -p \"$i\";done"
            for i in "${LOCATE_DEST_NEED_FOLDER[@]}";do
                echo "正在创建文件夹: $i"
                ssh "${SYNC_DEST_ALIAS}" "mkdir -p \"$i\""
            done
            _info "目的同步节点所需文件夹已创建成功"
        fi
        
        # 传输方向: 源节点 -> 目的节点 —— 源节点待传出文件
        if [ "${#LOCATE_SOURCE_OUTGOING_FILE[@]}" -gt 0 ]; then
            _info "源节点 -> 目的节点 开始传输"
            SOURCE_TO_DEST_FAILED=()
            for i in "${!LOCATE_SOURCE_OUTGOING_FILE[@]}"; do
                if ! scp -r "${SYNC_SOURCE_ALIAS}":"${LOCATE_SOURCE_OUTGOING_FILE[$i]}" "${SYNC_DEST_ALIAS}":"${LOCATE_DEST_INCOMING_FILE[$i]}"; then
                    SOURCE_TO_DEST_FAILED+=("${LOCATE_SOURCE_OUTGOING_FILE[$i]} -> ${LOCATE_DEST_INCOMING_FILE[$i]}")
                fi
            done
            if [ "${#SOURCE_TO_DEST_FAILED[@]}" -gt 0 ]; then
                _warning "部分文件传输失败，请查看报错日志"
                ErrorWarningSyncLog
                echo "传输方向: 源节点 -> 目的节点 存在部分文件同步失败，请检查" >> "${EXEC_ERROR_WARNING_SYNC_LOGFILE}"
                for i in "${SOURCE_TO_DEST_FAILED[@]}"; do
                    echo "$i" >> "${EXEC_ERROR_WARNING_SYNC_LOGFILE}"
                done
            fi
        fi
        
        # 传输方向: 目的节点 -> 源节点 —— 目的节点待传出文件
        if [ "${#LOCATE_DEST_OUTGOING_FILE[@]}" -gt 0 ]; then
            _info "目的节点 -> 源节点 开始传输"
            DEST_TO_SOURCE_FAILED=()
            for i in "${!LOCATE_DEST_OUTGOING_FILE[@]}"; do
                if ! scp -r "${SYNC_DEST_ALIAS}":"${LOCATE_DEST_OUTGOING_FILE[$i]}" "${SYNC_SOURCE_ALIAS}":"${LOCATE_SOURCE_INCOMING_FILE[$i]}"; then
                    DEST_TO_SOURCE_FAILED+=("${LOCATE_DEST_OUTGOING_FILE[$i]} -> ${LOCATE_SOURCE_INCOMING_FILE[$i]}")
                fi
            done
            if [ "${#DEST_TO_SOURCE_FAILED[@]}" -gt 0 ]; then
                _warning "部分文件传输失败，请查看报错日志"
                ErrorWarningSyncLog
                echo "传输方向: 目的节点 -> 源节点 存在部分文件同步失败，请检查" >> "${EXEC_ERROR_WARNING_SYNC_LOGFILE}"
                for i in "${DEST_TO_SOURCE_FAILED[@]}"; do
                    echo "$i" >> "${EXEC_ERROR_WARNING_SYNC_LOGFILE}"
                done
            fi
        fi
        
    elif [ "${SYNC_TYPE}" = "file" ]; then
        # 传输方向: 源节点 -> 目的节点 —— 源节点待传出文件
        if [ "${#LOCATE_SOURCE_OUTGOING_FILE[@]}" -gt 0 ]; then
            _info "源节点 -> 目的节点 开始传输"
            SOURCE_TO_DEST_FAILED=()
            for i in "${!LOCATE_SOURCE_OUTGOING_FILE[@]}"; do
                if ! scp -r "${SYNC_SOURCE_ALIAS}":"${LOCATE_SOURCE_OUTGOING_FILE[$i]}" "${SYNC_DEST_ALIAS}":"${LOCATE_DEST_INCOMING_FILE[$i]}"; then
                    SOURCE_TO_DEST_FAILED+=("${LOCATE_SOURCE_OUTGOING_FILE[$i]} -> ${LOCATE_DEST_INCOMING_FILE[$i]}")
                fi
            done
            if [ "${#SOURCE_TO_DEST_FAILED[@]}" -gt 0 ]; then
                _warning "部分文件传输失败，请查看报错日志"
                ErrorWarningSyncLog
                echo "传输方向: 源节点 -> 目的节点 存在部分文件同步失败，请检查" >> "${EXEC_ERROR_WARNING_SYNC_LOGFILE}"
                for i in "${SOURCE_TO_DEST_FAILED[@]}"; do
                    echo "$i" >> "${EXEC_ERROR_WARNING_SYNC_LOGFILE}"
                done
            fi
        fi
        
        # 传输方向: 目的节点 -> 源节点 —— 目的节点待传出文件
        if [ "${#LOCATE_DEST_OUTGOING_FILE[@]}" -gt 0 ]; then
            _info "目的节点 -> 源节点 开始传输"
            DEST_TO_SOURCE_FAILED=()
            for i in "${!LOCATE_DEST_OUTGOING_FILE[@]}"; do
                if ! scp -r "${SYNC_DEST_ALIAS}":"${LOCATE_DEST_OUTGOING_FILE[$i]}" "${SYNC_SOURCE_ALIAS}":"${LOCATE_SOURCE_INCOMING_FILE[$i]}"; then
                    DEST_TO_SOURCE_FAILED+=("${LOCATE_DEST_OUTGOING_FILE[$i]} -> ${LOCATE_SOURCE_INCOMING_FILE[$i]}")
                fi
            done
            if [ "${#DEST_TO_SOURCE_FAILED[@]}" -gt 0 ]; then
                _warning "部分文件传输失败，请查看报错日志"
                ErrorWarningSyncLog
                echo "传输方向: 目的节点 -> 源节点 存在部分文件同步失败，请检查" >> "${EXEC_ERROR_WARNING_SYNC_LOGFILE}"
                for i in "${DEST_TO_SOURCE_FAILED[@]}"; do
                    echo "$i" >> "${EXEC_ERROR_WARNING_SYNC_LOGFILE}"
                done
            fi
        fi
    fi
}

BackupOperation(){
    if [ "${BACKUP_TYPE}" = "dir" ]; then
        _info "源节点文件夹备份开始"
        SOURCE_TO_DEST_FAILED=()
        for i in "${!BACKUP_SOURCE_FIND_FOLDER_FULL_PATH[@]}"; do
            if ! scp -r "${BACKUP_SOURCE_ALIAS}":"${BACKUP_SOURCE_FIND_FOLDER_FULL_PATH[$i]}" "${BACKUP_DEST_ALIAS}":"${BACKUP_DEST_PATH}"; then
                SOURCE_TO_DEST_FAILED+=("${BACKUP_SOURCE_FIND_FOLDER_FULL_PATH[$i]} -> ${BACKUP_DEST_PATH}")
            fi
        done
        if [ "${#SOURCE_TO_DEST_FAILED[@]}" -gt 0 ]; then
            _warning "部分文件夹传输失败，请查看报错日志"
            ErrorWarningBackupLog
            echo "源节点部分文件夹备份失败，请检查" >> "${EXEC_ERROR_WARNING_BACKUP_LOGFILE}"
            for i in "${SOURCE_TO_DEST_FAILED[@]}"; do
                echo "$i" >> "${EXEC_ERROR_WARNING_BACKUP_LOGFILE}"
            done
        fi
    elif [ "${BACKUP_TYPE}" = "file" ]; then
        _info "源节点文件备份开始"
        SOURCE_TO_DEST_FAILED=()
        for i in "${!BACKUP_SOURCE_FIND_FILE_1[@]}"; do
            if ! scp -r "${BACKUP_SOURCE_ALIAS}":"${BACKUP_SOURCE_FIND_FILE_1[$i]}" "${BACKUP_DEST_ALIAS}":"${BACKUP_DEST_PATH}"; then
                SOURCE_TO_DEST_FAILED+=("${BACKUP_SOURCE_FIND_FILE_1[$i]} -> ${BACKUP_DEST_PATH}")
            fi
        done
        if [ "${#SOURCE_TO_DEST_FAILED[@]}" -gt 0 ]; then
            _warning "部分文件传输失败，请查看报错日志"
            ErrorWarningBackupLog
            echo "源节点部分文件备份失败，请检查" >> "${EXEC_ERROR_WARNING_BACKUP_LOGFILE}"
            for i in "${SOURCE_TO_DEST_FAILED[@]}"; do
                echo "$i" >> "${EXEC_ERROR_WARNING_BACKUP_LOGFILE}"
            done
        fi
    fi
}

ErrorWarningSyncLog(){
    [ ! -d /var/log/${SH_NAME}/log ] && _warning "未创建日志文件夹，开始创建" && mkdir -p /var/log/${SH_NAME}/{exec,log}
    cat >> /var/log/${SH_NAME}/log/exec-error-warning-sync-"$(date +"%Y-%m-%d")".log <<EOF

------------------------------------------------
时间：$(date +"%H:%M:%S")
执行情况：
EOF
}

ErrorWarningBackupLog(){
    [ ! -d /var/log/${SH_NAME}/log ] && _warning "未创建日志文件夹，开始创建" && mkdir -p /var/log/${SH_NAME}/{exec,log}
    cat >> /var/log/${SH_NAME}/log/exec-error-warning-backup-"$(date +"%Y-%m-%d")".log <<EOF

------------------------------------------------
时间：$(date +"%H:%M:%S")
执行情况：
EOF
}

CommonLog(){
    [ ! -d /var/log/${SH_NAME}/log ] && _warning "未创建日志文件夹，开始创建" && mkdir -p /var/log/${SH_NAME}/{exec,log}
    cat >> /var/log/${SH_NAME}/log/exec-"$(date +"%Y-%m-%d")".log <<EOF

------------------------------------------------
时间：$(date +"%H:%M:%S")
执行情况：
EOF
}

DeleteExpiredLog(){
    _info "开始清理陈旧日志文件"
    logfile=$(find /var/log/${SH_NAME}/log -name "exec*.log" -mtime +10)
    for a in $logfile
    do
        rm -f "${a}"
    done
    _success "日志清理完成"
}

Deploy(){
    _info "开始部署..."
    ssh "${DEPLOY_NODE_ALIAS}" "mkdir -p /var/log/${SH_NAME}/{exec,log}"
    scp "$(pwd)"/"${SH_NAME}".sh "${DEPLOY_NODE_ALIAS}":/var/log/${SH_NAME}/exec/${SH_NAME}
    ssh "${DEPLOY_NODE_ALIAS}" "chmod +x /var/log/${SH_NAME}/exec/${SH_NAME}"
    ssh "${DEPLOY_NODE_ALIAS}" "sed -i \"/${SH_NAME}/d\" /etc/bashrc"
    ssh "${DEPLOY_NODE_ALIAS}" "echo \"alias msb='/usr/bin/bash <(cat /var/log/${SH_NAME}/exec/${SH_NAME})'\" >> /etc/bashrc"
    ssh "${DEPLOY_NODE_ALIAS}" "sed -i \"/${SH_NAME})\ -e/d\" /etc/crontab"
    ssh "${DEPLOY_NODE_ALIAS}" "echo \"${LOG_CRON} root /usr/bin/bash -c 'bash <(cat /var/log/${SH_NAME}/exec/${SH_NAME}) -e'\" >> /etc/crontab"

    # 集合定时任务，里面将存放各种同步或备份的执行功能
    ssh "${DEPLOY_NODE_ALIAS}" "[ ! -f /var/log/${SH_NAME}/exec/run-\"${OPERATION_CRON_NAME}\" ] && echo -e \"#!/bin/bash\n\" >/var/log/${SH_NAME}/exec/run-\"${OPERATION_CRON_NAME}\" && chmod +x /var/log/${SH_NAME}/exec/run-\"${OPERATION_CRON_NAME}\""
    ssh "${DEPLOY_NODE_ALIAS}" "echo \"${OPERATION_CRON} root /usr/bin/bash -c 'bash <(cat /var/log/${SH_NAME}/exec/run-${OPERATION_CRON_NAME})'\" >> /etc/crontab"
    # 向集合定时任务添加具体执行功能
    if [ -n "${SYNC_OPERATION_NAME}" ]; then
        ssh "${DEPLOY_NODE_ALIAS}" "echo \"bash <(cat /var/log/${SH_NAME}/exec/${SH_NAME}) --days \"\"${ALLOW_DAYS}\"\" --sync_source_path \"\"${SYNC_SOURCE_PATH}\"\" --sync_dest_path \"\"${SYNC_DEST_PATH}\"\" --sync_source_alias \"\"${SYNC_SOURCE_ALIAS}\"\" --sync_dest_alias \"\"${SYNC_DEST_ALIAS}\"\" --sync_group \"\"${SYNC_GROUP_INFO}\"\" --sync_type \"\"${SYNC_TYPE}\"\" --sync_date_type \"\"${SYNC_DATE_TYPE}\"\" --sync_operation_name \"\"${SYNC_OPERATION_NAME}\"\" -y\" >> /var/log/${SH_NAME}/exec/run-\"${OPERATION_CRON_NAME}\""
    fi
    if [ -n "${BACKUP_OPERATION_NAME}" ]; then
        ssh "${DEPLOY_NODE_ALIAS}" "echo \"bash <(cat /var/log/${SH_NAME}/exec/${SH_NAME}) --days \"\"${ALLOW_DAYS}\"\" --backup_source_path \"\"${BACKUP_SOURCE_PATH}\"\" --backup_dest_path \"\"${BACKUP_DEST_PATH}\"\" --backup_source_alias \"\"${BACKUP_SOURCE_ALIAS}\"\" --backup_dest_alias \"\"${BACKUP_DEST_ALIAS}\"\" --backup_group \"\"${BACKUP_GROUP_INFO}\"\" --backup_type \"\"${BACKUP_TYPE}\"\" --backup_date_type \"\"${BACKUP_DATE_TYPE}\"\" --backup_operation_name \"\"${BACKUP_OPERATION_NAME}\"\" -y\" >> /var/log/${SH_NAME}/exec/run-\"${OPERATION_CRON_NAME}\""
    fi
    _success "部署成功"
    exit 0
}

Remove(){
    _info "开始卸载同步工具本身和生成的日志，不会对同步或备份文件产生任何影响"
    rm -rf /${SH_NAME}.sh /var/log/${SH_NAME}
    sed -i "/${SH_NAME}/d" /etc/bashrc
    sed -i "/${SH_NAME})\ -r/d" /etc/crontab
    _success "卸载成功"
}

Help(){
    echo "
    本脚本依赖 SCP 传输
    所有内置选项及传参格式如下，有参选项必须加具体参数，否则脚本会自动检测并阻断运行：
    -P | --source_path <本地发送方的绝对路径>           有参选项，脚本会从此路径下查找符合条件的搜索结果，
                                                        找不到的话会停止工作防止通过 SCP 往远程节点乱拉屎

    -p | --dest_path <远程节点接收方的绝对路径>         有参选项，脚本会检查远程节点是否存在此目录，没有的话会自动创建，
                                                        如果用户错误输入非绝对路径，会根据目的节点默认登录路径自动修复为绝对路径

    -u | --user <远程节点的登录用户名>           有参选项，脚本无法检测是否正确，但如果填写错误的话，
                                                        在已经配置了密钥公钥的两台服务器之间使用 scp 会提示要输入密码

    -d | --address <远程节点的 IP 地址>         有参选项，脚本无法检测是否正确，但如果填写错误的话，
                                                        脚本会根据超时时长到时间自动退出防止死在当前不可继续的任务上

    -L | --deploy                                       不可独立无参选项，目的是一键部署，但必须与所有有参选项同时搭配才能完成部署
    -B | --backup_cron                                  有参选项，方便测试和生产环境定时备份的一键设置，不设置此选项则默认生产环境参数
    -l | --log_cron                                     有参选项，方便测试和生产环境定时删日志的一键设置，不设置此选项则默认生产环境参数
    -r | --delete_expired_log <删除脚本产生的超时陈旧日志>           可独立无参选项，指定后会立即清理超过预定时间的陈旧日志
    -R | --remove                                       可独立无参选项，目的是一键移除脚本对系统所做的所有修改。
    -h | --help                                         打印此帮助信息并退出

    部署和立即同步只有一个 -L 区别，其他完全相同，部署的时候不会进行同步。

    使用示例：
    1.1 测试部署(需同时指定本地备份所在路径 + 远程节点已配置过密钥对登录的用户名 + 节点 IP + 节点中备份的目标路径 + 超时阈值)
    bash <(cat ${SH_NAME}.sh) -P /root/test108 -p /root/test119 -u root -d 1.2.3.4 -t 10s -B \"*/2 * * * *\" -l \"* * */10 * *\" -L

    1.2 生产部署(需同时指定本地备份所在路径 + 远程节点已配置过密钥对登录的用户名 + 节点 IP + 节点中备份的目标路径 + 超时阈值)
    bash <(cat ${SH_NAME}.sh) -P /root/test108 -p /root/test119 -u root -d 1.2.3.4 -t 10s -B \"30 23 * * *\" -l \"* * */10 * *\" -L

    2. 立即同步(需同时指定本地备份所在路径 + 远程节点已配置过密钥对登录的用户名 + 节点 IP + 节点中备份的目标路径 + 超时阈值)
    bash <(cat ${SH_NAME}.sh) -P /root/test108 -p /root/test119 -u root -d 1.2.3.4 -t 10s

    3. 删除陈旧日志(默认10天)
    bash <(cat ${SH_NAME}.sh) -r

    4. 卸载
    bash <(cat ${SH_NAME}.sh) -R
"
}

Main(){
    EnvCheck
    # 卸载检测和执行
    if [ -n "${REMOVE_NODE_ALIAS}" ]; then
        CheckRemoveOption
        if [ "${CONFIRM_CONTINUE}" -eq 1 ]; then
            Remove
        else
            _info "如确认汇总的检测信息无误，请重新运行命令并添加选项 -y 或 --yes 以实现检测完成后自动执行工作"
        fi
        exit 0
    fi
    CheckExecOption
    CheckDeployOption  # 这里有一个检测退出和确认执行完成后退出的功能，只要进入此模块后成功进入部署分支，无论成功与否都不会走完此模块后往下执行
    CheckTransmissionStatus
    SearchCondition
}

[ ! -d /var/log/${SH_NAME} ] && _warning "未创建日志文件夹，开始创建" && mkdir -p /var/log/${SH_NAME}/{exec,log}
Main | tee -a "${EXEC_COMMON_LOGFILE}"
