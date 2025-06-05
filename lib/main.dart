// main.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Fungsi utama untuk menjalankan aplikasi
void main() {
  runApp(const MyApp());
}

// Kelas utama aplikasi
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App - Data External',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TodoListPage(),
    );
  }
}

// Kelas untuk membuat model data Todo
class Todo {
  final int userId;
  final int id;
  final String title;
  final bool completed;

  // Constructor untuk membuat objek Todo
  const Todo({
    required this.userId,
    required this.id,
    required this.title,
    required this.completed,
  });

  // Fungsi untuk mengubah JSON menjadi objek Todo
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      userId: json['userId'],
      id: json['id'],
      title: json['title'],
      completed: json['completed'],
    );
  }
}

// Halaman utama yang menampilkan daftar Todo
class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  TodoListPageState createState() => TodoListPageState();
}

class TodoListPageState extends State<TodoListPage> {
  // List untuk menyimpan data todo yang diambil dari API
  List<Todo> todos = [];
  
  // Variable untuk mengetahui apakah data sedang dimuat
  bool isLoading = true;
  
  // Variable untuk menyimpan pesan error jika ada
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Memanggil fungsi untuk mengambil data saat aplikasi dimulai
    fetchTodos();
  }

  // Fungsi untuk mengambil data dari API external
  Future<void> fetchTodos() async {
    try {
      // Mengirim permintaan HTTP GET ke API
      final response = await http.get(
        Uri.parse('https://jsonplaceholder.typicode.com/todos'),
      );

      // Mengecek apakah permintaan berhasil (status code 200)
      if (response.statusCode == 200) {
        // Mengubah response body (JSON string) menjadi List
        List<dynamic> jsonData = json.decode(response.body);
        
        // Mengubah setiap item JSON menjadi objek Todo
        List<Todo> fetchedTodos = jsonData
            .map((item) => Todo.fromJson(item))
            .toList();

        // Memperbarui state dengan data yang baru
        setState(() {
          todos = fetchedTodos;
          isLoading = false;
        });
      } else {
        // Jika terjadi error, tampilkan pesan error
        setState(() {
          errorMessage = 'Gagal mengambil data. Status: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      // Menangani error yang mungkin terjadi (misal: tidak ada internet)
      setState(() {
        errorMessage = 'Terjadi kesalahan: $e';
        isLoading = false;
      });
    }
  }

  // Fungsi untuk refresh data
  Future<void> refreshData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    await fetchTodos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar (header aplikasi)
      appBar: AppBar(
        title: const Text('Daftar Todo'),
        backgroundColor: Colors.blue,
        actions: [
          // Tombol refresh di AppBar
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshData,
          ),
        ],
      ),
      
      // Body aplikasi
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header informasi
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                children: [
                  const Text(
                    'Data Todo dari API External',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sumber: jsonplaceholder.typicode.com',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Konten utama
            Expanded(
              child: buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk membangun konten berdasarkan state
  Widget buildContent() {
    // Jika sedang loading, tampilkan loading indicator
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Mengambil data...'),
          ],
        ),
      );
    }

    // Jika ada error, tampilkan pesan error
    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: refreshData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    // Jika data berhasil dimuat, tampilkan list
    return Column(
      children: [
        // Info jumlah data
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Todo: ${todos.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Selesai: ${todos.where((todo) => todo.completed).length}',
                style: const TextStyle(color: Colors.green),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Daftar todo
        Expanded(
          child: RefreshIndicator(
            onRefresh: refreshData,
            child: ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) {
                final todo = todos[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    // Icon berdasarkan status selesai atau tidak
                    leading: Icon(
                      todo.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: todo.completed ? Colors.green : Colors.grey,
                    ),
                    
                    // Judul todo
                    title: Text(
                      todo.title,
                      style: TextStyle(
                        decoration: todo.completed 
                            ? TextDecoration.lineThrough 
                            : TextDecoration.none,
                        color: todo.completed ? Colors.grey : Colors.black,
                      ),
                    ),
                    
                    // Subtitle dengan info ID dan User ID
                    subtitle: Text(
                      'ID: ${todo.id} | User: ${todo.userId}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    
                    // Trailing dengan status
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: todo.completed ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        todo.completed ? 'Selesai' : 'Belum',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}