import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _cachedUsername;

  Future<String> _fetchUsername(String uid) async {
    if (_cachedUsername != null) {
      return _cachedUsername!;
    }
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    _cachedUsername = userDoc.data()?['username'] ?? 'No Username';
    return _cachedUsername!;
  }

  String _getInitial(String? name) {
    if (name == null || name.isEmpty) {
      return 'U';
    }
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            FutureBuilder<String?>(
              future: _fetchUsername(user?.uid ?? ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey,
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                } else if (snapshot.hasError || snapshot.data == null) {
                  return CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.deepPurple,
                    child: Text(
                      _getInitial(user?.displayName),
                      style: const TextStyle(color: Colors.white, fontSize: 30),
                    ),
                  );
                } else {
                  return CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.deepPurple,
                    child: Text(
                      _getInitial(snapshot.data),
                      style: const TextStyle(color: Colors.white, fontSize: 30),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            FutureBuilder<String?>(
              future: _fetchUsername(user?.uid ?? ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError || snapshot.data == null) {
                  return Text(
                    user?.displayName ?? 'No Username',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  );
                } else {
                  return Text(
                    snapshot.data!,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 10),
            Text(
              user?.email ?? 'No Email',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.settings,
                      color: Colors.deepPurple,
                    ),
                    title: const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      // Navigate to settings screen
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.deepPurple),
                    title: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
