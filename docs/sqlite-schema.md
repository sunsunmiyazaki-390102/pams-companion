# PAMS Companion

# SQLiteデータベース設計
### SQLite Schema

---

## 文書情報

| 項目 | 内容 |
|---|---|
| 文書名 | sqlite-schema.md |
| プロジェクト | PAMS Companion |
| 作成日 | 2026年7月30日 |
| 最終更新日 | 2026年7月30日 |
| 版数 | 0.1 |

---

# 更新履歴

| 日付 | 版 | 内容 |
|---|---|---|
| 2026年7月30日 | 0.1 | 端末内完結型MVPの初期SQLiteスキーマを定義 |

---

# 1. 本書の目的

本書は、PAMS Companionのスマートフォンアプリが端末内で使用するSQLiteデータベースの構造を定義する。

PAMS Companionは、利用者のプロジェクト、AIとの対話、知識資産、決定事項、TODOなどを端末内に保存する。

初期版では外部サーバーを使用せず、利用者のデータを利用者自身のデバイス内で管理する。

本書は、次の実装の基礎資料とする。

- Flutterのデータモデル
- SQLiteのテーブル作成
- Repository層
- バックアップと復元
- アプリ更新時のデータ移行

---

# 2. 基本方針

## 2.1 端末内完結

初期版では、すべてのデータを端末内のSQLiteデータベースに保存する。

利用者の操作によらない外部送信は行わない。

---

## 2.2 主キー

各主要テーブルの主キーにはUUID文字列を使用する。

```sql
id TEXT PRIMARY KEY
```

UUIDはFlutterアプリ側で生成する。

例：

```text
550e8400-e29b-41d4-a716-446655440000
```

UUIDを使用することで、将来のバックアップ統合や複数端末対応にも備える。

---

## 2.3 日時

日時はISO 8601形式の文字列として保存する。

```text
2026-07-30T10:30:00+09:00
```

基本となる日時列は次のとおりとする。

```sql
created_at TEXT NOT NULL
updated_at TEXT NOT NULL
```

日時はFlutterアプリ側で生成し、タイムゾーン情報を含めて保存する。

---

## 2.4 論理削除

主要データは、原則として直ちに物理削除しない。

削除日時を次の列へ記録する。

```sql
deleted_at TEXT
```

`deleted_at` が `NULL` の場合は有効なデータとする。

日時が設定されている場合は削除済みとする。

---

## 2.5 外部キー

SQLite接続時には、外部キー制約を有効にする。

```sql
PRAGMA foreign_keys = ON;
```

関連先が削除された場合でも、重要な知識資産や対話記録が連鎖的に失われないようにする。

---

## 2.6 原文と整理結果の分離

AIへ渡した文章とAIから受け取った回答原文は、整理後の知識資産とは分離して保存する。

これにより、後から整理結果を確認するときに元の対話へ戻ることができる。

---

## 2.7 利用者による承認

AIの回答から得られた情報は、直ちに正式な知識資産にしない。

最初は知識資産候補として保存し、利用者が確認・承認したものだけを正式な知識資産へ登録する。

---

## 2.8 スキーマ変更への対応

アプリのバージョンアップ時に、既存データを保持したままテーブル構造を変更できるようにする。

スキーマのバージョンは `schema_migrations` テーブルで管理する。

---

# 3. MVPのテーブル一覧

初期スキーマでは、次のテーブルを使用する。

| テーブル名 | 用途 |
|---|---|
| `schema_migrations` | データベース構造のバージョン管理 |
| `app_settings` | アプリ全体の設定 |
| `profiles` | 利用者プロフィール |
| `projects` | プロジェクト |
| `ai_sessions` | AIへの相談・回答・整理の記録 |
| `knowledge_candidates` | 正式保存前の知識資産候補 |
| `knowledge_assets` | 利用者が承認した知識資産 |
| `decisions` | 利用者が決定した事項 |
| `tasks` | TODO |
| `categories` | 知識資産の分類 |
| `tags` | 知識資産へ付与するタグ |
| `knowledge_asset_tags` | 知識資産とタグの中間テーブル |

---

# 4. テーブル関係

```text
profiles
   │
   ├── projects
   │      │
   │      ├── ai_sessions
   │      ├── knowledge_assets
   │      ├── decisions
   │      └── tasks
   │
   ├── ai_sessions
   │      │
   │      ├── knowledge_candidates
   │      ├── knowledge_assets
   │      ├── decisions
   │      └── tasks
   │
   ├── categories
   └── tags

knowledge_assets
   │
   └── knowledge_asset_tags ── tags
```

