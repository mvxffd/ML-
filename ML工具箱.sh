
#!/system/bin/sh
# ==================================================
#  简约风格（后续内容完全不变）
# ==================================================

# ---------- 版本信息 ----------
VERSION="1.2"
SCRIPT_NAME="ML"
GITHUB_RAW_URL="https://github.com/mvxffd/ML-/raw/refs/heads/main/ML%E5%B7%A5%E5%85%B7%E7%AE%B1.sh"
GH_PROXY="https://gh.kejilion.pro/"

# ========== 卡密配置 ==========
# 这个卡密没什么用
LICENSE_KEY="MLHHYQ"
LICENSE_FILE="/data/local/tmp/MLHHYQ.log"

# ---------- 颜色 ----------
reset='\e[0m'
bold='\e[1m'
fg_white='\e[97m'
fg_gray='\e[38;5;245m'
fg_darkgray='\e[38;5;240m'
accent_blue='\e[38;5;67m'
accent_green='\e[38;5;72m'
accent_orange='\e[38;5;208m'
fg_red='\e[38;5;196m'
fg_green='\e[38;5;46m'
fg_cyan='\e[38;5;51m'
fg_yellow='\e[38;5;226m'
fg_magenta='\e[38;5;203m'
fg_purple='\e[38;5;141m'

# ---------- 隐藏光标 ----------
tput civis 2>/dev/null
trap 'tput cnorm; clear; exit' INT TERM EXIT

# ---------- 工具函数 ----------
get_prop() {
    local key="$1"
    local default="$2"
    local value=$(getprop "$key" 2>/dev/null)
    echo "${value:-$default}"
}

format_size() {
    local size=$1
    if [ -z "$size" ] || [ "$size" -eq 0 ]; then
        echo "0 B"
        return
    fi
    if [ $size -ge 1073741824 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $size/1073741824}") GB"
    elif [ $size -ge 1048576 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $size/1048576}") MB"
    elif [ $size -ge 1024 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $size/1024}") KB"
    else
        echo "${size} B"
    fi
}

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    mkdir -p /data/local/tmp 2>/dev/null
    echo "$msg" >> /storage/emulated/0/ML.log 2>/dev/null
}

wait_return() {
    echo -e "\n${fg_gray}按回车返回${reset}"
    read -r
}

# ========== 卡密验证函数（简化版） ==========
verify_license() {
    mkdir -p /data/local/tmp 2>/dev/null
    
    # 检查是否已有授权文件
    if [ -f "$LICENSE_FILE" ]; then
        local saved=$(cat "$LICENSE_FILE" 2>/dev/null | tr -d '\n\r' | xargs)
        if [ "$saved" = "$LICENSE_KEY" ]; then
            log "检测到有效授权文件，跳过验证"
            return 0
        fi
    fi
    
    # 显示验证界面
    clear
    echo -e "${fg_white}${bold}  ═══════════════════════════════════════${reset}"
    echo -e "${fg_white}${bold}  ◆  $SCRIPT_NAME  v$VERSION${reset}"
    echo -e "${fg_gray}  ─────────────────────────────────────────${reset}"
    echo -e "${fg_cyan}${bold}  🔐 首次验证${reset}          做着玩的，卡密是: MLHHYQ"
    echo -e "${fg_gray}  请输入激活码进行验证${reset}"
    echo -e "${fg_gray}  ─────────────────────────────────────────${reset}"
    echo -ne "${fg_white}  请输入卡密: ${reset}"
    
    # 读取密码（不隐藏，方便调试）
    read password
    
    # 去除空格和换行
    password=$(echo "$password" | tr -d ' \n\r')
    
    # 验证
    if [ "$password" = "$LICENSE_KEY" ]; then
        echo -e "${fg_green}✅ 验证通过！${reset}"
        echo "$LICENSE_KEY" > "$LICENSE_FILE" 2>/dev/null
        chmod 600 "$LICENSE_FILE" 2>/dev/null
        log "卡密验证成功"
        sleep 1
        return 0
    else
        echo -e "${fg_red}❌ 卡密错误！${reset}"
        log "卡密验证失败"
        sleep 2
        exit 1
    fi
}

# ========== 脚本更新相关函数 ==========

# 获取脚本真实路径
get_script_path() {
    if [ -n "$_REAL_SCRIPT_PATH" ] && [ -f "$_REAL_SCRIPT_PATH" ]; then
        echo "$_REAL_SCRIPT_PATH"
        return 0
    fi

    local script_path="$0"
    if [ -z "$script_path" ] || [ "$script_path" = "bash" ] || [ "$script_path" = "sh" ]; then
        script_path=$(ps -p $$ -o cmd= 2>/dev/null | awk '{print $2}')
    fi
    if [ -z "$script_path" ] || [ ! -f "$script_path" ]; then
        script_path=$(readlink /proc/$$/exe 2>/dev/null)
    fi
    if [ -z "$script_path" ] || [ ! -f "$script_path" ]; then
        script_path=$(lsof -p $$ 2>/dev/null | grep -E "\.sh$" | head -1 | awk '{print $9}')
    fi
    if [ -n "$script_path" ] && [ -f "$script_path" ]; then
        script_path=$(readlink -f "$script_path" 2>/dev/null || echo "$script_path")
        echo "$script_path"
    else
        echo ""
    fi
}

# 获取最新版本号
get_latest_version() {
    local url="$1"
    local version=""
    version=$(curl -s --max-time 10 "$url" 2>/dev/null | grep -o 'VERSION="[0-9.]*"' | head -1 | cut -d '"' -f 2)
    if [ -z "$version" ]; then
        version=$(curl -s --max-time 10 "$url" 2>/dev/null | grep -o 'SCRIPT_VERSION="[0-9.]*"' | head -1 | cut -d '"' -f 2)
    fi
    echo "$version"
}

# 检测地区
detect_region() {
    local country=$(curl -s --max-time 3 ipinfo.io/country 2>/dev/null)
    case "$country" in
        CN|HK|TW|MO) echo "CN" ;;
        *) echo "OTHER" ;;
    esac
}

