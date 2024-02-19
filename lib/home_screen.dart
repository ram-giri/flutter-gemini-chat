import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  final _inputController = TextEditingController();
  late final ChatSession _session;
  final GenerativeModel _model =
      GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
  bool _loading = false;
  final ScrollController _scrollController = ScrollController();

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(
          milliseconds: 750,
        ),
        curve: Curves.easeOutCirc,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _session = _model.startChat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat With Gemini Pro'),
        centerTitle: true,
      ),
      body: Column(children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            children: [
              ..._session.history.map(
                (content) {
                  var text = content.parts
                      .whereType<TextPart>()
                      .map<String>((e) => e.text)
                      .join('');
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        content.role == 'user' ? 'User:' : 'Gemini:',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      MarkdownBody(data: text),
                      const Divider(),
                      const SizedBox(height: 10.0),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(
                        color: Colors.grey,
                      ),
                    ),
                    hintText: 'Enter your prompt',
                  ),
                  onEditingComplete: () {
                    if (!_loading) {
                      _sendMessage();
                    }
                  },
                ),
              ),
              _loading
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    )
                  : IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send),
                    ),
            ],
          ),
        )
      ]),
    );
  }

  _sendMessage() async {
    setState(() {
      _loading = true;
    });
    try {
      final response =
          await _session.sendMessage(Content.text(_inputController.text));

      if (response.text == null) {
        _showError('No response from API');
      } else {
        setState(() {
          _loading = false;
          _scrollDown();
        });
      }
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _loading = false;
      });
    } finally {
      _inputController.clear();
      setState(() {
        _loading = false;
      });
    }
  }

  _showError(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
