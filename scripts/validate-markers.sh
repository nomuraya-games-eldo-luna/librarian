#!/bin/bash
# 司書AIシステム - markerバリデーションスクリプト
# メタデータのmarkerが本文に存在するかチェック

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
METADATA_DIR="$PROJECT_ROOT/.llms/metadata"
DOCS_DIR="$PROJECT_ROOT/docs"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 司書AIシステム - markerバリデーション"
echo ""

ERRORS=0
WARNINGS=0

# YAMLファイルを検索
for yaml_file in "$METADATA_DIR"/*.yaml; do
  if [ ! -f "$yaml_file" ]; then
    continue
  fi

  filename=$(basename "$yaml_file")
  echo "📄 チェック中: $filename"

  # YAMLから file と marker を抽出
  file_path=$(grep "^file:" "$yaml_file" | sed 's/file: *"//' | sed 's/"$//')
  full_path="$PROJECT_ROOT/$file_path"

  if [ ! -f "$full_path" ]; then
    echo -e "${RED}❌ エラー: 本文ファイルが見つかりません${NC}"
    echo "   パス: $file_path"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # markerを抽出してチェック
  markers=$(grep "marker:" "$yaml_file" | sed 's/.*marker: *"//' | sed 's/"$//')

  while IFS= read -r marker; do
    if [ -z "$marker" ]; then
      continue
    fi

    # エスケープ処理（grepで使えるように）
    # **を\*\*に、：を：に（そのまま）
    escaped_marker=$(echo "$marker" | sed 's/\*/\\*/g')

    # 本文にmarkerが存在するかチェック
    if grep -qF "$marker" "$full_path"; then
      echo -e "${GREEN}✓${NC} 見つかりました: $marker"
    else
      echo -e "${RED}❌ 見つかりません: $marker${NC}"
      echo "   本文ファイル: $file_path"
      ERRORS=$((ERRORS + 1))
    fi
  done <<< "$markers"

  echo ""
done

# 結果サマリー
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ERRORS -eq 0 ]; then
  echo -e "${GREEN}✅ すべてのmarkerが本文に存在します${NC}"
  exit 0
else
  echo -e "${RED}❌ $ERRORS 件のエラーが見つかりました${NC}"
  echo ""
  echo "対処方法:"
  echo "1. 本文の見出しがメタデータのmarkerと一致しているか確認"
  echo "2. メタデータのmarkerを本文に合わせて修正"
  echo "3. または、generate-metadata.sh で自動生成"
  exit 1
fi
