import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String databaseName = 'pams_companion.db';
  static const int databaseVersion = 8;

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
    await _createAiSessionsTable(database);
    await _createAiConversationsTable(database);
    await _createKnowledgeAssetsTable(database);
    await _createKnowledgeLinksTable(database);
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
        ai_response TEXT NOT NULL,
        summary TEXT,
        ai_provider TEXT,
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
        knowledge_type TEXT NOT NULL DEFAULT 'insight',
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (session_id)
          REFERENCES ai_sessions (session_id)
          ON DELETE CASCADE,
        FOREIGN KEY (conversation_id)
          REFERENCES ai_conversations (conversation_id)
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

  Future<void> close() async {
    final currentDatabase = _database;

    if (currentDatabase == null) {
      return;
    }

    await currentDatabase.close();
    _database = null;
  }
}
