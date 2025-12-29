# シーンナビゲーションフレームワーク（汎用版）

**目的**: 物語コンテンツの効率的なナビゲーションを実現する汎用フレームワーク。

**特徴**:
- プロジェクト非依存（paths.yaml で設定）
- AI非依存（Claude、Gemini、Codex、ChatGPT 共通）
- 言語非依存（日本語・英語対応）

---

## 設計原則

### 1. 三層アーキテクチャ

```
┌─────────────────────────────────┐
│  実行層（Mode/Script/Skill）      │  ← AI固有の実装
├─────────────────────────────────┤
│  設定層（paths.yaml）             │  ← プロジェクト固有の設定
├─────────────────────────────────┤
│  共通ロジック層（本フレームワーク）  │  ← 汎用的な処理
└─────────────────────────────────┘
```

### 2. データ構造の標準化

**YAMLメタデータフォーマット** - すべてのプロジェクトで統一:
```yaml
---
chapter: <番号>
title: "<タイトル>"
total_lines: <本文の総行数>
total_scenes: <シーン総数>
scenes:
  - number: <シーン番号>
    title: "<シーンタイトル>"
    line_start: <開始行>
    line_end: <終了行>
    summary: "<1行概要>"
---
```

**INDEX.md フォーマット** - すべてのプロジェクトで統一:
```markdown
# INDEX.md

## ファイル構造

| パート | ファイル | サイズ | 行数 | シーン数 | 内容 |
|--------|---------|--------|------|---------|------|
| ... | ... | ... | ... | ... | ... |

## 内容概要

### ファイル名

**ストーリー**: ...
**主要イベント**: ...
**登場キャラクター**: ...
**テーマ**: ...

## 主要シーン検索テーブル

| カテゴリ | キーワード | ファイル | 該当行 |
|---------|-----------|---------|--------|
| ... | ... | ... | ... |
```

---

## シーンナビゲーションパターン

### パターン1: シーン単位の取得

**入力**: シーン番号（例: 5）

**処理フロー**:
```
1. YAMLメタデータを読み込み
2. scenes配列からnumber == 5を検索
3. line_start, line_endを取得
4. offset = line_start - 1, limit = line_end - line_start + 1 を計算
5. Read(file_path, offset, limit)を実行
```

**疑似コード**:
```python
def get_scene(file_path, scene_number):
    # YAML frontmatter読み込み（最初の50行程度）
    yaml_data = read_yaml_frontmatter(file_path)

    # シーン検索
    scene = next((s for s in yaml_data['scenes'] if s['number'] == scene_number), None)

    if not scene:
        raise SceneNotFoundError(f"SCENE {scene_number} not found")

    # 行番号計算
    offset = scene['line_start'] - 1
    limit = scene['line_end'] - scene['line_start'] + 1

    # 読み込み
    return read_file(file_path, offset, limit)
```

---

### パターン2: シーンジャンプ

**入力**: 現在のシーン番号（例: 1）、ジャンプ先のシーン番号（例: 5）

**処理フロー**:
```
1. パターン1と同様にシーン5を取得
2. current_sceneを5に更新
3. 「SCENE 2-4をスキップしました」と通知
```

**状態管理**:
```python
session_state = {
    'current_chapter': 1,
    'current_scene': 5,
    'file_path': 'docs/part1/chapter-1.md',
    'yaml_metadata': {...}  # キャッシュ
}
```

---

### パターン3: 範囲指定

**入力**: 開始シーン番号（例: 3）、終了シーン番号（例: 7）

**処理フロー**:
```
1. YAMLメタデータからSCENE 3, 4, 5, 6, 7を取得
2. 最初のシーンのline_start、最後のシーンのline_endを使用
3. 総行数を計算してユーザーに通知（例: 400行、約750トークン）
4. ユーザー承認後にRead(offset=SCENE3.line_start-1, limit=SCENE7.line_end-SCENE3.line_start+1)
```

**疑似コード**:
```python
def get_scene_range(file_path, start_scene, end_scene):
    yaml_data = read_yaml_frontmatter(file_path)

    # 範囲内のシーンを取得
    scenes_in_range = [s for s in yaml_data['scenes']
                       if start_scene <= s['number'] <= end_scene]

    if not scenes_in_range:
        raise SceneRangeError(f"SCENE {start_scene}-{end_scene} not found")

    # 範囲の開始・終了を計算
    first_scene = scenes_in_range[0]
    last_scene = scenes_in_range[-1]

    offset = first_scene['line_start'] - 1
    limit = last_scene['line_end'] - first_scene['line_start'] + 1

    # コンテキスト消費を推定（約2トークン/行）
    estimated_tokens = limit * 2

    # ユーザー確認
    print(f"SCENE {start_scene}-{end_scene}は約{limit}行（約{estimated_tokens}トークン）です。")
    print("表示しますか？")

    # 承認後に読み込み
    return read_file(file_path, offset, limit)
```