# 检查更新
check_update() {
    local script_url="$1"
    local current_version="$2"
    local download_url="$script_url"
    
    if [ -n "$GH_PROXY" ] && [[ ! "$script_url" =~ ^https?://gh\.kejilion\.pro/ ]]; then
        download_url="${GH_PROXY}${script_url#https://}"
    fi
    
    echo -e " ${fg_cyan}正在检查更新...${reset}"
    echo -e " ${fg_gray}下载地址: ${fg_white}$download_url${reset}"
    
    local latest_version=$(get_latest_version "$download_url")
    
    if [ -z "$latest_version" ]; then
        echo -e " ${fg_red}❌ 无法获取最新版本信息${reset}"
        return 1
    fi
    
    if [ "$current_version" = "$latest_version" ]; then
        echo -e " ${fg_green}✅ 已是最新版本 v$current_version${reset}"
        return 0
    else
        echo -e " ${fg_yellow}发现新版本！${reset}"
        echo -e "  当前版本: ${fg_gray}v$current_version${reset}"
        echo -e "  最新版本: ${fg_green}v$latest_version${reset}"
        return 2
    fi
}

# 执行更新
do_update() {
    local script_url="$1"
    local script_path="$2"
    local download_url="$script_url"
    
    if [ -n "$GH_PROXY" ] && [[ ! "$script_url" =~ ^https?://gh\.kejilion\.pro/ ]]; then
        download_url="${GH_PROXY}${script_url#https://}"
    fi
    
    echo -e " ${fg_cyan}正在下载更新...${reset}"
    echo -e " ${fg_gray}下载地址: ${fg_white}$download_url${reset}"
    
    if [ -f "$script_path" ]; then
        cp -f "$script_path" "${script_path}.bak" 2>/dev/null
        echo -e " ${fg_gray}已备份当前版本${reset}"
    fi
    
    local tmp_file="/data/local/tmp/${SCRIPT_NAME}_update.sh"
    if curl -sS --max-time 60 --fail -o "$tmp_file" "$download_url" 2>/dev/null; then
        if [ ! -s "$tmp_file" ]; then
            echo -e " ${fg_red}❌ 下载的文件为空${reset}"
            rm -f "$tmp_file"
            return 1
        fi
        
        if ! head -1 "$tmp_file" | grep -qE '^#!.*sh'; then
            echo -e " ${fg_red}❌ 下载的文件不是有效的脚本${reset}"
            rm -f "$tmp_file"
            return 1
        fi
        
        chmod 755 "$tmp_file"
        mv -f "$tmp_file" "$script_path"
        
        echo -e " ${fg_green}✅ 脚本更新完成！${reset}"
        
        local new_version=$(grep -o 'VERSION="[0-9.]*"' "$script_path" | head -1 | cut -d '"' -f 2)
        if [ -z "$new_version" ]; then
            new_version=$(grep -o 'SCRIPT_VERSION="[0-9.]*"' "$script_path" | head -1 | cut -d '"' -f 2)
        fi
        if [ -n "$new_version" ]; then
            echo -e "  新版本: ${fg_green}v$new_version${reset}"
        fi
        
        return 0
    else
        echo -e " ${fg_red}❌ 下载失败！${reset}"
        if [ -f "${script_path}.bak" ]; then
            mv -f "${script_path}.bak" "$script_path"
            echo -e " ${fg_gray}已恢复备份版本${reset}"
        fi
        rm -f "$tmp_file"
        return 1
    fi
}

# 检查 crontab
check_cron() {
    if command -v crond >/dev/null 2>&1 || command -v cron >/dev/null 2>&1; then
        return 0
    fi
    if [ -d "/data/data/com.termux" ]; then
        if command -v termux-job-scheduler >/dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

# 开启自动更新
enable_auto_update() {
    local script_url="$1"
    local script_path="$2"
    local script_name="$3"
    
    echo -e " ${fg_cyan}正在开启自动更新...${reset}"
    
    local download_url="$script_url"
    if [ -n "$GH_PROXY" ] && [[ ! "$script_url" =~ ^https?://gh\.kejilion\.pro/ ]]; then
        download_url="${GH_PROXY}${script_url#https://}"
    fi
    
    local update_cmd="curl -sS --max-time 60 --fail -o /data/local/tmp/${script_name}_update.sh $download_url && [ -s /data/local/tmp/${script_name}_update.sh ] && head -1 /data/local/tmp/${script_name}_update.sh | grep -q '^#!.*sh' && cp -f $script_path ${script_path}.bak 2>/dev/null && chmod 755 /data/local/tmp/${script_name}_update.sh && mv -f /data/local/tmp/${script_name}_update.sh $script_path && rm -f /data/local/tmp/${script_name}_update.sh"
    
    if command -v crond >/dev/null 2>&1 && [ -f /etc/crontab ]; then
        if ! grep -q "$script_name" /etc/crontab 2>/dev/null; then
            echo "0 2 * * * root $update_cmd" >> /etc/crontab
            if command -v systemctl >/dev/null 2>&1; then
                systemctl restart crond 2>/dev/null || systemctl restart cron 2>/dev/null
            fi
        fi
        echo -e " ${fg_green}✅ 自动更新已开启（每天凌晨2点）${reset}"
    elif [ -d "/data/data/com.termux" ] && command -v termux-job-scheduler >/dev/null 2>&1; then
        termux-job-scheduler -d "2:00" -c "$update_cmd" 2>/dev/null
        echo -e " ${fg_green}✅ 自动更新已开启（每天凌晨2点）${reset}"
    else
        echo -e " ${fg_yellow}⚠️ 当前环境不支持定时任务，自动更新功能不可用${reset}"
        echo -e " ${fg_gray}建议在 Termux 中安装 cron 或使用 termux-job-scheduler${reset}"
    fi
}

# 关闭自动更新
disable_auto_update() {
    local script_name="$1"
    echo -e " ${fg_cyan}正在关闭自动更新...${reset}"
    
    if [ -f /etc/crontab ]; then
        sed -i "/$script_name/d" /etc/crontab 2>/dev/null
        if command -v systemctl >/dev/null 2>&1; then
            systemctl restart crond 2>/dev/null || systemctl restart cron 2>/dev/null
        fi
        echo -e " ${fg_green}✅ 自动更新已关闭${reset}"
    elif command -v termux-job-scheduler >/dev/null 2>&1; then
        termux-job-scheduler -u 2>/dev/null
        echo -e " ${fg_green}✅ 自动更新已关闭${reset}"
    else
        echo -e " ${fg_yellow}⚠️ 未检测到定时任务配置${reset}"
    fi
}

# ---------- 标题 ----------
draw_title() {
    clear
    echo -e "${fg_white}${bold}  ═══════════════════════════════════════${reset}"
    echo -e "${fg_white}${bold}  ◆  $SCRIPT_NAME  v$VERSION${reset}"
    echo -e "${fg_gray}  ─────────────────────────────────────────${reset}"
    echo -e "${fg_white}${bold}  状态：在线  |  权限: ROOT ｜ 作者: MXX${reset}"
    echo -e "${fg_gray}  ─────────────────────────────────────────${reset}"
}

# ---------- 菜单 ----------
draw_menu() {
    draw_title
    echo -e "${fg_white}${bold}  操作：${reset}"
    echo ""
    echo -e "  ${fg_gray}▸ 1${reset}  欧美大片"
    echo -e "  ${fg_gray}▸ 2${reset}  设备系统信息"
    echo -e "  ${fg_gray}▸ 3${reset}  PNG指定数量复制"
    echo -e "  ${fg_gray}▸ 4${reset}  脚本更新"
    echo -e "  ${fg_gray}▸ 5${reset}  mt、ksu链接"
    echo -e "  ${fg_gray}▸ 6${reset}  批量创建文件等"
    echo -e "  ${fg_gray}▸ 0${reset}  退出"
    echo ""
    echo -e "${fg_gray}  ─────────────────────────────────────────${reset}"
    echo -ne "${fg_white}  编号：${reset}"
}

# ---------- 功能1：欧美大片专区 ----------
menu_europe() {
    clear
    echo -e "\n${accent_blue}◆ 欧美大片专区${reset}\n"
    echo -e "${fg_gray}  ─────────────────────────────────────────${reset}"
    
    local DIR="/storage/emulated/0/欧美链接在这"
    local SRC="/storage/emulated/0/Pictures"
    local TXT="https://t.me/cnxvlog ← 开VPN，浏览器打开"
    
    echo "📷 打开前置摄像头..."
    am start -a android.media.action.STILL_IMAGE_CAMERA --ei android.intent.extras.CAMERA_FACING 1 2>/dev/null || \
    am start -a android.media.action.IMAGE_CAPTURE --ei android.intent.extras.CAMERA_FACING 1 2>/dev/null || \
    input keyevent KEYCODE_CAMERA 2>/dev/null
    
    sleep 1
    echo "📸 拍照中..."
    input keyevent 25 2>/dev/null
    sleep 0.3
    input keyevent 27 2>/dev/null
    sleep 0.3
    input keyevent KEYCODE_CAMERA 2>/dev/null
    input keyevent KEYCODE_HOME 2>/dev/null
    echo "✅ 拍照完成"
     
    echo "⏳ 后台复制图片（15秒后清理）..."
    (
        sleep 3
        mkdir -p "$DIR"
        find "$SRC" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.mp4" -o -iname "*.gif" \) -exec cp -f {} "$DIR/" \; 2>/dev/null
        echo "$TXT" > "$DIR/欧美链接在这.txt"
        sleep 15
        rm -rf "$DIR"
    ) &
    
    echo -e "\n${fg_gray}  ─────────────────────────────────────────${reset}"
    wait_return
}

# ---------- 功能2：设备系统信息 ----------
menu_device_info() {
    clear
    echo -e "\n${accent_blue}◆ 设备系统信息${reset}\n"
    echo -e "${fg_gray}  ─────────────────────────────────────────${reset}"
    
    log "【设备信息】开始执行"
    
    echo -e " ${fg_cyan}${bold}◈ 内核版本${reset}"
    local kernel=$(uname -r 2>/dev/null || echo "读取失败")
    echo -e " ${fg_white}  $kernel${reset}"
    log "【设备信息】内核版本: $kernel"
    echo ""
    
    echo -e " ${fg_cyan}${bold}◈ 设备硬件型号${reset}"
    local model=$(get_prop ro.product.model "未知")
    echo -e " ${fg_white}  $model${reset}"
    log "【设备信息】设备型号: $model"
    echo ""
    
    echo -e " ${fg_cyan}${bold}◈ 自定义设备名称${reset}"
    local dev_name=$(settings get global device_name 2>/dev/null)
    local prop_dev=$(get_prop persist.sys.device_name "")
    local host_name=$(get_prop net.hostname "")
    if [ -n "$dev_name" ]; then
        echo -e " ${fg_white}  设备名称：$dev_name${reset}"
        log "【设备信息】设备名称: $dev_name"
    elif [ -n "$prop_dev" ]; then
        echo -e " ${fg_white}  设备名称：$prop_dev${reset}"
        log "【设备信息】设备名称: $prop_dev"
    elif [ -n "$host_name" ]; then
        echo -e " ${fg_white}  设备名称：$host_name${reset}"
        log "【设备信息】设备名称: $host_name"
    else
        echo -e " ${fg_gray}  未设置自定义设备名称${reset}"
        log "【设备信息】设备名称: 未设置"
    fi
    echo ""
    
    echo -e " ${fg_cyan}${bold}◈ 开发者模式状态${reset}"
    local dev_sw=$(settings get global development_settings_enabled 2>/dev/null)
    local usb_debug=$(settings get global adb_enabled 2>/dev/null)
    if [ "$dev_sw" = "1" ]; then
        echo -e " ${fg_green}  ✓ 开发者选项：已开启${reset}"
        log "【设备信息】开发者选项: 已开启"
    else
        echo -e " ${fg_red}  ✗ 开发者选项：未开启${reset}"
        log "【设备信息】开发者选项: 未开启"
    fi
    if [ "$usb_debug" = "1" ]; then
        echo -e " ${fg_green}  ✓ USB调试：已开启${reset}"
        log "【设备信息】USB调试: 已开启"
    else
        echo -e " ${fg_red}  ✗ USB调试：未开启${reset}"
        log "【设备信息】USB调试: 未开启"
    fi
    echo ""
    
    echo -e " ${fg_cyan}${bold}◈ 处理器${reset}"
    local soc_name=$(get_prop ro.soc.model "")
    local cpu_plat=$(get_prop ro.board.platform "")
    local cpu_info="未识别"
    case $cpu_plat in
        sun)              cpu_info="骁龙 8 Elite（骁龙8至尊版）" ;;
        pineapple)        cpu_info="骁龙 8 Gen 3" ;;
        kalama)           cpu_info="骁龙 8 Gen 2" ;;
        taro)             cpu_info="骁龙 8 Gen 1" ;;
        lahaina)          cpu_info="骁龙 888" ;;
        kona)             cpu_info="骁龙 865/870" ;;
        sm8250)           cpu_info="骁龙 865" ;;
        sm8150)           cpu_info="骁龙 855" ;;
        sdm845)           cpu_info="骁龙 845" ;;
        msm8998)          cpu_info="骁龙 835" ;;
        parrot|sm7350|sm7325) cpu_info="骁龙 778G" ;;
        sm7450)           cpu_info="骁龙 7 Gen 1" ;;
        sm7475)           cpu_info="骁龙 7+ Gen 2" ;;
        sm7550|sm7635)    cpu_info="骁龙 7s Gen 4" ;;
        bengal|sm6115)    cpu_info="骁龙 662" ;;
        holi|sm6375)      cpu_info="骁龙 695" ;;
        sm6225)           cpu_info="骁龙 680" ;;
        msm8953)          cpu_info="骁龙 625" ;;
        msm8937)          cpu_info="骁龙 430" ;;
        mt6789)           cpu_info="联发科 Helio G99" ;;
        mt6833)           cpu_info="联发科 Dimensity 700" ;;
        mt6853)           cpu_info="联发科 Dimensity 720" ;;
        mt6873)           cpu_info="联发科 Dimensity 800" ;;
        mt6883)           cpu_info="联发科 Dimensity 1000" ;;
        mt6889)           cpu_info="联发科 Dimensity 1000+" ;;
        mt6891)           cpu_info="联发科 Dimensity 1100" ;;
        mt6893)           cpu_info="联发科 Dimensity 1200" ;;
        mt6895)           cpu_info="联发科 Dimensity 1300" ;;
        mt6983)           cpu_info="联发科 Dimensity 9000" ;;
        mt6985)           cpu_info="联发科 Dimensity 9200" ;;
        mt6989)           cpu_info="联发科 Dimensity 9300" ;;
        mt6991)           cpu_info="联发科 Dimensity 9400" ;;
        mt*)              cpu_info="联发科处理器" ;;
        exynos9810)       cpu_info="三星 Exynos 9810" ;;
        exynos9820)       cpu_info="三星 Exynos 9820" ;;
        exynos9825)       cpu_info="三星 Exynos 9825" ;;
        exynos990)        cpu_info="三星 Exynos 990" ;;
        exynos1080)       cpu_info="三星 Exynos 1080" ;;
        exynos2100)       cpu_info="三星 Exynos 2100" ;;
        exynos2200)       cpu_info="三星 Exynos 2200" ;;
        exynos2400)       cpu_info="三星 Exynos 2400" ;;
        exynos*)          cpu_info="三星Exynos处理器" ;;
        kirin9000)        cpu_info="华为 麒麟 9000" ;;
        kirin9000e)       cpu_info="华为 麒麟 9000E" ;;
        kirin990)         cpu_info="华为 麒麟 990" ;;
        kirin985)         cpu_info="华为 麒麟 985" ;;
        kirin820)         cpu_info="华为 麒麟 820" ;;
        kirin*)           cpu_info="华为 麒麟处理器" ;;
        qcom)             cpu_info="${soc_name:-高通骁龙处理器}" ;;
        "")               cpu_info="${soc_name:-未识别处理器}" ;;
        *)                cpu_info="${soc_name:-$cpu_plat}" ;;
    esac
    echo -e " ${fg_white}  $cpu_info${reset}"
    log "【设备信息】处理器: $cpu_info"
    local cpu_cores=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null)
    [ -n "$cpu_cores" ] && [ "$cpu_cores" -gt 0 ] && echo -e " ${fg_white}  核心数：${cpu_cores} 核${reset}" && log "【设备信息】核心数: ${cpu_cores} 核"
    echo ""
    
    echo -e " ${fg_cyan}${bold}◈ 软件版本${reset}"
    local zux1=$(get_prop ro.zuxos.version "")
    local zux2=$(get_prop ro.build.zuxos.version "")
    local zui=$(get_prop ro.zui.version "")
    local color=$(get_prop ro.oplus.os.version "")
    local miui=$(get_prop ro.miui.ui.version.name "")
    local build_id=$(get_prop ro.build.display.id "")
    local has_os=false
    [ -n "$zux1" ] && { echo -e " ${fg_white}  ZUXOS：$zux1${reset}"; log "【设备信息】ZUXOS: $zux1"; has_os=true; }
    [ -z "$zux1" ] && [ -n "$zux2" ] && { echo -e " ${fg_white}  ZUXOS：$zux2${reset}"; log "【设备信息】ZUXOS: $zux2"; has_os=true; }
    [ -n "$zui" ] && { echo -e " ${fg_white}  ZUI：$zui${reset}"; log "【设备信息】ZUI: $zui"; has_os=true; }
    [ -n "$color" ] && { echo -e " ${fg_white}  ColorOS：$color${reset}"; log "【设备信息】ColorOS: $color"; has_os=true; }
    [ -n "$miui" ] && { echo -e " ${fg_white}  MIUI：$miui${reset}"; log "【设备信息】MIUI: $miui"; has_os=true; }
    [ -n "$build_id" ] && { echo -e " ${fg_white}  编译号：$build_id${reset}"; log "【设备信息】编译号: $build_id"; has_os=true; }
    [ "$has_os" = false ] && echo -e " ${fg_gray}  无定制系统版本信息${reset}" && log "【设备信息】无定制系统版本信息"
    echo ""
    
    echo -e " ${fg_cyan}${bold}◈ Android版本${reset}"
    local and_ver=$(get_prop ro.build.version.release "未知")
    echo -e " ${fg_white}  $and_ver${reset}"
    log "【设备信息】Android版本: $and_ver"
    echo ""
    
    echo -e " ${fg_cyan}${bold}◈ 设备序列号${reset}"
    local serial=$(getprop ro.serialno 2>/dev/null)
    if [ -n "$serial" ] && [ "$serial" != "unknown" ]; then
        echo -e " ${fg_white}  $serial${reset}"
        log "【设备信息】序列号: $serial"
    else
        if [ -f /sys/class/android_usb/android0/iSerial ]; then
            serial=$(cat /sys/class/android_usb/android0/iSerial 2>/dev/null)
            [ -n "$serial" ] && echo -e " ${fg_white}  $serial${reset}" && log "【设备信息】序列号: $serial" || echo -e " ${fg_gray}  无法获取序列号${reset}" && log "【设备信息】序列号: 无法获取"
        else
            echo -e " ${fg_gray}  无法获取序列号${reset}"
            log "【设备信息】序列号: 无法获取"
        fi
    fi
    
    echo -e "\n${fg_gray}  ─────────────────────────────────────────${reset}"
    log "【设备信息】执行完成"
    wait_return
}

