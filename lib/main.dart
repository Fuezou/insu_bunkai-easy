import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '因数分解クイズ',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const QuizPage(),
    );
  }
}

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int currentIndex = 0;
  List<Problem> problems = [];
  List<Result> results = [];
  bool isAnswered = false;
  int? selectedChoice;
  DateTime? startTime;
  Duration totalTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    generateInitialProblems();
    startTime = DateTime.now();
  }

  void generateInitialProblems() {
    problems = [];
    for (int i = 0; i < 5; i++) {
      problems.add(generateProblem(i));
    }
    problems.shuffle();
  }

  Problem generateProblem(int pattern) {
    final random = Random();
    String expr = '';
    String answer = '';
    
    switch (pattern) {
      case 0: // x² ± bx
        int b = random.nextInt(10) + 1;
        bool isPlus = random.nextBool();
        if (isPlus) {
          expr = b == 1 ? 'x^2 + x' : 'x^2 + ${b}x';
          answer = 'x(x + $b)';
        } else {
          expr = b == 1 ? 'x^2 - x' : 'x^2 - ${b}x';
          answer = 'x(x - $b)';
        }
        break;
        
      case 1: // (x ± a)² 完全平方式
        int a = random.nextInt(5) + 1;
        bool isPlus = random.nextBool();
        if (isPlus) {
          int b = 2 * a;
          int c = a * a;
          expr = 'x^2 + ${b}x + $c';
          answer = '(x + $a)^2';
        } else {
          int b = 2 * a;
          int c = a * a;
          expr = 'x^2 - ${b}x + $c';
          answer = '(x - $a)^2';
        }
        break;
        
      case 2: // ax² ± bx
        int coef = random.nextInt(4) + 2;
        int root = random.nextInt(5) + 1;
        bool isPlus = random.nextBool();
        if (isPlus) {
          expr = '${coef}x^2 + ${coef * root}x';
          answer = '${coef}x(x + $root)';
        } else {
          expr = '${coef}x^2 - ${coef * root}x';
          answer = '${coef}x(x - $root)';
        }
        break;
        
      case 3: // (x - α)(x - β) = x² - (α+β)x + αβ
        int r1 = random.nextInt(5) + 1;
        int r2 = random.nextInt(5) + 1;
        // r1とr2が同じにならないようにする
        while (r2 == r1) {
          r2 = random.nextInt(5) + 1;
        }
        int b = r1 + r2;
        int c = r1 * r2;
        
        if (b == 1) {
          expr = 'x^2 - x + $c';
        } else {
          expr = 'x^2 - ${b}x + $c';
        }
        answer = '(x - $r1)(x - $r2)';
        break;
        
      case 4: // 平方の差 x² - a²
        int a = random.nextInt(10) + 1;
        int c = a * a;
        expr = 'x^2 - $c';
        answer = '(x + $a)(x - $a)';
        break;
    }
    
    List<String> choices = [answer];
    while (choices.length < 4) {
      String wrong = generateWrongAnswer(answer, pattern, random);
      if (!choices.contains(wrong)) {
        choices.add(wrong);
      }
    }
    // 全ての選択肢で1xの表記を修正
    for (int i = 0; i < choices.length; i++) {
      choices[i] = choices[i].replaceAll(RegExp(r'\b1x'), 'x');
      choices[i] = choices[i].replaceAll(RegExp(r'\(1x'), '(x');
    }
    
    choices.shuffle();
    
    return Problem(
      expression: expr,
      correctAnswer: answer,
      choices: choices,
      pattern: pattern,
    );
  }

  String generateWrongAnswer(String correct, int pattern, Random random) {
    int type = random.nextInt(4);
    String wrong = correct;
    
    switch (type) {
      case 0: // 符号ミス
        if (correct.contains('+')) {
          wrong = correct.replaceFirst('+', '-');
        } else if (correct.contains('-')) {
          wrong = correct.replaceFirst('-', '+');
        }
        break;
        
      case 1: // 係数忘れ
        if (RegExp(r'^\d+').hasMatch(correct)) {
          wrong = correct.replaceFirst(RegExp(r'^\d+'), '');
        } else {
          wrong = '2$correct';
        }
        break;
        
      case 2: // 指数忘れ
        if (correct.contains('^2')) {
          wrong = correct.replaceAll('^2', '');
        }
        break;
        
      case 3: // 数値を変える
        int newNum = random.nextInt(10) + 1;
        if (correct.contains(RegExp(r'\d+'))) {
          var match = RegExp(r'\d+').firstMatch(correct);
          if (match != null) {
            wrong = correct.substring(0, match.start) + 
                   newNum.toString() + 
                   correct.substring(match.end);
          }
        }
        break;
    }
    
    // 1xの表記を修正（係数1は省略）
    wrong = wrong.replaceAll(RegExp(r'\b1x'), 'x');
    wrong = wrong.replaceAll(RegExp(r'\(1x'), '(x');
    
    return wrong;
  }

  void selectAnswer(int index) {
    if (isAnswered) return;
    
    setState(() {
      isAnswered = true;
      selectedChoice = index;
      
      bool isCorrect = problems[currentIndex].choices[index] == 
                       problems[currentIndex].correctAnswer;
      
      results.add(Result(
        question: problems[currentIndex].expression,
        correct: problems[currentIndex].correctAnswer,
        userAnswer: problems[currentIndex].choices[index],
        isCorrect: isCorrect,
      ));
      
      if (!isCorrect && problems.length < 10) {
        problems.add(generateProblem(problems[currentIndex].pattern));
      }
      
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (currentIndex < problems.length - 1) {
          setState(() {
            currentIndex++;
            isAnswered = false;
            selectedChoice = null;
          });
        } else {
          totalTime = DateTime.now().difference(startTime!);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ResultPage(
                results: results,
                totalTime: totalTime,
              ),
            ),
          );
        }
      });
    });
  }

  Color getButtonColor(int index) {
    if (!isAnswered) {
      return Theme.of(context).colorScheme.primaryContainer;
    }
    
    bool isCorrectAnswer = problems[currentIndex].choices[index] == 
                          problems[currentIndex].correctAnswer;
    
    if (isCorrectAnswer) {
      return Colors.green.shade300;
    } else if (selectedChoice == index) {
      return Colors.red.shade300;
    }
    return Colors.grey.shade300;
  }

  @override
  Widget build(BuildContext context) {
    if (problems.isEmpty) return const Scaffold();
    
    final problem = problems[currentIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('因数分解クイズ'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (currentIndex + 1) / problems.length,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              '問題 ${currentIndex + 1} / ${problems.length}',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 30),
            
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Math.tex(
                problem.expression,
                textStyle: const TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(height: 40),
            
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 4.0,
                children: List.generate(4, (index) {
                  return Material(
                    color: getButtonColor(index),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => selectAnswer(index),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Center(
                          child: Math.tex(
                            problem.choices[index],
                            textStyle: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            if (isAnswered)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: results.last.isCorrect 
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  results.last.isCorrect ? '正解！' : '不正解',
                  style: TextStyle(
                    fontSize: 20,
                    color: results.last.isCorrect ? Colors.green : Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ResultPage extends StatelessWidget {
  final List<Result> results;
  final Duration totalTime;
  
  const ResultPage({
    super.key, 
    required this.results,
    required this.totalTime,
  });
  
  @override
  Widget build(BuildContext context) {
    int correctCount = results.where((r) => r.isCorrect).length;
    int percentage = (correctCount / results.length * 100).round();
    String timeString = '${totalTime.inMinutes}分${totalTime.inSeconds % 60}秒';
    
    return Scaffold(
      appBar: AppBar(title: const Text('結果')),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.blue.shade100,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('$correctCount / ${results.length}', 
                        style: const TextStyle(fontSize: 24)),
                      Text('正答率: $percentage%',
                        style: const TextStyle(fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('解答時間: $timeString',
                    style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final result = results[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    padding: const EdgeInsets.all(4),
                    color: result.isCorrect 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                    child: Row(
                      children: [
                        Text('${index + 1}. '),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Math.tex(result.question,
                                  textStyle: const TextStyle(fontSize: 10)),
                              ),
                              const Text(' = '),
                              Flexible(
                                child: Math.tex(result.correct,
                                  textStyle: const TextStyle(fontSize: 10)),
                              ),
                              Text(result.isCorrect ? ' ◯' : ' ✕'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const QuizPage()),
                );
              },
              child: const Text('もう一度'),
            ),
          ],
        ),
      ),
    );
  }
}

class Problem {
  final String expression;
  final String correctAnswer;
  final List<String> choices;
  final int pattern;
  
  Problem({
    required this.expression,
    required this.correctAnswer,
    required this.choices,
    required this.pattern,
  });
}

class Result {
  final String question;
  final String correct;
  final String userAnswer;
  final bool isCorrect;
  
  Result({
    required this.question,
    required this.correct,
    required this.userAnswer,
    required this.isCorrect,
  });
}