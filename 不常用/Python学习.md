

# Deep Learning

## nn.ModuleList和nn.Sequential

 - nn.Sequential内部实现了forward函数，因此可以不用写forward函数，而nn.ModuleList则没有实现内部forward函数。
 - nn.Sequential可以使用OrderedDict对每层进行命名。
 -  nn.Sequential里面的模块按照顺序进行排列的，所以必须确保前一个模块的输出大小和下一个模块的输入大小是一致的。而nn.ModuleList并没有定义一个网络，它只是将不同的模块储存在一起，这些模块之间并没有什么先后顺序可言。

### nn.ModuleList
不同于一般的list，加入到nn.ModuleList里面的module是会自动注册到整个网络上的，同时module的parameters也会自动添加到整个网络中。
### 忠告
如果确定 nn.Sequential 里面的顺序是你想要的，而且不需要再添加一些其他处理的函数 (比如 nn.functional 里面的函数 )，那么完全可以直接用 nn.Sequential。这么做的代价就是失去了**部分灵活性**，毕竟不能自己去定制 forward 函数里面的内容了。

## nn.Embedding

```python
import torch
from torch import nn
 
# 创建最大词个数为10，每个词用维度为4表示
embedding = nn.Embedding(10, 4)
 
# 将第一个句子填充0，与第二个句子长度对齐
in_vector = torch.LongTensor([[1, 2, 3, 4, 0, 0], [1, 2, 5, 6, 5, 7]])
out_emb = embedding(in_vector)
print(in_vector.shape)
print((out_emb.shape))
print(out_emb)
print(embedding.weight)
```

为什么输入向量是2乘6的矩阵，而embedding的权重是10乘4的，还可以进行embedding？

在PyTorch中，`nn.Embedding`类是用来将离散的数字（通常用来表示词语或者其它类型的标记）转换成向量的。这些数字每一个都对应于嵌入矩阵中的一行。嵌入矩阵的行数代表可嵌入的最大词汇量，而每一行的维度代表了嵌入向量的维度。

当你创建一个嵌入层 `nn.Embedding(10, 4)`时，你告诉PyTorch你想要一个能够嵌入最多10个不同的词的矩阵，每一个词被表示为一个4维的向量。这就是为什么嵌入的权重大小是10乘4的原因——你有10个可能的输入词，每个词被转换为一个4维的嵌入向量。

在这个例子中，你有两个句子，每个句子由6个词的索引组成。这些索引用来从嵌入矩阵中选取相应的向量。因此，尽管你的输入矩阵是2乘6的，每个索引都会被转换成一个4维的向量，所以输出的嵌入向量的维度将会是2乘6乘4。这里的2代表句子数量，6代表每个句子的词数，4代表每个嵌入向量的维度。

**嵌入操作实际上是在做索引操作：它查看输入的索引，并从嵌入矩阵中选取对应行的向量。这就是为什么即使输入向量的维度和嵌入矩阵的维度不直接相关，嵌入操作仍然可以工作的原因。**

**注：embeddings中的值是正态分布N(0,1)中随机取值。**

索引操作！！！！！！！！！

```python
torch.Size([2, 6])
torch.Size([2, 6, 4])
tensor([[[-0.6642, -0.6263,  1.2333, -0.6055],
         [ 0.9950, -0.2912,  1.0008,  0.1202],
         [ 1.2501,  0.1923,  0.5791, -1.4586],
         [-0.6935,  2.1906,  1.0595,  0.2089],
         [ 0.7359, -0.1194, -0.2195,  0.9161],
         [ 0.7359, -0.1194, -0.2195,  0.9161]],
 
        [[-0.6642, -0.6263,  1.2333, -0.6055],
         [ 0.9950, -0.2912,  1.0008,  0.1202],
         [-0.3216,  1.2407,  0.2542,  0.8630],
         [ 0.6886, -0.6119,  1.5270,  0.1228],
         [-0.3216,  1.2407,  0.2542,  0.8630],
         [ 0.0048,  1.8500,  1.4381,  0.3675]]], grad_fn=<EmbeddingBackward0>)
Parameter containing:
tensor([[ 0.7359, -0.1194, -0.2195,  0.9161],
        [-0.6642, -0.6263,  1.2333, -0.6055],
        [ 0.9950, -0.2912,  1.0008,  0.1202],
        [ 1.2501,  0.1923,  0.5791, -1.4586],
        [-0.6935,  2.1906,  1.0595,  0.2089],
        [-0.3216,  1.2407,  0.2542,  0.8630],
        [ 0.6886, -0.6119,  1.5270,  0.1228],
        [ 0.0048,  1.8500,  1.4381,  0.3675],
        [ 0.3810, -0.7594, -0.1821,  0.5859],
        [-1.4029,  1.2243,  0.0374, -1.0549]], requires_grad=True)
```