---

# 5. schema_migrations

## 5.1 目的

適用済みのデータベース変更を記録する。

## 5.2 定義

```sql
CREATE TABLE schema_migrations (
    version INTEGER PRIMARY KEY,
    description TEXT NOT NULL,
    applied_at TEXT NOT NULL
);
```

## 5.3 初期データ

```sql
INSERT INTO schema_migrations (
    version,
    description,
    applied_at
) VALUES (
    1,
    'Initial schema',
    '2026-07-30T00:00:00+09:00'
);
```

実際の `applied_at` は、マイグレーション実行時の日時を使用する。

---

# 6. app_settings

## 6.1 目的

アプリ全体の設定をキーと値の組み合わせで保存する。

## 6.2 定義

```sql
CREATE TABLE app_settings (
    setting_key TEXT PRIMARY KEY,
    setting_value TEXT,
    value_type TEXT NOT NULL DEFAULT 'string',
    updated_at TEXT NOT NULL,

    CHECK (
        value_type IN (
            'string',
            'integer',
            'boolean',
            'json'
        )
    )
);
```

## 6.3 設定例

```text
theme_mode
font_size
first_launch_completed
backup_reminder_enabled
last_backup_at
default_ai_service
```

---

# 7. profiles

## 7.1 目的

利用者の基本情報と、AIへ繰り返し伝える情報を保存する。

初期版では一人の利用者を想定するが、将来の拡張に備えて独立したテーブルとする。

## 7.2 定義

```sql
CREATE TABLE profiles (
    id TEXT PRIMARY KEY,
    display_name TEXT NOT NULL,
    introduction TEXT,
    usage_purpose TEXT,
    decision_criteria TEXT,
    preferences TEXT,
    preferred_response_format TEXT,
    frequently_used_ai TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT
);
```

---

# 8. projects

## 8.1 目的

仕事、研究、学習、生活上の課題など、継続的に取り組むテーマを管理する。

## 8.2 定義

```sql
CREATE TABLE projects (
    id TEXT PRIMARY KEY,
    profile_id TEXT NOT NULL,
    name TEXT NOT NULL,
    summary TEXT,
    purpose TEXT,
    current_status TEXT,
    history TEXT,
    decision_criteria TEXT,
    next_issue TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    started_on TEXT,
    completed_on TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    archived_at TEXT,
    deleted_at TEXT,

    FOREIGN KEY (profile_id)
        REFERENCES profiles(id)
        ON DELETE RESTRICT,

    CHECK (
        status IN (
            'active',
            'on_hold',
            'completed',
            'archived'
        )
    )
);
```

---

# 9. ai_sessions

## 9.1 目的

一つの相談目的に対する、AIへの質問、回答、整理までを一つの単位として保存する。

MVPでは、一回の質問と一回の回答を一つの `ai_session` とする。

## 9.2 定義

```sql
CREATE TABLE ai_sessions (
    id TEXT PRIMARY KEY,
    profile_id TEXT NOT NULL,
    project_id TEXT,
    title TEXT NOT NULL,
    ai_service TEXT,
    consultation_purpose TEXT,
    original_question TEXT,
    generated_request TEXT,
    ai_response TEXT,
    response_summary TEXT,
    next_questions TEXT,
    used_at TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'draft',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    archived_at TEXT,
    deleted_at TEXT,

    FOREIGN KEY (profile_id)
        REFERENCES profiles(id)
        ON DELETE RESTRICT,

    FOREIGN KEY (project_id)
        REFERENCES projects(id)
        ON DELETE SET NULL,

    CHECK (
        status IN (
            'draft',
            'waiting_response',
            'organizing',
            'reviewed',
            'archived'
        )
    )
);
```

## 9.3 状態

| 値 | 意味 |
|---|---|
| `draft` | 質問作成中 |
| `waiting_response` | AIへ質問済み、回答待ち |
| `organizing` | 回答整理中 |
| `reviewed` | 利用者確認済み |
| `archived` | 保管済み |

---

# 10. knowledge_candidates

## 10.1 目的

AIの回答から得られた情報を、正式な知識資産として保存する前の候補として管理する。

## 10.2 定義

