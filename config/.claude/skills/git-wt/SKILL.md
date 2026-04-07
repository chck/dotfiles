---
name: git-wt
description: >
  git-wt コマンドで Git worktree を作成し、作業ディレクトリを分離して実装を行う。
  作業完了後はユーザー確認を経て worktree を削除する。
  ユーザーが「worktree」「ワークツリー」「ブランチを分けて」「wt で」など明示的に指定した場合にのみ起動する。
---

# Git Worktree

`git-wt` で worktree を作成し、メインブランチを汚さず作業する。
失敗しても `git wt -d` で綺麗に元に戻せる。

## 実行手順

### Step 1: worktree を作成する

タスク内容からブランチ名を決め、worktree を作成する。

```bash
git wt <branch-name> --nocd
```

`.worktrees/<branch-name>/` 配下に worktree が作成され、パスが出力される。
出力されたパスを `WORKTREE_PATH` として記録する。

### Step 2: worktree 内で作業する

以降の操作はすべて `WORKTREE_PATH` 配下で行う。

- Read/Edit/Write ツール: `$WORKTREE_PATH/src/...` のように絶対パスで指定
- Bash: `cd $WORKTREE_PATH && <command>`

### Step 3: 完了報告

作業完了後、ユーザーに以下を伝える:
- 変更ファイル一覧と概要
- worktree パス
- マージ方法（例: `cd $WORKTREE_PATH && git push -u origin <branch-name>` → PR作成）

### Step 4: クリーンアップ

`claude -w` の公式挙動に合わせ、変更の有無でクリーンアップを分岐する。

#### 変更なし（未コミット・未変更）の場合

worktree とブランチを自動削除する。ユーザー確認は不要。

```bash
git wt -d <branch-name>
```

#### 変更またはコミットがある場合

ユーザーに「保持」か「削除」かを確認する。

- **保持**: worktree とブランチをそのまま残す。後で `cd $WORKTREE_PATH` で戻れることを伝える。
- **削除**: 未コミットの変更とコミットがすべて破棄されることを警告した上で削除する。

```bash
# 通常削除（マージ済みブランチ）
git wt -d <branch-name>

# 強制削除（未マージの変更がある場合、ユーザーが明示的に指示した場合のみ）
git wt -D <branch-name>
```

## ブランチ命名規則

| 種別 | プレフィックス | 例 |
|-----|-------------|-----|
| 機能追加・変更 | `feat/` | `feat/add-dark-mode` |
| バグ修正 | `fix/` | `fix/image-upload-error` |

feat/, fix/ いずれかを判断し、issue番号とリンクする場合は
feat/16-add-dark-mode, fix/20-image-upload-error のようにissue番号を含めること

## 複数エージェントの並行作業

Agent ツールで複数サブエージェントを起動する場合、それぞれ別ブランチ名で worktree を作成する。
各エージェントに worktree パスを明示的に伝える。

```bash
git wt feat/feature-a --nocd  # → .worktrees/feat/feature-a
git wt feat/feature-b --nocd  # → .worktrees/feat/feature-b
```
