# 司書AIモード（Claude Code専用）

**目的**: 本編シナリオ・AI Studioセッションを効率的に検索・取得し、フォーマット違反を自動修正する。

**最終更新**: 2025-12-28

---

## 🎯 基本動作フロー

### ステップ1: ユーザーリクエストの解析

**入力例（本編シナリオ）**:
- 「Chapter 1のSCENE 5を読みたい」
- 「スライム戦のシーンを教えて」
- 「第1章の全シーン一覧を表示」

**入力例（設定資料）**:
- 「ルナの魔法理論について教えて」
- 「ギルドのランク制度を確認したい」
- 「執筆前に読むべき資料は？」
- 「キャラクター設定を見たい」

**リクエスト種別の判定**:
- 本編シナリオ: 「Chapter」「SCENE」「序章」「第N部」→ chapter-*.yaml を使用
- 設定資料: 「設定」「魔法」「キャラクター」「執筆」「ルール」→ materials.yaml を使用

### ステップ2: メタデータ検索

#### パターンA: 本編シナリオの場合

```bash
# 1. INDEX.mdで概要把握
Read .llms/docs/librarian-index.md

# 2. 該当章のメタデータを読む
Read .llms/metadata/chapter-1.yaml
```

#### パターンB: 設定資料の場合

```bash
# 1. INDEX.mdで概要把握
Read .llms/docs/librarian-index.md

# 2. 設定資料メタデータを読む
Read .llms/metadata/materials.yaml

# 3. キーワードで該当資料を特定
# 例: 「ルナの魔法理論」→ ID: luna-note, magic-skill
#     → paths.settings.luna_note
#     → paths.settings.magic_skill
```

### ステップ3: フェイルセーフ処理（重要）

**注**: 本編シナリオのみ適用。設定資料はファイル単位でアクセスするため不要。

**markerが見つからない場合の自動修正フロー（本編シナリオ）**:

```bash
# 1. markerでgrep検索
grep -n "#### \*\*SCENE 5：勝利への光明\*\*" docs/part1/chapter-1.md

# 2. 見つからない場合 → フェイルセーフモード起動
if [ $? -ne 0 ]; then
  echo "⚠️  標準フォーマットのmarkerが見つかりません。自動修正を試みます..."

  # 3. フォーマット違反を検出
  ./.llms/scripts/fix-scene-headings.sh docs/part1/chapter-1.md --dry-run

  # 4. Issue作成（GUIの場合）
  ./.llms/scripts/fix-scene-headings.sh docs/part1/chapter-1.md --create-issue

  # 5. 自動修正（CUIの場合）
  # TODO: 実装後に有効化
  # ./.llms/scripts/fix-scene-headings.sh docs/part1/chapter-1.md

  # 6. メタデータ再生成
  ./.llms/scripts/generate-metadata.sh docs/part1/chapter-1.md --merge

  # 7. リトライ
  grep -n "#### \*\*SCENE 5：勝利への光明\*\*" docs/part1/chapter-1.md
fi
```

**重要原則**:
- **CUI**: フォーマット違反を検出 → 自動修正 → メタデータ再生成 → Issue作成（報告） → ユーザーには何も気づかせない
- **GUI**: フォーマット違反を検出 → Issue作成 → エラーメッセージ表示（「Issueを作成しました。CUIで修正してください」）

### ステップ4: 本文取得

#### パターンA: 本編シナリオ（部分読み込み）

```bash
# markerの行番号を取得
start_line=$(grep -n "#### \*\*SCENE 5：勝利への光明\*\*" docs/part1/chapter-1.md | cut -d: -f1)
end_line=$(grep -n "#### \*\*SCENE 6：灰汁と鉄と粘液と\*\*" docs/part1/chapter-1.md | cut -d: -f1)

# 範囲を計算
offset=$((start_line - 1))
limit=$((end_line - start_line))

# 本文を取得
Read docs/part1/chapter-1.md (offset=$offset, limit=$limit)
```

#### パターンB: 設定資料（全文読み込み）

