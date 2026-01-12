#!/bin/bash
set -e

# 获取脚本所在目录作为项目根目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$SCRIPT_DIR"
REVEALJS_DIR_NAME="reveal.js"
REVEALJS_PATH="$PROJECT_ROOT/$REVEALJS_DIR_NAME"
TEMPLATE_FILE="$PROJECT_ROOT/revealjs.template"

# 检查 pandoc
if ! command -v pandoc &> /dev/null; then
    echo "错误: 未找到 pandoc。请先安装 pandoc。"
    exit 1
fi

# 检查 reveal.js
if [ ! -d "$REVEALJS_PATH" ]; then
    echo "警告: 未找到 $REVEALJS_PATH 目录。"
    echo "尝试初始化 git 子模块..."
    git submodule update --init --recursive
    if [ ! -d "$REVEALJS_PATH" ]; then
        echo "错误: 无法获取 reveal.js。请确保已添加子模块。"
        exit 1
    fi
fi

# 检查 styles.html，如果不存在则创建（pandoc 模板需要）
if [ ! -f "$PROJECT_ROOT/styles.html" ]; then
    echo "提示: styles.html 不存在，正在创建空文件以满足模板要求..."
    touch "$PROJECT_ROOT/styles.html"
fi

# 确定目标目录
TARGET_DIR="${1:-$PROJECT_ROOT}"
if [ ! -d "$TARGET_DIR" ]; then
    echo "错误: 目录 $TARGET_DIR 不存在。"
    exit 1
fi

# 转为绝对路径，方便后续处理
TARGET_DIR=$(realpath "$TARGET_DIR")

echo "==========================================="
echo "项目根目录: $PROJECT_ROOT"
echo "目标目录:   $TARGET_DIR"
echo "==========================================="

render_slide() {
    local file="$1"
    local dir output_file rel_path_to_root revealjs_url css_url

    dir="$(dirname "$file")"
    output_file="${file%.md}.html"

    rel_path_to_root="$(realpath --relative-to="$dir" "$PROJECT_ROOT")"
    revealjs_url="$rel_path_to_root/$REVEALJS_DIR_NAME"
    css_url="$rel_path_to_root/css/linux4ai.css"

    echo "处理 slides: $file"

    pandoc -t revealjs -s -o "$output_file" "$file" \
        -V revealjs-url="$revealjs_url" \
        --template="$TEMPLATE_FILE" \
        -V theme=white \
        --css="$css_url" \
        -V transition=fade \
        -V history=true \
        --no-highlight \
        -V hlss=kate \
        --slide-level=2 \
        --mathjax
}

render_lab() {
    local file="$1"
    local dir output_file rel_path_to_root css_url title

    dir="$(dirname "$file")"
    output_file="${file%.md}.html"

    rel_path_to_root="$(realpath --relative-to="$dir" "$PROJECT_ROOT")"
    css_url="$rel_path_to_root/css/linux4ai.css"
    title="$(sed -n 's/^#\{1,\}[[:space:]]\+//p' "$file" | head -n 1)"
    if [ -z "$title" ]; then
        title="$(basename "${file%.md}")"
    fi

    echo "处理 labs:   $file"

    pandoc -s -o "$output_file" "$file" \
        --css="$css_url" \
        --metadata title="$title"
}

find "$TARGET_DIR" \
    -type d \( -name ".git" -o -name "$REVEALJS_DIR_NAME" -o -name "node_modules" -o -name ".tasks" -o -name "old" \) -prune -o \
    -type f -path "*/slides/*.md" -print0 | while IFS= read -r -d '' file; do
    render_slide "$file"
done

find "$TARGET_DIR" \
    -type d \( -name ".git" -o -name "$REVEALJS_DIR_NAME" -o -name "node_modules" -o -name ".tasks" -o -name "old" \) -prune -o \
    -type f -path "*/labs/*.md" -print0 | while IFS= read -r -d '' file; do
    render_lab "$file"
done

echo "==========================================="
echo "转换完成！"
