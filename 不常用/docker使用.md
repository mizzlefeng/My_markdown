[Docker最新超详细版教程通俗易懂(基础版) - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/442442997)

```cmd
# 常用命令
docker run 镜像id 新建容器并启动
docker ps 列出所有运行的容器 docker container list
docker rm 容器id 删除指定容器
docker start 容器id #启动容器
docker restart容器id #重启容器
docker stop 容器id #停止当前正在运行的容器
docker kill 容器id #强制停止当前容器

docker logs --help # 查看日志
```

**重启WinNAT服务**：通过停止并重新启动WinNAT服务，可以解决一些临时的网络配置问题或重置网络状态。

```shell
net stop winnat  // 停止WinNAT服务
net start winnat // 重新启动WinNAT服务
```