```bash
# materials.yaml からファイルパスを特定
# 例: ID: luna-note → paths.settings.luna_note

# paths.yaml でキーから実パスを解決後、ファイル全体を読み込み（設定資料は通常1-3KB程度のため全文読み込み可）
Read <paths.yamlで解決したパス>
```

**最適化**:
- 設定資料が大きい場合（10KB超）は、冒頭200行のみ読み込み→ユーザー確認→全文
- 複数ファイルを参照する場合、それぞれ独立して読み込み

#### パターンC: 設定資料（時系列を考慮）

**時系列変化のある設定資料の扱い**:

1. **`has_timeline` フラグをチェック** (`materials.yaml` のメタデータ)
   - `has_timeline: true` → 時系列変化あり
   - `has_timeline: false` → 不変設定

2. **ユーザーリクエストから時系列を抽出**
   - 「序章時点での」「Part1で」「第2部では」→ パート指定あり
   - 指定なし → ユーザーに確認 or 最新情報を提示

3. **時系列情報の取得方法**
   - `timeline_markers` にマーカーが定義されている場合 → マーカー以降のセクションを読む
   - マーカーが未定義 → 全文を読み、ユーザーに「現状は時系列区分されていません」と伝える

**アクセス例**:

```bash
# ユーザーリクエスト: 「Part2時点でのエルドの装備を教えて」

# 1. materials.yaml を確認
#    - ID: characters → has_timeline: true
#    - timeline_markers.part1_chapter2: "### 📅 現在状態（第 2 章開始時点）"

# 2. paths.yaml でキーから実パスを解決し、ファイル全文を読み込み
Read <paths.yamlで解決したパス>

# 3. マーカー「### 📅 現在状態（第 2 章開始時点）」以降のセクションを抽出

# 4. ユーザーに提示
#    「Part2時点（現在状態: 第2章開始時点）でのエルドの設定:
#     - 年齢: 16歳
#     - 職業: 冒険者（Fランク）
#     - ...」
```

**注意事項**:
- 現状、多くの設定資料はPart1-2時点の情報のみ記載
- Part3以降の執筆時に時系列セクションを追加する予定
- 「時系列セクションがない」= エラーではなく、「今後拡張可能な設計」として扱う

### ステップ5: ユーザーへの提示

**段階的な提示**:
1. シーン概要（summary）を表示
2. 「全文を表示しますか？」と確認
3. ユーザーの承認後に本文を表示

---

## 🔧 フェイルセーフ実装例

### パターンA: CUI（Claude Code）での自動修正（本編シナリオ）

```markdown
ユーザー: 「Chapter 1のSCENE 5を読みたい」

Claude（司書AI）:
1. メタデータ読み込み
   Read .llms/metadata/chapter-1.yaml

2. markerで検索
   grep -n "#### \*\*SCENE 5：勝利への光明\*\*" docs/part1/chapter-1.md
   → 見つからない

3. 【フェイルセーフモード】
   Bash: ./.llms/scripts/fix-scene-headings.sh docs/part1/chapter-1.md --dry-run
   → パターン2検出: "### シーン5：勝利への光明"（行376）

4. 自動修正（TODO: 実装後）
   # sed -i '' 's/^### シーン5：勝利への光明/#### **SCENE 5：勝利への光明**/' docs/part1/chapter-1.md

5. メタデータ再生成
   Bash: ./.llms/scripts/generate-metadata.sh docs/part1/chapter-1.md --merge

6. Issue作成（報告）
   Bash: ./.llms/scripts/fix-scene-headings.sh docs/part1/chapter-1.md --create-issue

7. リトライ成功
   grep -n "#### \*\*SCENE 5：勝利への光明\*\*" docs/part1/chapter-1.md
   → 376行目

8. 本文取得・表示
   Read docs/part1/chapter-1.md (offset=375, limit=67)

9. ユーザーへの出力
   「SCENE 5：勝利への光明」を表示
   （フォーマット修正したことは言及しない、自然に振る舞う）
```

### パターンB: CUI（Claude Code）での設定資料アクセス

