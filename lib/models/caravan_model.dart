import 'package:uuid/uuid.dart';

class CaravanModel {
  final String id;
  final String name;
  final String joinCode;
  final String leaderId;
  final List<String> members;
  final bool isActive;

  // Destination info
  final String destinationName;
  final double destinationLatitude;
  final double destinationLongitude;
  final DateTime? estimatedArrivalTime;

  CaravanModel({
    String? id,
    required this.name,
    String? joinCode,
    required this.leaderId,
    List<String>? members,
    this.isActive = true,
    required this.destinationName,
    required this.destinationLatitude,
    required this.destinationLongitude,
    this.estimatedArrivalTime,
  }) : id = id ?? const Uuid().v4(),
       joinCode = joinCode ?? _generateJoinCode(),
       members = members ?? [leaderId];

  // Generate a random join code
  static String _generateJoinCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (index) {
      return chars[Uuid().v4().hashCode % chars.length];
    }).join();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'joinCode': joinCode,
      'leaderId': leaderId,
      'members': members,
      'isActive': isActive,
      'destinationName': destinationName,
      'destinationLatitude': destinationLatitude,
      'destinationLongitude': destinationLongitude,
      'estimatedArrivalTime': estimatedArrivalTime?.millisecondsSinceEpoch,
    };
  }

  factory CaravanModel.fromMap(Map<String, dynamic> map) {
    return CaravanModel(
      id: map['id'],
      name: map['name'],
      joinCode: map['joinCode'],
      leaderId: map['leaderId'],
      members: List<String>.from(map['members'] ?? []),
      isActive: map['isActive'] ?? true,
      destinationName: map['destinationName'],
      destinationLatitude: map['destinationLatitude'],
      destinationLongitude: map['destinationLongitude'],
      estimatedArrivalTime:
          map['estimatedArrivalTime'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['estimatedArrivalTime'])
              : null,
    );
  }
}
