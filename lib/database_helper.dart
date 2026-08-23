import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cardio_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE patients (
        id TEXT PRIMARY KEY,
        created_at TEXT NOT NULL,
        status TEXT NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE modules (
        id TEXT PRIMARY KEY,
        titre_fr TEXT NOT NULL,
        titre_ar TEXT NOT NULL,
        contenu_fr TEXT NOT NULL,
        contenu_ar TEXT NOT NULL,
        categorie TEXT NOT NULL
      )
    ''');

    await _seedDatabase(db);
  }

  Future<void> _seedDatabase(Database db) async {
    // Insertion des patients démo
    await db.insert('patients', {
      'id': 'PAT-DEMO-001',
      'created_at': DateTime.now().toIso8601String(),
      'status': 'demo',
      'notes': 'Patient coronarien, HTA, Tabac'
    });
    await db.insert('patients', {
      'id': 'PAT-DEMO-002',
      'created_at': DateTime.now().toIso8601String(),
      'status': 'demo',
      'notes': 'Fibrillation atriale sous Sintrom'
    });

    // Module Sel & HTA
    await db.insert('modules', {
      'id': 'MOD_HTA_SEL',
      'titre_fr': 'Hypertension et sel : Mieux manger',
      'titre_ar': 'ضغط الدم المرتفع والملح: نصائح عملية',
      'contenu_fr': 'Le sel retient l’eau dans les vaisseaux et augmente la tension. Limitez le pain classique, les conserves, le thon en boîte et la harissa industrielle. Utilisez le cumin, carvi, ail et citron.',
      'contenu_ar': 'يقوم الملح بحبس الماء داخل الأوعية الدموية مما يرفع الضغط. تجنب الخبز العادي والمعلبات والهريسة المصنعة. استخدم الثوم والليمون والكمون والكروية.',
      'categorie': 'Alimentation'
    });

    // Module Fiqh & Ramadan
    await db.insert('modules', {
      'id': 'MOD_FIQH_RAMADAN',
      'titre_fr': 'Fiqh & Ramadan pour le patient cardiaque',
      'titre_ar': 'أحكام الصيام والمريض في الفقه المالكي',
      'contenu_fr': 'Selon le fiqh malékite, le patient dont la santé est menacée par le jeûne a l’obligation religieuse de rompre le jeûne sur avis médical (Rokhsa).',
      'contenu_ar': 'وفق الفقه المالكي، إذا كان الصوم يشكل خطراً على صحة المريض بتقرير الطبيب، يجب عليه الإفطار أخذًا برخصة الشريعة.',
      'categorie': 'Fiqh'
    });
  }

  Future<List<Map<String, dynamic>>> getPatients() async {
    final db = await instance.database;
    return await db.query('patients');
  }

  Future<List<Map<String, dynamic>>> getModules() async {
    final db = await instance.database;
    return await db.query('modules');
  }
}
