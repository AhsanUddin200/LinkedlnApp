import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<bool> _isFollowing(String userId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('following')
        .doc(userId)
        .get();

    return doc.exists;
  }

  Future<void> _toggleFollow(String userId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final followingRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('following')
        .doc(userId);

    final followersRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('followers')
        .doc(currentUser.uid);

    final isFollowing = await _isFollowing(userId);

    if (isFollowing) {
      // Unfollow
      await followingRef.delete();
      await followersRef.delete();
    } else {
      // Follow
      await followingRef.set({'timestamp': FieldValue.serverTimestamp()});
      await followersRef.set({'timestamp': FieldValue.serverTimestamp()});

      // Create notification for followed user
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': 'follow',
        'content': 'started following you',
        'userId': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          print('User Data: $userData'); // Debug print

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      Container(
                        height: 140,
                        width: double.infinity,
                        color: Colors.blue[100],
                      ),
                      Positioned(
                        left: 16,
                        top: 80,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          child: Icon(Icons.person, size: 60, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editProfile(userData),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => FirebaseAuth.instance.signOut(),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData['name'] ?? 'Add your name',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(userData['uid'])
                                .collection('followers')
                                .snapshots(),
                            builder: (context, snapshot) {
                              return Text(
                                '${snapshot.data?.docs.length ?? 0} followers',
                                style: TextStyle(color: Colors.grey[600]),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(userData['uid'])
                                .collection('following')
                                .snapshots(),
                            builder: (context, snapshot) {
                              return Text(
                                '${snapshot.data?.docs.length ?? 0} following',
                                style: TextStyle(color: Colors.grey[600]),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userData['title'] ?? 'Add your headline',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        userData['location'] ?? 'Add location',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => _editProfile(userData),
                        child: const Text('Edit Profile'),
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        'About',
                        userData['about'] ?? 'Add a summary about yourself',
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        'Experience',
                        userData['experience'] ?? 'Add your work experience',
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        'Education',
                        userData['education'] ?? 'Add your education',
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        'Skills',
                        userData['skills'] ?? 'Add your skills',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {},
              iconSize: 20,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(color: Colors.grey[800]),
        ),
      ],
    );
  }

  Future<void> _editProfile(Map<String, dynamic> currentData) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final nameController = TextEditingController(text: currentData['name']);
      final titleController = TextEditingController(text: currentData['title']);
      final locationController = TextEditingController(text: currentData['location']);
      final aboutController = TextEditingController(text: currentData['about']);
      final educationController = TextEditingController(text: currentData['education']);
      final skillsController = TextEditingController(text: currentData['skills']);
      final experienceController = TextEditingController(text: currentData['experience']);

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Headline'),
                ),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                TextField(
                  controller: aboutController,
                  decoration: const InputDecoration(labelText: 'About'),
                  maxLines: 3,
                ),
                TextField(
                  controller: educationController,
                  decoration: const InputDecoration(labelText: 'Education'),
                  maxLines: 2,
                ),
                TextField(
                  controller: skillsController,
                  decoration: const InputDecoration(labelText: 'Skills'),
                  maxLines: 2,
                ),
                TextField(
                  controller: experienceController,
                  decoration: const InputDecoration(labelText: 'Experience'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .update({
                    'name': nameController.text.trim(),
                    'title': titleController.text.trim(),
                    'location': locationController.text.trim(),
                    'about': aboutController.text.trim(),
                    'education': educationController.text.trim(),
                    'skills': skillsController.text.trim(),
                    'experience': experienceController.text.trim(),
                  });
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated successfully!')),
                    );
                  }
                } catch (e) {
                  print('Error updating profile: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update profile')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error in edit profile: $e');
    }
  }
} 