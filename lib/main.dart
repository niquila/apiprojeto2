import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(BookSearchApp());
}

class BookSearchApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Busca de Livros',
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: Color.fromRGBO(255, 0, 174, 1),
        ),
      ),
      home: BookSearchPage(),
    );
  }
}

class BookSearchPage extends StatefulWidget {
  @override
  _BookSearchPageState createState() => _BookSearchPageState();
}

class _BookSearchPageState extends State<BookSearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _books = [];
  bool _isLoading = false;

  Future<void> _searchBooks(String query) async {
    setState(() => _isLoading = true);

    final url = Uri.parse('https://openlibrary.org/search.json?title=${Uri.encodeComponent(query)}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() => _books = data['docs'] ?? []);
    } else {
      setState(() => _books = []);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buscar Livros'),
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ReadingListPage()),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Digite o nome do livro',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _searchBooks(_controller.text);
                    }
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : Expanded(
              child: ListView.builder(
                itemCount: _books.length,
                itemBuilder: (context, index) {
                  final book = _books[index];
                  return ListTile(
                    title: Text(book['title'] ?? 'Título desconhecido'),
                    subtitle: Text(book['author_name']?.join(', ') ?? 'Autor desconhecido'),
                    trailing: IconButton(
                      icon: Icon(Icons.bookmark_add),
                      onPressed: () async {
                        await DatabaseHelper.instance.insertBook(book['title']);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Livro salvo na lista de leitura!'),
                        ));
                      },
                    ),
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

class ReadingListPage extends StatefulWidget {
  @override
  _ReadingListPageState createState() => _ReadingListPageState();
}

class _ReadingListPageState extends State<ReadingListPage> {
  List<Map<String, dynamic>> _readingList = [];

  @override
  void initState() {
    super.initState();
    _loadReadingList();
  }

  Future<void> _loadReadingList() async {
    _readingList = await DatabaseHelper.instance.getBooks();
    setState(() {});
  }

  Future<void> _editBookTitle(int id, String newTitle) async {
    await DatabaseHelper.instance.updateBook(id, newTitle);
    _loadReadingList();
  }

  Future<void> _deleteBook(int id) async {
    await DatabaseHelper.instance.deleteBook(id);
    _loadReadingList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lista de Leitura')),
      body: ListView.builder(
        itemCount: _readingList.length,
        itemBuilder: (context, index) {
          final book = _readingList[index];
          return ListTile(
            title: Text(book['title']),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    TextEditingController controller = TextEditingController(text: book['title']);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Editar título'),
                        content: TextField(controller: controller),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              _editBookTitle(book['id'], controller.text);
                              Navigator.pop(context);
                            },
                            child: Text('Salvar'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteBook(book['id']),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'books.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE books (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertBook(String title) async {
    final db = await instance.database;
    await db.insert('books', {'title': title});
  }

  Future<List<Map<String, dynamic>>> getBooks() async {
    final db = await instance.database;
    return await db.query('books');
  }

  Future<void> updateBook(int id, String title) async {
    final db = await instance.database;
    await db.update('books', {'title': title}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteBook(int id) async {
    final db = await instance.database;
    await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }
}
