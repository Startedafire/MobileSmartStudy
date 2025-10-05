import 'package:flutter/material.dart';

class QuizGenerationScreen extends StatefulWidget {
  final int noteId;
  final String noteTitle;
  final String storagePath;

  const QuizGenerationScreen({
    super.key,
    required this.noteId,
    required this.noteTitle,
    required this.storagePath,
  });

  @override
  State<QuizGenerationScreen> createState() => _QuizGenerationScreenState();
}

class _QuizGenerationScreenState extends State<QuizGenerationScreen> {
  int numberOfQuestions = 5;
  String questionType = 'MCQ';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Generate Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Note: ${widget.noteTitle}',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text('Number of questions: $numberOfQuestions'),
            Slider(
              value: numberOfQuestions.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              label: '$numberOfQuestions',
              onChanged: (value) {
                setState(() {
                  numberOfQuestions = value.toInt();
                });
              },
            ),
            const SizedBox(height: 20),
            const Text('Question Type'),
            DropdownButton<String>(
              value: questionType,
              items: const [
                DropdownMenuItem(value: 'MCQ', child: Text('Multiple Choice')),
                DropdownMenuItem(value: 'TF', child: Text('True / False')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    questionType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Generating $numberOfQuestions $questionType questions for "${widget.noteTitle}"')),
                  );
                  // TODO: Call quiz generation logic
                },
                child: const Text('Generate Quiz'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
