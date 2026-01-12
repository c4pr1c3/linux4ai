# Linux4AI

本仓库包含《Linux 系统与网络管理》课程的课件与实验材料，课件采用 Markdown 编写，使用 pandoc 渲染为 Reveal.js 幻灯片（HTML）。

## 目录结构

- `courseware/`：按单元组织的课件与实验
- `css/linux4ai.css`：课件样式
- `revealjs.template`：pandoc 的 Reveal.js 模板
- `reveal.js/`：Reveal.js 子模块
- `build_slides.sh`：将 `.md` 转换为 `.html` 的构建脚本

## 快速开始

### 1) 初始化子模块

```bash
git submodule update --init --recursive
```

### 2) 安装 pandoc

脚本依赖 `pandoc`，请先安装并确保命令可用：

```bash
pandoc -v
```

### 3) 生成课件 HTML

默认会在目标目录内查找 `.md` 文件并生成同名 `.html`（与源文件同目录）。

```bash
./build_slides.sh
```

也可以只构建课件目录：

```bash
./build_slides.sh courseware
```

生成后直接用浏览器打开 `courseware/**/**/*.html` 即可查看。