```sql
CREATE TABLE knowledge_candidates (
    id TEXT PRIMARY KEY,
    profile_id TEXT NOT NULL,
    project_id TEXT,
    ai_session_id TEXT NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    candidate_type TEXT,
    extraction_reason TEXT,
    status TEXT NOT NULL DEFAULT 'pending',
    reviewed_at TEXT,
    approved_asset_id TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT,

    FOREIGN KEY (profile_id)
        REFERENCES profiles(id)
        ON DELETE RESTRICT,

    FOREIGN KEY (project_id)
        REFERENCES projects(id)
        ON DELETE SET NULL,

    FOREIGN KEY (ai_session_id)
        REFERENCES ai_sessions(id)
        ON DELETE RESTRICT,

    FOREIGN KEY (approved_asset_id)
        REFERENCES knowledge_assets(id)
        ON DELETE SET NULL,

    CHECK (
        status IN (
            'pending',
            'approved',
            'on_hold',
            'rejected'
        )
    )
);
```

`approved_asset_id` は、候補が正式な知識資産になった場合に、その知識資産のIDを記録する。

---

# 11. knowledge_assets

## 11.1 目的

利用者が将来再利用する価値があると判断し、正式に保存した知識資産を管理する。

## 11.2 定義

```sql
CREATE TABLE knowledge_assets (
    id TEXT PRIMARY KEY,
    profile_id TEXT NOT NULL,
    project_id TEXT,
    source_session_id TEXT,
    category_id TEXT,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    summary TEXT,
    asset_type TEXT NOT NULL DEFAULT 'knowledge',
    importance TEXT NOT NULL DEFAULT 'normal',
    source_type TEXT NOT NULL DEFAULT 'ai_session',
    source_description TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    last_used_at TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    archived_at TEXT,
    deleted_at TEXT,

    FOREIGN KEY (profile_id)
        REFERENCES profiles(id)
        ON DELETE RESTRICT,

    FOREIGN KEY (project_id)
        REFERENCES projects(id)
        ON DELETE SET NULL,

    FOREIGN KEY (source_session_id)
        REFERENCES ai_sessions(id)
        ON DELETE SET NULL,

    FOREIGN KEY (category_id)
        REFERENCES categories(id)
        ON DELETE SET NULL,

    CHECK (
        asset_type IN (
            'knowledge',
            'experience',
            'criteria',
            'idea',
            'summary',
            'lesson',
            'reference',
            'question',
            'answer',
            'background',
            'preference'
        )
    ),

    CHECK (
        importance IN (
            'low',
            'normal',
            'high',
            'critical'
        )
    ),

    CHECK (
        source_type IN (
            'ai_session',
            'user_input',
            'document',
            'import'
        )
    ),

    CHECK (
        status IN (
            'active',
            'archived'
        )
    )
);
```

---

# 12. decisions

## 12.1 目的

利用者が決定した事項と、その理由や判断材料を保存する。

AIの提案と利用者の決定を区別する。

## 12.2 定義

```sql
CREATE TABLE decisions (
    id TEXT PRIMARY KEY,
    profile_id TEXT NOT NULL,
    project_id TEXT,
    ai_session_id TEXT,
    decision_text TEXT NOT NULL,
    reason TEXT,
    evidence TEXT,
    decided_on TEXT NOT NULL,
    review_condition TEXT,
    review_on TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT,

    FOREIGN KEY (profile_id)
        REFERENCES profiles(id)
        ON DELETE RESTRICT,

    FOREIGN KEY (project_id)
        REFERENCES projects(id)
        ON DELETE SET NULL,

    FOREIGN KEY (ai_session_id)
        REFERENCES ai_sessions(id)
        ON DELETE SET NULL,

    CHECK (
        status IN (
            'active',
            'under_review',
            'changed',
            'cancelled'
        )
    )
);
```

---

# 13. tasks

## 13.1 目的

AIとの対話やプロジェクトから生まれたTODOを管理する。

## 13.2 定義

```sql
CREATE TABLE tasks (
    id TEXT PRIMARY KEY,
    profile_id TEXT NOT NULL,
    project_id TEXT,
    ai_session_id TEXT,
    title TEXT NOT NULL,
    details TEXT,
    due_at TEXT,
    priority TEXT NOT NULL DEFAULT 'normal',
    status TEXT NOT NULL DEFAULT 'not_started',
    completed_at TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT,

    FOREIGN KEY (profile_id)
        REFERENCES profiles(id)
        ON DELETE RESTRICT,

    FOREIGN KEY (project_id)
        REFERENCES projects(id)
        ON DELETE SET NULL,

    FOREIGN KEY (ai_session_id)
        REFERENCES ai_sessions(id)
        ON DELETE SET NULL,

    CHECK (
        priority IN (
            'low',
            'normal',
            'high',
            'urgent'
        )
    ),

    CHECK (
        status IN (
            'not_started',
            'in_progress',
            'completed',
            'on_hold',
            'cancelled'
        )
    )
);
```

