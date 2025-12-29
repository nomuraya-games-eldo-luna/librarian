#!/bin/bash
# 司書AIシステム - シーン見出しフォーマット自動修正スクリプト
# フォーマット違反を検出して標準形式に自動修正

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

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
  echo "  $0 docs/part1/chapter-1.md --dry-run  # 修正内容を表示するのみ"
  echo "  $0 docs/part1/chapter-1.md --create-issue  # Issue作成"
  echo ""
  exit 1
}

# 引数チェック
if [ $# -lt 1 ]; then
  usage
fi

SOURCE_FILE="$1"
DRY_RUN=false
CREATE_ISSUE=false

# オプション解析
shift
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --create-issue)
      CREATE_ISSUE=true
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

echo -e "${BLUE}🔍 シーン見出しフォーマットチェック: $SOURCE_FILE${NC}"
echo ""

# 一時ファイル
TEMP_FILE=$(mktemp)
ISSUE_FILE=$(mktemp)
trap "rm -f $TEMP_FILE $ISSUE_FILE" EXIT

# フォーマット違反のパターンを検出
VIOLATIONS=0

# パターン1: ## Scene N: タイトル（H2、小文字scene、半角コロン）
if grep -n '^## [Ss]cene [0-9]\+:' "$SOURCE_FILE" > /dev/null 2>&1; then
  echo -e "${YELLOW}📌 パターン1検出: ## Scene N: タイトル${NC}"
  grep -n '^## [Ss]cene [0-9]\+:' "$SOURCE_FILE" | while IFS=: read -r line_num content; do
    echo "   行 $line_num: $content"
    VIOLATIONS=$((VIOLATIONS + 1))

    # Issue用に記録
    echo "- 行 $line_num: \`$content\`" >> "$ISSUE_FILE"
    echo "  - 問題: H2（##）を使用、sceneが小文字、半角コロン" >> "$ISSUE_FILE"
    echo "  - 修正: \`#### **SCENE N：タイトル**\`" >> "$ISSUE_FILE"
  done
  echo ""
fi

# パターン2: ### シーン N：タイトル（H3、日本語「シーン」）
if grep -n '^### シーン[0-9]\+：' "$SOURCE_FILE" > /dev/null 2>&1; then
  echo -e "${YELLOW}📌 パターン2検出: ### シーン N：タイトル${NC}"
  grep -n '^### シーン[0-9]\+：' "$SOURCE_FILE" | while IFS=: read -r line_num content; do
    echo "   行 $line_num: $content"
    VIOLATIONS=$((VIOLATIONS + 1))

    echo "- 行 $line_num: \`$content\`" >> "$ISSUE_FILE"
    echo "  - 問題: H3（###）を使用、「シーン」は日本語" >> "$ISSUE_FILE"
    echo "  - 修正: \`#### **SCENE N：タイトル**\`" >> "$ISSUE_FILE"
  done
  echo ""
fi

# パターン3: #### SCENE N - タイトル（ハイフン区切り）
if grep -n '^#### SCENE [0-9]\+ -' "$SOURCE_FILE" > /dev/null 2>&1; then
  echo -e "${YELLOW}📌 パターン3検出: #### SCENE N - タイトル${NC}"
  grep -n '^#### SCENE [0-9]\+ -' "$SOURCE_FILE" | while IFS=: read -r line_num content; do
    echo "   行 $line_num: $content"
    VIOLATIONS=$((VIOLATIONS + 1))

    echo "- 行 $line_num: \`$content\`" >> "$ISSUE_FILE"
    echo "  - 問題: ハイフン（-）区切り、太字なし" >> "$ISSUE_FILE"
    echo "  - 修正: \`#### **SCENE N：タイトル**\`" >> "$ISSUE_FILE"
  done
  echo ""
fi

