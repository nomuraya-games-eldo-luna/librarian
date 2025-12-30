# librarian 使用ガイド（AI向け）

**役割**: 執筆支援汎用フレームワーク
**最終更新**: 2025-12-30

---

## 概要

librarianは執筆プロジェクトを支援する**汎用フレームワーク**。プロジェクト固有設定と組み合わせて使用する。

```yaml
アーキテクチャ: 2層構造
  汎用層: librarian/（このリポジトリ）
  固有層: {project}/librarian/（プロジェクト側）

優先順位: プロジェクト固有 > librarian汎用
```

---

## ディレクトリ構造

```
librarian/
├── AGENTS.md              # 本ファイル（AI向けガイド）
├── README.md              # 人間向け詳細説明
├── paths.yaml             # パス参照
├── claude/
│   └── librarian.md       # 司書AIモード定義
├── rules/
│   └── forbidden-expressions.yaml  # 汎用禁止表現ルール
├── scripts/
│   ├── detect-forbidden-expressions.sh  # 禁止表現検出
│   └── quality-check.sh   # 品質チェック
├── prompts/               # プロンプトテンプレート
├── docs/                  # ドキュメント
└── framework/             # フレームワーク資料
```

---

## 使い方

### 1. 禁止表現検出

```bash
# 基本（プロジェクトルート自動検出）
librarian/scripts/detect-forbidden-expressions.sh "原稿/xxx.md"

# プロジェクト指定
librarian/scripts/detect-forbidden-expressions.sh "原稿/xxx.md" "/path/to/project"
```

**動作**:
1. 汎用ルール（時間表現、年齢等）をチェック
2. `{project}/librarian/rules/forbidden-expressions.sh` があれば追加実行

### 2. 司書AIモード

```yaml
起動: 「司書AI」「librarian」「壁打ち」

読み込み順:
  1. librarian/claude/librarian.md（汎用）
  2. {project}/librarian/claude/librarian.md（固有、あれば）
```

### 3. プロジェクト固有ルールの追加

```bash
# プロジェクト側に作成
mkdir -p {project}/librarian/rules

# forbidden-expressions.sh を作成
# detect_pattern 関数を使用
```

例（book-1-notitle）:
```bash
# 世界観違反
detect_pattern "商人" "商人|商工会" "専業商人は存在しない" || true

# 呼称チェック
detect_pattern "呼称" "女たち|男たち" "エルドの性格に合わない呼称" || true
```

---

## 提供機能一覧

| カテゴリ | ファイル | 用途 |
|---------|---------|------|
| **スクリプト** | `scripts/detect-forbidden-expressions.sh` | 禁止表現検出 |
| | `scripts/quality-check.sh` | 品質チェック |
| **ルール** | `rules/forbidden-expressions.yaml` | 禁止表現定義 |
| **モード** | `claude/librarian.md` | 司書AIモード |
| **プロンプト** | `prompts/*.md` | テンプレート |

---

## 対応プロジェクト

| プロジェクト | 固有設定 |
|-------------|---------|
| book-1-notitle | `librarian/rules/forbidden-expressions.sh` |

---

## 関連リポジトリ

| リポジトリ | 役割 |
|-----------|------|
| worldbuilding | 世界観設定（参照先） |
| book-1-notitle | 原稿プロジェクト（利用側） |
| originals | セッションログ原文 |
| .github-private | オーガニゼーション管理 |
