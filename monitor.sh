#!/bin/sh
# ===============================
# VPS Monitor Mini v1.0
# vps_moniter_mini - Alpine sh | Compatible version
# 状态变化（在线↔掉线）或 IP 变化才通知
# 状态文件默认存在monitor.sh所在文件夹内
# ===============================

CONFIG_FILE="$(dirname "$0")/config.sh"
[ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE" || { echo "config.sh 未找到"; exit 1; }

STATE_FILE="$(dirname "$0")/monitor_mini.state"

send_tg() {
    text="$1"
    curl -s -X POST "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" \
         -d chat_id="${TG_CHAT_ID}" \
         -d text="$text" \
         -d parse_mode="HTML" >/dev/null 2>&1
}

# 确保状态文件存在
[ -f "$STATE_FILE" ] || touch "$STATE_FILE"

# 循环每行服务器
echo "$servers" | while IFS= read -r entry; do
    [ -z "$entry" ] && continue  # 跳过空行

    name="${entry%%|*}"
    target="${entry##*|}"

    # Ping 测试
    if ping -c 1 -W 3 "$target" >/dev/null 2>&1; then
        status="online"
    else
        status="offline"
    fi

    # 获取上次状态和 IP
    prev_status=$(grep "^$target.status=" "$STATE_FILE" | cut -d'=' -f2)
    prev_ip=$(grep "^$target.ip=" "$STATE_FILE" | cut -d'=' -f2)

    # 获取当前 IP（仅域名解析有效）
    if echo "$target" | grep -q '[a-zA-Z]'; then
        ip_now=$(ping -c1 "$target" | head -1 | awk -F'[()]' '{print $2}')
        [ -z "$ip_now" ] && ip_now="unknown"
    else
        ip_now="$target"
    fi

    # 状态变化通知
    if [ "$status" != "$prev_status" ]; then
        if [ "$status" = "offline" ]; then
            send_tg "🚨 <b>$name</b> ($target) 掉线！"
        else
            send_tg "✅ <b>$name</b> ($target) 上线！"
        fi
    fi

    # IP 变化通知
    if [ "$ip_now" != "$prev_ip" ] && [ -n "$prev_ip" ]; then
        send_tg "⚠️ <b>$name</b> ($target) IP 变化：$prev_ip → $ip_now"
    fi

    # 更新状态文件
    grep -v "^$target\." "$STATE_FILE" > "$STATE_FILE.tmp" 2>/dev/null || true
    echo "$target.status=$status" >> "$STATE_FILE.tmp"
    echo "$target.ip=$ip_now" >> "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"
done