---

### パターン4: キーワード検索

**入力**: キーワード（例: "スライム戦"）

**処理フロー**:
```
1. INDEX.mdの主要シーン検索テーブルで検索
2. または、YAMLメタデータのtitle/summaryで検索
3. 該当シーンが見つかったらパターン1で取得
```

**疑似コード**:
```python
def search_keyword(keyword, index_path, file_path):
    # INDEX.md検索テーブルで検索
    search_result = grep_in_index(index_path, keyword)

    if search_result:
        # ファイルパス、該当行を取得
        return get_scene_by_line(search_result['file_path'], search_result['line_number'])

    # YAMLメタデータで検索
    yaml_data = read_yaml_frontmatter(file_path)

    for scene in yaml_data['scenes']:
        if keyword in scene['title'] or keyword in scene['summary']:
            return get_scene(file_path, scene['number'])

    raise KeywordNotFoundError(f"Keyword '{keyword}' not found")
```

---

### パターン5: 章一覧の表示

**入力**: なし

**処理フロー**:
```
1. INDEX.mdを読み込み
2. ファイル構造テーブルを表示
3. 内容概要を表示
```

**出力例**:
```
## 本編シナリオ 章一覧

| パート | ファイル | シーン数 | 内容 |
|--------|---------|---------|------|
| 序章 | prologue.md | 10 | エルドとルナの出会い～村崩壊～旅立ち |
| 第1部 | part1/chapter-1.md | 9 | 冒険者登録、最初の依頼、スライム退治 |
| 第1部 | part1/chapter-2.md | - | （章のテーマ） |
...

どの章を読みますか？
```

---

## YAMLメタデータのパース方法

### YAMLフロントマターの読み込み

**構造**:
```markdown
---
chapter: 1
title: "タイトル"
scenes: [...]
---

### **章タイトル**
本文...
```

**読み込み方法**:
```python
def read_yaml_frontmatter(file_path):
    """
    ファイルの最初の50行程度を読み込み、YAML frontmatterをパースする
    """
    # 最初の50行を読み込み（offset=0, limit=50）
    lines = read_file_lines(file_path, 0, 50)

    # YAML部分を抽出（--- で囲まれた部分）
    yaml_content = extract_yaml_block(lines)

    # YAMLをパース
    import yaml
    return yaml.safe_load(yaml_content)

def extract_yaml_block(lines):
    """
    --- で囲まれたYAMLブロックを抽出
    """
    in_yaml = False
    yaml_lines = []

    for line in lines:
        if line.strip() == '---':
            if in_yaml:
                # 2つ目の --- で終了
                break
            else:
                # 1つ目の --- で開始
                in_yaml = True
        elif in_yaml:
            yaml_lines.append(line)

    return '\n'.join(yaml_lines)
```

---

## エラーハンドリングパターン

### 1. YAMLメタデータが存在しない

**検出方法**:
```python
def has_yaml_frontmatter(file_path):
    """
    ファイルがYAML frontmatterを持つか確認
    """
    first_line = read_file_lines(file_path, 0, 1)[0]
    return first_line.strip() == '---'
```

**対応**:
- INDEX.mdで概要のみ提示
- ユーザーに通知: 「YAMLメタデータ未整備のため、全文読み込みが必要です」
- 承認後に全文表示

### 2. INDEX.mdが存在しない

**検出方法**:
```python
def has_index_md(base_path):
    """
    INDEX.mdが存在するか確認
    """
    return os.path.exists(os.path.join(base_path, 'INDEX.md'))
```

**対応**:
- ファイル一覧を取得（Glob）
- ユーザーに通知: 「INDEX.md未整備のため、ファイル名から推測します」
- ファイル名ベースで該当ファイルを特定

### 3. シーン番号が範囲外

**検出方法**:
```python
def validate_scene_number(yaml_data, scene_number):
    """
    シーン番号が有効範囲内か確認
    """
    total_scenes = yaml_data['total_scenes']
    if not (1 <= scene_number <= total_scenes):
        raise SceneOutOfRangeError(
            f"SCENE {scene_number} is out of range (1-{total_scenes})"
        )
```

**対応**:
- エラーメッセージ: 「第1章はSCENE 1-9です。SCENE 10は存在しません」
- 章一覧を表示して再選択を促す

