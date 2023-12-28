# 如何让除了登陆节点外的其他节点也可以访问外网

```shell
# 集群内只有登录节点能够访问外网，现在需要让某台计算节点也可以访问外网，可以怎么做呢？
# 答：集群登录节点有一个公网IP，其它节点都是使用局域网的IP，我通过NAT让需要联网的节点数据包都通过公网IP发出去，这样就可以访问外网了，结束之后再还原成初始状态。

# 具体的操作我通过询问chatgpt得到的解决
# 如果集群所有节点都是局域网IP，而登录节点是通过校园网登录的方式才有网络连接，可以考虑在登录节点上启用NAT(Network Address Translation)功能，将登录节点的IP地址转换为校园网的公网IP地址，从而实现其他节点共享登录节点的网络连接。

# 具体实现方法如下：

# 1.在登录节点上安装iptables和ip_forward：
sudo apt-get install iptables
sudo sysctl -w net.ipv4.ip_forward=1

# 2.编辑iptables规则，将登录节点的IP地址转换为校园网公网IP地址：
sudo iptables -t nat -A POSTROUTING -o eno1 -j MASQUERADE
# 其中，eno1是登录节点连接到校园网的网卡名称，可以通过ifconfig命令查看。
# iptables -t nat -D POSTROUTING -o eno1 -j MASQUERADE 这行命令可以删除刚才那条规则

# 3.将iptables规则保存：
sudo sh -c "iptables-save > /etc/iptables.rules"

# 在登录节点启动时加载iptables规则：
sudo iptables-restore < /etc/iptables.rules

# 这样就可以实现登录节点对外网的访问，并让其他节点通过登录节点共享网络连接了。
```

# 如何还原到之前的状态？

```shell
# 使用以下命令列出当前所有 iptables 规则：
sudo iptables -L -n -v --line-numbers

# 找到添加的规则对应的行号，例如：
Chain POSTROUTING (policy ACCEPT 0 packets, 0 bytes)
num   pkts bytes target     prot opt in     out     source               destination         
1       0     0 MASQUERADE  all  --  *      eth0    0.0.0.0/0            0.0.0.0/0           
# 在这个例子中，我们要删除的规则行号是 1。

# 使用以下命令删除对应的规则：
sudo iptables -t nat -D POSTROUTING 1

# 再次使用 sudo iptables -L -n -v --line-numbers 命令确认规则已经被删除。如果规则已经被删除，你应该不再看到添加的规则。
```


<!--stackedit_data:
eyJoaXN0b3J5IjpbLTY2NTMzMzEwMF19
-->