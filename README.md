# Ubuntu-Debian-2-Docker
Build customs linux system to docker tars


v1 See branches.

脚本目的：

将Ubuntu等linux系统打包成自定义的docker镜像tar包，本脚本使用tar.xz压缩格式。 建议在排除文件夹中运行。

脚本特性:

可视化进度提示 新增旋转指针动画，在计算数据量时显示：
使用du替代find，速度提升10-100倍
将计算过程放到后台子shell，避免阻塞主线程
结果暂存到/tmp/data_size文件
排除路径兼容性
单独为du和tar生成排除参数：
该版本通过以下方式确保稳定性：

使用du替代find提升计算速度
后台计算+旋转指针避免假死现象
显式删除临时文件防止残留
统一排除参数保证数据一致性
导入命令：

docker import ubuntu_system_**********.tar.xz ubuntu:custom （按实际填写）
