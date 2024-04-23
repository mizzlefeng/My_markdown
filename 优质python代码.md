# 优美的code

## argpaser

```python
import argparse

def get_parse():
    parser = argparse.ArgumentParser()
    parser.add_argument("--file_path", default=None, type=str,required=True, help="The path of the data file to process")
    parser.add_argument("--output_dir", default=None, type=str,required=True, help="The path of the output file")
    
    # Other parameters
    parser.add_argument("--is_count", default=None, type=str,help="Whether to calculate the sample size")
    parser.add_argument("--overwrite_output_dir", action="store_true",help="Overwrite the content of the output directory") 
    parser.add_argument('-n', '--name', default=None, type=str,help="give me a name of the program")
    return parser

if __name__ == "__main__":
    args = get_parse().parse_args()
```

default：默认值

缩写："-","--"

action：用于指定当命令行参数被解析时所采取的动作。它定义了参数的行为方式，包括存储值、统计参数、打印帮助信息等。action 参数的取值可以是一些预定义的动作，也可以是自定义的动作。

required：是否必要

help：帮助信息

dest：变量名，如果你使用了长参数名（以`--`开头），你应该能够通过`args.<参数名>`的方式访问这些参数的值，其中`<参数名>`是长参数名去掉`--`的部分。对于短参数名（以`-`开头），通常你也需要使用长参数名的方式访问它们的值，除非你显式设置了`dest`属性。

## json文件解析参数

```python
config.json:
{
  "file_name": "DISC-Med-SFT_covert.json",
  "input_dir": "./program_data/old",
  "output_dir": "./program_data/new",

  "shuffle": false,
  "shuffle_source_data": true,

  "log_file": "",
  "disease": "copd",
    ···
}

from types import SimpleNamespace
def get_config(config_path):
    with open(config_path, "r", encoding="utf-8") as f:
        config_dict = json.load(f)
    config = SimpleNamespace(**config_dict)
    return config

config = get_config(args.config)
```

## 日志记录器

```python
import logging
from pathlib import Path

logger = logging.getLogger()

def init_logger(log_file=None, log_file_level=logging.NOTSET):
    """
    Example:
        >>> init_logger(log_file)
        >>> logger.info("abc'")
    """
    if isinstance(log_file, Path):
        log_file = str(log_file)
    log_format = logging.Formatter(
        fmt="%(asctime)s - %(levelname)s - %(name)s -   %(message)s",
        datefmt="%m/%d/%Y %H:%M:%S",
    )

    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    console_handler = logging.StreamHandler()
    console_handler.setFormatter(log_format)
    logger.handlers = [console_handler]
    if log_file and log_file != "":
        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(log_file_level)
        # file_handler.setFormatter(log_format)
        logger.addHandler(file_handler)
    return logger
```



# Python细节

## 正则表达式

### 脱机符和任意非单词字符

```python
pattern = r"{0}\W*=\W*\"([^\"]+)\"".format("__version__")
(version,) = re.findall(pattern, file_content)
```

任意非单词字符（`\W*`）

**`\"`**: 匹配一个双引号字符。在正则表达式中，双引号需要被转义（使用`\`），因此写作`\"`。

**`([^\"]+)`**: 这是一个捕获组，用于匹配并捕获一对双引号之间的内容。`[^\"]`表示匹配任意字符，除了双引号。`+`表示“1次或多次”匹配。这意味着这个组会匹配一个或多个非双引号字符。

在正则表达式中，**方括号`[]`用于定义一个字符集合**，用来匹配集合内的任意一个字符。如果字符集合的开头是一个**脱字符`^`**，则表示匹配不在该集合内的任何一个字符，即这个字符集合是被否定或排除的。

### 方括号

方括号 `[...]` 用于指定一个字符集合，它表示匹配其中任何一个字符。

### ^

在方括号内部的开头位置使用 `^` 表示取反的意思，即匹配不在指定字符集合内的字符。

### \s

这是一个转义字符，表示匹配任意空白字符，包括空格、制表符、换行符等。

### \p{L}

Unicode 属性的一种表示形式。`\p{L}` 匹配任何 Unicode 字母字符，包括中文、英文、日文等。它表示任何被认为是“字母”的 Unicode 字符。

### '

这只是一个普通的单引号字符，表示匹配单引号本身。

所以 `"[^\s\p{L}']"` 表示匹配除了空白字符、Unicode 字母和单引号之外的所有字符。

## json

### json.load

操作的是文件流

```python
with open('s.json', 'r') as f:
    s1 = json.load(f)
```



### json.loads

操作的是字符串

```python
s = '{"name": "wade", "age": 54, "gender": "man"}'
json.loads(s)
```

