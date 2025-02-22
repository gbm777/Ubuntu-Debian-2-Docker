#!/bin/bash
set -eo pipefail

# 内存保护机制
export XZ_DEFAULTS="-T0 --memlimit-compress=80%"  # 限制xz内存使用

# 增强型排除列表（精确到内核模块路径）
EXCLUDE_PATHS=(
    "/proc" "/sys" "/dev" "/tmp" "/run" "/mnt" "/media"
    "/var/cache" "/var/run" "/var/lock" "/lost+found"
    "/sys/module/*"  # 使用通配符排除所有内核模块
    "/sys/firmware"
    "/sys/fs/cgroup"
    "/sys/kernel/*"  # 排除所有内核调试和安全相关
    "/sys/devices/virtual"
    "/sys/class/*/device"  # 排除硬件设备链接
    "/sys/power"
    "/sys/hypervisor"
)

# 转换排除参数
tar_excludes=()
for path in "${EXCLUDE_PATHS[@]}"; do
    tar_excludes+=( "--exclude=$path" )
done

# 安全计算模式
echo "[进度] 正在计算需要打包的数据量..."
TOTAL_SIZE=$(sudo du -sbx / "${tar_excludes[@]}" 2>/dev/null | awk '{sum+=$1} END{print sum}')

# 输出文件配置
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="ubuntu_system_${TIMESTAMP}.tar.xz"

# 安全打包流程
{
    echo "[步骤1/2] 系统打包 (预计耗时: $((TOTAL_SIZE/15000000))秒)" >&2
    sudo tar -cpPf - / "${tar_excludes[@]}" \
        --warning=no-file-changed \
        --ignore-failed-read \
        --no-recursion \
        --exclude-backups \
        | pv -s "$TOTAL_SIZE" -N "打包进度" -f

    echo -e "\n[步骤2/2] 内存优化压缩 (最大使用80%内存)" >&2
} | (
    # 创建安全管道
    mkfifo xz_pipe
    trap 'rm -f xz_pipe' EXIT

    # 启动压缩进程
    xz -T0 -7e --verbose -c > "$OUTPUT_FILE" 2>xz_pipe &
    
    # 进度监控
    awk '/%/ {printf "%.2f\n", $4 * 100}' xz_pipe \
        | pv -s "$TOTAL_SIZE" -N "压缩进度" -ltr &
    
    wait
)

# 结果验证
echo -e "\n[完成] 生成文件信息:"
ls -lh "$OUTPUT_FILE"
echo "SHA256校验: $(sha256sum "$OUTPUT_FILE" | cut -d' ' -f1)"
echo "Docker导入命令: docker import $OUTPUT_FILE ubuntu:custom"