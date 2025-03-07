import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/caravan_provider.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final caravanProvider = Provider.of<CaravanProvider>(context);
    final user = authProvider.currentUser;
    final caravan = caravanProvider.activeCaravan;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not found')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User profile card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // User info
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    user.email,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Active caravan info
          if (caravan != null) ...[
            ListTile(
              title: const Text('Caravan'),
              subtitle: Text(caravan.name),
              leading: const Icon(Icons.car_rental),
            ),

            ListTile(
              title: const Text('Role'),
              subtitle: Text(caravan.leaderId == user.id ? 'Leader' : 'Member'),
              leading: const Icon(Icons.person),
            ),

            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: () {
                caravanProvider.leaveCaravan();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.exit_to_app, color: Colors.red),
              label: const Text(
                'Leave Caravan',
                style: TextStyle(color: Colors.red),
              ),
            ),

            const SizedBox(height: 16),
          ],

          // Logout button
          ElevatedButton.icon(
            onPressed: () {
              authProvider.logout();
              if (caravan != null) {
                caravanProvider.leaveCaravan();
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
