import 'dart:convert';
import 'package:flutter/material.dart';

class PrizeItem {
  final String id;
  final String name;
  final int initialStock;
  int currentStock;
  final Color color;
  final int weight;

  PrizeItem({
    required this.id,
    required this.name,
    required this.initialStock,
    required this.currentStock,
    required this.color,
    this.weight = 20,
  });

  factory PrizeItem.fromJson(Map<String, dynamic> json) {
    Color parsedColor = Colors.amber;
    if (json['color'] != null) {
      final hex = json['color'].toString().replaceAll('#', '');
      if (hex.length == 6) {
        parsedColor = Color(int.parse('FF$hex', radix: 16));
      }
    }
    return PrizeItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      initialStock: json['initialStock'] ?? 10,
      currentStock: json['currentStock'] ?? 10,
      color: parsedColor,
      weight: json['weight'] ?? 20,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'initialStock': initialStock,
      'currentStock': currentStock,
      'color': '#${color.value.toRadixString(16).substring(2)}',
      'weight': weight,
    };
  }
}

class RoomModel {
  final String id;
  final String code;
  final String name;
  final String description;
  final String pin;
  final String status;
  final List<PrizeItem> prizes;
  final List<String> activeGames;

  RoomModel({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.pin,
    required this.status,
    required this.prizes,
    required this.activeGames,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    final prizeList = (json['prizes'] as List<dynamic>?)
            ?.map((p) => PrizeItem.fromJson(p))
            .toList() ??
        [];
    final gamesList = (json['activeGames'] as List<dynamic>?)
            ?.map((g) => g.toString())
            .toList() ??
        ['spinwheel', 'scratch', 'slot', 'gashapon', 'shake'];

    return RoomModel(
      id: json['id'] ?? '',
      code: (json['code'] ?? '').toString().toUpperCase(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      pin: json['pin'] ?? '1234',
      status: json['status'] ?? 'active',
      prizes: prizeList,
      activeGames: gamesList,
    );
  }
}

class ParticipantLead {
  final String id;
  final String roomId;
  final String fullName;
  final String waNumber;
  final String waParentNumber;
  final String email;
  final String grade;
  final String schoolName;
  final String schoolCity;
  final String studyInterest;
  final String gamePlayed;
  final String prizeWon;
  final String claimCode;
  bool isClaimed;
  final String? claimedAt;
  final String createdAt;

  ParticipantLead({
    required this.id,
    required this.roomId,
    required this.fullName,
    required this.waNumber,
    required this.waParentNumber,
    required this.email,
    required this.grade,
    required this.schoolName,
    required this.schoolCity,
    required this.studyInterest,
    required this.gamePlayed,
    required this.prizeWon,
    required this.claimCode,
    required this.isClaimed,
    this.claimedAt,
    required this.createdAt,
  });

  factory ParticipantLead.fromJson(Map<String, dynamic> json) {
    return ParticipantLead(
      id: json['id'] ?? '',
      roomId: json['roomId'] ?? '',
      fullName: json['fullName'] ?? '',
      waNumber: json['waNumber'] ?? '',
      waParentNumber: json['waParentNumber'] ?? '',
      email: json['email'] ?? '',
      grade: json['grade'] ?? '',
      schoolName: json['schoolName'] ?? '',
      schoolCity: json['schoolCity'] ?? '',
      studyInterest: json['studyInterest'] ?? '',
      gamePlayed: json['gamePlayed'] ?? '',
      prizeWon: json['prizeWon'] ?? '',
      claimCode: json['claimCode'] ?? '',
      isClaimed: json['isClaimed'] ?? false,
      claimedAt: json['claimedAt'],
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'fullName': fullName,
      'waNumber': waNumber,
      'waParentNumber': waParentNumber,
      'email': email,
      'grade': grade,
      'schoolName': schoolName,
      'schoolCity': schoolCity,
      'studyInterest': studyInterest,
      'gamePlayed': gamePlayed,
      'prizeWon': prizeWon,
      'claimCode': claimCode,
      'isClaimed': isClaimed,
      'claimedAt': claimedAt,
      'createdAt': createdAt,
    };
  }
}
