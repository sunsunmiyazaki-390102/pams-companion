import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/default_theme.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String databaseName = 'pams_companion.db';
  static const int databaseVersion = 15;

  Database? _database;

  Future<Database> get database async {
    final currentDatabase = _database;

    if (currentDatabase != null) {
      return currentDatabase;
    }

    final openedDatabase = await _openDatabase();
    _database = openedDatabase;

    return openedDatabase;
  }

  Future<Database> _openDatabase() async {
    final databaseDirectory = await getDatabasesPath();
    final databasePath = path.join(
      databaseDirectory,
      databaseName,
    );

    return openDatabase(
      databasePath,
      version: databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(
    Database database,
  ) async {
    await database.execute(
      'PRAGMA foreign_keys = ON',
    );
  }

  Future<void> _onCreate(
    Database database,
    int version,
  ) async {
    await _createProjectsTable(database);

    await _insertDefaultThemes(database);

    await _createAiSessionsTable(database);
    await _createAiConversationsTable(database);
    await _createKnowledgeAssetsTable(database);
    await _createKnowledgeLinksTable(database);
    await _createKnowledgeCandidatesTable(database);
    await _createNewQuestionsTable(database);
    await _createReflectionQueueTable(database);
    await _createDailyMemoriesTable(database);
  }

  Future<void> _onUpgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createAiSessionsTable(database);
    }

    if (oldVersion < 3) {
      await _createAiConversationsTable(database);
    }

    if (oldVersion < 4) {
      await _createKnowledgeAssetsTable(database);
    } else if (oldVersion < 5) {
      await _addKnowledgeTypeColumn(database);
    }

    if (oldVersion < 6) {
      await _createKnowledgeLinksTable(database);
    } else if (oldVersion < 7) {
      await _addKnowledgeLinkReasonColumn(database);
    }
  
    if (oldVersion < 8) {
      await _addAiConversationResponseStatusColumn(
        database,
      );
    } 
  
    if (oldVersion < 9) {
      await _addAiConversationQuestionColumns(
        database,
      );
    }  
  
    if (oldVersion < 10) {
      await _createKnowledgeCandidatesTable(
        database,
      );
      await _createNewQuestionsTable(
        database,
      );
    }  
 
    if (oldVersion < 11) {
      await _addKnowledgeSourceCandidateColumn(
        database,
      );
    } 
  
    if (oldVersion < 12) {
      await _createReflectionQueueTable(
        database,
      );
    }  
  
    if (oldVersion < 13) {
      await _createDailyMemoriesTable(
        database,
      );
    }  
 
    if (oldVersion < 14) {
      await _insertDefaultThemes(
        database,
      );
    } 
  
    if (oldVersion < 15) {
      await _addAiConversationPromptColumn(
        database,
      );
    }  
  }

  Future<void> _createProjectsTable(
    Database database,
  ) async {
    await database.execute('''
      CREATE TABLE projects (
        project_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createAiSessionsTable(
    Database database,
  ) async {
    await database.execute('''
      CREATE TABLE ai_sessions (
        session_id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (project_id)
          REFERENCES projects (project_id)
          ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createAiConversationsTable(
    Database database,
  ) async {
    await database.execute('''
      CREATE TABLE ai_conversations (
        conversation_id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        user_message TEXT NOT NULL,
        ai_prompt TEXT NOT NULL DEFAULT '',
        ai_response TEXT NOT NULL,       
        summary TEXT,
        ai_provider TEXT,
        question_topic TEXT,
        question_purpose TEXT,
        question_context TEXT,
        question_detail_level TEXT,
        question_conditions TEXT,
        response_status TEXT NOT NULL DEFAULT 'received',       
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (session_id)
          REFERENCES ai_sessions (session_id)
          ON DELETE CASCADE
      )
    ''');

    await database.execute('''
      CREATE INDEX index_ai_conversations_session_id
      ON ai_conversations (session_id)
    ''');
 
    await database.execute('''
      CREATE INDEX index_ai_conversations_response_status
      ON ai_conversations (response_status)
    ''');  
  }

  Future<void> _createKnowledgeAssetsTable(
    Database database,
  ) async {
    await database.execute('''
      CREATE TABLE knowledge_assets (
        knowledge_id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        conversation_id TEXT,
        source_candidate_id TEXT,
        knowledge_type TEXT NOT NULL DEFAULT 'insight',
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (session_id)
          REFERENCES ai_sessions (session_id)
          ON DELETE CASCADE,
        FOREIGN KEY (conversation_id)
          REFERENCES ai_conversations (conversation_id)
          ON DELETE SET NULL,
        FOREIGN KEY (source_candidate_id)
          REFERENCES knowledge_candidates (candidate_id)
          ON DELETE SET NULL       
      )
    ''');

    await database.execute('''
      CREATE INDEX index_knowledge_assets_session_id
      ON knowledge_assets (session_id)
    ''');

    await database.execute('''
      CREATE INDEX index_knowledge_assets_conversation_id
      ON knowledge_assets (conversation_id)
    ''');

    await database.execute('''
      CREATE INDEX index_knowledge_assets_knowledge_type
      ON knowledge_assets (knowledge_type)
    ''');
 
    await database.execute('''
      CREATE UNIQUE INDEX
      index_knowledge_assets_source_candidate_id
      ON knowledge_assets (source_candidate_id)
    '''); 
  }

  Future<void> _addKnowledgeTypeColumn(
    Database database,
  ) async {
    await database.execute('''
      ALTER TABLE knowledge_assets
      ADD COLUMN knowledge_type
      TEXT NOT NULL DEFAULT 'insight'
    ''');

    await database.execute('''
      CREATE INDEX index_knowledge_assets_knowledge_type
      ON knowledge_assets (knowledge_type)
    ''');
  }

  Future<void> _createKnowledgeLinksTable(
    Database database,
  ) async {
    await database.execute('''
      CREATE TABLE knowledge_links (
        link_id TEXT PRIMARY KEY,
        from_knowledge_id TEXT NOT NULL,
        to_knowledge_id TEXT NOT NULL,
        link_type TEXT NOT NULL,
        link_reason TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (from_knowledge_id)
          REFERENCES knowledge_assets (knowledge_id)
          ON DELETE CASCADE,
        FOREIGN KEY (to_knowledge_id)
          REFERENCES knowledge_assets (knowledge_id)
          ON DELETE CASCADE
      )
    ''');

    await database.execute('''
      CREATE INDEX index_knowledge_links_from_knowledge_id
      ON knowledge_links (from_knowledge_id)
    ''');

    await database.execute('''
      CREATE INDEX index_knowledge_links_to_knowledge_id
      ON knowledge_links (to_knowledge_id)
    ''');

    await database.execute('''
      CREATE INDEX index_knowledge_links_link_type
      ON knowledge_links (link_type)
    ''');
  }

  Future<void> _createKnowledgeCandidatesTable(
    Database database,
  ) async {
    await database.execute('''
      CREATE TABLE knowledge_candidates (
        candidate_id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        content TEXT NOT NULL,
        suggested_type TEXT NOT NULL,
        reason TEXT NOT NULL DEFAULT '',
        source_excerpt TEXT,
        status TEXT NOT NULL DEFAULT 'candidate',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (conversation_id)
          REFERENCES ai_conversations (conversation_id)
          ON DELETE CASCADE
      )
    ''');

    await database.execute('''
      CREATE INDEX index_knowledge_candidates_conversation_id
      ON knowledge_candidates (conversation_id)
    ''');

    await database.execute('''
      CREATE INDEX index_knowledge_candidates_status
      ON knowledge_candidates (status)
    ''');
  }

  Future<void> _createNewQuestionsTable(
    Database database,
  ) async {
    await database.execute('''
      CREATE TABLE new_questions (
        question_id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        content TEXT NOT NULL,
        reason TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'candidate',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (conversation_id)
          REFERENCES ai_conversations (conversation_id)
          ON DELETE CASCADE
      )
    ''');

    await database.execute('''
      CREATE INDEX index_new_questions_conversation_id
      ON new_questions (conversation_id)
    ''');

    await database.execute('''
      CREATE INDEX index_new_questions_status
      ON new_questions (status)
    ''');
  }

  Future<void> _createReflectionQueueTable(
    Database database,
  ) async {
    await database.execute('''
      CREATE TABLE reflection_queue (
        queue_id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL UNIQUE,
        priority INTEGER NOT NULL DEFAULT 1,
        status TEXT NOT NULL DEFAULT 'waiting',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (conversation_id)
          REFERENCES ai_conversations (conversation_id)
          ON DELETE CASCADE
      )
    ''');

    await database.execute('''
      CREATE INDEX index_reflection_queue_status
      ON reflection_queue (status)
    ''');

    await database.execute('''
      CREATE INDEX index_reflection_queue_priority
      ON reflection_queue (priority)
    ''');
  }

  Future<void> _addKnowledgeLinkReasonColumn(
    Database database,
  ) async {
    await database.execute('''
      ALTER TABLE knowledge_links
      ADD COLUMN link_reason
      TEXT NOT NULL DEFAULT ''
    ''');
  }

  Future<void>
      _addAiConversationResponseStatusColumn(
    Database database,
  ) async {
    await database.execute('''
      ALTER TABLE ai_conversations
      ADD COLUMN response_status
      TEXT NOT NULL DEFAULT 'received'
    ''');

    await database.execute('''
      CREATE INDEX index_ai_conversations_response_status
      ON ai_conversations (response_status)
    ''');
  }

  Future<void> _addAiConversationQuestionColumns(
    Database database,
  ) async {
    await database.execute('''
      ALTER TABLE ai_conversations
      ADD COLUMN question_topic TEXT
    ''');

    await database.execute('''
      ALTER TABLE ai_conversations
      ADD COLUMN question_purpose TEXT
    ''');

    await database.execute('''
      ALTER TABLE ai_conversations
      ADD COLUMN question_context TEXT
    ''');

    await database.execute('''
      ALTER TABLE ai_conversations
      ADD COLUMN question_detail_level TEXT
    ''');

    await database.execute('''
      ALTER TABLE ai_conversations
      ADD COLUMN question_conditions TEXT
    ''');
  }

  Future<void> _addAiConversationPromptColumn(
    Database database,
  ) async {
    await database.execute('''
      ALTER TABLE ai_conversations
      ADD COLUMN ai_prompt
      TEXT NOT NULL DEFAULT ''
    ''');
  }

  Future<void> _addKnowledgeSourceCandidateColumn(
    Database database,
  ) async {
    await database.execute('''
      ALTER TABLE knowledge_assets
      ADD COLUMN source_candidate_id TEXT
      REFERENCES knowledge_candidates (candidate_id)
      ON DELETE SET NULL
    ''');

    await database.execute('''
      CREATE UNIQUE INDEX
      index_knowledge_assets_source_candidate_id
      ON knowledge_assets (source_candidate_id)
    ''');
  }

  Future<void> close() async {
    final currentDatabase = _database;

    if (currentDatabase == null) {
      return;
    }

    await currentDatabase.close();
    _database = null;
  }

  Future<void> _createDailyMemoriesTable(
    Database database,
  ) async {
    await database.execute('''
      CREATE TABLE daily_memories (
        memory_id TEXT PRIMARY KEY,
        memory_date TEXT NOT NULL UNIQUE,
        content TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE UNIQUE INDEX index_daily_memories_memory_date
      ON daily_memories (memory_date)
    ''');
  }

  Future<void> _insertDefaultThemes(
    Database database,
  ) async {
    final now =
        DateTime.now().toIso8601String();

    for (final projectId
        in DefaultTheme.ids) {
      await database.insert(
        'projects',
        {
          'project_id': projectId,
          'name':
              DefaultTheme.nameOf(
            projectId,
          ),
          'description':
              DefaultTheme.descriptionOf(
            projectId,
          ),
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm:
            ConflictAlgorithm.ignore,
      );
    }
  }
}
