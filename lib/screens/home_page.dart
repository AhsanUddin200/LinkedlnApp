import 'package:flutter/material.dart';
import 'feed_page.dart';
import 'profile_page.dart';
import 'create_post_screen.dart';
import 'notifications_page.dart';
import 'jobs_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    FeedPage(),
    ProfilePage(),
    CreatePostScreen(),
    NotificationsPage(),
    JobsPage(),
  ];

  void _handleNavigation(int index) {
    if (index == 2) {
      // Post button index
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreatePostScreen()),
      );
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[300]!)),
          color: Colors.white,
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _handleNavigation,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey[600],
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(
              icon:
                  Icon(_selectedIndex == 0 ? Icons.home : Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 1
                  ? Icons.supervisor_account
                  : Icons.supervisor_account_outlined),
              label: 'My Profile',
            ),
            BottomNavigationBarItem(
              icon: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.all(2),
                child: const Icon(Icons.add),
              ),
              label: 'Post',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  Icon(_selectedIndex == 3 
                    ? Icons.notifications 
                    : Icons.notifications_outlined
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .collection('notifications')
                        .where('read', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const SizedBox();
                      }
                      return Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            '${snapshot.data!.docs.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 4 ? Icons.work : Icons.work_outline),
              label: 'Jobs',
            ),
          ],
        ),
      ),
    );
  }
}
