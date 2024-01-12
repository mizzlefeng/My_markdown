# nn.ModuleList和nn.Sequential
nn.Sequential内部实现了forward函数，因此可以不用写forward函数，而nn.ModuleList则没有实现内部forward函数。
nn.Sequential可以使用OrderedDict对每层进行命名。
nn.Sequential里面的模块按照顺序进行排列的，所以必须确保前一个模块的输出大小和下一个模块的输入大小是一致的。而nn.ModuleList 并没有定义一个网络，它只是将不同的模块储存在一起，这些模块之间并没有什么先后顺序可言。
<!--stackedit_data:
eyJoaXN0b3J5IjpbLTE2ODMxMDI1NDVdfQ==
-->