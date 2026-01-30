#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

OUTPUT_DIR="${1:-$PROJECT_ROOT/dist/pages}"
OUTPUT_DIR="$(realpath -m "$OUTPUT_DIR")"

REVEALJS_DIR_NAME="reveal.js"
REVEALJS_PATH="$PROJECT_ROOT/$REVEALJS_DIR_NAME"

if ! command -v pandoc &>/dev/null; then
  echo "错误: 未找到 pandoc。请先安装 pandoc。"
  exit 1
fi

if [ ! -d "$REVEALJS_PATH" ]; then
  echo "警告: 未找到 $REVEALJS_PATH 目录。"
  echo "尝试初始化 git 子模块..."
  git submodule update --init --recursive
fi

if [ ! -d "$REVEALJS_PATH" ]; then
  echo "错误: 无法获取 reveal.js。请确保已添加子模块或目录存在。"
  exit 1
fi

if [ -e "$OUTPUT_DIR" ] && [ "$OUTPUT_DIR" = "/" ]; then
  echo "错误: OUTPUT_DIR 解析为 / ，拒绝执行。"
  exit 1
fi

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

cp -a "$PROJECT_ROOT/courseware" "$OUTPUT_DIR/"
cp -a "$PROJECT_ROOT/css" "$OUTPUT_DIR/"
if [ -d "$PROJECT_ROOT/js" ]; then
  cp -a "$PROJECT_ROOT/js" "$OUTPUT_DIR/"
fi
cp -a "$REVEALJS_PATH" "$OUTPUT_DIR/"

touch "$OUTPUT_DIR/.nojekyll"

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

cp "$PROJECT_ROOT/revealjs.template" "$TMP_DIR/revealjs.template"
touch "$TMP_DIR/styles.html"

mapfile -d '' SLIDE_MD_FILES < <(find "$PROJECT_ROOT/courseware" -type f -path "*/slides/*.md" -print0 | sort -z)
mapfile -d '' LAB_MD_FILES < <(find "$PROJECT_ROOT/courseware" -type f -path "*/labs/*.md" -print0 | sort -z)

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

html_escape() {
  local s="$1"
  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  s="${s//\"/&quot;}"
  printf '%s' "$s"
}

