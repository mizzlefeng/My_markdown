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
git remote -v ：列出当前仓库中已配置的远程仓库，并显示它们的 URL
git remote add <remote_name> <remote_url> ：添加一个新的远程仓库。
git remote remove lufei #删除lufei这个远程地址
```
# 常见问题
```
error: src refspec main does not match any
```
**mian** 和 **master**

你可能已经注意到了，在我们每次使用git指令时，git都在一直用蓝色的字提示我们当前处在一个叫**master**的分支
这是git为我们创建的默认分支，而在上述过程中我们完全无视了这一点，我们只关心github上的那个**main**分支
所以原因就是github的仓库中没有**master**这个分支，我们本地的仓库没有**main**分支，那好办，我们将本地仓库的**master**分支改名为**main**分支，它们不就统一了？
```
git branch -m master main
```
可以看到**master**已经被成功改为**main**了
! [rejected] main -> main (non-fast-forward)
这个问题解释起来很简单，还记得我们创建仓库时添加到README和license吗？在github仓库的main分支中有这两个文件，而在我们本地的仓库并没有这两个文件，如果我们执行这次commit，那么可能导致这两个文件丢失。

接下来你有以下几个解决方案：下列代码中的example为远程仓库名称

无视警告，README和license我不要了。
```
git push --force
```
试着合并初始提交与你的提交,这也是我**最推荐的方法**：
```
git fetch example
git merge --allow-unrelated-histories example/main
```


<!--stackedit_data:
eyJoaXN0b3J5IjpbMzMwNDE2NTI5LDE2ODg5MzUyMjEsLTIyND
E5Nzk3NywxNjgyNTU1NzkyLDkxNzM3NzQ2OCwtMjA1ODg4ODUz
XX0=
-->