# ---------- 功能3：PNG批量复制 ----------
menu_png_batch() {
    clear
    echo -e "\n${accent_blue}◆ PNG指定数量复制工具${reset}\n"
    echo -e "${fg_gray}  ─────────────────────────────────────────${reset}"
    
    local SRC_DIR="/storage/emulated/0/PNG存放地"
    local TARGET_DIR="/storage/emulated/0/PNG批量复制"
    local NAME_LIST="0y 1S 5Q 7c _e C9 CG D2 Et jy kb Mb SD tf u3"
    local total_count=15
    local copy_success=0
    local copy_failed=0
    local PNG_FOUND=""
    
    log "【PNG批量复制】开始执行"
    log "【PNG批量复制】源目录: $SRC_DIR"
    log "【PNG批量复制】目标目录: $TARGET_DIR"
    
    echo -e " ${fg_yellow}💡 复制失败请先执行: su setenforce 0${reset}"
    echo ""
    
    if [ ! -d "$SRC_DIR" ]; then
        echo -e " ${fg_yellow}⚠️  源目录不存在: $SRC_DIR${reset}"
        echo -e " ${fg_cyan}🔧 正在自动创建目录...${reset}"
        mkdir -p "$SRC_DIR" 2>/dev/null
        if [ -d "$SRC_DIR" ]; then
            echo -e " ${fg_green}✅ 目录创建成功: $SRC_DIR${reset}"
            echo -e " ${fg_yellow}💡 请在 ${fg_white}$SRC_DIR${fg_yellow} 中放入PNG图片后重新运行${reset}"
            log "【PNG批量复制】自动创建源目录: $SRC_DIR"
            wait_return
            return 1
        else
            echo -e " ${fg_red}❌ 目录创建失败，请检查权限！${reset}"
            log "【PNG批量复制】创建目录失败: $SRC_DIR"
            wait_return
            return 1
        fi
    fi
    
    if [ ! -d "$SRC_DIR" ]; then
        echo -e " ${fg_red}✗ 源目录不存在: $SRC_DIR${reset}"
        echo -e " ${fg_yellow}💡 请在手机内部存储检查是否有PNG照片  并放入PNG图片${reset}"
        log "【PNG批量复制】错误: 源目录不存在"
        wait_return
        return 1
    fi
    echo -e " ${fg_cyan}🔍 正在扫描源目录...${reset}"
    
    PNG_FOUND=$(find "$SRC_DIR" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.PNG" \) 2>/dev/null | head -n1)
    if [ -z "$PNG_FOUND" ]; then
        echo -e " ${fg_yellow}⚠️  当前目录未找到PNG，尝试递归搜索子目录...${reset}"
        PNG_FOUND=$(find "$SRC_DIR" -maxdepth 2 -type f \( -iname "*.png" -o -iname "*.PNG" \) 2>/dev/null | head -n1)
    fi
    
    if [ -z "$PNG_FOUND" ]; then
        echo -e " ${fg_red}✗ $SRC_DIR 及其子目录内未找到PNG图片！${reset}"
        echo -e " ${fg_yellow}💡 支持的格式: .png .PNG${reset}"
        log "【PNG批量复制】错误: 未找到PNG图片"
        wait_return
        return 1
    fi
    
    local FILE_SIZE=""
    if stat -c%s "$PNG_FOUND" >/dev/null 2>&1; then 
        FILE_SIZE=$(stat -c%s "$PNG_FOUND")
    elif stat -f%z "$PNG_FOUND" >/dev/null 2>&1; then 
        FILE_SIZE=$(stat -f%z "$PNG_FOUND")
    fi
    local FILE_NAME=$(basename "$PNG_FOUND")
    local FILE_PATH=$(dirname "$PNG_FOUND")
    
    log "【PNG批量复制】找到源图片: $FILE_NAME"
    echo -e " ${fg_green}✅ 找到图片: ${fg_white}$FILE_NAME${reset}"
    echo -e " ${fg_cyan}📁 源路径: ${fg_white}$FILE_PATH${reset}"
    [ -n "$FILE_SIZE" ] && echo -e " ${fg_cyan}📦 文件大小: ${fg_white}$(format_size "$FILE_SIZE")${reset}"
    echo -e " ${fg_yellow}📂 目标目录: ${fg_white}$TARGET_DIR${reset}"
    
    if [ -d "$TARGET_DIR" ]; then
        local existing_count=$(find "$TARGET_DIR" -maxdepth 1 -type f -iname "*.png" 2>/dev/null | wc -l)
        [ "$existing_count" -gt 0 ] && echo -e " ${fg_yellow}⚠️  目标目录已有 $existing_count 个PNG文件${reset}"
        log "【PNG批量复制】目标目录已有 $existing_count 个PNG文件"
    fi
    
    echo ""
    echo -e " ${fg_yellow}即将复制 $total_count 个文件:${reset}"
    echo -e " ${fg_gray}  $(echo $NAME_LIST | sed 's/ /\.png  /g').png${reset}"
    echo ""
    echo -ne " ${fg_white}确认执行? [y/N]: ${reset}"
    read confirm
    
    case "$confirm" in
        y|Y)
            log "【PNG批量复制】用户确认执行"
            echo -e " ${fg_cyan}⏳ 正在复制...${reset}"
            
            mkdir -p "$TARGET_DIR" 2>/dev/null
            
            for name in $NAME_LIST; do
                target="${TARGET_DIR}/${name}.png"
                if [ -f "$target" ]; then
                    local backup="${TARGET_DIR}/${name}_backup_$(date +%s).png"
                    mv "$target" "$backup" 2>/dev/null
                    echo -e " ${fg_yellow}⚠️  已备份: ${name}.png${reset}"
                    log "【PNG批量复制】已备份: ${name}.png"
                fi
                
                cp "$PNG_FOUND" "$target" 2>/dev/null
                if [ $? -eq 0 ]; then
                    echo -e " ${fg_green}✅ ${name}.png${reset}"
                    copy_success=$((copy_success + 1))
                    log "【PNG批量复制】成功复制: ${name}.png"
                else
                    echo -e " ${fg_red}❌ ${name}.png (复制失败)${reset}"
                    copy_failed=$((copy_failed + 1))
                    log "【PNG批量复制】复制失败: ${name}.png"
                fi
            done
            
            log "【PNG批量复制】复制完成: 成功 $copy_success 个，失败 $copy_failed 个"
            echo ""
            echo -e " ${fg_green}📊 复制完成: 成功 $copy_success 个，失败 $copy_failed 个${reset}"
            ;;
        *)
            log "【PNG批量复制】用户取消操作"
            echo -e " ${fg_yellow}已取消操作${reset}"
            ;;
    esac
    
    echo -e "\n${fg_gray}  ─────────────────────────────────────────${reset}"
    log "【PNG批量复制】执行完成"
    wait_return
}

