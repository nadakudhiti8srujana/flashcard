import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

// --- Data Models ---
class Flashcard {
  String id;
  String question;
  String answer;

  Flashcard({required this.id, required this.question, required this.answer});

  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question,
    'answer': answer,
  };

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
    id: json['id'],
    question: json['question'],
    answer: json['answer'],
  );
}

class Deck {
  String id;
  String name;
  List<Flashcard> cards;

  Deck({required this.id, required this.name, required this.cards});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'cards': cards.map((card) => card.toJson()).toList(),
  };

  factory Deck.fromJson(Map<String, dynamic> json) => Deck(
    id: json['id'],
    name: json['name'],
    cards: List<Flashcard>.from(
        json['cards'].map((x) => Flashcard.fromJson(x))),
  );
}

// --- Data Service for Saving/Loading ---
class DataService {
  Future<List<Deck>> _loadDecksFromJson() async {
    final String jsonString =
    await rootBundle.loadString('assets/flashcards.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Deck.fromJson(json)).toList();
  }

  Future<List<Deck>> loadDecks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? decksString = prefs.getString('decks');

    if (decksString != null) {
      final List<dynamic> decksJson = jsonDecode(decksString);
      return decksJson.map((json) => Deck.fromJson(json)).toList();
    } else {
      final defaultDecks = await _loadDecksFromJson();
      await saveDecks(defaultDecks);
      return defaultDecks;
    }
  }

  Future<void> saveDecks(List<Deck> decks) async {
    final prefs = await SharedPreferences.getInstance();
    final String decksString =
    jsonEncode(decks.map((deck) => deck.toJson()).toList());
    await prefs.setString('decks', decksString);
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlashcardApp());
}

class FlashcardApp extends StatelessWidget {
  const FlashcardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flashcard App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: DeckListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- Screen 1: List of all decks ---
class DeckListScreen extends StatefulWidget {
  @override
  _DeckListScreenState createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  List<Deck> _decks = [];
  bool _isLoading = true;
  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    _decks = await _dataService.loadDecks();
    setState(() {
      _isLoading = false;
    });
  }

  void _addDeck() {
    _showDeckDialog(onSave: (name) {
      final newDeck =
      Deck(id: DateTime.now().toString(), name: name, cards: []);
      setState(() {
        _decks.add(newDeck);
      });
      _dataService.saveDecks(_decks);
    });
  }

  void _editDeck(Deck deck) {
    _showDeckDialog(deck: deck, onSave: (name) {
      setState(() {
        deck.name = name;
      });
      _dataService.saveDecks(_decks);
    });
  }

  void _deleteDeck(Deck deck) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Deck?'),
        content: Text('Are you sure you want to delete "${deck.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _decks.remove(deck);
              });
              _dataService.saveDecks(_decks);
              Navigator.pop(context);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeckDialog({Deck? deck, required Function(String) onSave}) {
    final nameController = TextEditingController(text: deck?.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(deck == null ? 'New Deck' : 'Edit Deck'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Deck Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  onSave(nameController.text);
                  Navigator.pop(context);
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Flashcard Decks'),
        centerTitle: true,
        elevation: 2,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _decks.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.layers_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No decks yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Tap + to create your first deck'),
          ],
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _decks.length,
        itemBuilder: (context, index) {
          final deck = _decks[index];
          return Card(
            margin: EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.layers, color: Colors.indigo),
              ),
              title: Text(deck.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text('${deck.cards.length} cards'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      icon: Icon(Icons.edit, color: Colors.grey),
                      onPressed: () => _editDeck(deck)),
                  IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteDeck(deck)),
                ],
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CardListScreen(deck: deck)),
                );
                _loadData();
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDeck,
        icon: Icon(Icons.add),
        label: Text('New Deck'),
      ),
    );
  }
}

// --- Screen 2: List of cards in a deck ---
class CardListScreen extends StatefulWidget {
  final Deck deck;
  CardListScreen({required this.deck});