# パターン4: #### **SCENEN：タイトル**（スペースなし）
if grep -n '^#### \*\*SCENE[0-9]\+：' "$SOURCE_FILE" > /dev/null 2>&1; then
  echo -e "${YELLOW}📌 パターン4検出: #### **SCENEN：タイトル**${NC}"
  grep -n '^#### \*\*SCENE[0-9]\+：' "$SOURCE_FILE" | while IFS=: read -r line_num content; do
    echo "   行 $line_num: $content"
    VIOLATIONS=$((VIOLATIONS + 1))

    echo "- 行 $line_num: \`$content\`" >> "$ISSUE_FILE"
    echo "  - 問題: SCENEと番号の間にスペースがない" >> "$ISSUE_FILE"
    echo "  - 修正: \`#### **SCENE N：タイトル**\`" >> "$ISSUE_FILE"
  done
  echo ""
fi

# パターン5: #### **SCENE N:タイトル**（半角コロン）
if grep -n '^#### \*\*SCENE [0-9]\+:' "$SOURCE_FILE" > /dev/null 2>&1; then
  echo -e "${YELLOW}📌 パターン5検出: #### **SCENE N:タイトル**${NC}"
  grep -n '^#### \*\*SCENE [0-9]\+:' "$SOURCE_FILE" | while IFS=: read -r line_num content; do
    echo "   行 $line_num: $content"
    VIOLATIONS=$((VIOLATIONS + 1))

    echo "- 行 $line_num: \`$content\`" >> "$ISSUE_FILE"
    echo "  - 問題: 半角コロン（:）を使用" >> "$ISSUE_FILE"
    echo "  - 修正: \`#### **SCENE N：タイトル**\`（全角コロン）" >> "$ISSUE_FILE"
  done
  echo ""
fi

# 違反がなければ成功
if [ $VIOLATIONS -eq 0 ]; then
  echo -e "${GREEN}✅ すべてのシーン見出しが標準フォーマットに準拠しています${NC}"
  exit 0
fi

echo -e "${RED}❌ $VIOLATIONS 件のフォーマット違反を検出しました${NC}"
echo ""

# Dry-run モード
if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}📄 Dry-run モード: 自動修正は実行しません${NC}"
  echo ""
  echo "修正方法:"
  echo "1. 手動で標準フォーマットに修正: #### **SCENE N：タイトル**"
  echo "2. または、このスクリプトを --dry-run なしで実行"
  exit 1
fi

# Issue作成モード
if [ "$CREATE_ISSUE" = true ]; then
  echo -e "${BLUE}📝 GitHub Issueを作成します...${NC}"

  ISSUE_TITLE="シーン見出しフォーマット違反を検出（$SOURCE_FILE）"
  ISSUE_BODY="## 概要

\`$SOURCE_FILE\` でシーン見出しのフォーマット違反を検出しました。

## 検出された違反（$VIOLATIONS 件）

$(cat "$ISSUE_FILE")

## 標準フォーマット

\`\`\`markdown
#### **SCENE N：タイトル**
\`\`\`

## 対処方法

### 自動修正（推奨）

\`\`\`bash
./.llms/scripts/fix-scene-headings.sh $SOURCE_FILE
\`\`\`

### 手動修正

\`.llms/docs/scene-heading-format.md\` を参照して手動で修正してください。

---

**自動生成日時**: $(date +%Y-%m-%d\ %H:%M:%S)
"

  gh issue create \
    --title "$ISSUE_TITLE" \
    --body "$ISSUE_BODY" \
    --label "司書AI,フォーマット修正" \
    --assignee @me

  echo -e "${GREEN}✅ Issueを作成しました${NC}"
  exit 0
fi

# TODO: 自動修正ロジック（将来実装）
echo -e "${YELLOW}⚠️  自動修正機能は未実装です${NC}"
echo ""
echo "現在の対処方法:"
echo "1. --create-issue オプションでIssueを作成"
echo "2. 手動で標準フォーマットに修正"
echo "3. または、CUIで司書AIに修正を依頼"
echo ""
echo "例:"
echo "  ./.llms/scripts/fix-scene-headings.sh $SOURCE_FILE --create-issue"

exit 1
