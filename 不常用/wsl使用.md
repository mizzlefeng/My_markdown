# 安装WSL

Windows Subsystem for Linux（简称WSL），Windows下的Linux子系统。

安装方式：

```shell
# 在powershell 管理员模式 启用“虚拟机平台”功能
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# cmd直接进行wsl的安装
wsl --install

# 设置root密码
sudo passwd root

# 检查wsl的版本
wsl -l -v或者wsl --list --verbose
```

查看硬盘驱动器

```cmd
wmic diskdrive list brief
```

