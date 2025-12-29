#!/bin/bash
# 司書AIシステム - Git hooks インストールスクリプト

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 司書AIシステム - Git hooks インストール${NC}"
echo ""

# .git/hooks ディレクトリの存在確認
if [ ! -d "$HOOKS_DIR" ]; then
  echo -e "${RED}❌ エラー: .git/hooks ディレクトリが見つかりません${NC}"
  echo "   このスクリプトはGitリポジトリのルートで実行してください。"
  exit 1
fi

# pre-commit hook の作成
PRE_COMMIT_HOOK="$HOOKS_DIR/pre-commit"

echo -e "${YELLOW}📝 pre-commit hook を作成中...${NC}"

cat > "$PRE_COMMIT_HOOK" <<'EOF'
#!/bin/bash
# 司書AIシステム - pre-commit hook
# 自動生成 - 手動で編集しないでください

# pre-commit チェックスクリプトを実行
./.llms/scripts/pre-commit-check.sh

# 終了コードを継承（警告があってもコミットは通す）
exit $?
EOF

chmod +x "$PRE_COMMIT_HOOK"

echo -e "${GREEN}✅ pre-commit hook をインストールしました${NC}"
echo "   パス: $PRE_COMMIT_HOOK"
echo ""

# 動作確認
echo -e "${BLUE}🔍 動作確認（dry-run）${NC}"
echo ""

# テスト実行
if ./.llms/scripts/pre-commit-check.sh; then
  echo ""
  echo -e "${GREEN}✅ pre-commit hook が正常に動作しています${NC}"
else
  echo ""
  echo -e "${YELLOW}⚠️  警告が検出されました（コミットは可能です）${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}インストール完了${NC}"
echo ""
echo "次回のコミットから自動的にフォーマットチェックが実行されます。"
echo ""
echo "アンインストール:"
echo "  rm $PRE_COMMIT_HOOK"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
