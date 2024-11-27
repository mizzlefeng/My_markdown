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

# 常见设置

## vscode调试当前文件

```shell
"cwd":"${fileDirname}" # 设置为当前文件目录，用于直接调试
"cwd": "${workspaceFolder}" # 设置为根目录，用于命令行调试
"args": ["train","lora_sft.yaml"] # 用于带参数调试
```

## vscode隐藏.开头文件夹和文件

1. 按下Ctrl + ,快捷键打开设置。您也可以点击屏幕左下角的齿轮图标，然后选择“Settings”。
2. 在设置搜索框中，键入files.exclude。
3. 在找到的Files: Exclude项中，点击Add Pattern按钮来添加一个新的模式，或者直接在搜索结果的设置区域进行编辑。
4. 在输入框中输入**/.*，这是一个glob模式，意味着匹配任何目录下以点开始的文件或文件夹。
5. 勾选旁边的框以启用此隐藏模式。

