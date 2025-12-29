#!/bin/bash
# 司書AIシステム - pre-commit hook
# フォーマット違反を検出して警告（コミットはブロックしない）

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 司書AIシステム - pre-commit チェック${NC}"
echo ""

# コミット対象のファイルを取得
CHANGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

# 本文ファイル（docs/part*/chapter-*.md）のみチェック
CHAPTER_FILES=$(echo "$CHANGED_FILES" | grep '^docs/part[0-9]\+/chapter-[0-9]\+\.md$' || true)

if [ -z "$CHAPTER_FILES" ]; then
  echo -e "${GREEN}✅ チェック対象ファイルなし（本文ファイル以外の変更）${NC}"
  exit 0
fi

echo -e "${YELLOW}📄 チェック対象ファイル:${NC}"
echo "$CHAPTER_FILES" | while read -r file; do
  echo "  - $file"
done
echo ""

WARNINGS=0

# 各ファイルをチェック
echo "$CHAPTER_FILES" | while read -r file; do
  echo -e "${BLUE}🔍 チェック中: $file${NC}"

  # フォーマット違反を検出
  if ./.llms/scripts/fix-scene-headings.sh "$file" --dry-run > /dev/null 2>&1; then
    echo -e "${GREEN}✓ フォーマット準拠${NC}"
  else
    echo -e "${YELLOW}⚠️  フォーマット違反を検出${NC}"
    WARNINGS=$((WARNINGS + 1))

    # 詳細を表示
    ./.llms/scripts/fix-scene-headings.sh "$file" --dry-run 2>&1 | grep -A 100 "📌 パターン" || true

    echo ""
    echo -e "${YELLOW}推奨対応:${NC}"
    echo "  1. 自動修正: ./.llms/scripts/fix-scene-headings.sh $file"
    echo "  2. メタデータ再生成: ./.llms/scripts/generate-metadata.sh $file --merge"
    echo "  3. 再度コミット: git add . && git commit --amend"
    echo ""
    echo -e "${YELLOW}または、このままコミットして CI で検出させることも可能です。${NC}"
  fi

  echo ""
done

# 警告があってもコミットは通す
if [ $WARNINGS -gt 0 ]; then
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${YELLOW}⚠️  $WARNINGS 件の警告がありますが、コミットは続行します。${NC}"
  echo ""
  echo "CI でさらに詳細なチェックが実行されます。"
  echo "修正が必要な場合は Issue が自動作成されます。"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
fi

exit 0  # コミットをブロックしない
