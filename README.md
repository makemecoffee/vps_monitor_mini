

# vps_moniter_mini

轻量化的 VPS / 域名在线状态监控脚本，通过 Telegram Bot 通知。

##  功能
- 纯 sh + curl，无依赖
- 多 VPS / 域名检测
- Telegram 掉线/恢复通知
- 适合放在任意 VPS 运行

##  安装使用

### ① 下载项目

```sh
curl -L -o tmp.zip https://github.com/on99darlin/vps_moniter_mini/archive/refs/heads/main.zip && mkdir -p monitor_mini && unzip -q tmp.zip -d monitor_mini && mv monitor_mini/vps_moniter_mini-main/* monitor_mini/ && rm -rf monitor_mini/vps_moniter_mini-main tmp.zip
```

### ② 修改配置文件

```sh
cd monitor_mini
vi config.sh
```

填写你的 Telegram Bot Token 和 Chat ID以及需要监控的VPS

赋予文件执行权利

```
chmod +x monitor.sh
```

### ③ 测试脚本是否生效

```sh
./monitor.sh
```

若Telegram bot收到信息即成功

### ④添加定时任务

```sh
crontab -e
```

在打开的文件最后加上一行，例如每 **5 分钟** 运行一次

```
*/5 * * * * /root/monitor_mini/monitor.sh >/dev/null 2>&1
```

### ⑤查看任务是否生效

查看所有当前定时任务：

```
crontab -l
```

查看 cron 服务运行状态：

- Alpine：

```
rc-service crond status
```

- Debian：

```
systemctl status cron
```