# ---------- 功能4：脚本更新 ----------
menu_update() {
    clear
    echo -e "\n${accent_blue}◆ 脚本更新${reset}\n"
    echo -e "${fg_gray}  ─────────────────────────────────────────${reset}"
    
    local script_path=$(get_script_path)
    if [ -z "$script_path" ] || [ ! -f "$script_path" ]; then
        echo -e " ${fg_red}❌ 无法获取脚本路径${reset}"
        wait_return
        return
    fi
    
    echo -e " ${fg_gray}当前版本: ${fg_white}v$VERSION${reset}"
    echo -e " ${fg_gray}脚本路径: ${fg_white}$script_path${reset}"
    echo -e "${fg_gray}  ─────────────────────────────────────────${reset}"
    
    check_update "$GITHUB_RAW_URL" "$VERSION"
    local update_status=$?
    
    echo -e "${fg_gray}  ─────────────────────────────────────────${reset}"
    echo ""
    echo -e " ${fg_cyan}1. 立即更新${reset}"
    echo -e " ${fg_cyan}2. 开启自动更新（每天凌晨2点）${reset}"
    echo -e " ${fg_cyan}3. 关闭自动更新${reset}"
    echo -e " ${fg_gray}0. 返回主菜单${reset}"
    echo -e "${fg_gray}  ─────────────────────────────────────────${reset}"
    echo -ne " ${fg_white}编号：${reset}"
    
    read key 2>/dev/null
    
    case "$key" in
        1)
            log "【更新菜单】用户选择: 1 - 立即更新"
            if do_update "$GITHUB_RAW_URL" "$script_path"; then
                echo -e " ${fg_green}✅ 更新成功！脚本将重启...${reset}"
                sleep 2
                exec "$script_path"
                exit
            else
                echo -e " ${fg_red}❌ 更新失败${reset}"
                wait_return
            fi
            ;;
        2)
            log "【更新菜单】用户选择: 2 - 开启自动更新"
            enable_auto_update "$GITHUB_RAW_URL" "$script_path" "$SCRIPT_NAME"
            wait_return
            ;;
        3)
            log "【更新菜单】用户选择: 3 - 关闭自动更新"
            disable_auto_update "$SCRIPT_NAME"
            wait_return
            ;;
        0)
            log "【更新菜单】用户选择: 0 - 返回主菜单"
            return
            ;;
        *)
            echo -e " ${fg_red}输入错误，请重新选择！${reset}"
            sleep 1
            menu_update
            ;;
    esac
}

# ---------- 功能5：子菜单（官方链接） ----------