## torch.einsum

爱因斯坦求和约定

爱因斯坦求和约定（einsum）提供了一套既简洁又优雅的规则，可实现包括但不限于：向量内积，向量外积，矩阵乘法，转置和张量收缩（tensor contraction）等张量操作，熟练运用 einsum 可以很方便的实现复杂的张量操作，而且不容易出错。

```python
a = torch.rand(2,3)
b = torch.rand(3,4)
c = torch.einsum("ik,kj->ij", [a, b])
# 等价操作 torch.mm(a, b)
```

其中需要重点关注的是 einsum 的第一个参数 "ik,kj->ij"，该字符串（下文以 equation 表示）表示了输入和输出张量的维度。equation 中的箭头左边表示输入张量，以逗号分割每个输入张量，箭头右边则表示输出张量。表示维度的字符只能是26个英文字母 'a' - 'z'。

而 einsum 的第二个参数表示实际的输入张量列表，其数量要与 equation 中的输入数量对应。同时对应每个张量的 子 equation 的字符个数要与张量的真实维度对应，比如 "ik,kj->ij" 表示输入和输出张量都是两维的。

**理解重点：**

**equation 中的字符也可以理解为索引，就是输出张量的某个位置的值，是怎么从输入张量中得到的，比如上面矩阵乘法的输出 c 的某个点 c[i, j] 的值是通过 a[i, k] 和 b[k, j] 沿着 k 这个维度做内积得到的。**equation 箭头左边，在不同输入之间重复出现的索引表示，把输入张量沿着该维度做乘法操作，比如还是以上面矩阵乘法为例， "ik,kj->ij"，k 在输入中重复出现，所以就是把 a 和 b **沿着 k 这个维度作相乘操作**；

![img](D:\python_work\My_markdown\不常用\assets\v2-5ea45c6952b3cb9f13eaf259681dbdfb_720w.webp)

## torch.reshape

改变tensor的shape

view() 与 reshape()从功能上来看，它们的作用是相同的，都是用来重塑 Tensor 的 shape 的。view 只适合对满足连续性条件 (contiguous) 的 Tensor进行操作，而reshape 同时还可以对不满足连续性条件的 Tensor 进行操作，具有更好的鲁棒性。view 能干的 reshape都能干，如果 view 不能干就可以用 reshape 来处理。

所有情况都无脑使用 reshape。

张量存储的底层原理：

![img](D:\python_work\My_markdown\不常用\assets\v2-709633113eeddc572eb4e6efc6a64396_r.jpg)

## contiguous()

本质就是深拷贝，不会影响之前的tensor



**`transpose()后改变元数据`**

```python
x = torch.randn(3, 2)
y = torch.transpose(x, 0, 1)
print("修改前：")
print("x-", x)
print("y-", y)
 
print("\n修改后：")
y[0, 0] = 11
print("x-", x)
print("y-", y)
```

```python
修改前：
x- tensor([[-0.5670, -1.0277],
           [ 0.1981, -1.2250],
           [ 0.8494, -1.4234]])
y- tensor([[-0.5670,  0.1981,  0.8494],
           [-1.0277, -1.2250, -1.4234]])
 
修改后：
x- tensor([[11.0000, -1.0277],
           [ 0.1981, -1.2250],
           [ 0.8494, -1.4234]])
y- tensor([[11.0000,  0.1981,  0.8494],
           [-1.0277, -1.2250, -1.4234]])
```

**改变了y的元素的值的同时，x的元素的值也发生了变化**。

因此可以说，**x是contiguous的**，但**y不是**，因为tensor中数据还是在内存中一块区域里，只是**布局**的问题。**y里面数据布局的方式和从头开始创建一个常规的tensor布局的方式是不一样的。**这个**可能只是python中之前常用的浅拷贝**，**y还是指向x变量所处的位置，只是说记录了transpose这个变化的布局。**

