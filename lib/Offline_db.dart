import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class OfflineDB{
  static Database? _db;

  static Future<Database> getDatabase() async {
    if(_db != null) return _db!;

    final path = join(await getDatabasesPath(),'offline_data.db');

    _db = await openDatabase(
        path,
        version: 1,
        onCreate: (db,version) async{
           await db.execute('''
            CREATE TABLE OfflineData (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                data TEXT
            )
           ''');
        },
    );
    return _db!;
  }

  static Future<void> insert(Map<String,dynamic> json) async {
    final db = await getDatabase();
    await db.insert('OfflineData',{'data':jsonEncode(json)});
  }

  static Future<List<Map<String,dynamic>>> readall() async{
    final db = await getDatabase();
    final rows = await db.query('OfflineData');
    return rows.map<Map<String,dynamic>>((row) {
      final raw = row['data'];
      final decoded = jsonDecode(raw as String);
      if(decoded is Map<String,dynamic>){
        return decoded;
      }
      else{
        throw Exception("Invalid Json row in db");
      }
    }
    ).toList();
  }
  static Future<void> deletefirstN(int n) async {
    final db = await getDatabase();
    await db.delete(
      'OfflineData',
      where:'id IN (SELECT id from OfflineData ORDER BY id LIMIT ?)',
      whereArgs:[n],
    );
  }

  static Future<int> count() async {
    final db = await getDatabase();
    final result = await db.rawQuery('SELECT count(*) FROM OfflineData');
    return Sqflite.firstIntValue(result) ?? 0;
  }

}