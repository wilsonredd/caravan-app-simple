import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:clipboard/clipboard.dart';
import '../providers/auth_provider.dart';
import '../providers/caravan_provider.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _caravanNameController = TextEditingController();
  final _destinationNameController = TextEditingController();
  final _joinCodeController = TextEditingController();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _locationTimer;
  bool _isCreating = true;

  @override
  void initState() {
    super.initState();
    // Start simulating location updates
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _caravanNameController.dispose();
    _destinationNameController.dispose();
    _joinCodeController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final caravanProvider = Provider.of<CaravanProvider>(
        context,
        listen: false,
      );
      if (caravanProvider.activeCaravan != null) {
        _updateUserLocation();
      }
    });
  }

  void _updateUserLocation() {
    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    if (currentUser == null) return;

    final random = math.Random();
    final latOffset = (random.nextDouble() - 0.5) * 0.001;
    final lngOffset = (random.nextDouble() - 0.5) * 0.001;

    currentUser.updateLocation(
      latitude: 37.7749 + latOffset,
      longitude: -122.4194 + lngOffset,
      heading: random.nextDouble() * 360,
      speed: 10 + random.nextDouble() * 20,
    );

    setState(() {});
  }

  Future<void> _createCaravan() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
    final caravanProvider = Provider.of<CaravanProvider>(
      context,
      listen: false,
    );

    final currentUser = authProvider.currentUser;
    if (currentUser == null) return;

    await caravanProvider.createCaravan(
      name: _caravanNameController.text.trim(),
      destinationName: _destinationNameController.text.trim(),
      destinationLatitude: 37.7749, // Demo coordinates
      destinationLongitude: -122.4194,
      currentUser: currentUser,
    );
  }

  Future<void> _joinCaravan() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
    final caravanProvider = Provider.of<CaravanProvider>(
      context,
      listen: false,
    );

    final currentUser = authProvider.currentUser;
    if (currentUser == null) return;

    await caravanProvider.joinCaravan(
      joinCode: _joinCodeController.text.trim().toUpperCase(),
      currentUser: currentUser,
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
    final caravanProvider = Provider.of<CaravanProvider>(
      context,
      listen: false,
    );

    if (authProvider.currentUser != null) {
      caravanProvider.sendMessage(
        text: _messageController.text.trim(),
        sender: authProvider.currentUser!,
      );

      _messageController.clear();

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final caravanProvider = Provider.of<CaravanProvider>(context);
    final authProvider = Provider.of<AppAuthProvider>(context);
    final caravan = caravanProvider.activeCaravan;

    return Scaffold(
      appBar: AppBar(
        title: Text(caravan?.name ?? 'Caravan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body:
          caravan == null
              ? _buildCaravanSetupView()
              : _buildActiveCaravanView(),
    );
  }

  Widget _buildCaravanSetupView() {
    final caravanProvider = Provider.of<CaravanProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Toggle between create and join
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Create Caravan'),
                  icon: Icon(Icons.add),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Join Caravan'),
                  icon: Icon(Icons.group_add),
                ),
              ],
              selected: {_isCreating},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _isCreating = newSelection.first;
                });
              },
            ),

            const SizedBox(height: 24),

            if (_isCreating) ...[
              // Create Caravan Form
              TextFormField(
                controller: _caravanNameController,
                decoration: const InputDecoration(
                  labelText: 'Caravan Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name for your caravan';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _destinationNameController,
                decoration: const InputDecoration(
                  labelText: 'Destination',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your destination';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: caravanProvider.isLoading ? null : _createCaravan,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    caravanProvider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Create Caravan'),
              ),
            ] else ...[
              // Join Caravan Form
              TextFormField(
                controller: _joinCodeController,
                decoration: const InputDecoration(
                  labelText: 'Join Code',
                  border: OutlineInputBorder(),
                  hintText: 'Enter 6-character code',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the join code';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: caravanProvider.isLoading ? null : _joinCaravan,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    caravanProvider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Join Caravan'),
              ),
            ],

            const SizedBox(height: 32),

            // Demo buttons
            OutlinedButton(
              onPressed: () {
                _caravanNameController.text = 'Family Trip';
                _destinationNameController.text = 'Grand Canyon';
                _isCreating = true;
                setState(() {});
              },
              child: const Text('Fill Demo Data'),
            ),

            const SizedBox(height: 8),

            OutlinedButton(
              onPressed: () {
                _joinCodeController.text = 'ABC123';
                _isCreating = false;
                setState(() {});
              },
              child: const Text('Use Demo Code'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCaravanView() {
    final caravanProvider = Provider.of<CaravanProvider>(context);
    final authProvider = Provider.of<AppAuthProvider>(context);
    final caravan = caravanProvider.activeCaravan;
    final members = caravanProvider.caravanMembers;
    final messages = caravanProvider.messages;
    final currentUserId = authProvider.currentUser?.id;
    
    // Get join code for sharing
    final joinCode = caravan?.joinCode ?? '';

    return Column(
      children: [
        // Simple Map View - Shows member locations
        Expanded(
          flex: 3,
          child: Container(
            color: Colors.grey[200],
            child: Stack(
              children: [
                // Map placeholder text
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.map, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Destination: ${caravan?.destinationName ?? "Unknown"}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Show join code for sharing
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Card(
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.group_add, size: 16),
                                  const SizedBox(width: 8),
                                  const Text('Join Code:'),
                                  const SizedBox(width: 8),
                                  SelectableText(
                                    joinCode,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 16),
                                    onPressed: () {
                                      // Copy to clipboard
                                      FlutterClipboard.copy(joinCode).then((_) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Join code copied to clipboard'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      });
                                    },
                                    tooltip: 'Copy join code',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Member avatars
                for (final member in members)
                  Positioned(
                    // Random positions for demo
                    left: 100 + (member.id.hashCode % 200),
                    top: 100 + (member.name.hashCode % 200),
                    child: Tooltip(
                      message: member.name,
                      child: CircleAvatar(
                        backgroundColor:
                            member.id == caravan?.leaderId
                                ? Colors.red
                                : Colors.blue,
                        child: const Icon(
                          Icons.directions_car,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Chat section
        Expanded(
          flex: 2,
          child: Column(
            children: [
              // Messages
              Expanded(
                child:
                    messages.isEmpty
                        ? const Center(child: Text('No messages yet'))
                        : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isCurrentUser =
                                message.senderId == currentUserId;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    isCurrentUser
                                        ? MainAxisAlignment.end
                                        : MainAxisAlignment.start,
                                children: [
                                  if (!isCurrentUser)
                                    CircleAvatar(
                                      backgroundColor: Colors.grey,
                                      radius: 16,
                                      child: Text(message.senderName[0]),
                                    ),

                                  SizedBox(width: isCurrentUser ? 0 : 8),

                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          isCurrentUser
                                              ? Colors.blue[100]
                                              : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(message.text),
                                  ),

                                  SizedBox(width: isCurrentUser ? 8 : 0),

                                  if (isCurrentUser)
                                    CircleAvatar(
                                      backgroundColor: Colors.blue,
                                      radius: 16,
                                      child: Text(message.senderName[0]),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
              ),

              // Message input
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Message',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