extract_frontmatter_key() {
  local file="$1"
  local key="$2"
  local line
  # Limit search to the first 20 lines to avoid matching content
  line="$(head -n 20 "$file" | grep "^${key}:" | head -n 1 | tr -d '\r')"
  line="$(trim "$line")"
  
  if [[ -z "$line" ]]; then
    printf ''
    return 0
  fi
  
  # Remove key:
  line="${line#${key}:}"
  line="$(trim "$line")"
  
  # Remove quotes
  if [[ "$line" == \"*\" && "$line" == *\" ]]; then
    line="${line#\"}"
    line="${line%\"}"
  elif [[ "$line" == \'*\' && "$line" == *\' ]]; then
    line="${line#\'}"
    line="${line%\'}"
  fi
  printf '%s' "$line"
}

extract_title() {
  extract_frontmatter_key "$1" "title"
}

extract_subtitle() {
  extract_frontmatter_key "$1" "subtitle"
}

extract_first_h1_title() {
  local file="$1"
  local title
  title="$(sed -n 's/^#\{1,\}[[:space:]]\+//p' "$file" | head -n 1 | tr -d '\r')"
  title="$(trim "$title")"
  if [ -z "$title" ]; then
    title="$(basename "${file%.md}")"
  fi
  printf '%s' "$title"
}

for file in "${SLIDE_MD_FILES[@]}"; do
  rel_path_from_root="$(realpath --relative-to="$PROJECT_ROOT" "$file")"
  output_file="$OUTPUT_DIR/${rel_path_from_root%.md}.html"
  output_dir="$(dirname "$output_file")"
  mkdir -p "$output_dir"

  rel_path_to_output_root="$(realpath --relative-to="$output_dir" "$OUTPUT_DIR")"
  revealjs_url="$rel_path_to_output_root/$REVEALJS_DIR_NAME"
  css_url="$rel_path_to_output_root/css/linux4ai.css"

  pandoc -t revealjs -s -o "$output_file" "$file" \
    -V revealjs-url="$revealjs_url" \
    --template="$TMP_DIR/revealjs.template" \
    -V theme=white \
    --css="$css_url" \
    -V transition=fade \
    -V history=true \
    --no-highlight \
    -V hlss=kate \
    --slide-level=2 \
    --mathjax
done

for file in "${LAB_MD_FILES[@]}"; do
  rel_path_from_root="$(realpath --relative-to="$PROJECT_ROOT" "$file")"
  output_file="$OUTPUT_DIR/${rel_path_from_root%.md}.html"
  output_dir="$(dirname "$output_file")"
  mkdir -p "$output_dir"

  rel_path_to_output_root="$(realpath --relative-to="$output_dir" "$OUTPUT_DIR")"
  css_url="$rel_path_to_output_root/css/linux4ai.css"
  js_url="$rel_path_to_output_root/js/toc.js"
  title="$(extract_first_h1_title "$file")"

  pandoc -s -o "$output_file" "$file" \
    --css="$css_url" \
    --toc \
    --metadata title="$title"

  # Add markdown-body class to body and inject TOC script
  sed -i 's/<body>/<body class="markdown-body">/' "$output_file"
  sed -i "s|</body>|<script src=\"$js_url\"></script></body>|" "$output_file"
done

# Process syllabus.md
if [ -f "$PROJECT_ROOT/syllabus.md" ]; then
  echo "Processing syllabus.md..."
  output_file="$OUTPUT_DIR/syllabus.html"
  
  # Markmap headers
  MARKMAP_HEADER='<script src="https://cdn.jsdelivr.net/npm/markmap-autoloader@0.16"></script><style>.markmap > svg { width: 100%; height: 100%; min-height: 500px; }</style>'
  
  pandoc -s -o "$output_file" "$PROJECT_ROOT/syllabus.md" \
    --css="css/linux4ai.css" \
    --toc \
    --variable header-includes="$MARKMAP_HEADER" \
    --metadata title="Linux4AI Syllabus"

  # Add markdown-body class to body and inject TOC script
  sed -i 's/<body>/<body class="markdown-body">/' "$output_file"
  sed -i 's|</body>|<script src="js/toc.js"></script></body>|' "$output_file"
fi

{
  echo '<!doctype html>'
  echo '<html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
  echo '<title>Linux4AI</title></head><body>'
  echo '<h1>Linux4AI</h1>'
  echo '<p><a href="syllabus.html">课程大纲 (Syllabus)</a></p>'
  echo '<h2>Slides</h2>'
  echo '<ul>'
  for file in "${SLIDE_MD_FILES[@]}"; do
    rel_path_from_root="$(realpath --relative-to="$PROJECT_ROOT" "$file")"
    html_file="${rel_path_from_root%.md}.html"
    title="$(extract_title "$file")"
    subtitle="$(extract_subtitle "$file")"
    title="$(trim "$title")"
    subtitle="$(trim "$subtitle")"

    if [ -n "$subtitle" ]; then
      title="$title - $subtitle"
    fi

    if [ -z "$title" ]; then
      title="$html_file"
    fi
    title="$(html_escape "$title")"
    echo "<li><a href=\"$html_file\">$title</a></li>"
  done
  echo '</ul>'
  echo '<h2>Labs</h2>'
  echo '<ul>'
  for file in "${LAB_MD_FILES[@]}"; do
    rel_path_from_root="$(realpath --relative-to="$PROJECT_ROOT" "$file")"
    html_file="${rel_path_from_root%.md}.html"
    title="$(extract_first_h1_title "$file")"
    title="$(html_escape "$title")"
    echo "<li><a href=\"$html_file\">$title</a></li>"
  done
  echo '</ul>'
  echo '</body></html>'
} >"$OUTPUT_DIR/index.html"

echo "输出目录: $OUTPUT_DIR"
