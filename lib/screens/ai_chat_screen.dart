import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AiChatScreen extends StatefulWidget {
  final String? filePath;
  const AiChatScreen({super.key, this.filePath});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  String? _apiKey;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    // Adding dummy data for now
    _messages.addAll([
      {'role': 'ai', 'text': 'Hello! I am your Smart AI assistant. How can I help you with your PDFs today?'},
      {'role': 'user', 'text': 'Can you summarize a PDF for me?'},
      {'role': 'ai', 'text': 'Yes, I can! Just upload a PDF and ask me anything about it. Currently, I am running in demo mode with dummy data.'},
    ]);
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKey = prefs.getString('gemini_api_key');
    });
  }

  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key);
    setState(() {
      _apiKey = key;
    });
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;

    final userText = _controller.text;
    setState(() {
      _messages.add({'role': 'user', 'text': userText});
      _isLoading = true;
    });
    _controller.clear();

    if (_apiKey == null || _apiKey!.isEmpty) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'ai', 
            'text': 'I see you haven\'t configured your Gemini API key yet. Please go to settings to add it so I can provide real-time assistance.'
          });
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey!);
      final prompt = widget.filePath != null 
          ? "Context: User is reading a PDF file at ${widget.filePath}. Question: $userText"
          : userText;
      
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      if (mounted) {
        setState(() {
          _messages.add({'role': 'ai', 'text': response.text ?? 'No response from AI.'});
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'role': 'error', 'text': 'I encountered an error while processing your request. Please check your internet connection or API key.'});
        });
        debugPrint('AI Chat Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Smart AI Chat', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: _ApiKeyConfigView(onSave: (key) {
                    _saveApiKey(key);
                    Navigator.pop(context);
                  }),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                final isError = msg['role'] == 'error';
                
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isUser 
                          ? colorScheme.primary 
                          : (isError ? colorScheme.error.withOpacity(0.1) : colorScheme.surfaceContainerLow),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      msg['text']!,
                      style: GoogleFonts.plusJakartaSans(
                        color: isUser ? Colors.white : colorScheme.onSurface,
                        fontSize: 15,
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),
                );
              },
            ),
          ),
          if (_isLoading) 
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: colorScheme.secondary),
            ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ask about the PDF...',
                        hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.3)),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send_rounded, color: colorScheme.primary),
                    onPressed: _sendMessage,
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

class _ApiKeyConfigView extends StatefulWidget {
  final Function(String) onSave;
  const _ApiKeyConfigView({required this.onSave});

  @override
  State<_ApiKeyConfigView> createState() => _ApiKeyConfigViewState();
}

class _ApiKeyConfigViewState extends State<_ApiKeyConfigView> {
  final TextEditingController _keyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.security_rounded, size: 64, color: Colors.purpleAccent),
          const SizedBox(height: 24),
          Text(
            'Gemini API Key Required',
            style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'To use the Smart AI feature, please enter your Google Gemini API key.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(color: colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _keyController,
            decoration: InputDecoration(
              filled: true,
              fillColor: colorScheme.surfaceContainerLow,
              hintText: 'Enter API Key...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => widget.onSave(_keyController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Save API Key'),
          ),
        ],
      ),
    );
  }
}
