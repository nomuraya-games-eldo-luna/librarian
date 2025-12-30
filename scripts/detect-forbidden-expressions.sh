#!/bin/bash
# detect-forbidden-expressions.sh
# 原稿中の禁止表現（現実を想起させる表現）を検出するスクリプト
#
# 使用方法:
#   ./detect-forbidden-expressions.sh [ファイルパス]
#   ./detect-forbidden-expressions.sh [ファイルパス] [プロジェクトルート]
#
# プロジェクト固有ルール:
#   {プロジェクトルート}/librarian/rules/forbidden-expressions.sh があれば追加読み込み
#
# レベル0品質チェック用

set -euo pipefail

# 色定義
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 引数処理
TARGET_PATH="${1:-.}"
PROJECT_ROOT="${2:-}"

# プロジェクトルートの自動検出
if [ -z "$PROJECT_ROOT" ]; then
    # TARGET_PATHからプロジェクトルートを推測
    if [ -f "$TARGET_PATH" ]; then
        PROJECT_ROOT="$(cd "$(dirname "$TARGET_PATH")" && pwd)"
        # 原稿/や設定/があるディレクトリまで遡る
        while [ "$PROJECT_ROOT" != "/" ]; do
            if [ -d "$PROJECT_ROOT/原稿" ] || [ -d "$PROJECT_ROOT/設定" ]; then
                break
            fi
            PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
        done
    fi
fi

echo "=========================================="
echo "禁止表現検出スクリプト（レベル0品質チェック）"
echo "=========================================="
echo -e "検索対象: ${CYAN}$TARGET_PATH${NC}"
[ -n "$PROJECT_ROOT" ] && echo -e "プロジェクト: ${CYAN}$PROJECT_ROOT${NC}"
echo ""

# カウンタ
total_violations=0

# 検出関数
detect_pattern() {
    local category="$1"
    local pattern="$2"
    local description="$3"
    local severity="${4:-error}"  # error or warning

    local results
    if [ -d "$TARGET_PATH" ]; then
        results=$(grep -rn --include="*.md" -E "$pattern" "$TARGET_PATH" 2>/dev/null || true)
    else
        results=$(grep -n -E "$pattern" "$TARGET_PATH" 2>/dev/null || true)
    fi

    if [ -n "$results" ]; then
        if [ "$severity" = "warning" ]; then
            echo -e "${YELLOW}■ $category${NC}: $description"
        else
            echo -e "${RED}■ $category${NC}: $description"
        fi
        echo "$results" | while IFS= read -r line; do
            echo "   $line"
            ((total_violations++)) || true
        done
        echo ""
        return 1
    fi
    return 0
}

# ===== 汎用ルール（librarian/rules/forbidden-expressions.yaml 相当） =====

echo "【時間表現】"
echo "----------------------------------------"

detect_pattern "時間帯" "夕方|夜明け|真夜中" "夕方・夜明け・真夜中" || true
detect_pattern "太陽表現" "[^夕朝]日が[昇沈]|^日が[昇沈]|陽が[上沈]" "日が昇る・日が沈む" || true
detect_pattern "刻" "[一二三四五六七八九十半]刻[^まん]|[一二三四五六七八九十半]刻$" "〜刻（時間単位）" || true
detect_pattern "日数" "十日|半日ほど|一日[がだで]" "〜日（日数）" || true
detect_pattern "期間" "一週間|[一二三]ヶ月|[一二三]年" "週・月・年" || true
detect_pattern "相対日時" "今日|明日|昨日|去年|来年|来月|先月" "今日・明日・昨日・去年・来年・来月・先月" || true

echo ""
echo "【回数・数量表現】"
echo "----------------------------------------"

detect_pattern "年齢" "[0-9一二三四五六七八九十]+歳" "〜歳（年齢）" || true

echo ""
echo "【要確認（false positive の可能性あり）】"
echo "----------------------------------------"

detect_pattern "時間帯複合語" "朝食|昼食|昼飯|夕食|夕飯|朝ごはん|昼ごはん|夕ごはん" "食事の時間帯表現（要確認）" "warning" || true
detect_pattern "時間帯単体" "今朝|毎朝|朝から|昼から|昼過ぎ|昼間" "時間帯表現（要確認）" "warning" || true

# ===== プロジェクト固有ルール =====

PROJECT_RULES="$PROJECT_ROOT/librarian/rules/forbidden-expressions.sh"
if [ -n "$PROJECT_ROOT" ] && [ -f "$PROJECT_RULES" ]; then
    echo ""
    echo -e "${CYAN}【プロジェクト固有ルール】${NC}"
    echo "----------------------------------------"
    # shellcheck source=/dev/null
    source "$PROJECT_RULES"
fi

echo ""
echo "=========================================="
echo -e "検出完了"
echo "=========================================="
