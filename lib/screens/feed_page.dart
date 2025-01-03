import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'comments_sheet.dart';
import 'create_post_screen.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({Key? key}) : super(key: key);

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  Stream<QuerySnapshot> _getPostsStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Stream.empty();

    // Show all posts for now
    return FirebaseFirestore.instance
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots();

    // Uncomment this when you want to show only followed users' posts
    /*
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('following')
        .snapshots()
        .asyncMap((followingSnapshot) async {
      final followingIds = followingSnapshot.docs.map((doc) => doc.id).toList();
      followingIds.add(currentUser.uid);

      if (followingIds.isEmpty) {
        return await FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .limit(10)
            .get();
      }

      return await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', whereIn: followingIds)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();
    });
    */
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

    final doc = await followingRef.get();
    final isFollowing = doc.exists;

    if (isFollowing) {
      await followingRef.delete();
      await followersRef.delete();
    } else {
      await followingRef.set({'timestamp': FieldValue.serverTimestamp()});
      await followersRef.set({'timestamp': FieldValue.serverTimestamp()});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[200],
              child: Icon(Icons.person, color: Colors.grey[600], size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.message, color: Colors.grey[600]),
          ],
        ),
      ),
      body: ListView(
        children: [
          _buildPostCreator(),
          const Divider(height: 8, thickness: 8),
          StreamBuilder<QuerySnapshot>(
            stream: _getPostsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Something went wrong'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              return Column(
                children: snapshot.data!.docs.map((doc) {
                  return _buildPost(doc);
                }).toList(),
              );
            },
          ),
          _buildSuggestedUsers(),
        ],
      ),
    );
  }

  Widget _buildPostCreator() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CreatePostScreen()),
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[200],
                  child: Icon(Icons.person, color: Colors.grey[600], size: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'Start a post',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPostOption(Icons.image, 'Photo', Colors.blue),
              _buildPostOption(Icons.videocam, 'Video', Colors.green),
              _buildPostOption(Icons.event, 'Event', Colors.orange),
              _buildPostOption(Icons.article, 'Write article', Colors.pink),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostOption(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildPost(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final bool isLiked = data['likes']?.contains(currentUserId) ?? false;

    Future<void> handleLike() async {
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) return;

        if (isLiked) {
          await FirebaseFirestore.instance
              .collection('posts')
              .doc(doc.id)
              .update({
            'likes': FieldValue.arrayRemove([userId])
          });
        } else {
          // Add like
          await FirebaseFirestore.instance
              .collection('posts')
              .doc(doc.id)
              .update({
            'likes': FieldValue.arrayUnion([userId])
          });

          // Create notification for post owner
          if (data['userId'] != userId) {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get();
            final userName = userDoc.data()?['name'] ?? 'Someone';

            await FirebaseFirestore.instance
                .collection('users')
                .doc(data['userId'])
                .collection('notifications')
                .add({
              'type': 'like',
              'content': '$userName liked your post',
              'timestamp': FieldValue.serverTimestamp(),
              'postId': doc.id,
              'userId': userId,
            });
          }
        }
      } catch (e) {
        print('Error liking post: $e');
      }
    }

    Future<void> showComments() async {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => CommentsSheet(postId: doc.id),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info and more options
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[200],
                  child: Icon(Icons.person, color: Colors.grey[600], size: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(data['userId'])
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final userData =
                                snapshot.data!.data() as Map<String, dynamic>;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userData['name'] ?? 'Anonymous',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  userData['title'] ?? '',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '2h • 🌏',
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
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {},
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
          // Post content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              data['content'],
              style: const TextStyle(fontSize: 14),
            ),
          ),
          // Post image if exists
          if (data['imageUrl'] != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(data['imageUrl']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          // Reactions summary
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.thumb_up_alt, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 4),
                Text(
                  '${data['likes']?.length ?? 0}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
                Text(
                  '${data['comments']?.length ?? 0} comments • ${data['shares']?.length ?? 0} shares',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPostAction(
                  icon: isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  label: 'Like',
                  onTap: handleLike,
                  isActive: isLiked,
                ),
                _buildPostAction(
                  icon: Icons.comment_outlined,
                  label: 'Comment',
                  onTap: showComments,
                ),
                _buildPostAction(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: () {},
                ),
                _buildPostAction(
                  icon: Icons.send_outlined,
                  label: 'Send',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? Colors.blue : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.blue : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedUsers() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggested Users',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final userData = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(userData['name'] ?? 'User'),
                    subtitle: Text(userData['title'] ?? ''),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // Add this method to check if user is being followed
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
}
