# 基础代码——安装包篇

```r
# 1 在CRAN 存储库的r包
install.packages("xxx")

# 2 在Bioconductor存储库中的r包 首先先安装BioManager,然后从BioManager中安装相应的R包  以SummarizedExperiment为例。
install.packages("BiocManager")
BiocManager::install("SummarizedExperiment")

# 3 在GitHub储存库中r包  首先加载devtools,然后安装相应的R包
library(devtools)
install_github("authorName/repositoryName")
# 或者直接利用devtools安装,以ggplot2举例
devtools::install_github("tidyverse/ggplot2")


# 实战：安装maftools
install.packages("devtools")
BiocManager::install("maftools")
```

# 代码逻辑

## for循环

```r
for (i in list){
    print(i)
}
```

# 常用代码

## 提取数据框data.frame的行名和列名

```r
rownames(data)    # 返回行名
colnames(data)    # 返回列名
# 以上两个函数会将行名和列名以list的形式返回
```

## 分割以点为分隔符的字符串

```r
a="NO.40_T"
strsplit(a,split='[.]') # 注意加[]，相当于正则了
strsplit(a,".",fixed = T)
strsplit(a,"\\.")
```

## 保存图片

```r
# -- 第一种方法 --
# 1. 创建画布
png( 
    filename = "name.png", # 文件名称
    width = 480,           # 宽
    height = 480,          # 高
    units = "px",          # 单位
    bg = "white",          # 背景颜色
    res = 72)              # 分辨率
# 2. 绘图
plot(1:5) 
# 3. 关闭画布
dev.off()

# 此外类似的方法还有jpeg(), bmp(), tiff(), pdf(), svg()

# -- 第二种方法 --
library(ggplot2)
p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()

# ggsave 会默认保存上一个ggplot对象
ggsave(
  filename = "name.png", # 保存的文件名称。通过后缀来决定生成什么格式的图片
  width = 7,             # 宽
  height = 7,            # 高
  units = "in",          # 单位
  dpi = 300              # 分辨率DPI
)

# -- 第三种方法 --
library(Cairo)
# Cairo.capabilities() # 检查当前电脑所支持的格式

# 1. 创建画布
Cairo::CairoPNG( 
  filename = "name.png", # 文件名称
  width = 7,           # 宽
  height = 7,          # 高
  units = "in",        # 单位
  dpi = 300)           # 分辨率
# 2. 绘图
plot(1:5) 
# 3. 关闭画布
dev.off() 

# 此外类似的方法还有CairoJPEG(), CairoTIFF(), CairoPDF(), CairoSVG()等

# 建议
# 只要是使用ggplot2绘图的都推荐使用ggsave保存图片。其他的使用Cairo保存图片。
```


<!--stackedit_data:
eyJoaXN0b3J5IjpbMjAxMDkzNTU2NV19
-->