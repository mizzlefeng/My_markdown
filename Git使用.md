# Git安装

教程：[Git教程 - 廖雪峰的官方网站 (liaoxuefeng.com)](https://www.liaoxuefeng.com/wiki/896043488029600)

下载git，git的官网是：https://git-scm.com/

```cmd
git version # 检查是否安装成功，检查当前版本
```

配置GIT

```cmd
git config --global user.name "mizzle"
git config --global user.email  "838966499@qq.com"
git config --list # 检查是否配置成功
```

# Pycharm中的GIT

注意是在file——>settings中的Git理的cmd文件夹里的git.exe

## git.init

创建仓库

方法一：手动创建目录名 + git init

方法二：git init 目录名

方法三：拷贝一个库，打开GitHub，找到需要的库，点击**clone or download**，复制链接。在pycharm中输入 **git clone + 复制连接 + 目录名**，即可创建库。

```cmd
git init MedFollowUp
git status # 查看库的状态
```

![输入图片说明](/imgs/2024-02-01/ZEiOl9wRt4brKgpQ.png)

## git add & commit

随便新建一个文件并保存

```cmd
git add .
git add *
git add file,txt
# 上述操作将文件保存至暂存区

git commit -m "备注" # 提交暂存的文件并创建一个新的版本历史记录
```

检查保存记录

```cmd
git log
```

## Tips

**注意：内容未显示完整，jk可以上下移动；**

​     **按q是退出。**

## git checkout

```cmd
git checkout +序列号 # 序列号可以用git log查看，jk翻页

```

## 建立远程仓库提交代码

1.pycharm中登陆Github，在版本控制里

2.Git SSH创建Key：

- [x] 打开Git bash
- [x] 输入 cd ~/.ssh/ 若出现“No such file or directory”,则表示需要创建一个ssh keys

输入下面的内容：

```cmd
git config --global user.name "起个名字"
git config --global user.email "你的邮箱"
ssh-keygen -t rsa -C "你的邮箱"  三个连续回车，设置密码为空
```
![输入图片说明](/imgs/2024-02-01/Rq7mjnLSdiq7CJaY.png)

- [x] 在C盘.ssh路径下有id_rsa和id_rsa.pub，使用记事本打开id_rsa.pub复制里面的秘钥
- [x] 打开Github，在Settings中有SSH and GPG keys，选择SSH keys新增。
- [x] 使用ssh -T git@github.com来检测是否添加成功。

![输入图片说明](/imgs/2024-02-01/quy6z7tqF3TyEPFq.png)
然后使用pycharm里的Git进行推送就可以了
```
git push -u origin master
```

<!--stackedit_data:
eyJoaXN0b3J5IjpbMTY4MjU1NTc5Miw5MTczNzc0NjgsLTIwNT
g4ODg1M119
-->