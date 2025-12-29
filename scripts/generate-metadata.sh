#!/bin/bash
# 司書AIシステム - メタデータ自動生成スクリプト
# 本文からSCENEマーカーを抽出してYAMLメタデータを生成

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
METADATA_DIR="$PROJECT_ROOT/.llms/metadata"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 使い方
usage() {
  echo "使い方: $0 <本文ファイルパス> [オプション]"
  echo ""
  echo "例:"
  echo "  $0 docs/part1/chapter-1.md"
  echo "  $0 docs/part1/chapter-1.md --merge  # 既存のsummaryを保持"
  echo ""
  echo "オプション:"
  echo "  --merge    既存メタデータのsummaryを保持してマージ"
  echo "  --dry-run  生成内容を表示するのみ（ファイル書き込みなし）"
  exit 1
}

# 引数チェック
if [ $# -lt 1 ]; then
  usage
fi

SOURCE_FILE="$1"
MERGE_MODE=false
DRY_RUN=false

# オプション解析
shift
while [ $# -gt 0 ]; do
  case "$1" in
    --merge)
      MERGE_MODE=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      echo -e "${RED}❌ 不明なオプション: $1${NC}"
      usage
      ;;
  esac
done

# ファイル存在チェック
if [ ! -f "$SOURCE_FILE" ]; then
  echo -e "${RED}❌ エラー: ファイルが見つかりません${NC}"
  echo "   パス: $SOURCE_FILE"
  exit 1
fi

# ファイル名からメタデータファイル名を決定
# 例: docs/part1/chapter-1.md → chapter-1.yaml
basename_file=$(basename "$SOURCE_FILE" .md)
metadata_file="$METADATA_DIR/${basename_file}.yaml"

echo -e "${BLUE}🔍 本文ファイル: $SOURCE_FILE${NC}"
echo -e "${BLUE}📝 メタデータ出力: $metadata_file${NC}"
echo ""

# 章番号を抽出（ファイル名から）
chapter_num=$(echo "$basename_file" | grep -o '[0-9]\+' | head -1)
if [ -z "$chapter_num" ]; then
  chapter_num="?"
fi

# 章タイトルを抽出（本文の最初の見出しから）
chapter_title=$(grep -m 1 "^###.*章" "$SOURCE_FILE" | sed 's/^### \*\*//;s/\*\*$//' || echo "（未定）")

# SCENEマーカーを抽出
# パターン: #### **SCENE N：タイトル**
scenes=$(grep -n "^#### \*\*SCENE [0-9]\+：" "$SOURCE_FILE" || true)

if [ -z "$scenes" ]; then
  echo -e "${YELLOW}⚠️  警告: SCENEマーカーが見つかりませんでした${NC}"
  echo "   本文に '#### **SCENE N：タイトル**' 形式の見出しがあるか確認してください"
  exit 1
fi

# シーン数をカウント
scene_count=$(echo "$scenes" | wc -l | tr -d ' ')

echo -e "${GREEN}✓ $scene_count シーンを検出しました${NC}"
echo ""

# 既存メタデータを一時ファイルに抽出（--merge モード）
SUMMARY_TEMP_FILE=""
if [ "$MERGE_MODE" = true ] && [ -f "$metadata_file" ]; then
  echo -e "${YELLOW}🔄 既存メタデータからsummaryを読み込み中...${NC}"

  # 一時ファイルに number:summary のペアを抽出
  SUMMARY_TEMP_FILE=$(mktemp)

  # YAMLから既存のsummaryを抽出（sed/grepベース）
  # number: N の後の summary: "..." をペアで取得
  current_num=""
  while IFS= read -r line; do
    # number: N を検出
    if echo "$line" | grep -q '^[[:space:]]*-[[:space:]]*number:[[:space:]]*[0-9]\+'; then
      current_num=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*number:[[:space:]]*//;s/[[:space:]]*$//')
    fi

    # summary: "..." を検出
    if echo "$line" | grep -q '^[[:space:]]*summary:[[:space:]]*"'; then
      summary=$(echo "$line" | sed 's/^[[:space:]]*summary:[[:space:]]*"//;s/"[[:space:]]*$//')
      if [ -n "$current_num" ] && [ -n "$summary" ]; then
        echo "${current_num}:${summary}" >> "$SUMMARY_TEMP_FILE"
        current_num=""
      fi
    fi
  done < "$metadata_file"

  summary_count=$(wc -l < "$SUMMARY_TEMP_FILE" | tr -d ' ')
  echo -e "${GREEN}✓ ${summary_count} 件のsummaryを読み込みました${NC}"
  echo ""
fi

# summaryを取得する関数
get_existing_summary() {
  local scene_num=$1
  if [ -n "$SUMMARY_TEMP_FILE" ] && [ -f "$SUMMARY_TEMP_FILE" ]; then
    grep "^${scene_num}:" "$SUMMARY_TEMP_FILE" | cut -d: -f2- || echo ""
  else
    echo ""
  fi
}

# YAMLヘッダー生成
yaml_content="# 第${chapter_num}章メタデータ（自動生成）

file: \"${SOURCE_FILE#$PROJECT_ROOT/}\"
chapter: $chapter_num
title: \"$chapter_title\"
total_scenes: $scene_count

scenes:"

# 各シーンの情報を抽出
echo -e "${BLUE}📋 シーン一覧:${NC}"
echo ""

while IFS= read -r scene_line; do
  # 行番号とマーカーを分離
  line_num=$(echo "$scene_line" | cut -d: -f1)
  marker=$(echo "$scene_line" | cut -d: -f2-)

  # シーン番号を抽出
  scene_num=$(echo "$marker" | grep -o 'SCENE [0-9]\+' | grep -o '[0-9]\+')

  # シーンタイトルを抽出（#### **SCENE N：の後ろ、**まで）
  scene_title=$(echo "$marker" | sed -E 's/^####[[:space:]]\*\*SCENE[[:space:]][0-9]+：//' | sed 's/\*\*$//')

  # 既存のsummaryを取得（なければ空文字）
  summary=$(get_existing_summary "$scene_num")

  # 表示
  if [ -n "$summary" ]; then
    echo -e "  ${GREEN}SCENE $scene_num${NC}: $scene_title"
    echo -e "    → summary: $summary"
  else
    echo -e "  ${YELLOW}SCENE $scene_num${NC}: $scene_title"
    echo -e "    → ${YELLOW}summary未設定${NC}"
  fi

  # YAMLに追加
  yaml_content+="
  - number: $scene_num
    title: \"$scene_title\"
    marker: \"$marker\"
    summary: \"$summary\""

done <<< "$scenes"

# 使い方コメントを追加
yaml_content+="

# 使い方:
# 1. marker で grep 検索して行番号を取得
# 2. 次のシーンのmarkerまでの範囲を計算
# 3. Read ツールで該当範囲を読み込み
#
# 例: SCENE 5を取得
# grep -n \"#### \\*\\*SCENE 5\" $SOURCE_FILE  # → N行目
# grep -n \"#### \\*\\*SCENE 6\" $SOURCE_FILE  # → M行目
# Read $SOURCE_FILE (offset=N-1, limit=M-N)
#
# 再生成:
# ./.llms/scripts/generate-metadata.sh $SOURCE_FILE --merge
"

echo ""

# 一時ファイルのクリーンアップ
cleanup() {
  if [ -n "$SUMMARY_TEMP_FILE" ] && [ -f "$SUMMARY_TEMP_FILE" ]; then
    rm -f "$SUMMARY_TEMP_FILE"
  fi
}
trap cleanup EXIT

# Dry-run モード
if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}📄 Dry-run モード: 生成内容を表示します${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "$yaml_content"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
fi

# ファイル書き込み
mkdir -p "$METADATA_DIR"
echo "$yaml_content" > "$metadata_file"

echo -e "${GREEN}✅ メタデータを生成しました${NC}"
echo "   出力先: $metadata_file"
echo ""

# summaryが未設定の場合は警告
if [ "$MERGE_MODE" = false ] || [ -z "$SUMMARY_TEMP_FILE" ]; then
  echo -e "${YELLOW}⚠️  次のステップ:${NC}"
  echo "   1. $metadata_file を開く"
  echo "   2. 各シーンの summary フィールドを手動で追記"
  echo "   3. または、--merge オプションで既存のsummaryを保持"
fi

echo ""
echo -e "${BLUE}🔍 バリデーション実行:${NC}"
./.llms/scripts/validate-markers.sh
