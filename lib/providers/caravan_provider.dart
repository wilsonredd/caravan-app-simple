import 'package:flutter/foundation.dart';
import '../models/caravan_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class CaravanProvider with ChangeNotifier {
  CaravanModel? _activeCaravan;
  List<UserModel> _caravanMembers = [];
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  String? _error;

  CaravanModel? get activeCaravan => _activeCaravan;
  List<UserModel> get caravanMembers => _caravanMembers;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Create a new caravan
  Future<bool> createCaravan({
    required String name,
    required String destinationName,
    required double destinationLatitude,
    required double destinationLongitude,
    required UserModel currentUser,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      final newCaravan = CaravanModel(
        name: name,
        leaderId: currentUser.id,
        destinationName: destinationName,
        destinationLatitude: destinationLatitude,
        destinationLongitude: destinationLongitude,
        estimatedArrivalTime: DateTime.now().add(const Duration(hours: 2)),
      );

      _activeCaravan = newCaravan;
      _caravanMembers = [currentUser];
      _messages = [];

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Join an existing caravan
  Future<bool> joinCaravan({
    required String joinCode,
    required UserModel currentUser,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Check if join code is valid
      if (joinCode.isEmpty) {
        _error = "Invalid join code";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Simulate finding the caravan with the join code
      // In a real app, this would query a database
      final caravan = CaravanModel(
        id: "caravan123",
        name: "Demo Caravan",
        joinCode: joinCode,
        leaderId: "leader123",
        members: ["leader123", currentUser.id],
        destinationName: "San Francisco",
        destinationLatitude: 37.7749,
        destinationLongitude: -122.4194,
        estimatedArrivalTime: DateTime.now().add(const Duration(hours: 3)),
      );

      _activeCaravan = caravan;

      // Create some demo members
      _caravanMembers = [
        UserModel(
          id: "leader123",
          name: "John Leader",
          email: "leader@example.com",
          latitude: 37.7749,
          longitude: -122.4194,
        ),
        currentUser,
      ];

      // Create some demo messages
      _messages = [
        MessageModel(
          caravanId: caravan.id,
          senderId: "leader123",
          senderName: "John Leader",
          text: "Welcome to the caravan!",
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ];

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Send a message
  void sendMessage({
    required String text,
    required UserModel sender,
    bool isPreset = false,
  }) {
    if (_activeCaravan == null) return;

    final newMessage = MessageModel(
      caravanId: _activeCaravan!.id,
      senderId: sender.id,
      senderName: sender.name,
      text: text,
      isPreset: isPreset,
    );

    _messages.add(newMessage);
    notifyListeners();
  }

  // Leave a caravan
  void leaveCaravan() {
    _activeCaravan = null;
    _caravanMembers = [];
    _messages = [];
    notifyListeners();
  }
}
