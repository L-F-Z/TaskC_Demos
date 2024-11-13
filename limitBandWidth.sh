#!/bin/bash

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  echo "请以 root 权限运行此脚本。使用 sudo ./limitbandwidth.sh <带宽>"
  exit 1
fi

# 检查是否提供带宽参数
if [ -z "$1" ]; then
  echo "用法: $0 <带宽_in_Mbit>"
  echo "示例: $0 500"
  exit 1
fi

BANDWIDTH=$1
INTERFACE="eth0"  # 根据实际情况修改

echo "开始设置 ${INTERFACE} 的带宽限制为 ${BANDWIDTH} Mbit/s"

# 删除现有的 qdisc
echo "删除现有的 qdisc..."
tc qdisc del dev $INTERFACE root 2>/dev/null
tc qdisc del dev $INTERFACE ingress 2>/dev/null

# 添加新的 HTB qdisc
echo "添加 HTB qdisc..."
tc qdisc add dev $INTERFACE root handle 1: htb default 10

# 添加主类 1:1，设置为 1Gbit
echo "添加主类 1:1..."
tc class add dev $INTERFACE parent 1: classid 1:1 htb rate 1gbit ceil 1gbit

# 添加子类 1:10，设置为指定的带宽
echo "添加子类 1:10..."
tc class add dev $INTERFACE parent 1:1 classid 1:10 htb rate ${BANDWIDTH}mbit ceil ${BANDWIDTH}mbit

# 添加过滤器，将所有流量导向子类 1:10
echo "添加过滤器..."
tc filter add dev $INTERFACE protocol ip parent 1:0 prio 1 u32 match ip dst 0.0.0.0/0 flowid 1:10

# 显示当前配置
echo "当前 ${INTERFACE} 的 tc 配置："
tc qdisc show dev $INTERFACE
tc class show dev $INTERFACE
tc filter show dev $INTERFACE

echo "带宽限制已成功设置为 ${BANDWIDTH} Mbit/s"
