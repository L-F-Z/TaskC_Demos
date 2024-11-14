#!/bin/bash

name=$1
CGROUP_PATH="/sys/fs/cgroup/${name}"

# 检查 cgroup 路径是否存在
if [ ! -d "$CGROUP_PATH" ]; then
  echo "Cgroup $CGROUP_PATH 不存在。请确认 cgroup 的名称和路径是否正确。"
  exit 1
fi

# 读取初始 CPU 使用量
read_cpu_usage() {
  if grep -q "usage_usec" "$CGROUP_PATH/cpu.stat"; then
    awk '/usage_usec/ {print $2}' "$CGROUP_PATH/cpu.stat"
  elif grep -q "usage_nsec" "$CGROUP_PATH/cpu.stat"; then
    awk '/usage_nsec/ {print $2}' "$CGROUP_PATH/cpu.stat"
  else
    echo "0"
  fi
}

read_procs_list() {
    

}

prev_cpu_usage=$(read_cpu_usage)

echo "开始监控 cgroup: mygroup"
echo "每3秒输出一次 CPU 和内存使用率 (按 Ctrl+C 结束)..."

while true; do
  sleep 3

  # 读取当前 CPU 使用量
  current_cpu_usage=$(read_cpu_usage)
  if [ -z "$current_cpu_usage" ]; then
    echo "无法读取 CPU 使用量。"
    continue
  fi

  # 计算 CPU 使用差值
  cpu_diff=0
  if grep -q "usage_usec" "$CGROUP_PATH/cpu.stat"; then
    cpu_diff=$((current_cpu_usage - prev_cpu_usage))
    cpu_diff_sec=$(echo "scale=3; $cpu_diff / 1000000" | bc)
  elif grep -q "usage_nsec" "$CGROUP_PATH/cpu.stat"; then
    cpu_diff_nsec=$((current_cpu_usage - prev_cpu_usage))
    cpu_diff_sec=$(echo "scale=3; $cpu_diff_nsec / 1000000000" | bc)
  else
    cpu_diff_sec="N/A"
  fi
  prev_cpu_usage=$current_cpu_usage

  # 读取内存使用量
  memory_current=$(cat "$CGROUP_PATH/memory.current" 2>/dev/null)
  memory_max=$(cat "$CGROUP_PATH/memory.max" 2>/dev/null)

  if [ "$memory_max" != "max" ] && [ -n "$memory_max" ]; then
    mem_usage_percent=$(echo "scale=2; ($memory_current / $memory_max) * 100" | bc)
    mem_current_readable=$(numfmt --to=iec --suffix=B "$memory_current")
    mem_max_readable=$(numfmt --to=iec --suffix=B "$memory_max")
    mem_info="$mem_current_readable / $mem_max_readable ($mem_usage_percent%)"
  else
    mem_current_readable=$(numfmt --to=iec --suffix=B "$memory_current")
    mem_info="$mem_current_readable / Unlimited"
  fi

  # 显示监控信息
  echo "----------------------------------------"
  echo "内存使用: $mem_info"
  if [ "$cpu_diff_sec" != "N/A" ]; then
    echo "CPU 使用 (过去3秒): $cpu_diff_sec 秒"
  else
    echo "CPU 使用 (过去3秒): N/A"
  fi
  echo "时间: $(date)"
done