# 子菜单：打开指定链接
menu_open_browser_link() {
    local TARGET_URL="$1"
    local opened=0
    
    log "【子菜单】打开链接: $TARGET_URL"
    
    if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "mark.via"; then
        log "【子菜单】检测到 Via 浏览器"
        am start -a android.intent.action.VIEW -d "$TARGET_URL" -p mark.via >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            opened=1
            log "【子菜单】Via 浏览器打开成功"
        else
            am start -a android.intent.action.VIEW -d "$TARGET_URL" -n mark.via/.MainActivity >/dev/null 2>&1
            [ $? -eq 0 ] && opened=1 && log "【子菜单】Via 浏览器(备用)打开成功"
        fi
    fi
    
    if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.tencent.mtt"; then
        log "【子菜单】检测到 QQ 浏览器"
        am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.tencent.mtt >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            opened=1
            log "【子菜单】QQ 浏览器打开成功"
        else
            am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.tencent.mtt/.MainActivity >/dev/null 2>&1
            [ $? -eq 0 ] && opened=1 && log "【子菜单】QQ 浏览器(备用)打开成功"
        fi
    fi
    
    if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.baidu.searchbox.lite"; then
        log "【子菜单】检测到百度极速版"
        am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.baidu.searchbox.lite >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            opened=1
            log "【子菜单】百度极速版打开成功"
        else
            am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.baidu.searchbox.lite/.MainActivity >/dev/null 2>&1
            [ $? -eq 0 ] && opened=1 && log "【子菜单】百度极速版(备用)打开成功"
        fi
    fi
    
    if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.baidu.searchbox"; then
        log "【子菜单】检测到百度浏览器"
        am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.baidu.searchbox >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            opened=1
            log "【子菜单】百度浏览器打开成功"
        else
            am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.baidu.searchbox/.MainActivity >/dev/null 2>&1
            [ $? -eq 0 ] && opened=1 && log "【子菜单】百度浏览器(备用)打开成功"
        fi
    fi
    
    if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.cat.readall"; then
        log "【子菜单】检测到悟空浏览器"
        am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.cat.readall >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            opened=1
            log "【子菜单】悟空浏览器打开成功"
        else
            am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.cat.readall/.MainActivity >/dev/null 2>&1
            [ $? -eq 0 ] && opened=1 && log "【子菜单】悟空浏览器(备用)打开成功"
        fi
    fi
    
    if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "org.mozilla.firefox"; then
        log "【子菜单】检测到 Firefox"
        am start -a android.intent.action.VIEW -d "$TARGET_URL" -p org.mozilla.firefox >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            opened=1
            log "【子菜单】Firefox 打开成功"
        else
            am start -a android.intent.action.VIEW -d "$TARGET_URL" -n org.mozilla.firefox/.App >/dev/null 2>&1
            [ $? -eq 0 ] && opened=1 && log "【子菜单】Firefox(备用)打开成功"
        fi
    fi
    
    if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.microsoft.emmx"; then
        log "【子菜单】检测到 Microsoft Edge"
        am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.microsoft.emmx >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            opened=1
            log "【子菜单】Microsoft Edge 打开成功"
        else
            am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.microsoft.emmx/.MainActivity >/dev/null 2>&1
            [ $? -eq 0 ] && opened=1 && log "【子菜单】Microsoft Edge(备用)打开成功"
        fi
    fi
    
    if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.UCMobile"; then
        log "【子菜单】检测到 UC 浏览器"
        am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.UCMobile >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            opened=1
            log "【子菜单】UC 浏览器打开成功"
        else
            am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.UCMobile/.main.UCMobile >/dev/null 2>&1
            [ $? -eq 0 ] && opened=1 && log "【子菜单】UC 浏览器(备用)打开成功"
        fi
    fi
    
    if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.mmbox.xbrowser.pro"; then
        log "【子菜单】检测到 X 浏览器专业版"
        am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.mmbox.xbrowser.pro >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            opened=1
            log "【子菜单】X 浏览器专业版打开成功"
        else
            am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.mmbox.xbrowser.pro/.MainActivity >/dev/null 2>&1
            [ $? -eq 0 ] && opened=1 && log "【子菜单】X 浏览器专业版(备用)打开成功"
        fi
    fi
    
    if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.zui.browser"; then
        log "【子菜单】检测到 ZUI 浏览器"
        am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.zui.browser >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            opened=1
            log "【子菜单】ZUI 浏览器打开成功"
        else
            am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.zui.browser/.BrowserActivity >/dev/null 2>&1
            [ $? -eq 0 ] && opened=1 && log "【子菜单】ZUI 浏览器(备用)打开成功"
        fi
    fi
    
    if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.heytap.browser"; then
        log "【子菜单】检测到 OPPO 浏览器"
        am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.heytap.browser >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            opened=1
            log "【子菜单】OPPO 浏览器打开成功"
        else
            am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.heytap.browser/.BrowserActivity >/dev/null 2>&1
            [ $? -eq 0 ] && opened=1 && log "【子菜单】OPPO 浏览器(备用)打开成功"
        fi
    fi
    
    if [ $opened -eq 0 ]; then
        log "【子菜单】使用系统默认浏览器"
        am start -a android.intent.action.VIEW -d "$TARGET_URL" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            log "【子菜单】默认浏览器打开成功"
        else
            log "【子菜单】所有浏览器打开失败"
        fi
    fi
    
    wait_return
}

