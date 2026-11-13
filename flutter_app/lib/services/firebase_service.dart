import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import '../firebase_options.dart';

class FirebaseService {
  static const String _projectId = 'kadoo-5b673';
  static const String _apiKey = 'AIzaSyDUmyTZmEBq4gDKkYvEaJWQdtbTH1gO4Jk';
  static const String _restBaseUrl =
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  static bool _sdkInitialized = false;
  static bool get isInitialized => true; // Always true because REST API is active

  static FirebaseFirestore? get _db {
    if (!_sdkInitialized) return null;
    return FirebaseFirestore.instance;
  }

  static Future<bool> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _sdkInitialized = true;
    } catch (_) {
      // Fallback to direct REST API if JS SDK fails to load
    }
    _seedDemoData();
    return true;
  }

  // --- REST Field Encoders & Decoders ---
  static Map<String, dynamic> _encodeValue(dynamic value) {
    if (value == null) return {'nullValue': null};
    if (value is bool) return {'booleanValue': value};
    if (value is int) return {'integerValue': value.toString()};
    if (value is double) return {'doubleValue': value};
    if (value is num) return {'doubleValue': value.toDouble()};
    if (value is String) return {'stringValue': value};
    if (value is List) {
      return {
        'arrayValue': {
          'values': value.map((e) => _encodeValue(e)).toList(),
        }
      };
    }
    if (value is Map) {
      final fields = <String, dynamic>{};
      value.forEach((k, v) {
        fields[k.toString()] = _encodeValue(v);
      });
      return {'mapValue': {'fields': fields}};
    }
    return {'stringValue': value.toString()};
  }

  static dynamic _decodeValue(Map<String, dynamic> val) {
    if (val.containsKey('stringValue')) return val['stringValue'];
    if (val.containsKey('integerValue')) return int.tryParse(val['integerValue'].toString()) ?? 0;
    if (val.containsKey('doubleValue')) return (val['doubleValue'] as num).toDouble();
    if (val.containsKey('booleanValue')) return val['booleanValue'] == true;
    if (val.containsKey('nullValue')) return null;
    if (val.containsKey('arrayValue')) {
      final list = val['arrayValue']?['values'] as List? ?? [];
      return list.map((item) => item is Map<String, dynamic> ? _decodeValue(item) : item).toList();
    }
    if (val.containsKey('mapValue')) {
      final fields = val['mapValue']?['fields'] as Map<String, dynamic>? ?? {};
      return fields.map((k, v) => MapEntry(k, v is Map<String, dynamic> ? _decodeValue(v) : v));
    }
    return null;
  }

  static Map<String, dynamic> _docToMap(Map<String, dynamic> doc) {
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};
    final result = <String, dynamic>{};
    fields.forEach((k, v) {
      if (v is Map<String, dynamic>) {
        result[k] = _decodeValue(v);
      } else {
        result[k] = v;
      }
    });
    return result;
  }

  static Map<String, dynamic> _mapToFields(Map<String, dynamic> data) {
    final fields = <String, dynamic>{};
    data.forEach((k, v) {
      fields[k] = _encodeValue(v);
    });
    return {'fields': fields};
  }

  // --- Seed Demo Room ---
  static void _seedDemoData() async {
    try {
      final existing = await getRoom('DEMO2026');
      if (existing == null) {
        final demoRoom = {
          'id': 'room-demo',
          'code': 'DEMO2026',
          'name': 'Education Expo 2026 - Booth Kampus',
          'description': 'Doorprize spesial kunjungan booth pameran pendidikan',
          'pin': '1234',
          'status': 'active',
          'activeGames': ['spinwheel', 'scratch', 'slot', 'gashapon', 'shake'],
          'adminId': 'admin',
          'prizes': [
            {'id': 'p1', 'name': 'Smartwatch Keren', 'color': '#EF4444', 'currentStock': 2, 'initialStock': 2, 'weight': 10},
            {'id': 'p2', 'name': 'Tumbler Stainless Exclusive', 'color': '#3B82F6', 'currentStock': 15, 'initialStock': 15, 'weight': 25},
            {'id': 'p3', 'name': 'Kaos Kampus Trendy', 'color': '#10B981', 'currentStock': 20, 'initialStock': 20, 'weight': 30},
            {'id': 'p4', 'name': 'Totebag Kanvas', 'color': '#F59E0B', 'currentStock': 30, 'initialStock': 30, 'weight': 35},
            {'id': 'p5', 'name': 'Sticker Pack & Pulpen Gel', 'color': '#8B5CF6', 'currentStock': 50, 'initialStock': 50, 'weight': 40},
          ],
          'createdAt': DateTime.now().toIso8601String(),
        };
        await saveRoom(demoRoom);
      }
    } catch (_) {}
  }

  // 1. Save or Update Room
  static Future<bool> saveRoom(Map<String, dynamic> room) async {
    final code = (room['code'] ?? '').toString().toUpperCase();
    if (code.isEmpty) return false;

    bool saved = false;

    // A. Direct Firestore REST API (Works unconditionally)
    try {
      final uri = Uri.parse('$_restBaseUrl/rooms/$code?key=$_apiKey');
      final res = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(_mapToFields(room)),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        saved = true;
      }
    } catch (_) {}

    // B. Cloud Firestore SDK (if initialized)
    try {
      final db = _db;
      if (db != null) {
        await db.collection('rooms').doc(code).set(room, SetOptions(merge: true));
        saved = true;
      }
    } catch (_) {}

    return saved;
  }

  // 2. Get Single Room
  static Future<Map<String, dynamic>?> getRoom(String roomCode) async {
    final code = roomCode.toUpperCase();
    if (code.isEmpty) return null;

    // A. Direct REST API
    try {
      final uri = Uri.parse('$_restBaseUrl/rooms/$code?key=$_apiKey');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic> && data.containsKey('fields')) {
          return _docToMap(data);
        }
      }
    } catch (_) {}

    // B. Cloud Firestore SDK
    try {
      final db = _db;
      if (db != null) {
        final doc = await db.collection('rooms').doc(code).get();
        if (doc.exists && doc.data() != null) {
          return doc.data();
        }
      }
    } catch (_) {}

    return null;
  }

  // 3. Stream Single Room Real-time (with periodic polling fallback)
  static Stream<Map<String, dynamic>?> streamRoom(String roomCode) {
    final db = _db;
    if (db != null) {
      final code = roomCode.toUpperCase();
      return db.collection('rooms').doc(code).snapshots().map((doc) => doc.data());
    }
    return Stream.periodic(const Duration(seconds: 3))
        .asyncMap((_) => getRoom(roomCode));
  }

  // 4. Get Rooms Created by Admin
  static Future<List<Map<String, dynamic>>?> getAdminRooms(String adminId) async {
    final cleanAdmin = adminId.trim().toLowerCase();
    List<Map<String, dynamic>> rooms = [];

    // A. Direct REST API
    try {
      final uri = Uri.parse('$_restBaseUrl/rooms?key=$_apiKey');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final docs = (data['documents'] as List<dynamic>?) ?? [];
        for (final item in docs) {
          if (item is Map<String, dynamic>) {
            final room = _docToMap(item);
            final roomAdmin = (room['adminId'] ?? '').toString().trim().toLowerCase();
            if (cleanAdmin == 'admin' || roomAdmin == cleanAdmin || roomAdmin.isEmpty) {
              rooms.add(room);
            }
          }
        }
        if (rooms.isNotEmpty) return rooms;
      }
    } catch (_) {}

    // B. SDK Fallback
    try {
      final db = _db;
      if (db != null) {
        final query = await db
            .collection('rooms')
            .where('adminId', isEqualTo: cleanAdmin)
            .get();
        if (query.docs.isNotEmpty) {
          return query.docs.map((doc) => doc.data()).toList();
        }
      }
    } catch (_) {}

    return rooms.isNotEmpty ? rooms : null;
  }

  // 5. Register Lead and Play (with duplicate prevention and stock decrement)
  static Future<Map<String, dynamic>?> registerAndPlay(
    String roomCode,
    Map<String, dynamic> payload,
  ) async {
    final cleanCode = roomCode.toUpperCase();
    final waNumber = (payload['waNumber'] ?? '').toString().trim();

    try {
      // A. Check duplicate WA in room via REST/SDK
      final participants = await getParticipants(cleanCode);
      if (participants != null && waNumber.isNotEmpty) {
        for (final p in participants) {
          if ((p['waNumber'] ?? '').toString().trim() == waNumber) {
            return {
              'success': false,
              'alreadyPlayed': true,
              'lead': p,
            };
          }
        }
      }

      // B. Fetch room to inspect prize stock
      Map<String, dynamic>? roomData = await getRoom(cleanCode);
      if (roomData == null) {
        roomData = {
          'id': 'room-$cleanCode',
          'code': cleanCode,
          'name': 'Education Expo 2026 - Booth Kampus',
          'description': 'Doorprize spesial kunjungan booth pameran pendidikan',
          'pin': '1234',
          'status': 'active',
          'activeGames': ['spinwheel', 'scratch', 'slot', 'gashapon', 'shake'],
          'prizes': [
            {'id': 'p1', 'name': 'Smartwatch Keren', 'color': '#EF4444', 'currentStock': 2, 'initialStock': 2, 'weight': 10},
            {'id': 'p2', 'name': 'Tumbler Stainless Exclusive', 'color': '#3B82F6', 'currentStock': 15, 'initialStock': 15, 'weight': 25},
            {'id': 'p3', 'name': 'Kaos Kampus Trendy', 'color': '#10B981', 'currentStock': 20, 'initialStock': 20, 'weight': 30},
            {'id': 'p4', 'name': 'Totebag Kanvas', 'color': '#F59E0B', 'currentStock': 30, 'initialStock': 30, 'weight': 35},
            {'id': 'p5', 'name': 'Sticker Pack & Pulpen Gel', 'color': '#8B5CF6', 'currentStock': 50, 'initialStock': 50, 'weight': 40},
          ],
          'adminId': 'admin',
          'createdAt': DateTime.now().toIso8601String(),
        };
        await saveRoom(roomData);
      }

      final prizesList = (roomData['prizes'] as List<dynamic>?) ?? [];

      // Pick available prize
      final availablePrizes = prizesList.where((p) {
        final stock = ((p['currentStock'] ?? p['initialStock'] ?? 0) as num).toInt();
        return stock > 0;
      }).toList();

      Map<String, dynamic> selectedPrize;
      if (availablePrizes.isNotEmpty) {
        final rand = Random();
        selectedPrize = Map<String, dynamic>.from(
          availablePrizes[rand.nextInt(availablePrizes.length)],
        );
      } else if (prizesList.isNotEmpty) {
        selectedPrize = Map<String, dynamic>.from(prizesList.first);
      } else {
        selectedPrize = {'name': 'Souvenir Menarik'};
      }

      // Decrement prize stock in room document
      for (final p in prizesList) {
        if (p['name'] == selectedPrize['name']) {
          final curr = ((p['currentStock'] ?? p['initialStock'] ?? 0) as num).toInt();
          if (curr > 0) {
            p['currentStock'] = curr - 1;
          }
        }
      }
      roomData['prizes'] = prizesList;
      await saveRoom(roomData);

      // Generate unique claim code
      final codeNum = 1000 + Random().nextInt(8999);
      final claimCode = 'SP-$codeNum';
      final leadId = 'lead-${DateTime.now().millisecondsSinceEpoch}';

      final leadMap = {
        'id': leadId,
        'roomId': cleanCode,
        'fullName': payload['fullName'] ?? '',
        'waNumber': payload['waNumber'] ?? '',
        'waParentNumber': payload['waParentNumber'] ?? '',
        'email': payload['email'] ?? '',
        'grade': payload['grade'] ?? '12',
        'schoolName': payload['schoolName'] ?? '',
        'schoolCity': payload['schoolCity'] ?? '',
        'studyInterest': payload['studyInterest'] ?? '',
        'gamePlayed': payload['gamePlayed'] ?? '',
        'prizeWon': selectedPrize['name'] ?? 'Souvenir',
        'claimCode': claimCode,
        'isClaimed': false,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Direct REST save
      try {
        final uri = Uri.parse('$_restBaseUrl/participants/$leadId?key=$_apiKey');
        await http.patch(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(_mapToFields(leadMap)),
        ).timeout(const Duration(seconds: 5));
      } catch (_) {}

      // SDK save
      try {
        final db = _db;
        if (db != null) {
          await db.collection('participants').doc(leadId).set(leadMap);
        }
      } catch (_) {}

      return {
        'success': true,
        'lead': leadMap,
      };
    } catch (e) {
      return null;
    }
  }

  // 6. Get Participants for Admin
  static Future<List<Map<String, dynamic>>?> getParticipants(String roomCode) async {
    final cleanCode = roomCode.toUpperCase();
    List<Map<String, dynamic>> list = [];

    // A. Direct REST API
    try {
      final uri = Uri.parse('$_restBaseUrl/participants?key=$_apiKey&pageSize=300');
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final docs = (data['documents'] as List<dynamic>?) ?? [];
        for (final item in docs) {
          if (item is Map<String, dynamic>) {
            final p = _docToMap(item);
            if ((p['roomId'] ?? '').toString().toUpperCase() == cleanCode) {
              list.add(p);
            }
          }
        }
        list.sort((a, b) {
          final dateA = a['createdAt']?.toString() ?? '';
          final dateB = b['createdAt']?.toString() ?? '';
          return dateB.compareTo(dateA);
        });
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}

    // B. SDK Fallback
    try {
      final db = _db;
      if (db != null) {
        final query = await db
            .collection('participants')
            .where('roomId', isEqualTo: cleanCode)
            .get();
        final sdkList = query.docs.map((doc) => doc.data()).toList();
        sdkList.sort((a, b) {
          final dateA = a['createdAt']?.toString() ?? '';
          final dateB = b['createdAt']?.toString() ?? '';
          return dateB.compareTo(dateA);
        });
        return sdkList;
      }
    } catch (_) {}

    return list.isNotEmpty ? list : null;
  }

  // 7. Stream Participants Realtime (with periodic polling fallback)
  static Stream<List<Map<String, dynamic>>> streamParticipants(String roomCode) {
    final db = _db;
    if (db != null) {
      final cleanCode = roomCode.toUpperCase();
      return db
          .collection('participants')
          .where('roomId', isEqualTo: cleanCode)
          .snapshots()
          .map((snap) {
        final list = snap.docs.map((d) => d.data()).toList();
        list.sort((a, b) {
          final dateA = a['createdAt']?.toString() ?? '';
          final dateB = b['createdAt']?.toString() ?? '';
          return dateB.compareTo(dateA);
        });
        return list;
      });
    }
    return Stream.periodic(const Duration(seconds: 3))
        .asyncMap((_) async => (await getParticipants(roomCode)) ?? []);
  }

  // 8. Toggle Claim Status
  static Future<bool> toggleClaim(String leadId) async {
    try {
      Map<String, dynamic>? lead;

      // Fetch current lead via REST
      try {
        final uri = Uri.parse('$_restBaseUrl/participants/$leadId?key=$_apiKey');
        final res = await http.get(uri).timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          lead = _docToMap(jsonDecode(res.body));
        }
      } catch (_) {}

      // Fallback SDK fetch
      if (lead == null) {
        final db = _db;
        if (db != null) {
          final doc = await db.collection('participants').doc(leadId).get();
          if (doc.exists && doc.data() != null) {
            lead = doc.data();
          }
        }
      }

      if (lead != null) {
        final current = lead['isClaimed'] == true;
        final nextState = !current;
        final claimedAt = nextState ? DateTime.now().toIso8601String() : null;

        lead['isClaimed'] = nextState;
        if (nextState) {
          lead['claimedAt'] = claimedAt;
        } else {
          lead.remove('claimedAt');
        }

        // Direct REST update
        try {
          final patchUri = Uri.parse('$_restBaseUrl/participants/$leadId?key=$_apiKey');
          await http.patch(
            patchUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(_mapToFields(lead)),
          ).timeout(const Duration(seconds: 5));
        } catch (_) {}

        // SDK update
        try {
          final db = _db;
          if (db != null) {
            await db.collection('participants').doc(leadId).update({
              'isClaimed': nextState,
              'claimedAt': claimedAt,
            });
          }
        } catch (_) {}

        return true;
      }
    } catch (_) {}
    return false;
  }
}
