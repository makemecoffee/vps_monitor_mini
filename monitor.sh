#!/bin/sh
# ===============================
# VPS Monitor Mini v1.0
# vps_moniter_mini - Alpine sh | Compatible version
# status change（online↔offline）and IP change will be messange in TG_bot
# status file save in monitor._mini
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

# make sure status file
[ -f "$STATE_FILE" ] || touch "$STATE_FILE"

# circle find vps
echo "$servers" | while IFS= read -r entry; do
    [ -z "$entry" ] && continue  

    name="${entry%%|*}"
    target="${entry##*|}"

    # ping test
    if ping -c 1 -W 3 "$target" >/dev/null 2>&1; then
        status="online"
    else
        status="offline"
    fi

    # get pre status and IP
    prev_status=$(grep "^$target.status=" "$STATE_FILE" | cut -d'=' -f2)
    prev_ip=$(grep "^$target.ip=" "$STATE_FILE" | cut -d'=' -f2)

    # get current IP（only domain effect）
    if echo "$target" | grep -q '[a-zA-Z]'; then
        ip_now=$(ping -c1 "$target" | head -1 | awk -F'[()]' '{print $2}')
        [ -z "$ip_now" ] && ip_now="unknown"
    else
        ip_now="$target"
    fi

    # status change message
    if [ "$status" != "$prev_status" ]; then
        if [ "$status" = "offline" ]; then
            send_tg "🚨 <b>$name</b> ($target) 掉线！"
        else
            send_tg "✅ <b>$name</b> ($target) 上线！"
        fi
    fi

    # IP change message
    if [ "$ip_now" != "$prev_ip" ] && [ -n "$prev_ip" ]; then
        send_tg "⚠️ <b>$name</b> ($target) IP 变化：$prev_ip → $ip_now"
    fi

    # update status file
    grep -v "^$target\." "$STATE_FILE" > "$STATE_FILE.tmp" 2>/dev/null || true
    echo "$target.status=$status" >> "$STATE_FILE.tmp"
    echo "$target.ip=$ip_now" >> "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"
done
