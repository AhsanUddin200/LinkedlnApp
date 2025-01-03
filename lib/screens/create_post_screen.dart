import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _postController = TextEditingController();
  bool _isLoading = false;
  int _remainingChars = 280;

  @override
  void initState() {
    super.initState();
    _postController.addListener(() {
      setState(() {
        _remainingChars = 280 - _postController.text.length;
      });
    });
  }

  Future<void> _createPost() async {
    if (_postController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('posts').add({
        'content': _postController.text.trim(),
        'userId': user?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'comments': [],
        'shares': [],
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create post')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _remainingChars >= 0 ? _createPost : null,
                  child: const Text('Post'),
                ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: Icon(Icons.person, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser?.uid)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final userData = snapshot.data!.data() as Map<String, dynamic>;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userData['name'] ?? 'Anonymous',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                userData['title'] ?? '',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          );
                        }
                        return const Text('Loading...');
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _postController,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'What do you want to talk about?',
                border: InputBorder.none,
                counterText: '$_remainingChars characters remaining',
                errorText: _remainingChars < 0 ? 'Post is too long' : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 