### 4. ファイルパスが見つからない

**検出方法**:
```python
def validate_file_path(file_path):
    """
    ファイルが存在するか確認
    """
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File not found: {file_path}")
```

**対応**:
- INDEX.mdでファイル一覧を確認
- ユーザーに通知: 「該当ファイルが見つかりません」
- ファイル一覧を表示して再選択を促す

---

## コンテキスト消費の最適化戦略

### 戦略1: INDEX.mdファースト

**原則**: 全文を読む前に必ずINDEX.mdで概要を把握

**効果**:
- INDEX.md: 約100トークン
- 全文読み込みを回避: 約1,500トークン → 93%削減

### 戦略2: YAMLメタデータキャッシュ

**原則**: YAMLメタデータを一度読み込んだらセッション中はキャッシュ

**効果**:
- 初回: 約50トークン
- 2回目以降: 0トークン（キャッシュから取得）

### 戦略3: 部分読み込み

**原則**: シーン単位、範囲指定で必要な部分のみ読み込み

**効果**:
- SCENE 1のみ: 約150トークン（全文の10%）
- SCENE 3-7: 約750トークン（全文の50%）

### 戦略4: 段階的な提示

**原則**: 全文リクエストでも、まずはシーン一覧を提示

**効果**:
- ユーザーが特定シーンのみ選択 → 90%削減
- ユーザーが全文を要求 → 0%削減（しかし意図的な選択）

---

## プロジェクト移行時の手順

### 新規プロジェクトへの適用

**前提条件**:
- 本フレームワークは汎用的に設計されている
- プロジェクト固有の設定は paths.yaml に記載

**手順**:
1. **paths.yaml作成**
   ```yaml
   project_name: "new_novel_project"
   base_path: "/Users/nomuraya/workspace-ai/nomuraya-projects/new_novel_project"
   index_md_path: "docs/INDEX.md"
   chapter_pattern: "docs/part{part}/chapter-{chapter}.md"
   ```

2. **INDEX.md作成**
   - 本フレームワークの標準フォーマットに従う

3. **YAMLメタデータ追加**
   - 各章ファイルにYAML frontmatterを追加

4. **司書AIモード作成**
   - `.llms/claude/librarian.md` をプロジェクトに配置
   - paths.yamlを参照するように修正

5. **動作検証**
   - シーン単位の取得
   - シーンジャンプ
   - 範囲指定
   - キーワード検索

---

## 他AI環境への移行

### Gemini環境への適用

**差分**:
- `.llms/claude/librarian.md` → `.llms/gemini/librarian.md` を作成
- Readツールのパラメータ名が異なる可能性（offset/limit → start/count等）

### Codex環境への適用

**差分**:
- `.llms/codex/librarian.md` を作成
- VSCodeのAPIを活用する場合の実装差分

### ChatGPT環境への適用

**差分**:
- ChatGPT Web版ではファイル読み込み制限あり
- スクリプト化が推奨される（librarian.py）

---

## パフォーマンス測定

### 測定項目

| 項目 | 測定方法 |
|------|---------|
| **コンテキスト消費** | トークン数をカウント |
| **レスポンス速度** | Read実行時間を測定 |
| **ユーザー満足度** | シーン検索の成功率 |

### 目標値

| 項目 | 目標値 |
|------|--------|
| **コンテキスト削減率** | 70-90% |
| **レスポンス速度** | 3秒以内 |
| **検索成功率** | 95%以上 |

---

## 今後の拡張可能性

### フェーズ1（現在）: プロトタイプ

- rpg_adv_notitle専用
- INDEX.md + YAMLメタデータ
- Claude Code専用モード

### フェーズ2: 汎用化

- paths.yaml導入
- 他プロジェクトへの適用
- 他AI環境への移行

### フェーズ3: スクリプト化

- librarian.py作成
- 高速化（YAMLパース、検索処理）
- バッチ処理対応

### フェーズ4: スキル化

- 全AI共通スキル
- 自動起動（キーワード検出）
- 他プロジェクトへの自動適用

---

## 参照

**プロジェクト固有の実装**:
- `.llms/claude/librarian.md` - Claude固有の実装
- `paths.yaml` - プロジェクト固有の設定

**設計ドキュメント**:
- `/tmp/librarian-system-scalable-design.md` - スケーラブル設計
- `/tmp/scene-jump-use-case-analysis.md` - シーンジャンプのユースケース
- `/tmp/librarian-ai-full-text-retrieval-analysis.md` - 全文取得の分析
