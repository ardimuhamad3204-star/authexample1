import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController namaController = TextEditingController();

  final TextEditingController nimController = TextEditingController();

  final TextEditingController statusController = TextEditingController();

  String? selectedDocId;

  Future<void> tambahAbsensi() async {
    final user = FirebaseAuth.instance.currentUser;

    if (namaController.text.isEmpty ||
        nimController.text.isEmpty ||
        statusController.text.isEmpty) {
      return;
    }

    if (selectedDocId == null) {
      await _firestore.collection('absensi').add({
        'namaMahasiswa': namaController.text,
        'nim': nimController.text,
        'status': statusController.text,
        'userId': user!.uid,
        'userEmail': user.email,
        'createdAt': Timestamp.now(),
      });
    } else {
      await _firestore.collection('absensi').doc(selectedDocId).update({
        'namaMahasiswa': namaController.text,
        'nim': nimController.text,
        'status': statusController.text,
      });

      selectedDocId = null;
    }

    namaController.clear();
    nimController.clear();
    statusController.clear();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Data berhasil disimpan')));
  }

  Future<void> hapusAbsensi(String docId) async {
    await _firestore.collection('absensi').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sistem Absensi Mahasiswa"),
        actions: [
          IconButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Selamat Datang ${user?.email}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: namaController,
              decoration: const InputDecoration(
                labelText: "Nama Mahasiswa",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: nimController,
              decoration: const InputDecoration(
                labelText: "NIM",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: statusController,
              decoration: const InputDecoration(
                labelText: "Status Kehadiran",
                hintText: "Hadir / Izin / Sakit",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: tambahAbsensi,
                child: Text(
                  selectedDocId == null ? "Simpan Absensi" : "Update Absensi",
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Daftar Absensi",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('absensi')
                    .where('userId', isEqualTo: user?.uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text(snapshot.error.toString()));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("Belum ada data absensi"));
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];

                      final data = doc.data() as Map<String, dynamic>;

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(data['namaMahasiswa']),
                          subtitle: Text(
                            "NIM : ${data['nim']}\nStatus : ${data['status']}",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  namaController.text = data['namaMahasiswa'];

                                  nimController.text = data['nim'];

                                  statusController.text = data['status'];

                                  selectedDocId = doc.id;
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  await hapusAbsensi(doc.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
