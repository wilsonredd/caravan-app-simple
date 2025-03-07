import 'package:uuid/uuid.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  bool isActive;
  double? latitude;
  double? longitude;
  double? heading;
  double? speed;
  DateTime? lastUpdated;

  UserModel({
    String? id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.isActive = true,
    this.latitude,
    this.longitude,
    this.heading,
    this.speed,
    this.lastUpdated,
  }) : id = id ?? const Uuid().v4();

  // For simulating location updates
  void updateLocation({
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
  }) {
    this.latitude = latitude;
    this.longitude = longitude;
    this.heading = heading;
    this.speed = speed;
    this.lastUpdated = DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'isActive': isActive,
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
      'speed': speed,
      'lastUpdated': lastUpdated?.millisecondsSinceEpoch,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      profileImageUrl: map['profileImageUrl'],
      isActive: map['isActive'] ?? true,
      latitude: map['latitude'],
      longitude: map['longitude'],
      heading: map['heading'],
      speed: map['speed'],
      lastUpdated:
          map['lastUpdated'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'])
              : null,
    );
  }
}
