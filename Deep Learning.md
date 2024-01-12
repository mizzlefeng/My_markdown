# nn.ModuleList和nn.Sequential

 - nn.Sequential内部实现了forward函数，因此可以不用写forward函数，而nn.ModuleList则没有实现内部forward函数。
 - nn.Sequential可以使用OrderedDict对每层进行命名。
 -  nn.Sequential里面的模块按照顺序进行排列的，所以必须确保前一个模块的输出大小和下一个模块的输入大小是一致的。而nn.ModuleList并没有定义一个网络，它只是将不同的模块储存在一起，这些模块之间并没有什么先后顺序可言。

## nn.ModuleList
不同于一般的list，加入到nn.ModuleList里面的module是会自动注册到整个网络上的，同时module的parameters也会自动添加到整个网络中。
## 忠告
如果确定 nn.Sequential 里面的顺序是你想要的，而且不需要再添加一些其他处理的函数 (比如 nn.functional 里面的函数 )，那么完全可以直接用 nn.Sequential。这么做的代价就是失去了**部分灵活性**，毕竟不能自己去定制 forward 函数里面的内容了。
<!--stackedit_data:
eyJoaXN0b3J5IjpbOTc4ODk1MzI1XX0=
-->