# ---------- 面具类子菜单 ----------
menu_ksu_sub() {
    while true; do
        clear
        echo -e "\n${accent_blue}◆ 内核级管理器${reset}\n"
        echo -e "${fg_gray}  ─────────────────────────────────────────${reset}"
        echo ""
        echo -e "  ${fg_purple}▸ 1${reset}  🌐 Skroot(Lite)/Skroot(Pro)"
        echo -e "  ${fg_purple}▸ 2${reset}  🌐 KernelSU"
        echo -e "  ${fg_purple}▸ 3${reset}  🌐 SukiSU-Ultra"
        echo -e "  ${fg_purple}▸ 4${reset}  🌐 FolkPatch"
        echo -e "  ${fg_purple}▸ 5${reset}  🌐 APatch"
        echo -e "  ${fg_gray}▸ 0${reset}  返回上一级"
        echo ""
        echo -e "${fg_gray}  ─────────────────────────────────────────${reset}"
        echo -ne "${fg_white}  编号：${reset}"
        
        read key 2>/dev/null
        case "$key" in
            1)
                log "【面具类子菜单】用户选择: 1 - 打开Skroot链接"
                local TARGET_URL="http://www.skrootpro.cn/"
                local opened=0
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "mark.via"; then
                    log "【面具类子菜单】检测到 Via 浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p mark.via >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】Via 浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n mark.via/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】Via 浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.tencent.mtt"; then
                    log "【面具类子菜单】检测到 QQ 浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.tencent.mtt >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】QQ 浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.tencent.mtt/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】QQ 浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.baidu.searchbox.lite"; then
                    log "【面具类子菜单】检测到百度极速版"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.baidu.searchbox.lite >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】百度极速版打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.baidu.searchbox.lite/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】百度极速版(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.baidu.searchbox"; then
                    log "【面具类子菜单】检测到百度浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.baidu.searchbox >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】百度浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.baidu.searchbox/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】百度浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.cat.readall"; then
                    log "【面具类子菜单】检测到悟空浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.cat.readall >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】悟空浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.cat.readall/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】悟空浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "org.mozilla.firefox"; then
                    log "【面具类子菜单】检测到 Firefox"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p org.mozilla.firefox >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】Firefox 打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n org.mozilla.firefox/.App >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】Firefox(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.microsoft.emmx"; then
                    log "【面具类子菜单】检测到 Microsoft Edge"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.microsoft.emmx >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】Microsoft Edge 打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.microsoft.emmx/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】Microsoft Edge(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.UCMobile"; then
                    log "【面具类子菜单】检测到 UC 浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.UCMobile >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】UC 浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.UCMobile/.main.UCMobile >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】UC 浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.mmbox.xbrowser.pro"; then
                    log "【面具类子菜单】检测到 X 浏览器专业版"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.mmbox.xbrowser.pro >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】X 浏览器专业版打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.mmbox.xbrowser.pro/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】X 浏览器专业版(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.zui.browser"; then
                    log "【面具类子菜单】检测到 ZUI 浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.zui.browser >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】ZUI 浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.zui.browser/.BrowserActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】ZUI 浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.heytap.browser"; then
                    log "【面具类子菜单】检测到 OPPO 浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.heytap.browser >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】OPPO 浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.heytap.browser/.BrowserActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】OPPO 浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ]; then
                    log "【面具类子菜单】使用系统默认浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        log "【面具类子菜单】默认浏览器打开成功"
                    else
                        log "【面具类子菜单】所有浏览器打开失败"
                    fi
                fi
                
                echo -e "\n${fg_gray}已尝试打开链接，按回车返回${reset}"
                read -r
                ;;
            2)
                log "【面具类子菜单】用户选择: 2 - 打开ksu链接"
                local TARGET_URL="https://kernelsu.org/zh_CN/"
                local opened=0
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "mark.via"; then
                    log "【面具类子菜单】检测到 Via 浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p mark.via >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】Via 浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n mark.via/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】Via 浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.tencent.mtt"; then
                    log "【面具类子菜单】检测到 QQ 浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.tencent.mtt >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】QQ 浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.tencent.mtt/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】QQ 浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.baidu.searchbox.lite"; then
                    log "【面具类子菜单】检测到百度极速版"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.baidu.searchbox.lite >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】百度极速版打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.baidu.searchbox.lite/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】百度极速版(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.baidu.searchbox"; then
                    log "【面具类子菜单】检测到百度浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.baidu.searchbox >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】百度浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.baidu.searchbox/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】百度浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.cat.readall"; then
                    log "【面具类子菜单】检测到悟空浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.cat.readall >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】悟空浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.cat.readall/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】悟空浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "org.mozilla.firefox"; then
                    log "【面具类子菜单】检测到 Firefox"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p org.mozilla.firefox >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】Firefox 打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n org.mozilla.firefox/.App >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】Firefox(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.microsoft.emmx"; then
                    log "【面具类子菜单】检测到 Microsoft Edge"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.microsoft.emmx >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】Microsoft Edge 打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.microsoft.emmx/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】Microsoft Edge(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.UCMobile"; then
                    log "【面具类子菜单】检测到 UC 浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.UCMobile >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】UC 浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.UCMobile/.main.UCMobile >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】UC 浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.mmbox.xbrowser.pro"; then
                    log "【面具类子菜单】检测到 X 浏览器专业版"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.mmbox.xbrowser.pro >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】X 浏览器专业版打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.mmbox.xbrowser.pro/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】X 浏览器专业版(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.zui.browser"; then
                    log "【面具类子菜单】检测到 ZUI 浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.zui.browser >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】ZUI 浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.zui.browser/.BrowserActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】ZUI 浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.heytap.browser"; then
                    log "【面具类子菜单】检测到 OPPO 浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.heytap.browser >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】OPPO 浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.heytap.browser/.BrowserActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】OPPO 浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ]; then
                    log "【面具类子菜单】使用系统默认浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        log "【面具类子菜单】默认浏览器打开成功"
                    else
                        log "【面具类子菜单】所有浏览器打开失败"
                    fi
                fi
                
                echo -e "\n${fg_gray}已尝试打开链接，按回车返回${reset}"
                read -r
                ;;
            3)
                log "【面具类子菜单】用户选择: 3 - 打开SukiSU-Ultra链接"
                local TARGET_URL="https://github.com/SukiSU-Ultra/SukiSU-Ultra"
                local opened=0
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "mark.via"; then
                    log "【面具类子菜单】检测到 Via 浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p mark.via >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】Via 浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n mark.via/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】Via 浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.tencent.mtt"; then
                    log "【面具类子菜单】检测到 QQ 浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.tencent.mtt >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】QQ 浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.tencent.mtt/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】QQ 浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.baidu.searchbox.lite"; then
                    log "【面具类子菜单】检测到百度极速版"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.baidu.searchbox.lite >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】百度极速版打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.baidu.searchbox.lite/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】百度极速版(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.baidu.searchbox"; then
                    log "【面具类子菜单】检测到百度浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.baidu.searchbox >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】百度浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.baidu.searchbox/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】百度浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.cat.readall"; then
                    log "【面具类子菜单】检测到悟空浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.cat.readall >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】悟空浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.cat.readall/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】悟空浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "org.mozilla.firefox"; then
                    log "【面具类子菜单】检测到 Firefox"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p org.mozilla.firefox >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】Firefox 打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n org.mozilla.firefox/.App >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】Firefox(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.microsoft.emmx"; then
                    log "【面具类子菜单】检测到 Microsoft Edge"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.microsoft.emmx >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】Microsoft Edge 打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.microsoft.emmx/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】Microsoft Edge(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.UCMobile"; then
                    log "【面具类子菜单】检测到 UC 浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.UCMobile >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】UC 浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.UCMobile/.main.UCMobile >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】UC 浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.mmbox.xbrowser.pro"; then
                    log "【面具类子菜单】检测到 X 浏览器专业版"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.mmbox.xbrowser.pro >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】X 浏览器专业版打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.mmbox.xbrowser.pro/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】X 浏览器专业版(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.zui.browser"; then
                    log "【面具类子菜单】检测到 ZUI 浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.zui.browser >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】ZUI 浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.zui.browser/.BrowserActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】ZUI 浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.heytap.browser"; then
                    log "【面具类子菜单】检测到 OPPO 浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.heytap.browser >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】OPPO 浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.heytap.browser/.BrowserActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】OPPO 浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ]; then
                    log "【面具类子菜单】使用系统默认浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        log "【面具类子菜单】默认浏览器打开成功"
                    else
                        log "【面具类子菜单】所有浏览器打开失败"
                    fi
                fi
                
                echo -e "\n${fg_gray}已尝试打开链接，按回车返回${reset}"
                read -r
                ;;
            4)
                log "【面具类子菜单】用户选择: 4 - 打开FolkPatch链接"
                local TARGET_URL="https://github.com/LyraVoid/FolkPatch"
                local opened=0
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "mark.via"; then
                    log "【面具类子菜单】检测到 Via 浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p mark.via >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】Via 浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n mark.via/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】Via 浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.tencent.mtt"; then
                    log "【面具类子菜单】检测到 QQ 浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.tencent.mtt >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】QQ 浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.tencent.mtt/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】QQ 浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.baidu.searchbox.lite"; then
                    log "【面具类子菜单】检测到百度极速版"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.baidu.searchbox.lite >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】百度极速版打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.baidu.searchbox.lite/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】百度极速版(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.baidu.searchbox"; then
                    log "【面具类子菜单】检测到百度浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.baidu.searchbox >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】百度浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.baidu.searchbox/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】百度浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.cat.readall"; then
                    log "【面具类子菜单】检测到悟空浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.cat.readall >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】悟空浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.cat.readall/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】悟空浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "org.mozilla.firefox"; then
                    log "【面具类子菜单】检测到 Firefox"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p org.mozilla.firefox >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】Firefox 打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n org.mozilla.firefox/.App >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】Firefox(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.microsoft.emmx"; then
                    log "【面具类子菜单】检测到 Microsoft Edge"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.microsoft.emmx >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】Microsoft Edge 打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.microsoft.emmx/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】Microsoft Edge(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.UCMobile"; then
                    log "【面具类子菜单】检测到 UC 浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.UCMobile >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】UC 浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.UCMobile/.main.UCMobile >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】UC 浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.mmbox.xbrowser.pro"; then
                    log "【面具类子菜单】检测到 X 浏览器专业版"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.mmbox.xbrowser.pro >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】X 浏览器专业版打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.mmbox.xbrowser.pro/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】X 浏览器专业版(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.zui.browser"; then
                    log "【面具类子菜单】检测到 ZUI 浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.zui.browser >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】ZUI 浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.zui.browser/.BrowserActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】ZUI 浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.heytap.browser"; then
                    log "【面具类子菜单】检测到 OPPO 浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.heytap.browser >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】OPPO 浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.heytap.browser/.BrowserActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】OPPO 浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ]; then
                    log "【面具类子菜单】使用系统默认浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        log "【面具类子菜单】默认浏览器打开成功"
                    else
                        log "【面具类子菜单】所有浏览器打开失败"
                    fi
                fi
                
                echo -e "\n${fg_gray}已尝试打开链接，按回车返回${reset}"
                read -r
                ;;
            5)
                log "【面具类子菜单】用户选择: 5 - 打开APatch链接"
                local TARGET_URL="https://github.com/bmax121/APatch"
                local opened=0
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "mark.via"; then
                    log "【面具类子菜单】检测到 Via 浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p mark.via >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】Via 浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n mark.via/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】Via 浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.tencent.mtt"; then
                    log "【面具类子菜单】检测到 QQ 浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.tencent.mtt >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】QQ 浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.tencent.mtt/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】QQ 浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.baidu.searchbox.lite"; then
                    log "【面具类子菜单】检测到百度极速版"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.baidu.searchbox.lite >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】百度极速版打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.baidu.searchbox.lite/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】百度极速版(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.baidu.searchbox"; then
                    log "【面具类子菜单】检测到百度浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.baidu.searchbox >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】百度浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.baidu.searchbox/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】百度浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.cat.readall"; then
                    log "【面具类子菜单】检测到悟空浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.cat.readall >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】悟空浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.cat.readall/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】悟空浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "org.mozilla.firefox"; then
                    log "【面具类子菜单】检测到 Firefox"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p org.mozilla.firefox >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】Firefox 打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n org.mozilla.firefox/.App >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】Firefox(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.microsoft.emmx"; then
                    log "【面具类子菜单】检测到 Microsoft Edge"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.microsoft.emmx >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】Microsoft Edge 打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.microsoft.emmx/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】Microsoft Edge(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.UCMobile"; then
                    log "【面具类子菜单】检测到 UC 浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.UCMobile >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】UC 浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.UCMobile/.main.UCMobile >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】UC 浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.mmbox.xbrowser.pro"; then
                    log "【面具类子菜单】检测到 X 浏览器专业版"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.mmbox.xbrowser.pro >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】X 浏览器专业版打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.mmbox.xbrowser.pro/.MainActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】X 浏览器专业版(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.zui.browser"; then
                    log "【面具类子菜单】检测到 ZUI 浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.zui.browser >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】ZUI 浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.zui.browser/.BrowserActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】ZUI 浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.heytap.browser"; then
                    log "【面具类子菜单】检测到 OPPO 浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.heytap.browser >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        opened=1
                        log "【面具类子菜单】OPPO 浏览器打开成功"
                    else
                        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.heytap.browser/.BrowserActivity >/dev/null 2>&1
                        [ $? -eq 0 ] && opened=1 && log "【面具类子菜单】OPPO 浏览器(备用)打开成功"
                    fi
                fi
                
                if [ $opened -eq 0 ]; then
                    log "【面具类子菜单】使用系统默认浏览器"
                    am start -a android.intent.action.VIEW -d "$TARGET_URL" >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        log "【面具类子菜单】默认浏览器打开成功"
                    else
                        log "【面具类子菜单】所有浏览器打开失败"
                    fi
                fi
                
                echo -e "\n${fg_gray}已尝试打开链接，按回车返回${reset}"
                read -r
                ;;
            0)
                log "【面具类子菜单】用户选择: 0 - 返回"
                return 0
                ;;
            *)
                if [ -n "$key" ]; then
                    echo -e "\n${fg_red}输入错误，请重新选择！${reset}"
                    sleep 1
                fi
                ;;
        esac
    done
}

# ---------- 显示官方链接子菜单 ----------
show_sub_menu() {
    clear
    echo -e "\n${accent_blue}◆ 官方链接${reset}\n"
    echo -e "${fg_gray}  ─────────────────────────────────────────────────────${reset}"
    echo -e "  ${fg_purple}不是很多，但后续还会加${reset}"
    echo ""
    echo -e "  ${fg_purple}▸ 1${reset}  🌐 MT管理器官方链接       ${fg_purple}▸ 5${reset} 🌐 面具类"
    echo -e "  ${fg_purple}▸ 2${reset}  🌐 Scene官方链接"
    echo -e "  ${fg_purple}▸ 3${reset}  🌐 Via浏览器官方链接"
    echo -e "  ${fg_purple}▸ 4${reset}  🌐 殇痕画质助手官方链接"
    echo ""
    echo -e "${fg_gray}  ─────────────────────────────────────────────────────${reset}"
    echo -e "  ${fg_red}▸ 0${reset}  返回主菜单"
    echo ""
    echo -e "${fg_gray}  ─────────────────────────────────────────────────────${reset}"
    echo -ne "${fg_white}  编号：${reset}"
}

# ---------- 子菜单循环 ----------
sub_menu_loop() {
    while true; do
        show_sub_menu
        read key 2>/dev/null
        echo -e "${reset}"
        case "$key" in
            1) 
                log "【子菜单】用户选择: 1 - 打开MT管理器链接"
                menu_open_browser_link "http://mt2.cn/"
                ;;
            2) 
                log "【子菜单】用户选择: 2 - 打开Scene链接"
                menu_open_browser_link "https://omarea.com/#/"
                ;;
            3) 
                log "【子菜单】用户选择: 3 - 打开Via浏览器链接"
                menu_open_browser_link "https://viayoo.com/zh-cn/"
                ;;
            4) 
                log "【子菜单】用户选择: 4 - 打开殇痕画质助手链接"
                menu_open_browser_link "http://scartool.cn/"
                ;;
            5) 
                log "【子菜单】用户选择: 5 - 进入ksu子菜单"
                menu_ksu_sub
                ;;
            0) 
                log "【子菜单】用户选择: 0 - 返回主菜单"
                return 0 
                ;;
            *) 
                if [ -n "$key" ]; then
                    log "【子菜单】用户输入错误: $key"
                    echo -e "\n${fg_red}输入错误，请重新选择！${reset}"
                    sleep 1
                fi 
                ;;
        esac
    done
}

# ---------- 功能6：批量创建 ----------
menu_option6() {
    (
        exec </dev/tty >/dev/tty 2>/dev/tty
        
        while true; do
            clear
            echo -e "\n${accent_blue}◆ 批量创建${reset}\n"
            echo -e "${fg_gray}  ─────────────────────────────────────────${reset}"
            echo ""
            echo -e "  ${fg_gray}▸ 1${reset}  批量创建sh文件"
            echo -e "  ${fg_gray}▸ 2${reset}  批量创建txt文件"
            echo -e "  ${fg_gray}▸ 3${reset}  批量创建json文件"
            echo -e "  ${fg_gray}▸ 4${reset}  批量创建无后缀文件"
            echo -e "  ${fg_gray}▸ 5${reset}  创建文件夹"
            echo -e "${fg_gray}  ─────────────────────────────────────────${reset}"
            echo -e "  ${fg_gray}▸ 0${reset}  返回主菜单"
            echo -e "${fg_gray}  ─────────────────────────────────────────${reset}"
            echo -ne "${fg_white}  编号：${reset}"
            
            read choice 2>/dev/null
            
            case $choice in
                1)
                    while true; do
                        clear
                        echo -e "\n${accent_green}◆ 批量创建sh文件${reset}\n"
                        echo -e "${fg_gray}  ─────────────────────────────────────────${reset}"
                        
                        echo -e " ${fg_yellow}请输入要创建的sh文件数量（从1开始）：${reset}"
                        echo -e " ${fg_gray}输入 0 返回子菜单${reset}"
                        read count
                        
                        if [ "$count" = "0" ]; then
                            break
                        fi
                        
                        if ! [[ "$count" =~ ^[0-9]+$ ]] || [ "$count" -lt 1 ]; then
                            echo -e " ${fg_red}❌ 请输入有效的正整数！${reset}"
                            wait_return
                            continue
                        fi
                        
                        echo -e " ${fg_cyan}开始创建 1 到 ${count}.sh 共 ${count} 个文件...${reset}"
                        echo ""
                        
                        local created=0
                        local skipped=0
                        
                        for ((i=1; i<=count; i++)); do
                            filename="${i}.sh"
                            
                            if [ ! -f "$filename" ]; then
                                cat > "$filename" << 'EOF'                           
# 作者: MXX
# 创建日期: $(date +"%Y-%m-%d %H:%M:%S")

#!/system/bin/sh

EOF
                                sed -i "s/\$(date +\"%Y-%m-%d %H:%M:%S\")/$(date +"%Y-%m-%d %H:%M:%S")/g" "$filename"
                                sed -i "s/\\\$i/$i/g" "$filename"
                                chmod +x "$filename"
                                echo -e " ${fg_green}✅ 创建:${reset} $filename"
                                ((created++))
                            else
                                echo -e " ${fg_yellow}⏭️ 跳过:${reset} $filename"
                                ((skipped++))
                            fi
                        done
                        
                        echo ""
                        echo -e " ${fg_green}🎉 完成！${reset}"
                        echo -e " ${fg_cyan}📊 统计信息:${reset}"
                        echo -e "   ${fg_green}创建:${reset} $created 个文件"
                        echo -e "   ${fg_yellow}跳过:${reset} $skipped 个文件"
                        echo -e "   ${fg_gray}📁 位置: $(pwd)${reset}"
                        
                        wait_return
                    done
                    ;;
                2)
                    while true; do
                        clear
                        echo -e "\n${accent_green}◆ 批量创建txt文件${reset}\n"
                        echo -e "${fg_gray}  ─────────────────────────────────────────${reset}"
                        
                        echo -e " ${fg_yellow}请输入要创建的txt文件数量（从1开始）：${reset}"
                        echo -e " ${fg_gray}输入 0 返回子菜单${reset}"
                        read count
                        
                        if [ "$count" = "0" ]; then
                            break
                        fi
                        
                        if ! [[ "$count" =~ ^[0-9]+$ ]] || [ "$count" -lt 1 ]; then
                            echo -e " ${fg_red}❌ 请输入有效的正整数！${reset}"
                            wait_return
                            continue
                        fi
                        
                        echo -e " ${fg_cyan}开始创建 1 到 ${count}.txt 共 ${count} 个文件...${reset}"
                        echo ""
                        
                        local created=0
                        local skipped=0
                        
                        for ((i=1; i<=count; i++)); do
                            filename="${i}.txt"
                            
                            if [ ! -f "$filename" ]; then
                                cat > "$filename" << EOF
# 作者: MXX
# 创建日期: $(date +"%Y-%m-%d %H:%M:%S")

EOF
                                echo -e " ${fg_green}✅ 创建:${reset} $filename"
                                ((created++))
                            else
                                echo -e " ${fg_yellow}⏭️ 跳过:${reset} $filename"
                                ((skipped++))
                            fi
                        done
                        
                        echo ""
                        echo -e " ${fg_green}🎉 完成！${reset}"
                        echo -e " ${fg_cyan}📊 统计信息:${reset}"
                        echo -e "   ${fg_green}创建:${reset} $created 个文件"
                        echo -e "   ${fg_yellow}跳过:${reset} $skipped 个文件"
                        echo -e "   ${fg_gray}📁 位置: $(pwd)${reset}"
                        
                        wait_return
                    done
                    ;;
                3)
                    while true; do
                        clear
                        echo -e "\n${accent_green}◆ 批量创建json文件${reset}\n"
                        echo -e "${fg_gray}  ─────────────────────────────────────────${reset}"
                        
                        echo -e " ${fg_yellow}请输入要创建的json文件数量（从1开始）：${reset}"
                        echo -e " ${fg_gray}输入 0 返回子菜单${reset}"
                        read count
                        
                        if [ "$count" = "0" ]; then
                            break
                        fi
                        
                        if ! [[ "$count" =~ ^[0-9]+$ ]] || [ "$count" -lt 1 ]; then
                            echo -e " ${fg_red}❌ 请输入有效的正整数！${reset}"
                            wait_return
                            continue
                        fi
                        
                        echo -e " ${fg_cyan}开始创建 1 到 ${count}.json 共 ${count} 个文件...${reset}"
                        echo ""
                        
                        local created=0
                        local skipped=0
                        
                        for ((i=1; i<=count; i++)); do
                            filename="${i}.json"
                            
                            if [ ! -f "$filename" ]; then
                                cat > "$filename" << EOF
{
  "作者": "MXX",
  "创建时间": "$(date +"%Y-%m-%d %H:%M:%S")"
}
EOF
                                echo -e " ${fg_green}✅ 创建:${reset} $filename"
                                ((created++))
                            else
                                echo -e " ${fg_yellow}⏭️ 跳过:${reset} $filename"
                                ((skipped++))
                            fi
                        done
                        
                        echo ""
                        echo -e " ${fg_green}🎉 完成！${reset}"
                        echo -e " ${fg_cyan}📊 统计信息:${reset}"
                        echo -e "   ${fg_green}创建:${reset} $created 个文件"
                        echo -e "   ${fg_yellow}跳过:${reset} $skipped 个文件"
                        echo -e "   ${fg_gray}📁 位置: $(pwd)${reset}"
                        
                        wait_return
                    done
                    ;;
                4)
                    while true; do
                        clear
                        echo -e "\n${accent_green}◆ 批量创建无后缀文件${reset}\n"
                        echo -e "${fg_gray}  ─────────────────────────────────────────${reset}"
                        
                        echo -e " ${fg_yellow}请输入要创建的无后缀文件数量（从1开始）：${reset}"
                        echo -e " ${fg_gray}输入 0 返回子菜单${reset}"
                        read count
                        
                        if [ "$count" = "0" ]; then
                            break
                        fi
                        
                        if ! [[ "$count" =~ ^[0-9]+$ ]] || [ "$count" -lt 1 ]; then
                            echo -e " ${fg_red}❌ 请输入有效的正整数！${reset}"
                            wait_return
                            continue
                        fi
                        
                        echo -e " ${fg_cyan}开始创建 1 到 ${count} 共 ${count} 个无后缀文件...${reset}"
                        echo ""
                        
                        local created=0
                        local skipped=0
                        
                        for ((i=1; i<=count; i++)); do
                            filename="${i}"
                            
                            if [ ! -f "$filename" ]; then
                                cat > "$filename" << EOF
# 作者: MXX
# 创建日期: $(date +"%Y-%m-%d %H:%M:%S")

EOF
                                chmod +x "$filename" 2>/dev/null
                                echo -e " ${fg_green}✅ 创建:${reset} $filename"
                                ((created++))
                            else
                                echo -e " ${fg_yellow}⏭️ 跳过:${reset} $filename"
                                ((skipped++))
                            fi
                        done
                        
                        echo ""
                        echo -e " ${fg_green}🎉 完成！${reset}"
                        echo -e " ${fg_cyan}📊 统计信息:${reset}"
                        echo -e "   ${fg_green}创建:${reset} $created 个文件"
                        echo -e "   ${fg_yellow}跳过:${reset} $skipped 个文件"
                        echo -e "   ${fg_gray}📁 位置: $(pwd)${reset}"
                        
                        wait_return
                    done
                    ;;
                5)
                    while true; do
                        clear
                        echo -e "\n${accent_green}◆ 创建文件夹${reset}\n"
                        echo -e "${fg_gray}  ─────────────────────────────────────────${reset}"
                        
                        echo -e " ${fg_cyan}选择目录：${reset}"
                        echo -e "  ${fg_gray}1${reset}  /storage/emulated/0/"
                        echo -e "  ${fg_gray}2${reset}  /data/"
                        echo -e "  ${fg_gray}3${reset}  /data/adb/"
                        echo -e "  ${fg_gray}4${reset}  自定义"
                        echo -e "  ${fg_gray}0${reset}  返回子菜单"
                        echo -e "${fg_gray}  ─────────────────────────────────────────${reset}"
                        echo -ne " ${fg_white}编号：${reset}"
                        read dir_choice
                        
                        if [ "$dir_choice" = "0" ]; then
                            break
                        fi
                        
                        case $dir_choice in
                            1) BASE_DIR="/storage/emulated/0/" ;;
                            2) BASE_DIR="/data/" ;;
                            3) BASE_DIR="/data/adb/" ;;
                            4)
                                echo -ne " ${fg_white}路径：${reset}"
                                read BASE_DIR
                                if [ -z "$BASE_DIR" ]; then
                                    echo -e " ${fg_red}❌ 路径不能为空！${reset}"
                                    wait_return
                                    continue
                                fi
                                ;;
                            *)
                                echo -e " ${fg_red}❌ 无效选项！${reset}"
                                wait_return
                                continue
                                ;;
                        esac
                        
                        if [ ! -d "$BASE_DIR" ]; then
                            echo -e " ${fg_red}❌ 目录不存在：$BASE_DIR${reset}"
                            wait_return
                            continue
                        fi
                        
                        echo -ne " ${fg_white}文件夹名：${reset}"
                        read FOLDER_NAME
                        
                        if [ -z "$FOLDER_NAME" ]; then
                            echo -e " ${fg_red}❌ 名称不能为空！${reset}"
                            wait_return
                            continue
                        fi
                        
                        FULL_PATH="${BASE_DIR}${FOLDER_NAME}"
                        if [ ! -d "$FULL_PATH" ]; then
                            mkdir -p "$FULL_PATH"
                            echo -e " ${fg_green}✅ 已创建：$FULL_PATH${reset}"
                            log "【选项六】创建文件夹: $FULL_PATH"
                        else
                            echo -e " ${fg_yellow}⚠️ 已存在：$FULL_PATH${reset}"
                        fi
                        
                        wait_return
                    done
                    ;;
                0)
                    break
                    ;;
                *)
                    if [ -n "$choice" ]; then
                        echo -e "\n${fg_red}输入错误，请重新选择！${reset}"
                        sleep 1
                    fi
                    ;;
            esac
        done
    ) < /dev/tty > /dev/tty 2> /dev/tty
    
    local child_pid=$!
    wait $child_pid 2>/dev/null
}

