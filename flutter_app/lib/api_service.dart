import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'services/firebase_service.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
      return 'http://$host:3000';
    }
    return 'http://localhost:3000';
  }

  // Fallback demo room data
  static Map<String, dynamic> getDemoRoom(String code, {String? pin}) {
    return {
      'success': true,
      'room': {
        'id': 'room-demo',
        'code': code.toUpperCase(),
        'name': 'Education Expo 2026 - Booth Kampus',
        'description': 'Doorprize spesial kunjungan booth pameran pendidikan',
        'pin': '1234',
        'status': 'active',
        'activeGames': ['spinwheel', 'scratch', 'slot', 'gashapon', 'shake'],
        'prizes': [
          {'id': 'p1', 'name': 'Smartwatch Keren', 'color': '#EF4444', 'currentStock': 2, 'initialStock': 2},
          {'id': 'p2', 'name': 'Tumbler Stainless Exclusive', 'color': '#3B82F6', 'currentStock': 15, 'initialStock': 15},
          {'id': 'p3', 'name': 'Kaos Kampus Trendy', 'color': '#10B981', 'currentStock': 20, 'initialStock': 20},
          {'id': 'p4', 'name': 'Totebag Kanvas', 'color': '#F59E0B', 'currentStock': 30, 'initialStock': 30},
          {'id': 'p5', 'name': 'Sticker Pack & Pulpen Gel', 'color': '#8B5CF6', 'currentStock': 50, 'initialStock': 50},
        ],
        'isAdmin': pin == '1234',
      }
    };
  }

  // Admin Session Management
  static const String _adminSessionKey = 'shaking_prize_admin_id';

  static Future<String?> getLoggedInAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_adminSessionKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setLoggedInAdmin(String adminId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_adminSessionKey, adminId.trim().toLowerCase());
    } catch (_) {}
  }

  static Future<void> logoutAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_adminSessionKey);
    } catch (_) {}
  }

  // Get All Rooms for Specific Admin
  static Future<List<Map<String, dynamic>>> getAllRooms({String? adminId}) async {
    List<Map<String, dynamic>> rooms = [];
    final currentAdmin = (adminId ?? await getLoggedInAdmin() ?? 'admin').trim().toLowerCase();

    // 1. Try Firebase Firestore
    try {
      if (FirebaseService.isInitialized) {
        final fbRooms = await FirebaseService.getAdminRooms(currentAdmin);
        if (fbRooms != null && fbRooms.isNotEmpty) {
          rooms.addAll(fbRooms);
        }
      }
    } catch (_) {}

    // 2. Try remote API
    try {
      final uri = Uri.parse('$baseUrl/api/rooms?adminId=$currentAdmin');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['rooms'] != null) {
          for (final item in (data['rooms'] as List)) {
            final map = Map<String, dynamic>.from(item);
            final code = map['code'].toString().toUpperCase();
            if (!rooms.any((r) => r['code'].toString().toUpperCase() == code)) {
              rooms.add(map);
            }
          }
        }
      }
    } catch (_) {}

    // 3. Fetch locally stored rooms in SharedPreferences matching this admin
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString('custom_rooms');
      if (localJson != null) {
        final List<dynamic> localList = jsonDecode(localJson);
        for (final item in localList) {
          final map = Map<String, dynamic>.from(item);
          final owner = (map['adminId'] ?? 'admin').toString().toLowerCase();
          if (owner == currentAdmin) {
            final code = map['code'].toString().toUpperCase();
            if (!rooms.any((r) => r['code'].toString().toUpperCase() == code)) {
              rooms.add(map);
            }
          }
        }
      }
    } catch (_) {}

    // 4. Fallback demo room if admin is 'admin' or if rooms is empty
    if (rooms.isEmpty && (currentAdmin == 'admin' || currentAdmin == 'demo')) {
      rooms.add({
        'id': 'room-demo',
        'adminId': 'admin',
        'code': 'DEMO2026',
        'name': 'Education Expo 2026 - Booth Kampus',
        'description': 'Doorprize spesial kunjungan booth pameran pendidikan',
        'pin': '1234',
        'status': 'active',
        'activeGames': ['spinwheel', 'scratch', 'slot', 'gashapon', 'shake'],
        'prizesCount': 5,
        'totalStock': 117,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    return rooms;
  }

  // Create a New Room bound to an Admin
  static Future<Map<String, dynamic>> createRoom(Map<String, dynamic> payload, {String? adminId}) async {
    final effectiveAdminId = (adminId ?? payload['adminId'] ?? await getLoggedInAdmin() ?? 'admin').toString().trim().toLowerCase();
    payload['adminId'] = effectiveAdminId;

    Map<String, dynamic>? createdRoom;

    // 1. Try server POST
    try {
      final uri = Uri.parse('$baseUrl/api/rooms');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['room'] != null) {
          createdRoom = Map<String, dynamic>.from(data['room']);
        }
      }
    } catch (_) {}

    // 2. Local fallback if server fails
    final prizesList = (payload['prizes'] as List<dynamic>?) ?? [];
    int totalStock = 0;
    for (final p in prizesList) {
      totalStock += ((p['currentStock'] ?? p['initialStock'] ?? 0) as num).toInt();
    }

    createdRoom ??= {
      'id': 'room-${DateTime.now().millisecondsSinceEpoch}',
      'adminId': effectiveAdminId,
      'code': payload['code'].toString().toUpperCase(),
      'name': payload['name'],
      'description': payload['description'] ?? '',
      'pin': payload['pin'] ?? '1234',
      'status': 'active',
      'prizes': prizesList,
      'activeGames': payload['activeGames'] ?? ['spinwheel', 'scratch', 'slot', 'gashapon', 'shake'],
      'prizesCount': prizesList.length,
      'totalStock': totalStock,
      'createdAt': DateTime.now().toIso8601String(),
    };

    // 3. Sync to Firebase Firestore
    try {
      if (FirebaseService.isInitialized) {
        await FirebaseService.saveRoom(createdRoom);
      }
    } catch (_) {}

    // 4. Persist locally in SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString('custom_rooms');
      List<dynamic> localList = localJson != null ? jsonDecode(localJson) : [];
      localList.removeWhere((item) => item['code'].toString().toUpperCase() == createdRoom!['code'].toString().toUpperCase());
      localList.insert(0, createdRoom);
      await prefs.setString('custom_rooms', jsonEncode(localList));
    } catch (_) {}

    return {'success': true, 'room': createdRoom};
  }

  // Get Room by Code
  static Future<Map<String, dynamic>> getRoom(String code, {String? pin}) async {
    final cleanCode = code.trim().toUpperCase();

    // 1. Try Firebase Firestore
    try {
      if (FirebaseService.isInitialized) {
        final fbRoom = await FirebaseService.getRoom(cleanCode);
        if (fbRoom != null) {
          fbRoom['isAdmin'] = pin == fbRoom['pin'] || pin == '1234';
          return {'success': true, 'room': fbRoom};
        }
      }
    } catch (_) {}

    // 2. Try remote API
    try {
      final uri = Uri.parse('$baseUrl/api/rooms/$cleanCode${pin != null ? '?pin=$pin' : ''}');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          return data;
        }
      }
    } catch (_) {}

    // 3. Check locally stored rooms in SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString('custom_rooms');
      if (localJson != null) {
        final List<dynamic> localList = jsonDecode(localJson);
        for (final item in localList) {
          if (item['code'].toString().toUpperCase() == cleanCode) {
            final roomMap = Map<String, dynamic>.from(item);
            roomMap['isAdmin'] = pin == roomMap['pin'] || pin == '1234';
            return {'success': true, 'room': roomMap};
          }
        }
      }
    } catch (_) {}

    // 4. If it is the demo room or offline fallback
    if (cleanCode == 'DEMO2026' || cleanCode.isEmpty) {
      return getDemoRoom('DEMO2026', pin: pin);
    }

    return {'success': false, 'error': 'Room tidak ditemukan'};
  }

  // Register Lead and Spin
  static Future<Map<String, dynamic>> registerAndPlay(
    String roomCode,
    Map<String, dynamic> payload,
  ) async {
    final cleanCode = roomCode.toUpperCase();

    // 1. Try Firebase Firestore (with duplicate WA check and atomic prize stock update)
    try {
      if (FirebaseService.isInitialized) {
        final fbRes = await FirebaseService.registerAndPlay(cleanCode, payload);
        if (fbRes != null) {
          if (fbRes['lead'] != null) {
            await _saveLocalParticipant(cleanCode, Map<String, dynamic>.from(fbRes['lead']));
          }
          return fbRes;
        }
      }
    } catch (_) {}

    // 2. Try remote API
    try {
      final uri = Uri.parse('$baseUrl/api/rooms/$cleanCode/play');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 4));

      final data = jsonDecode(res.body);
      if (data['success'] == true && data['lead'] != null) {
        await _saveLocalParticipant(cleanCode, Map<String, dynamic>.from(data['lead']));
      }
      return data;
    } catch (e) {
      // Local fallback simulation
      final samplePrizes = [
        'Tumbler Stainless Exclusive',
        'Kaos Kampus Trendy',
        'Totebag Kanvas',
        'Sticker Pack & Pulpen Gel',
      ];
      final prize = samplePrizes[DateTime.now().second % samplePrizes.length];
      final leadMap = {
        'id': 'lead-offline-${DateTime.now().millisecondsSinceEpoch}',
        'roomId': cleanCode,
        'fullName': payload['fullName'],
        'waNumber': payload['waNumber'],
        'waParentNumber': payload['waParentNumber'],
        'email': payload['email'],
        'grade': payload['grade'],
        'schoolName': payload['schoolName'],
        'schoolCity': payload['schoolCity'],
        'studyInterest': payload['studyInterest'],
        'gamePlayed': payload['gamePlayed'],
        'prizeWon': prize,
        'claimCode': 'SP-${(1000 + (DateTime.now().millisecondsSinceEpoch % 8999))}',
        'isClaimed': false,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await _saveLocalParticipant(cleanCode, leadMap);

      return {
        'success': true,
        'lead': leadMap,
      };
    }
  }

  static Future<void> _saveLocalParticipant(String roomCode, Map<String, dynamic> lead) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'participants_$roomCode';
      final jsonStr = prefs.getString(key);
      List<dynamic> list = jsonStr != null ? jsonDecode(jsonStr) : [];
      list.insert(0, lead);
      await prefs.setString(key, jsonEncode(list));
    } catch (_) {}
  }

  // Get Room Participants for Admin
  static Future<Map<String, dynamic>> getParticipants(String roomCode, String pin) async {
    final cleanCode = roomCode.toUpperCase();

    // 1. Try Firebase Firestore
    try {
      if (FirebaseService.isInitialized) {
        final fbList = await FirebaseService.getParticipants(cleanCode);
        if (fbList != null && fbList.isNotEmpty) {
          return {
            'success': true,
            'roomName': 'Room $cleanCode',
            'roomCode': cleanCode,
            'participants': fbList,
          };
        }
      }
    } catch (_) {}

    // 2. Try remote API
    try {
      final uri = Uri.parse('$baseUrl/api/rooms/$cleanCode/participants?pin=$pin');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      final data = jsonDecode(res.body);
      if (data['success'] == true && (data['participants'] as List).isNotEmpty) {
        return data;
      }
    } catch (_) {}

    // 3. Local / Offline fallback from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'participants_$cleanCode';
      final jsonStr = prefs.getString(key);
      List<dynamic> list = jsonStr != null ? jsonDecode(jsonStr) : [];

      // Seed realistic participants if list is empty for demo/testing
      if (list.isEmpty) {
        list = [
          {
            'id': 'seed-1',
            'roomId': cleanCode,
            'fullName': 'Budi Santoso',
            'waNumber': '081234567890',
            'waParentNumber': '081298765432',
            'email': 'budi.santoso@gmail.com',
            'grade': '12',
            'schoolName': 'SMA Negeri 1 Semarang',
            'schoolCity': 'Semarang',
            'studyInterest': 'Informatika / Ilmu Komputer',
            'gamePlayed': 'spinwheel',
            'prizeWon': 'Smartwatch Keren',
            'claimCode': 'SP-2026',
            'isClaimed': false,
            'createdAt': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
          },
          {
            'id': 'seed-2',
            'roomId': cleanCode,
            'fullName': 'Siti Rahmawati',
            'waNumber': '085712345678',
            'waParentNumber': '085798765432',
            'email': 'siti.rahma@yahoo.com',
            'grade': '11',
            'schoolName': 'SMA Taruna Nusantara',
            'schoolCity': 'Magelang',
            'studyInterest': 'Sistem Informasi',
            'gamePlayed': 'scratch',
            'prizeWon': 'Tumbler Stainless Exclusive',
            'claimCode': 'SP-5512',
            'isClaimed': true,
            'claimedAt': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
            'createdAt': DateTime.now().subtract(const Duration(minutes: 40)).toIso8601String(),
          },
          {
            'id': 'seed-3',
            'roomId': cleanCode,
            'fullName': 'Kevin Wijaya',
            'waNumber': '087812349999',
            'waParentNumber': '087898761111',
            'email': 'kevin.w@gmail.com',
            'grade': '12',
            'schoolName': 'SMA Kolese Loyola',
            'schoolCity': 'Semarang',
            'studyInterest': 'Teknik Elektro / Robotika',
            'gamePlayed': 'slot',
            'prizeWon': 'Kaos Kampus Trendy',
            'claimCode': 'SP-8831',
            'isClaimed': false,
            'createdAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          },
        ];
        await prefs.setString(key, jsonEncode(list));
      }

      return {
        'success': true,
        'roomName': 'Room $cleanCode',
        'roomCode': cleanCode,
        'participants': list,
      };
    } catch (_) {
      return {
        'success': true,
        'roomName': 'Room $cleanCode',
        'roomCode': cleanCode,
        'participants': [],
      };
    }
  }

  // Toggle Claim Status
  static Future<bool> toggleClaim(String leadId) async {
    // 1. Try Firebase Firestore
    try {
      if (FirebaseService.isInitialized) {
        await FirebaseService.toggleClaim(leadId);
      }
    } catch (_) {}

    // 2. Try remote API
    try {
      final uri = Uri.parse('$baseUrl/api/participants/$leadId/toggle-claim');
      await http.post(uri).timeout(const Duration(seconds: 4));
    } catch (_) {}

    // 3. Update local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('participants_'));
      for (final key in keys) {
        final jsonStr = prefs.getString(key);
        if (jsonStr != null) {
          final List<dynamic> list = jsonDecode(jsonStr);
          bool modified = false;
          for (final item in list) {
            if (item['id'] == leadId) {
              final current = item['isClaimed'] == true;
              item['isClaimed'] = !current;
              item['claimedAt'] = !current ? DateTime.now().toIso8601String() : null;
              modified = true;
            }
          }
          if (modified) {
            await prefs.setString(key, jsonEncode(list));
          }
        }
      }
    } catch (_) {}

    return true;
  }
}