  @override
  _CardListScreenState createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> {
  final DataService _dataService = DataService();

  Future<void> _saveChanges() async {
    List<Deck> decks = await _dataService.loadDecks();
    int deckIndex = decks.indexWhere((d) => d.id == widget.deck.id);
    if (deckIndex != -1) {
      decks[deckIndex] = widget.deck;
      await _dataService.saveDecks(decks);
    }
  }

  void _addCard() {
    _showCardDialog(onSave: (question, answer) {
      final newCard = Flashcard(
          id: DateTime.now().toString(), question: question, answer: answer);
      setState(() {
        widget.deck.cards.add(newCard);
      });
      _saveChanges();
    });
  }

  void _editCard(Flashcard card) {
    _showCardDialog(card: card, onSave: (question, answer) {
      setState(() {
        card.question = question;
        card.answer = answer;
      });
      _saveChanges();
    });
  }

  void _deleteCard(Flashcard card) {
    setState(() {
      widget.deck.cards.remove(card);
    });
    _saveChanges();
  }

  void _showCardDialog({Flashcard? card, required Function(String, String) onSave}) {
    final questionController = TextEditingController(text: card?.question);
    final answerController = TextEditingController(text: card?.answer);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(card == null ? 'New Card' : 'Edit Card'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: questionController,
                  decoration: InputDecoration(
                    labelText: 'Question',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 2),
              SizedBox(height: 12),
              TextField(
                  controller: answerController,
                  decoration: InputDecoration(
                    labelText: 'Answer',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 2),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (questionController.text.isNotEmpty &&
                    answerController.text.isNotEmpty) {
                  onSave(questionController.text, answerController.text);
                  Navigator.pop(context);
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.name),
        actions: [
          if (widget.deck.cards.isNotEmpty)
            IconButton(
              icon: Icon(Icons.play_circle_filled, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => QuizScreen(deck: widget.deck)),
                );
              },
              tooltip: 'Start Quiz',
            ),
        ],
      ),
      body: widget.deck.cards.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.style_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No cards yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Tap + to add your first card'),
          ],
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: widget.deck.cards.length,
        itemBuilder: (context, index) {
          final card = widget.deck.cards[index];
          return Card(
            margin: EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Q', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ),
                      SizedBox(width: 8),
                      Expanded(child: Text(card.question, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('A', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ),
                      SizedBox(width: 8),
                      Expanded(child: Text(card.answer, style: TextStyle(color: Colors.grey.shade700))),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                          icon: Icon(Icons.edit, size: 20),
                          onPressed: () => _editCard(card)),
                      IconButton(
                          icon: Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () => _deleteCard(card)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCard,
        icon: Icon(Icons.add),
        label: Text('Add Card'),
      ),
    );
  }
}

// --- Screen 3: The Quiz View ---
class QuizScreen extends StatefulWidget {
  final Deck deck;
  QuizScreen({required this.deck});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  bool _showAnswer = false;
  late List<Flashcard> _shuffledCards;

  @override
  void initState() {
    super.initState();
    _shuffledCards = List.from(widget.deck.cards)..shuffle(Random());
  }

  void _nextCard() {
    setState(() {
      if (_currentIndex < _shuffledCards.length - 1) {
        _currentIndex++;
        _showAnswer = false;
      } else {
        _showQuizCompleteDialog();
      }
    });
  }

  void _previousCard() {
    setState(() {
      if (_currentIndex > 0) {
        _currentIndex--;
        _showAnswer = false;
      }
    });
  }

  void _showQuizCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(Icons.celebration, size: 60, color: Colors.amber),
            SizedBox(height: 8),
            Text('Quiz Complete!'),
          ],
        ),
        content: Text('You finished all ${_shuffledCards.length} cards!', textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Finish'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _shuffledCards.shuffle(Random());
                _currentIndex = 0;
                _showAnswer = false;
              });
            },
            child: Text('Restart'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_shuffledCards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Quiz Mode')),
        body: Center(child: Text('No cards to quiz!')),
      );
    }

    final card = _shuffledCards[_currentIndex];
    final progress = (_currentIndex + 1) / _shuffledCards.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Mode'),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Card ${_currentIndex + 1} of ${_shuffledCards.length}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text('${(progress * 100).toInt()}%',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  ],
                ),
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      color: _showAnswer ? Colors.green.shade400 : Colors.indigo,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _showAnswer ? 'ANSWER' : 'QUESTION',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            SizedBox(height: 24),
                            Text(
                              _showAnswer ? card.answer : card.question,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      setState(() {
                        _showAnswer = !_showAnswer;
                      });
                    },
                    child: Text(
                      _showAnswer ? 'Hide Answer' : 'Show Answer',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size(0, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _currentIndex > 0 ? _previousCard : null,
                          child: Text('Previous'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: Size(0, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _nextCard,
                          child: Text(_currentIndex < _shuffledCards.length - 1 ? 'Next' : 'Finish'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}