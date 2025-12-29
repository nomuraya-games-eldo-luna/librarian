# librarian

**執筆支援システム（司書AI）**

## 目的

このリポジトリは、小説・ゲームシナリオなどの執筆プロジェクトを支援する**汎用的な執筆支援システム**です。

### 含まれるもの（仕組み）

- **シーンナビゲーションフレームワーク**: AIがシーン単位でコンテンツを検索・参照する仕組み
- **メタデータ生成スクリプト**: シーン情報を自動生成・バリデーション
- **司書AIプロンプト**: Claude/Gemini/ChatGPT向けの司書AI実装
- **汎用的なフレームワーク**: プロジェクト非依存の再利用可能なロジック

### 含まれないもの（コンテンツ）

- **プロジェクト固有のINDEX**: 各プロジェクトの章・シーン情報（→ 各プロジェクトリポジトリの.llms/に配置）
- **プロジェクト固有のメタデータ**: chapter-1.yaml等（→ 各プロジェクトリポジトリの.llms/metadata/に配置）
- **プロジェクト固有の設定**: structure-mapping.yaml、worldbuilding-inference.yaml等（→ 各プロジェクトリポジトリに配置）

## ディレクトリ構成

```
librarian/
├── README.md                    # このファイル
├── framework/                   # 汎用フレームワーク（AI非依存）
│   └── scene-navigation.md      # シーンナビゲーションの仕組み
├── claude/                      # Claude固有の実装
│   └── librarian.md             # Claude版司書AIモード
├── gemini/                      # Gemini固有の実装（将来追加）
├── chatgpt/                     # ChatGPT固有の実装（将来追加）
├── docs/                        # ドキュメント・仕様
│   └── scene-heading-format.md  # シーン見出しフォーマット仕様
├── prompts/                     # プロンプトテンプレート
│   ├── scene-generation.md      # シーン生成プロンプト
│   ├── quality-check.md         # 品質チェックプロンプト
│   └── context-presets.md       # コンテキストプリセット
└── scripts/                     # 自動化スクリプト
    ├── generate-metadata.sh     # メタデータ自動生成
    ├── validate-markers.sh      # markerバリデーション
    ├── fix-scene-headings.sh    # フォーマット修正
    ├── pre-commit-check.sh      # pre-commitフック
    └── install-hooks.sh         # Git hooksインストーラー
```

## 使い方

### 1. 各プロジェクトでの設定

執筆プロジェクト（例: RPG-1、ADV-1）のリポジトリに以下を配置：

```
RPG-1/
├── 物語/                        # 本編シナリオ
│   ├── prologue.md
│   └── part1/
│       └── chapter-1.md
├── .llms/                       # プロジェクト固有のAI作業領域
│   ├── docs/
│   │   └── librarian-index.md   # このプロジェクト固有のINDEX
│   └── metadata/
│       └── chapter-1.yaml       # このプロジェクト固有のメタデータ
└── paths.yaml                   # パス設定（librarian参照を含む）
```

### 2. paths.yamlでlibrarianを参照

```yaml
# RPG-1/paths.yaml

external:
  librarian:
    root: "../librarian"
    framework: "../librarian/framework/scene-navigation.md"
    claude: "../librarian/claude/librarian.md"
    scripts: "../librarian/scripts"
```

### 3. メタデータ生成

```bash
# librarian/scripts/を使用してメタデータ生成
../librarian/scripts/generate-metadata.sh 物語/part1/chapter-1.md
```

## 他プロジェクトでの再利用

このlibrarianリポジトリは、nomuraya-games-eldo-lunaオーガニゼーション以外でも再利用可能です。

1. librarianリポジトリをクローン
2. 執筆プロジェクトの.llms/にプロジェクト固有データを配置
3. paths.yamlでlibrarianを参照

## 移行元

rpg_adv_notitle/.llms/から以下を移行：

- framework/scene-navigation.md
- claude/librarian.md
- docs/scene-heading-format.md
- prompts/*.md（scene-generation.md、quality-check.md、context-presets.md）
- scripts/*.sh

詳細は [.github-private/decisions/003-llms-directory-separation.md](https://github.com/nomuraya-games-eldo-luna/.github-private/blob/main/decisions/003-llms-directory-separation.md) を参照。

## ライセンス

（未定）

## 貢献

（未定）

