#!/bin/bash
# 创建XDMA设备免root访问的配置脚本
# 必须以root身份执行

# 定义用户组名（可根据需要修改）
GROUP_NAME="xdma"
UDEV_RULE_FILE="/etc/udev/rules.d/99-xdma-devices.rules"

# 检查root权限
if [ "$(id -u)" != "0" ]; then
    echo "错误：此脚本必须以root身份执行！" >&2
    echo "请使用 'sudo $0' 重新运行"
    exit 1
fi

# 1. 创建用户组
echo "创建用户组: $GROUP_NAME"
getent group "$GROUP_NAME" >/dev/null
if [ $? -eq 0 ]; then
    echo " - 用户组 $GROUP_NAME 已存在，跳过创建"
else
    groupadd "$GROUP_NAME"
    echo " - 用户组 $GROUP_NAME 创建成功"

# 2. 创建udev规则
echo "配置udev规则: $UDEV_RULE_FILE"
cat > "$UDEV_RULE_FILE" << EOF
# 为XDMA设备启用免root访问
SUBSYSTEM=="xdma", GROUP="$GROUP_NAME", MODE="0660"
EOF

# 设置正确的文件权限
chmod 644 "$UDEV_RULE_FILE"
echo " - 规则内容:"
cat "$UDEV_RULE_FILE" | sed 's/^/    /'

# 3. 重新加载udev规则
echo "应用udev设置..."
udevadm control --reload-rules
udevadm trigger --subsystem-match=xdma

echo -e "配置完成！"
fi
