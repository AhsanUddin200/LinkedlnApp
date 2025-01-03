import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JobsPage extends StatelessWidget {
  const JobsPage({Key? key}) : super(key: key);

  Future<void> _addSampleJobs() async {
    try {
      final List<Map<String, dynamic>> jobsList = [
        {
          'title': 'Flutter Developer',
          'company': 'Tech Corp',
          'location': 'Remote',
          'salary': '₹8-12 LPA',
        },
        {
          'title': 'React Developer',
          'company': 'Web Solutions',
          'location': 'Bangalore',
          'salary': '₹10-15 LPA',
        },
        {
          'title': 'UI/UX Designer',
          'company': 'Design Studio',
          'location': 'Delhi',
          'salary': '₹6-9 LPA',
        },
        {
          'title': 'Android Developer',
          'company': 'Mobile Apps Inc',
          'location': 'Hyderabad',
          'salary': '₹9-14 LPA',
        },
        {
          'title': 'Full Stack Developer',
          'company': 'Digital Solutions',
          'location': 'Mumbai',
          'salary': '₹12-18 LPA',
        },
        {
          'title': 'Product Manager',
          'company': 'StartUp Hub',
          'location': 'Pune',
          'salary': '₹15-25 LPA',
        },
        {
          'title': 'iOS Developer',
          'company': 'Apple Solutions',
          'location': 'Gurgaon',
          'salary': '₹10-16 LPA',
        },
        {
          'title': 'DevOps Engineer',
          'company': 'Cloud Tech',
          'location': 'Chennai',
          'salary': '₹14-20 LPA',
        }
      ];

      // Randomly select 3 different jobs
      jobsList.shuffle();
      final selectedJobs = jobsList.take(3);

      for (var job in selectedJobs) {
        // Add timestamp to each job
        job['postedAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('jobs').add(job);
      }

      print('New sample jobs added successfully!');
    } catch (e) {
      print('Error adding sample jobs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs'),
        backgroundColor: Colors.white,
        actions: [
          // Add this button to manually add sample jobs
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addSampleJobs,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .orderBy('postedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final jobs = snapshot.data?.docs ?? [];

          if (jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No jobs available'),
                  ElevatedButton(
                    onPressed: _addSampleJobs,
                    child: const Text('Add Sample Jobs'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    job['title'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job['company'] ?? ''),
                      Text(job['location'] ?? ''),
                      Text(
                        job['salary'] ?? '',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.bookmark_border),
                    onPressed: () {},
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