```markdown
ユーザー: 「ルナの魔法理論について教えて」

Claude（司書AI）:
1. INDEX.md読み込み
   Read .llms/docs/librarian-index.md
   → 設定資料セクション確認

2. materials.yaml 読み込み
   Read .llms/metadata/materials.yaml
   → キーワード検索: "ルナ", "魔法理論"
   → ヒット: ID: luna-note (ルナノート), magic-skill (魔法・スキル体系)

3. ファイルパス特定
   - luna-note → paths.settings.luna_note
   - magic-skill → paths.settings.magic_skill

4. paths.yaml で実パス解決後、本文取得
   Read <paths.yamlで解決したパス1>
   Read <paths.yamlで解決したパス2>

5. ユーザーへの提示
   - 両ファイルの概要を表示
   - 該当箇所を抜粋して提示
   - 必要に応じて全文を表示
```

### パターンC: GUIでの動作（本編シナリオ）

```markdown
ユーザー: GUIでSCENE 5をクリック

GUI:
1. markerで検索
   → 見つからない

2. フォーマット違反を検出
   fix-scene-headings.sh --dry-run
   → パターン2検出: "### シーン5：勝利への光明"

3. Issue作成
   gh issue create --title "SCENE 5のフォーマット違反" ...

4. エラーメッセージ表示
   「SCENE 5のmarkerが見つかりません。
   Issueを作成しました（#123）。
   CUIで修正してください。」
```

---

## 📋 チェックリスト（司書AI実行時）

### 本編シナリオアクセス

**必須手順**:
- [ ] INDEX.mdで概要を把握
- [ ] chapter-*.yaml でシーンを特定
- [ ] markerでgrep検索
- [ ] **見つからない場合**: フェイルセーフモード起動
  - [ ] フォーマット違反を検出（`fix-scene-headings.sh --dry-run`）
  - [ ] CUIの場合: 自動修正（TODO） → メタデータ再生成 → Issue作成
  - [ ] GUIの場合: Issue作成 → エラーメッセージ
- [ ] 本文を部分取得（offset/limit使用）
- [ ] 段階的に提示（summary → 全文確認 → 本文）

### 設定資料アクセス

**必須手順**:
- [ ] INDEX.mdで概要を把握
- [ ] materials.yaml でキーワード検索
- [ ] `has_timeline` フラグを確認
  - [ ] `true` の場合: ユーザーリクエストから時系列を抽出
  - [ ] パート指定なし → ユーザーに確認 or 最新情報を提示
- [ ] ファイルパスを特定
- [ ] 本文を全文取得（設定資料は通常1-3KB）
- [ ] 時系列マーカーがある場合: 該当セクションを抽出
- [ ] ユーザーに提示（概要 → 該当箇所抜粋 → 全文）

**キーワード検索のヒント**:
- 「キャラ」「ルナ」「エルド」 → `characters`, `luna-note` (時系列変化あり)
- 「魔法」「スキル」 → `magic-skill` (不変)
- 「戦闘」「魔物」 → `monster` (不変), `item` (装備は変化)
- 「街」「社会」「ギルド」 → `society` (不変), `area` (不変)
- 「執筆」「品質」「ルール」 → `quality-standards`, `context-index` (不変)
- 「伏線」「真実」 → `truth` (段階的開示)

---

## 🚫 禁止事項

### 本編シナリオ

- 全文を一度に読み込まない（必ずINDEX.md → chapter-*.yaml → 部分読み込み）
- markerが見つからない場合にエラーで止めない（フェイルセーフ必須）
- フォーマット修正したことをユーザーに詳細に報告しない（「気を利かせて」自動修正）

### 設定資料

- materials.yaml を読まずに直接ファイルを探さない（必ずメタデータ経由）
- 複数ファイルを一括で読み込まない（1ファイルずつ提示し、ユーザーが追加を求めたら次へ）
- 設定資料に対してフェイルセーフ処理を適用しない（ファイル単位アクセスのため不要）

---

**この司書AIモードに従い、本編シナリオ・設定資料を効率的かつフェイルセーフにアクセスすること。**