使用contiguous() 

如果想要**断开**这两个**变量之间的依赖**（x本身是contiguous的），就要**使用contiguous()针对x进行变化**，**感觉上就是我们认为的深拷贝**。

 当**调用contiguous()时**，**会强制拷贝一份tensor**，让它的布局和从头创建的一模一样，**但是两个tensor完全没有联系**。

```python
x = torch.randn(3, 2)
y = torch.transpose(x, 0, 1).contiguous()
print("修改前：")
print("x-", x)
print("y-", y)
 
print("\n修改后：")
y[0, 0] = 11
print("x-", x)
print("y-", y)

修改前：
x- tensor([[ 0.9730,  0.8559],
           [ 1.6064,  1.4375],
           [-1.0905,  1.0690]])
y- tensor([[ 0.9730,  1.6064, -1.0905],
           [ 0.8559,  1.4375,  1.0690]])
 
修改后：
x- tensor([[ 0.9730,  0.8559],
           [ 1.6064,  1.4375],
           [-1.0905,  1.0690]])
y- tensor([[11.0000,  1.6064, -1.0905],
           [ 0.8559,  1.4375,  1.0690]])
```

可以看到，当**对y使用了.contiguous()**后，**改变y的值时，x没有任何影响**！

## torch.nn.functional.conv1d

```python
torch.nn.functional.conv1d(input, weight, bias=None, stride=1, padding=0, dilation=1, groups=1) 
```

### 输出维度的计算：

输出维度可以根据一维卷积的公式计算得到：

![image-20240410160931167](D:\python_work\My_markdown\不常用\assets\image-20240410160931167.png)

![image-20240410163032980](D:\python_work\My_markdown\不常用\assets\image-20240410163032980.png)

# 日常使用

## tqdm
tqdm模块是python进度条库

```python
class tqdm(object):
  """
  Decorate an iterable object, returning an iterator which acts exactly
  like the original iterable, but prints a dynamically updating
  progressbar every time a value is requested.
  """

  def __init__(self, iterable=None, desc=None, total=None, leave=False,
               file=sys.stderr, ncols=None, mininterval=0.1,
               maxinterval=10.0, miniters=None, ascii=None,
               disable=False, unit='it', unit_scale=False,
               dynamic_ncols=False, smoothing=0.3, nested=False,
               bar_format=None, initial=0, gui=False):
```

- iterable: 可迭代的对象, 在手动更新时不需要进行设置
- **desc: 字符串, 左边进度条描述文字(前缀)**
- total: 总的项目数
- **leave: bool值, 迭代完成后是否保留进度条**
- ncols（int）：整个输出信息的宽度
- **dynamic_ncols(bool):会在环境中持续改变ncols和nrows**
- file: 输出指向位置, 默认是终端, 一般不需要设置
- ncols: 调整进度条宽度, 默认是根据环境自动调节长度, 如果设置为0, 就没有进度条, 只有输出的信息
- unit: 描述处理项目的文字, 默认是'it', 例如: 100 it/s, 处理照片的话设置为'img' ,则为 100 img/s
- unit_scale: 自动根据国际标准进行项目处理速度单位的换算, 例如 100000 it/s >> 100k it/s

## getattr

**getattr()** 函数用于返回一个对象属性值。

```python
getattr(object, name[, default])
# object -- 对象。
# name -- 字符串，对象属性。
# default -- 默认返回值，如果不提供该参数，在没有对应属性时，将触发 AttributeError。
```

直接访问属性值的例子

```python
>>>class A(object):
...     bar = 1
... 
>>> a = A()
>>> getattr(a, 'bar')        # 获取属性 bar 值
1
>>> getattr(a, 'bar2')       # 属性 bar2 不存在，触发异常
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
AttributeError: 'A' object has no attribute 'bar2'
>>> getattr(a, 'bar2', 3)    # 属性 bar2 不存在，但设置了默认值
3
```

获取对象属性后的返回值可以直接使用那个属性

```python
>>> class A(object):        
...     def set(self, a, b):
...         x = a        
...         a = b        
...         b = x        
...         print a, b   
... 
>>> a = A()                 
>>> c = getattr(a, 'set')
>>> c(a='1', b='2')
2 1
```

