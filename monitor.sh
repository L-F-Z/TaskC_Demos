#!/bin/bash

# 资源监控脚本，记录指定 scope 的 CPU 和内存使用情况
# 使用方式: sudo ./monitor_docker.sh <scope_name>

# 参数
scope=$1

# 检查参数
if [[ -z "$scope" ]]; then
  echo "用法: $0 <scope_name>"
  echo "示例: $0 docker_limited.scope"
  exit 1
fi

# 确定 cgroup 路径
CGROUP_PATH="/sys/fs/cgroup/system.slice/${scope}"
LOG_FILE="${scope}.log"
INTERVAL=3  # 采样间隔 (秒)

# 检查 cgroup 路径是否存在
if [[ ! -d "$CGROUP_PATH" ]]; then
  echo "错误: cgroup 路径不存在或不是目录: $CGROUP_PATH"
  exit 1
fi

# 检查必要的 cgroup 文件
if [[ ! -f "${CGROUP_PATH}/cpu.stat" || ! -f "${CGROUP_PATH}/cpu.max" || ! -f "${CGROUP_PATH}/memory.current" ]]; then
  echo "错误: cgroup 路径下缺少必要文件(cpu.stat, cpu.max, memory.current)"
  exit 1
fi

# 初始化日志文件
if [[ ! -f "$LOG_FILE" ]]; then
  echo "timestamp,cpu_usage(%),memory_usage(MB)" > "$LOG_FILE"
fi

# 读取初始 CPU 统计
cpu_usage_total_prev=$(grep "usage_usec" "${CGROUP_PATH}/cpu.stat" | awk '{print $2}')
read cpu_quota cpu_period < "${CGROUP_PATH}/cpu.max"

# 处理 cpu_period
if [[ -z "$cpu_period" || "$cpu_period" == "max" ]]; then
  cpu_period=1000000  # 默认周期为 1 秒
else
  if ! [[ "$cpu_period" =~ ^[0-9]+$ ]]; then
    cpu_period=1000000
  fi
fi

# 捕获中断信号以优雅退出
trap "echo '收到终止信号，退出监控。'; exit 0" SIGINT SIGTERM

# 监控循环
while true; do
  TIMESTAMP=$(date +%s)

  # 读取并计算 CPU 使用百分比
  cpu_usage_total_now=$(grep "usage_usec" "${CGROUP_PATH}/cpu.stat" | awk '{print $2}')
  cpu_usage_diff=$((cpu_usage_total_now - cpu_usage_total_prev))

  if [[ "$cpu_usage_diff" -lt 0 ]]; then
    cpu_usage_diff=0
  fi

  cpu_usage_percent=$(awk "BEGIN {printf \"%.2f\", ($cpu_usage_diff / $cpu_period) * 100}")
  cpu_usage_total_prev=$cpu_usage_total_now

  # 读取内存使用情况 (字节)
  memory_usage_bytes=$(cat "${CGROUP_PATH}/memory.current")
  memory_usage_mb=$(awk "BEGIN {printf \"%.2f\", $memory_usage_bytes / 1024 / 1024}")

  # 记录到日志
  echo "${TIMESTAMP},${cpu_usage_percent},${memory_usage_mb}" >> "$LOG_FILE"

  # 检查服务是否仍在运行
  if ! systemctl is-active --quiet "${scope}"; then
    echo "[$TIMESTAMP] 服务已停止，终止监控。" | tee -a "$LOG_FILE"
    break
  fi

  sleep "$INTERVAL"
done