---

# 14. categories

## 14.1 目的

知識資産を一定の種類へ分類する。

## 14.2 定義

```sql
CREATE TABLE categories (
    id TEXT PRIMARY KEY,
    profile_id TEXT,
    name TEXT NOT NULL,
    description TEXT,
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_system INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT,

    FOREIGN KEY (profile_id)
        REFERENCES profiles(id)
        ON DELETE CASCADE,

    CHECK (is_system IN (0, 1))
);
```

`profile_id` が `NULL` の分類は、アプリが用意する共通分類として扱う。

---

# 15. tags

## 15.1 目的

知識資産を複数の観点から柔軟に整理する。

## 15.2 定義

```sql
CREATE TABLE tags (
    id TEXT PRIMARY KEY,
    profile_id TEXT NOT NULL,
    name TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT,

    FOREIGN KEY (profile_id)
        REFERENCES profiles(id)
        ON DELETE CASCADE
);
```

---

# 16. knowledge_asset_tags

## 16.1 目的

知識資産とタグの多対多関係を管理する。

## 16.2 定義

```sql
CREATE TABLE knowledge_asset_tags (
    knowledge_asset_id TEXT NOT NULL,
    tag_id TEXT NOT NULL,
    created_at TEXT NOT NULL,

    PRIMARY KEY (
        knowledge_asset_id,
        tag_id
    ),

    FOREIGN KEY (knowledge_asset_id)
        REFERENCES knowledge_assets(id)
        ON DELETE CASCADE,

    FOREIGN KEY (tag_id)
        REFERENCES tags(id)
        ON DELETE CASCADE
);
```

---

# 17. インデックス

検索や一覧表示を効率化するため、次のインデックスを作成する。

```sql
CREATE INDEX idx_projects_profile_status
ON projects (
    profile_id,
    status
);

CREATE INDEX idx_projects_updated_at
ON projects (
    updated_at
);

CREATE INDEX idx_ai_sessions_project
ON ai_sessions (
    project_id
);

CREATE INDEX idx_ai_sessions_used_at
ON ai_sessions (
    used_at
);

CREATE INDEX idx_ai_sessions_status
ON ai_sessions (
    status
);

CREATE INDEX idx_knowledge_candidates_session
ON knowledge_candidates (
    ai_session_id
);

CREATE INDEX idx_knowledge_candidates_status
ON knowledge_candidates (
    status
);

CREATE INDEX idx_knowledge_assets_project
ON knowledge_assets (
    project_id
);

CREATE INDEX idx_knowledge_assets_category
ON knowledge_assets (
    category_id
);

CREATE INDEX idx_knowledge_assets_type
ON knowledge_assets (
    asset_type
);

CREATE INDEX idx_knowledge_assets_updated_at
ON knowledge_assets (
    updated_at
);

CREATE INDEX idx_decisions_project
ON decisions (
    project_id
);

CREATE INDEX idx_tasks_project_status
ON tasks (
    project_id,
    status
);

CREATE INDEX idx_tasks_due_at
ON tasks (
    due_at
);

CREATE UNIQUE INDEX idx_active_tag_name
ON tags (
    profile_id,
    name
)
WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX idx_active_category_name
ON categories (
    profile_id,
    name
)
WHERE deleted_at IS NULL;
```

---

# 18. 有効データの取得条件

論理削除を採用するテーブルでは、通常の一覧取得時に次の条件を使用する。

```sql
WHERE deleted_at IS NULL
```

例：

```sql
SELECT *
FROM knowledge_assets
WHERE deleted_at IS NULL
ORDER BY updated_at DESC;
```

保管済みデータを除外する場合は、状態も指定する。

```sql
SELECT *
FROM knowledge_assets
WHERE deleted_at IS NULL
  AND status = 'active'
ORDER BY updated_at DESC;
```

---

# 19. 初期分類

アプリの初回起動時には、次の基本分類を登録する。

```text
新しい知識
経験
判断基準
アイデア
要約
教訓
参考情報
質問
回答
背景・経緯
好み・希望
```

初期分類は `is_system = 1` とする。

利用者が追加した分類は `is_system = 0` とする。

---

# 20. マイグレーション方針

