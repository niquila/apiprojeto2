import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(BookSearchApp());
}

class BookSearchApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Busca de Livros',
      theme: ThemeData(appBarTheme: AppBarTheme(backgroundColor: Color.fromRGBO(255, 0, 174, 1),),),
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
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(
        'https://openlibrary.org/search.json?title=${Uri.encodeComponent(query)}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _books = data['docs'];
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Buscar Livros')),
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
                    subtitle:
                    Text(book['author_name']?.join(', ') ?? 'Autor desconhecido'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookDetailsPage(bookKey: book['key']),
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

class BookDetailsPage extends StatefulWidget {
  final String bookKey;

  BookDetailsPage({required this.bookKey});

  @override
  _BookDetailsPageState createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  Map<String, dynamic>? _bookDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookDetails();
  }

  Future<void> _fetchBookDetails() async {
    final url = Uri.parse('https://openlibrary.org${widget.bookKey}.json');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        _bookDetails = jsonDecode(response.body);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detalhes do Livro'),
      backgroundColor: Color.fromRGBO(255, 0, 174, 1),),
      backgroundColor: Color.fromRGBO(233, 186, 202, 1),),

      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _bookDetails == null
          ? Center(child: Text("Não foi possível carregar os detalhes"))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _bookDetails!['title'] ?? 'Título desconhecido',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Descrição: ${_bookDetails!['description'] ?? 'Sem descrição disponível'}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'Data de publicação: ${_bookDetails!['publish_date'] ?? 'Desconhecida'}',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
