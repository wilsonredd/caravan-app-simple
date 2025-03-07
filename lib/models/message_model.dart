import 'package:uuid/uuid.dart';

class MessageModel {
  final String id;
  final String caravanId;
  final String senderId;
  final String senderName;
  final String text;
  final bool isPreset;
  final DateTime timestamp;

  MessageModel({
    String? id,
    required this.caravanId,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.isPreset = false,
    DateTime? timestamp,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'caravanId': caravanId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'isPreset': isPreset,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'],
      caravanId: map['caravanId'],
      senderId: map['senderId'],
      senderName: map['senderName'],
      text: map['text'],
      isPreset: map['isPreset'] ?? false,
      timestamp:
          map['timestamp'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
              : DateTime.now(),
    );
  }
}