## 20.1 初期バージョン

本書で定義する初期スキーマを、データベースバージョン1とする。

```text
version = 1
```

## 20.2 バージョンアップ

テーブルや列を追加する場合は、変更処理をバージョンごとに分ける。

例：

```text
Version 1
初期テーブル作成

Version 2
knowledge_assetsへ新しい列を追加

Version 3
バックアップ履歴テーブルを追加
```

## 20.3 基本原則

- 既存テーブルを安易に削除しない
- 既存列の意味を変更しない
- 新しい列は可能な限りNULLを許可する
- 変更前にバックアップを作成する
- マイグレーション完了後にバージョンを記録する
- 途中で失敗した場合は処理をロールバックする

## 20.4 トランザクション

マイグレーション処理はトランザクション内で実行する。

```sql
BEGIN TRANSACTION;

-- スキーマ変更処理

COMMIT;
```

失敗時には次を実行する。

```sql
ROLLBACK;
```

---

# 21. バックアップ対象

バックアップでは、原則として次のテーブルをすべて書き出す。

- `app_settings`
- `profiles`
- `projects`
- `ai_sessions`
- `knowledge_candidates`
- `knowledge_assets`
- `decisions`
- `tasks`
- `categories`
- `tags`
- `knowledge_asset_tags`

`schema_migrations` は、バックアップファイルのメタ情報として別途バージョンを記録する。

---

# 22. バックアップファイルの基本構造

将来のJSONバックアップでは、次の構造を基本とする。

```json
{
  "format": "pams-companion-backup",
  "format_version": 1,
  "database_version": 1,
  "exported_at": "2026-07-30T10:30:00+09:00",
  "data": {
    "app_settings": [],
    "profiles": [],
    "projects": [],
    "ai_sessions": [],
    "knowledge_candidates": [],
    "knowledge_assets": [],
    "decisions": [],
    "tasks": [],
    "categories": [],
    "tags": [],
    "knowledge_asset_tags": []
  }
}
```

バックアップと復元の詳細仕様は、実装時に別途定義する。

---

# 23. MVP初期実装の優先順位

初期実装では、次の順番でテーブルを使用する。

## 第1段階

```text
schema_migrations
app_settings
profiles
projects
ai_sessions
knowledge_assets
```

この段階で、次の機能を実現する。

- 利用者プロフィール
- プロジェクト登録
- AIへの質問記録
- AI回答の保存
- 知識資産の手動登録

## 第2段階

```text
knowledge_candidates
decisions
tasks
```

この段階で、次の機能を追加する。

- 知識資産候補
- 決定事項
- TODO

## 第3段階

```text
categories
tags
knowledge_asset_tags
```

この段階で、分類・検索・再利用を強化する。

---

# 24. 将来拡張

将来、必要性を確認した上で次のテーブル追加を検討する。

- 複数回の対話を束ねる対話スレッド
- 知識資産の変更履歴
- バックアップ実行履歴
- データ取り込み履歴
- API接続設定
- 利用者の成長記録
- 複数端末間の同期情報
- 添付ファイル情報

これらは初期MVPには含めない。

---

# 25. 設計上の注意事項

## 25.1 個人情報

利用目的に不要な氏名、住所、電話番号などを必須項目にしない。

## 25.2 AIの回答

AIの回答は参考情報であり、利用者が承認するまでは正式な知識資産や決定事項として扱わない。

## 25.3 削除

知識資産、対話、決定事項及びTODOは、誤操作による消失を防ぐため論理削除を基本とする。

## 25.4 データ移行

アプリのバージョンアップ時には、利用者の既存データを保持することを最優先とする。

## 25.5 検索

初期版では通常のSQLite検索を使用する。

全文検索機能が必要になった場合は、SQLite FTSの導入を将来検討する。

---

# 26. まとめ

PAMS CompanionのSQLiteデータベースは、次の三つの中核概念を実現するために設計する。

1. AIとの対話ライフサイクル
2. 知識資産
3. 成長の循環

中心となる流れは次のとおりである。

```text
プロジェクト
      ↓
AIへの相談
      ↓
AIの回答
      ↓
知識資産候補
      ↓
利用者による確認
      ↓
正式な知識資産
      ↓
次回のAI利用へ再利用
```

初期版では端末内のSQLiteだけで動作し、利用者の情報を外部サーバーへ保存しない。

また、買い切り型アプリとして順次バージョンアップできるよう、スキーマのバージョン管理とデータ移行を最初から考慮する。
