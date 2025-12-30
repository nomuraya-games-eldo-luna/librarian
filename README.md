# librarian

**執筆支援システム（司書AI）**

## 目的

執筆プロジェクトを支援する**汎用フレームワーク**。プロジェクト固有設定と組み合わせて使用する。

---

## アーキテクチャ

```
librarian/                      # 汎用フレームワーク（本リポジトリ）
├── claude/librarian.md         # 司書AIモード定義
├── rules/                      # 汎用ルール定義
│   └── forbidden-expressions.yaml
├── scripts/                    # 汎用スクリプト
│   ├── detect-forbidden-expressions.sh
│   ├── quality-check.sh
│   └── ...
├── prompts/                    # プロンプトテンプレート
└── framework/                  # ドキュメント

{project}/                      # プロジェクトリポジトリ
├── librarian/                  # プロジェクト固有オーバーライド
│   ├── claude/librarian.md     # 固有の司書AI設定（任意）
│   └── rules/
│       └── forbidden-expressions.sh  # 固有ルール
├── 設定/
└── 原稿/
```

**優先順位**: プロジェクト固有設定 > librarian汎用設定

---

## 提供機能

### 1. スクリプト（scripts/）

| スクリプト | 用途 |
|-----------|------|
| `detect-forbidden-expressions.sh` | 禁止表現検出（汎用+プロジェクト固有ルール） |
| `quality-check.sh` | 品質チェック（文字数等） |
| `generate-metadata.sh` | メタデータ自動生成 |
| `validate-markers.sh` | マーカーバリデーション |
| `fix-scene-headings.sh` | フォーマット修正 |
| `pre-commit-check.sh` | pre-commitフック |
| `install-hooks.sh` | Git hooksインストーラー |

### 2. ルール定義（rules/）

| ファイル | 内容 |
|---------|------|
| `forbidden-expressions.yaml` | 禁止表現の汎用ルール定義 |

### 3. プロンプトテンプレート（prompts/）

| ファイル | 用途 |
|---------|------|
| `scene-generation.md` | シーン生成プロンプト |
| `quality-check.md` | 品質チェックプロンプト |
| `context-presets.md` | コンテキストプリセット |

### 4. 司書AIモード（claude/）

| ファイル | 内容 |
|---------|------|
| `librarian.md` | Claude Code向け司書AIモード定義 |

---

## 使い方

### プロジェクトでの設定

1. **プロジェクト固有ルールを作成**

```bash
mkdir -p {project}/librarian/rules
```

2. **固有ルールを定義**

```bash
# {project}/librarian/rules/forbidden-expressions.sh
# detect_pattern 関数を使用してプロジェクト固有のチェックを追加

detect_pattern "商人" "商人|商工会" "専業商人は存在しない" || true
```

3. **スクリプトを実行**

```bash
# librarianのスクリプトを直接実行
librarian/scripts/detect-forbidden-expressions.sh "原稿/xxx.md" "{project}"

# またはシンボリックリンクを作成
ln -s ../../librarian/scripts/detect-forbidden-expressions.sh {project}/scripts/
```

### 司書AIモードの使用

```bash
# Claude Codeで
# 1. 司書AI起動
# 2. librarian/claude/librarian.md が読み込まれる
# 3. {project}/librarian/claude/librarian.md があれば追加読み込み
```

---

## 対応プロジェクト

| プロジェクト | 固有設定 |
|-------------|---------|
| book-1-notitle | `librarian/rules/forbidden-expressions.sh` |

---

## 更新履歴

- 2025-12-30: 2層構造（汎用+プロジェクト固有）に再設計
- 2025-12-29: 初版作成
