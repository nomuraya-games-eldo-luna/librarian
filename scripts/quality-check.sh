#!/bin/bash
# 品質チェックスクリプト（レベル0-1の自動検出）
# 使用方法: ./quality-check.sh <原稿ファイル>

set -e

FILE="$1"

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "使用方法: $0 <原稿ファイル>"
  exit 1
fi

FILENAME=$(basename "$FILE")
echo "=== 品質チェック: $FILENAME ==="
echo ""

# カウンター
LEVEL0_ISSUES=0
LEVEL1_ISSUES=0

# ========================================
# レベル0: 没入感阻害要素
# ========================================
echo "[レベル0] 没入感阻害要素"
echo ""

# 章番号言及
CHAPTER_REFS=$(grep -n -E "(第[0-9]+章|[0-9]+章|Part[0-9]|Chapter[0-9])" "$FILE" 2>/dev/null || true)
if [ -n "$CHAPTER_REFS" ]; then
  echo "  ⚠️  章番号言及:"
  echo "$CHAPTER_REFS" | while read line; do
    echo "    $line"
  done
  LEVEL0_ISSUES=$((LEVEL0_ISSUES + 1))
else
  echo "  ✅ 章番号言及: なし"
fi

# 現実表現（数値+時間単位）
REALITY_REFS=$(grep -n -E "(三日前|1週間|24時間|[0-9]+日前|[0-9]+時間|[0-9]+分後)" "$FILE" 2>/dev/null || true)
if [ -n "$REALITY_REFS" ]; then
  echo "  ⚠️  現実表現:"
  echo "$REALITY_REFS" | while read line; do
    echo "    $line"
  done
  LEVEL0_ISSUES=$((LEVEL0_ISSUES + 1))
else
  echo "  ✅ 現実表現: なし"
fi

# メタ情報
META_REFS=$(grep -n -E "(場面転換|シーン[0-9]|見出し|ト書き)" "$FILE" 2>/dev/null || true)
if [ -n "$META_REFS" ]; then
  echo "  ⚠️  メタ情報:"
  echo "$META_REFS" | while read line; do
    echo "    $line"
  done
  LEVEL0_ISSUES=$((LEVEL0_ISSUES + 1))
else
  echo "  ✅ メタ情報: なし"
fi

echo ""

# ========================================
# レベル1: 基本品質
# ========================================
echo "[レベル1] 基本品質"
echo ""

# 文字数カウント（マークダウン記法を除く概算）
CHAR_COUNT=$(cat "$FILE" | sed 's/^#.*//g' | sed 's/\*\*//g' | sed 's/\*//g' | tr -d '\n' | wc -m | tr -d ' ')

if [ "$CHAR_COUNT" -lt 10000 ]; then
  echo "  ⚠️  文字数: ${CHAR_COUNT}文字（目標: 10,000字以上）→ 少なめ"
  LEVEL1_ISSUES=$((LEVEL1_ISSUES + 1))
else
  echo "  ✅ 文字数: ${CHAR_COUNT}文字（目標: 10,000字以上）"
fi

echo ""

# ========================================
# サマリー
# ========================================
echo "----------------------------------------"
if [ "$LEVEL0_ISSUES" -eq 0 ] && [ "$LEVEL1_ISSUES" -eq 0 ]; then
  echo "✅ レベル0-1: 問題なし"
else
  echo "検出された問題:"
  [ "$LEVEL0_ISSUES" -gt 0 ] && echo "  - レベル0: ${LEVEL0_ISSUES}件"
  [ "$LEVEL1_ISSUES" -gt 0 ] && echo "  - レベル1: ${LEVEL1_ISSUES}件"
fi
echo ""
echo "※ レベル2-3（五感描写、詩的表現等）は司書AIに相談してください"