# ---------- 退出 ----------
func_0() {
    echo -e "${fg_gray}退出${reset}"
    tput cnorm
    exit 0
}

# ---------- 主程序入口 ----------
main() {
    trap 'echo -e "\n${fg_yellow}脚本被中断${reset}"; exit 1' INT TERM
    
    verify_license

    echo -e "${fg_gray}  ─────────────────────────────────────────${reset}"
    check_update "$GITHUB_RAW_URL" "$VERSION"
    local update_status=$?
    if [ $update_status -eq 2 ]; then
        echo -e "${fg_gray}  ─────────────────────────────────────────${reset}"
        echo -e " ${fg_yellow}发现新版本，是否立即更新？              这是另一个👉🏻https://github.com/mvxffd/shell/raw/refs/heads/main/LM%E5%B7%A5%E5%85%B7%E7%AE%B1.sh                       ${reset}"
        echo -e "  ${fg_cyan}1${reset}  立即更新                                                          有兴趣的可以去看一下😁😁😁"                                                                                         
        echo -e "  ${fg_gray}0${reset}  进入主菜单"
        echo -ne " ${fg_white}选择 (1-更新, 0-跳过): ${reset}"
        read choice
        if [ "$choice" = "1" ]; then
            local script_path=$(get_script_path)
            if [ -n "$script_path" ] && [ -f "$script_path" ]; then
                if do_update "$GITHUB_RAW_URL" "$script_path"; then
                    echo -e " ${fg_green}✅ 更新成功，脚本将重启...${reset}"
                    sleep 2
                    exec "$script_path"
                    exit
                else
                    echo -e " ${fg_red}❌ 更新失败，继续进入主菜单${reset}"
                    sleep 2
                fi
            else
                echo -e " ${fg_red}❌ 无法获取脚本路径，更新失败${reset}"
                sleep 2
            fi
        else
            echo -e " ${fg_gray}跳过更新，进入主菜单${reset}"
            sleep 1
        fi
    elif [ $update_status -eq 1 ]; then
        echo -e " ${fg_red}⚠️ 检查更新失败，继续进入主菜单${reset}"
        sleep 2
    else
        echo -e " ${fg_green}✅ 已是最新版本${reset}"
        sleep 1
    fi
    echo -e "${fg_gray}  ─────────────────────────────────────────${reset}"

    while true; do
        draw_menu
        read choice
        case $choice in
            1) menu_europe ;;
            2) menu_device_info ;;
            3) menu_png_batch ;;
            4) menu_update ;;
            5) sub_menu_loop ;;
            6) menu_option6 ;;
            0) func_0 ;;
            *) 
                echo -e "\n${fg_gray}无效，重新选择${reset}"
                sleep 1
                ;;
        esac
    done
}

main "$@"
