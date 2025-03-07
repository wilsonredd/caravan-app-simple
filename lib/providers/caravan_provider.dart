import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../models/caravan_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class CaravanProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CaravanModel? _activeCaravan;
  List<UserModel> _caravanMembers = [];
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  String? _error;

  // Stream subscriptions for real-time updates
  StreamSubscription? _caravanSubscription;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _membersSubscription;

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
      final caravanId = const Uuid().v4();
      final joinCode = _generateJoinCode();

      final newCaravan = CaravanModel(
        id: caravanId,
        name: name,
        joinCode: joinCode,
        leaderId: currentUser.id,
        members: [currentUser.id],
        destinationName: destinationName,
        destinationLatitude: destinationLatitude,
        destinationLongitude: destinationLongitude,
        estimatedArrivalTime: DateTime.now().add(const Duration(hours: 2)),
      );

      // Save to Firestore
      await _firestore
          .collection('caravans')
          .doc(caravanId)
          .set(newCaravan.toMap());

      // Set active caravan and start listening for updates
      _activeCaravan = newCaravan;
      _caravanMembers = [currentUser];
      _messages = [];

      // Start listening to real-time updates
      _startListeningToCaravan(caravanId);

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
      // Find caravan with this join code
      final querySnapshot = await _firestore
          .collection('caravans')
          .where('joinCode', isEqualTo: joinCode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _error = "Invalid join code or caravan is no longer active";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final caravanDoc = querySnapshot.docs.first;
      final caravanData = caravanDoc.data();
      final caravanId = caravanDoc.id;

      // Add user to caravan members
      final members = List<String>.from(caravanData['members'] ?? []);

      if (!members.contains(currentUser.id)) {
        members.add(currentUser.id);
        await _firestore.collection('caravans').doc(caravanId).update({
          'members': members,
        });
      }

      // Set active caravan
      _activeCaravan = CaravanModel.fromMap(caravanData);

      // Start listening to real-time updates
      _startListeningToCaravan(caravanId);

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
  Future<void> sendMessage({
    required String text,
    required UserModel sender,
    bool isPreset = false,
  }) async {
    if (_activeCaravan == null) return;

    try {
      final messageId = const Uuid().v4();

      final newMessage = MessageModel(
        id: messageId,
        caravanId: _activeCaravan!.id,
        senderId: sender.id,
        senderName: sender.name,
        text: text,
        isPreset: isPreset,
      );

      // Save to Firestore
      await _firestore
          .collection('messages')
          .doc(messageId)
          .set(newMessage.toMap());

      // Local messages already updated via the listener
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Update user location
  Future<void> updateUserLocation({
    required String userId,
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'latitude': latitude,
        'longitude': longitude,
        'heading': heading,
        'speed': speed,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Leave a caravan
  Future<void> leaveCaravan() async {
    if (_activeCaravan == null) return;

    try {
      // Stop listening to updates
      _stopListeningToCaravan();

      // If you're not the leader, just remove yourself from members
      if (_activeCaravan!.leaderId != _currentUser?.id) {
        final members = List<String>.from(_activeCaravan!.members);
        members.remove(_currentUser?.id);

        await _firestore.collection('caravans').doc(_activeCaravan!.id).update({
          'members': members,
        });
      }

      // Reset local state
      _activeCaravan = null;
      _caravanMembers = [];
      _messages = [];

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Start listening to real-time updates
  void _startListeningToCaravan(String caravanId) {
    // Stop existing listeners
    _stopListeningToCaravan();

    // Listen for caravan updates
    _caravanSubscription = _firestore
        .collection('caravans')
        .doc(caravanId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            _activeCaravan = CaravanModel.fromMap(snapshot.data()!);
            _loadCaravanMembers();
            notifyListeners();
          } else {
            // Caravan was deleted
            _activeCaravan = null;
            _caravanMembers = [];
            _messages = [];
            notifyListeners();
          }
        });

    // Listen for messages
    _messagesSubscription = _firestore
        .collection('messages')
        .where('caravanId', isEqualTo: caravanId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
          _messages = snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data()))
              .toList();
          notifyListeners();
        });
  }

  // Stop listening to real-time updates
  void _stopListeningToCaravan() {
    _caravanSubscription?.cancel();
    _messagesSubscription?.cancel();
    _membersSubscription?.cancel();

    _caravanSubscription = null;
    _messagesSubscription = null;
    _membersSubscription = null;
  }

  // Load all caravan members
  Future<void> _loadCaravanMembers() async {
    if (_activeCaravan == null) return;

    try {
      final memberIds = _activeCaravan!.members;

      // Use a batch query to get all members
      final membersSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: memberIds)
          .get();

      _caravanMembers = membersSnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Generate a random join code
  String _generateJoinCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (index) {
      return chars[Uuid().v4().hashCode % chars.length];
    }).join();
  }

  // Get current user for internal use
  UserModel? get _currentUser => _caravanMembers.firstWhere(
    (user) => user.id == _activeCaravan?.leaderId,
    orElse: () => UserModel(id: '', name: 'Unknown', email: ''),
  );

  @override
  void dispose() {
    _stopListeningToCaravan();
    super.dispose();
  }
}