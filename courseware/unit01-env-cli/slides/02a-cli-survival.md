---
title: "第一单元: 环境构建与 CLI 生存指南"
subtitle: "命令行的艺术与技术"
author: 黄玮
date: 2026-01
output: revealjs::revealjs_presentation
---

# Topic 1: CLI 哲学

---

## 为什么还要用命令行?

- **可组合性**: 小工具通过管道 (`|`) 组合成大威力
- **自动化**: 所有命令都可写入脚本
- **远程友好**: 低带宽，无 GUI 依赖
- **精确**: 图形界面隐藏细节，命令行暴露真相

---

## 核心概念

- **Shell**: 命令解释器 (Bash, Zsh)
- **STDIN/STDOUT/STDERR**: 标准输入(0)、输出(1)、错误(2)
- **管道 (`|`)**: 前一个命令的输出 = 后一个命令的输入
  - `cat access.log | grep "404"`
- **重定向**:
  - `>`: 覆盖写入
  - `>>`: 追加写入
  - `2>`: 错误重定向

---

# Topic 2: 文本处理实战

---

## grep: 过滤行

> Global Regular Expression Print

```bash
grep "error" app.log            # 查找包含 error 的行
grep -i "error" app.log         # 忽略大小写
grep -v "debug" app.log         # 反向选择（不包含 debug）
grep -r "TODO" ./src            # 递归查找目录
```

---

## awk: 处理列

> 强大的文本分析工具，默认按空格/Tab 分割

```bash
# 打印第 1 列和第 9 列 (如 Apache 日志的 IP 和 状态码)
awk '{print $1, $9}' access.log

# 统计特定列的总和
ls -l | awk '{sum += $5} END {print sum}'
```

---

## sort & uniq: 统计

```bash
# 统计访问量最高的 Top 5 IP
cat access.log \
  | awk '{print $1}' \
  | sort \
  | uniq -c \
  | sort -nr \
  | head -n 5
```

---

# Topic 3: 文件高阶生存术

---

## find: 精确打击

> 在文件系统中根据条件搜索文件

```bash
find . -name "*.py"             # 按文件名查找
find . -type f -size +100M      # 查找大于 100M 的文件
find /var/log -mtime +7         # 查找 7 天前修改过的文件
find . -name "*.tmp" -delete    # 找到并删除 (慎用!)
```

---

## 管道进阶: xargs

> 很多命令不支持从标准输入读取参数，xargs 来救场

```bash
# 错误: rm 不接受标准输入
find . -name "*.tmp" | rm       

# 正确: xargs 将输入转换为参数列表
find . -name "*.tmp" | xargs rm
```

---

## 压缩与解压缩

- **tar**: Linux 标准归档工具
  - `c`: Create (创建) / `x`: Extract (解压)
  - `z`: Gzip (压缩) / `v`: Verbose (详细) / `f`: File (文件)

```bash
tar -czvf project.tar.gz ./src  # 打包压缩
tar -xzvf project.tar.gz        # 解压到当前目录
unzip material.zip              # 解压 zip 文件
```

---

## 字符编码: 拒绝乱码

- **问题**: Windows (GBK) vs Linux/Web (UTF-8)
- **file**: 查看文件类型和编码
- **iconv**: 转换编码

```bash
file -i data.csv                # 查看编码
# output: charset=iso-8859-1

iconv -f GBK -t UTF-8 old.txt > new.txt
```

---

## 校验: 数字指纹

> 验证文件完整性，确保未被篡改或损坏

```bash
# 生成指纹
md5sum release.iso > release.md5
sha256sum sensitive.data

# 验证 (检查 release.md5 中的指纹是否匹配)
md5sum -c release.md5
```

---

# Topic 4: 极简 Vim 入门

---

## 为什么要学 Vim?

> "I can't exit Vim" 是 StackOverflow 上的经典问题

- **普遍性**: 几乎所有 Linux 系统都预装
- **极端场景**: 
  - 物理机房维护 (没有 VS Code Remote)
  - 网络故障排查 (SSH 连接不稳定)
  - 救援模式 (只有最基础的 Shell)
- **效率**: 手不离键盘的极速编辑

---

## 核心概念: 模式 (Modes)

Vim 是**模态**编辑器，不同模式下按键含义不同：

1. **Normal Mode (普通模式)**: 默认模式，用于移动光标、删除、复制
   - 按 `Esc` 永远回到这里
2. **Insert Mode (插入模式)**: 像记事本一样打字
   - 按 `i` 进入
3. **Command Mode (命令模式)**: 保存、退出、搜索
   - 按 `:` 进入

---

## 生存指令: 记住这几个就够了

1. **进入编辑**: `vim filename`
2. **开始打字**: 按 `i` (Insert)
3. **停止打字**: 按 `Esc` (回到 Normal)
4. **保存退出**: 输入 `:wq` (Write & Quit) + `Enter`
5. **强制退出 (不保存)**: 输入 `:q!` + `Enter`

> 💡 进阶: 在终端输入 `vimtutor` 开启 30 分钟互动教程

---

# Topic 5: 寻求帮助

---

## 不要死记硬背

- **`man <command>`**: 查阅手册 (Manual)
  - `man ls`
  - 按 `q` 退出, `/` 搜索
- **`<command> --help`**: 快速简要帮助
- **tldr**: Too Long; Didn't Read (需安装)
  - `tldr tar` -> 只显示常用例子
