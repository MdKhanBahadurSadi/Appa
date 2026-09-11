import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:flip_card/flip_card.dart';
import '../models/ai_study_models.dart';
import '../services/pdf_ai_service.dart';

class AiStudyScreen extends StatefulWidget {
  final String filePath;
  final String fileName;
  final String apiKey;
  final String mode; // 'quiz' or 'flashcards'

  const AiStudyScreen({
    super.key,
    required this.filePath,
    required this.fileName,
    required this.apiKey,
    required this.mode,
  });

  @override
  State<AiStudyScreen> createState() => _AiStudyScreenState();
}

class _AiStudyScreenState extends State<AiStudyScreen> with SingleTickerProviderStateMixin {
  late PdfAiService _aiService;
  List<QuizQuestion> _questions = [];
  List<Flashcard> _flashcards = [];
  bool _isLoading = true;
  String? _error;
  
  // Quiz State
  int _currentQuestionIndex = 0;
  int _score = 0;
  int? _selectedOption;
  bool _isAnswered = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _aiService = PdfAiService(apiKey: widget.apiKey);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final text = await _aiService.extractTextFromPdf(widget.filePath);
      if (widget.mode == 'quiz') {
        final questions = await _aiService.generateQuiz(text);
        setState(() {
          _questions = questions;
          _isLoading = false;
        });
      } else {
        final flashcards = await _aiService.generateFlashcards(text);
        setState(() {
          _flashcards = flashcards;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _handleOptionTap(int index) {
    if (_isAnswered) return;
    setState(() {
      _selectedOption = index;
      _isAnswered = true;
      if (index == _questions[_currentQuestionIndex].correctOptionIndex) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOption = null;
        _isAnswered = false;
      });
    } else {
      _showResults();
    }
  }

  void _showResults() {
    if (_score >= 3) _confettiController.play();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Quiz Completed!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your Score: $_score / ${_questions.length}', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            Text(_score >= 3 ? 'Great job!' : 'Keep studying!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == 'quiz' ? 'AI Quiz' : 'AI Flashcards', 
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          if (_isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Generating ${widget.mode}...', style: GoogleFonts.plusJakartaSans()),
                ],
              ),
            )
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: colorScheme.error)),
              ),
            )
          else if (widget.mode == 'quiz')
            _buildQuizView()
          else
            _buildFlashcardView(),
          
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizView() {
    final question = _questions[_currentQuestionIndex];
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 24),
          Text('Question ${_currentQuestionIndex + 1} of ${_questions.length}', 
            style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text(question.question, 
            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: question.options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                Color bgColor = colorScheme.surfaceContainerLow;
                Color borderColor = Colors.transparent;
                IconData? icon;

                if (_isAnswered) {
                  if (index == question.correctOptionIndex) {
                    bgColor = Colors.green.withValues(alpha: 0.1);
                    borderColor = Colors.green;
                    icon = Icons.check_circle_rounded;
                  } else if (index == _selectedOption) {
                    bgColor = Colors.red.withValues(alpha: 0.1);
                    borderColor = Colors.red;
                    icon = Icons.cancel_rounded;
                  }
                } else if (_selectedOption == index) {
                  borderColor = colorScheme.primary;
                }

                return GestureDetector(
                  onTap: () => _handleOptionTap(index),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Row(
                      children: [
                        Text('${String.fromCharCode(65 + index)}.', 
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(question.options[index])),
                        if (icon != null) Icon(icon, color: borderColor),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isAnswered) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(question.explanation, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(_currentQuestionIndex == _questions.length - 1 ? 'Finish' : 'Next Question'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFlashcardView() {
    return PageView.builder(
      itemCount: _flashcards.length,
      itemBuilder: (context, index) {
        final card = _flashcards[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 80.0),
          child: FlipCard(
            front: _buildCardSide(card.front, 'Question', Colors.blue.withValues(alpha: 0.1)),
            back: _buildCardSide(card.back, 'Answer', Colors.green.withValues(alpha: 0.1)),
          ),
        );
      },
    );
  }

  Widget _buildCardSide(String text, String label, Color color) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: color,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label.toUpperCase(), style: GoogleFonts.plusJakartaSans(
              fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey)),
            const SizedBox(height: 24),
            Text(text, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(
              fontSize: 20, fontWeight: FontWeight.w600)),
            const Spacer(),
            const Text('Tap to Flip', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
