import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/workout.dart';
import '../models/water_entry.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fitness_hydration.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE workouts (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            durationMinutes INTEGER NOT NULL,
            caloriesBurned INTEGER NOT NULL,
            steps INTEGER NOT NULL,
            date TEXT NOT NULL,
            notes TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE water_entries (
            id TEXT PRIMARY KEY,
            amountMl INTEGER NOT NULL,
            timestamp TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // ---------------- Workouts ----------------

  Future<void> insertWorkout(Workout workout) async {
    if (kIsWeb) {
      final prefs = await _prefs;
      final rows = await _readRows('workouts');
      final index = rows.indexWhere((row) => row['id'] == workout.id);
      final row = workout.toMap();
      if (index >= 0) {
        rows[index] = row;
      } else {
        rows.add(row);
      }
      await prefs.setString(_storageKey('workouts'), jsonEncode(rows));
      return;
    }

    final db = await database;
    await db.insert(
      'workouts',
      workout.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Workout>> getWorkouts() async {
    if (kIsWeb) {
      final rows = await _readRows('workouts');
      return rows.map((row) => Workout.fromMap(row)).toList();
    }

    final db = await database;
    final rows = await db.query('workouts', orderBy: 'date DESC');
    return rows.map((row) => Workout.fromMap(row)).toList();
  }

  Future<List<Workout>> getWorkoutsForDate(DateTime date) async {
    if (kIsWeb) {
      final rows = await _readRows('workouts');
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      final filtered = rows.where((row) {
        final rowDate = DateTime.parse(row['date'] as String);
        return rowDate.isAtLeast(start) && rowDate.isBefore(end);
      }).toList();
      return filtered.map((row) => Workout.fromMap(row)).toList();
    }

    final db = await database;
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final rows = await db.query(
      'workouts',
      where: 'date >= ? AND date < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return rows.map((row) => Workout.fromMap(row)).toList();
  }

  Future<void> deleteWorkout(String id) async {
    if (kIsWeb) {
      final prefs = await _prefs;
      final rows = await _readRows('workouts');
      final filtered = rows.where((row) => row['id'] != id).toList();
      await prefs.setString(_storageKey('workouts'), jsonEncode(filtered));
      return;
    }

    final db = await database;
    await db.delete('workouts', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Water Entries ----------------

  Future<void> insertWaterEntry(WaterEntry entry) async {
    if (kIsWeb) {
      final prefs = await _prefs;
      final rows = await _readRows('water_entries');
      final index = rows.indexWhere((row) => row['id'] == entry.id);
      final row = entry.toMap();
      if (index >= 0) {
        rows[index] = row;
      } else {
        rows.add(row);
      }
      await prefs.setString(_storageKey('water_entries'), jsonEncode(rows));
      return;
    }

    final db = await database;
    await db.insert(
      'water_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<WaterEntry>> getWaterEntriesForDate(DateTime date) async {
    if (kIsWeb) {
      final rows = await _readRows('water_entries');
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      final filtered = rows.where((row) {
        final rowTimestamp = DateTime.parse(row['timestamp'] as String);
        return rowTimestamp.isAtLeast(start) && rowTimestamp.isBefore(end);
      }).toList();
      return filtered.map((row) => WaterEntry.fromMap(row)).toList();
    }

    final db = await database;
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final rows = await db.query(
      'water_entries',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp DESC',
    );
    return rows.map((row) => WaterEntry.fromMap(row)).toList();
  }

  Future<List<WaterEntry>> getWaterEntriesLastNDays(int days) async {
    if (kIsWeb) {
      final rows = await _readRows('water_entries');
      final cutoff = DateTime.now().subtract(Duration(days: days));
      final filtered = rows.where((row) {
        final timestamp = DateTime.parse(row['timestamp'] as String);
        return !timestamp.isBefore(cutoff);
      }).toList();
      return filtered.map((row) => WaterEntry.fromMap(row)).toList();
    }

    final db = await database;
    final start = DateTime.now().subtract(Duration(days: days));
    final rows = await db.query(
      'water_entries',
      where: 'timestamp >= ?',
      whereArgs: [start.toIso8601String()],
      orderBy: 'timestamp ASC',
    );
    return rows.map((row) => WaterEntry.fromMap(row)).toList();
  }

  Future<void> deleteWaterEntry(String id) async {
    if (kIsWeb) {
      final prefs = await _prefs;
      final rows = await _readRows('water_entries');
      final filtered = rows.where((row) => row['id'] != id).toList();
      await prefs.setString(_storageKey('water_entries'), jsonEncode(filtered));
      return;
    }

    final db = await database;
    await db.delete('water_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearWaterEntriesForDate(DateTime date) async {
    if (kIsWeb) {
      final prefs = await _prefs;
      final rows = await _readRows('water_entries');
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      final filtered = rows.where((row) {
        final timestamp = DateTime.parse(row['timestamp'] as String);
        return timestamp.isBefore(start) || !timestamp.isBefore(end);
      }).toList();
      await prefs.setString(_storageKey('water_entries'), jsonEncode(filtered));
      return;
    }

    final db = await database;
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    await db.delete(
      'water_entries',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );
  }

  // ---------------- Settings (e.g. daily water goal) ----------------

  Future<void> setSetting(String key, String value) async {
    if (kIsWeb) {
      final prefs = await _prefs;
      await prefs.setString(_storageKey('settings_$key'), value);
      return;
    }

    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    if (kIsWeb) {
      final prefs = await _prefs;
      return prefs.getString(_storageKey('settings_$key'));
    }

    final db = await database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<List<Map<String, dynamic>>> _readRows(String table) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_storageKey(table));
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  String _storageKey(String table) => 'fitness_hydration_tracker_$table';
}

extension _DateTimeComparison on DateTime {
  bool isAtLeast(DateTime other) => !isBefore(other);
}
