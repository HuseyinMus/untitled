import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:untitled/core/srs/srs.dart';
import 'package:untitled/data/models/word.dart';
import 'package:untitled/data/repositories/firebase_repository.dart';
import 'package:untitled/data/repositories/repository.dart';
import 'package:untitled/data/repositories/stats_repository.dart';

enum TutorStep { meaning, writing, pronunciation, sentence }

class TutorSessionScreen extends StatefulWidget {
  final Repository repository;
  final List<WordItem> initialQueue;
  const TutorSessionScreen({super.key, required this.repository, required this.initialQueue});

  @override
  State<TutorSessionScreen> createState() => _TutorSessionScreenState();
}

class _TutorSessionScreenState extends State<TutorSessionScreen> {
  late List<WordItem> queue;
  int currentIndex = 0;
  TutorStep step = TutorStep.meaning;
  int stepScore = 0; // 0..4 arası her kelime için skor

  // Step controllers/state
  List<String> meaningOptions = const <String>[];
  int? selectedMeaningIndex;
  int? correctMeaningIndex;

  final TextEditingController writingController = TextEditingController();
  String? writingError;

  bool pronunciationDone = false;
  late final FlutterTts tts;

  final TextEditingController sentenceController = TextEditingController();
  String? sentenceError;

  late final int initialTotal;

  @override
  void initState() {
    super.initState();
    queue = List<WordItem>.from(widget.initialQueue);
    initialTotal = queue.length;
    tts = FlutterTts();
    _initForCurrentWord();
  }

  Future<void> _initForCurrentWord() async {
    step = TutorStep.meaning;
    stepScore = 0;
    selectedMeaningIndex = null;
    correctMeaningIndex = null;
    writingController.clear();
    writingError = null;
    pronunciationDone = false;
    sentenceController.clear();
    sentenceError = null;
    await _prepareMeaningStep();
    setState(() {});
  }

  Future<void> _prepareMeaningStep() async {
    if (queue.isEmpty) return;
    final WordItem current = queue[currentIndex];
    // 4 şıklı TR anlam seçenekleri hazırla
    final List<String> pool = widget.repository.catalog.map((w) => w.turkish).toSet().toList();
    pool.remove(current.turkish);
    pool.shuffle();
    final List<String> opts = <String>[current.turkish];
    for (int i = 0; i < 3 && i < pool.length; i++) {
      opts.add(pool[i]);
    }
    opts.shuffle();
    meaningOptions = opts;
    correctMeaningIndex = opts.indexOf(current.turkish);
  }

  void _onMeaningSelected(int index) {
    selectedMeaningIndex = index;
    final bool correct = index == correctMeaningIndex;
    if (correct) {
      stepScore += 1;
    }
    setState(() {});
  }

  void _checkWriting() {
    writingError = null;
    if (queue.isEmpty) return;
    final String typed = writingController.text.trim();
    final String expected = queue[currentIndex].english.trim();
    if (typed.isEmpty) {
      writingError = 'Kelimeyi yazın';
    } else if (!_equalsIgnoreCase(typed, expected)) {
      writingError = 'Hatalı. Tekrar deneyin.';
    } else {
      stepScore += 1;
    }
    setState(() {});
  }

  bool _equalsIgnoreCase(String a, String b) => a.toLowerCase() == b.toLowerCase();

  Future<void> _playTts(String text, {String? lang}) async {
    try {
      if (lang != null) {
        await tts.setLanguage(lang);
      }
      await tts.setSpeechRate(0.45);
      await tts.setPitch(1.0);
      await tts.speak(text);
    } catch (_) {}
  }

  void _checkSentence() {
    sentenceError = null;
    if (queue.isEmpty) return;
    final WordItem w = queue[currentIndex];
    final String s = sentenceController.text.trim();
    if (s.length < 8) {
      sentenceError = 'Biraz daha uzun bir cümle yazın.';
    } else if (!s.toLowerCase().contains(w.english.toLowerCase())) {
      sentenceError = 'Cümlede hedef kelimeyi kullanın: ${w.english}';
    } else {
      stepScore += 1;
    }
    setState(() {});
  }

  Future<void> _nextStepOrWord() async {
    // Sonraki adıma geç veya kelimeyi bitir
    HapticFeedback.selectionClick();
    if (step == TutorStep.meaning) {
      step = TutorStep.writing;
    } else if (step == TutorStep.writing) {
      step = TutorStep.pronunciation;
    } else if (step == TutorStep.pronunciation) {
      step = TutorStep.sentence;
    } else {
      // Kelime tamamlandı → SRS derecelendirmesi uygula
      await _finishCurrentWord();
      return;
    }
    setState(() {});
  }

  Future<void> _finishCurrentWord() async {
    if (queue.isEmpty) return;
    final WordItem current = queue[currentIndex];
    final ReviewGrade grade = _gradeFromScore(stepScore);
    try {
      if (widget.repository is FirebaseRepository) {
        await (widget.repository as FirebaseRepository).applyReviewAsync(current.id, grade);
      } else {
        widget.repository.applyReview(current.id, grade);
      }
    } catch (_) {}
    await StatsRepository.recordStudyReview(isCorrect: grade != ReviewGrade.again);
    // Sonraki kelimeye geç
    if (currentIndex + 1 >= queue.length) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    currentIndex += 1;
    await _initForCurrentWord();
  }

  ReviewGrade _gradeFromScore(int score) {
    // 0–1: again, 2: hard, 3: good, 4: easy
    if (score <= 1) return ReviewGrade.again;
    if (score == 2) return ReviewGrade.hard;
    if (score == 3) return ReviewGrade.good;
    return ReviewGrade.easy;
  }

  @override
  void dispose() {
    try { tts.stop(); } catch (_) {}
    writingController.dispose();
    sentenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool finished = queue.isEmpty;
    final WordItem? w = finished ? null : queue[currentIndex];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eğitmen (4 Adım)'),
      ),
      body: finished
          ? const Center(child: Text('Tebrikler!'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${currentIndex + 1}/${initialTotal}'),
                      Text(_stepLabel(step)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: initialTotal == 0 ? 0 : (currentIndex) / initialTotal,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (w != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(w.english, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                            const SizedBox(height: 6),
                            Text(w.turkish, textAlign: TextAlign.center),
                            const SizedBox(height: 6),
                            Text('${w.partOfSpeech}${w.level == null ? '' : ' • ${w.level}'}', textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(child: _buildStepContent(w)),
                  ]
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    // kullanıcı adımı atlamak isterse: puan eklemeden devam
                    await _nextStepOrWord();
                  },
                  child: Text(step == TutorStep.sentence ? 'Bitir' : 'Atla'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    if (step == TutorStep.meaning) {
                      if (selectedMeaningIndex == null) return;
                      await _nextStepOrWord();
                    } else if (step == TutorStep.writing) {
                      _checkWriting();
                      await _nextStepOrWord();
                    } else if (step == TutorStep.pronunciation) {
                      if (!pronunciationDone) {
                        // Kullanıcı teyidi
                        pronunciationDone = true;
                        stepScore += 1;
                      }
                      await _nextStepOrWord();
                    } else {
                      _checkSentence();
                      await _nextStepOrWord();
                    }
                  },
                  child: Text(step == TutorStep.sentence ? 'Kaydet' : 'Devam'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _stepLabel(TutorStep s) => switch (s) {
        TutorStep.meaning => '1/4 Anlam',
        TutorStep.writing => '2/4 Yazma',
        TutorStep.pronunciation => '3/4 Telaffuz',
        TutorStep.sentence => '4/4 Cümle',
      };

  Widget _buildStepContent(WordItem w) {
    switch (step) {
      case TutorStep.meaning:
        return _buildMeaningStep(w);
      case TutorStep.writing:
        return _buildWritingStep(w);
      case TutorStep.pronunciation:
        return _buildPronunciationStep(w);
      case TutorStep.sentence:
        return _buildSentenceStep(w);
    }
  }

  Widget _buildMeaningStep(WordItem w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Doğru anlamı seçin:'),
        const SizedBox(height: 8),
        ...List.generate(meaningOptions.length, (i) {
          final String opt = meaningOptions[i];
          final bool isSelected = selectedMeaningIndex == i;
          final bool isCorrect = correctMeaningIndex == i;
          Color? color;
          if (selectedMeaningIndex != null) {
            if (isCorrect) color = Colors.green.withOpacity(0.15);
            if (isSelected && !isCorrect) color = Colors.red.withOpacity(0.15);
          }
          return Card(
            color: color,
            child: ListTile(
              title: Text(opt),
              onTap: selectedMeaningIndex == null ? () => setState(() => _onMeaningSelected(i)) : null,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWritingStep(WordItem w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Türkçe: ${w.turkish}'),
        const SizedBox(height: 8),
        TextField(
          controller: writingController,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'İngilizce kelimeyi yazın',
            errorText: writingError,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            _checkWriting();
          },
        ),
      ],
    );
  }

  Widget _buildPronunciationStep(WordItem w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Telaffuz çalışması:'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => _playTts(w.english, lang: 'en-US'),
              icon: const Icon(Icons.volume_up),
              label: const Text('Dinle (EN)'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                pronunciationDone = true;
                setState(() {});
              },
              icon: Icon(pronunciationDone ? Icons.check_circle : Icons.mic),
              label: Text(pronunciationDone ? 'Tamamlandı' : 'Tekrar ettim'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Not: Otomatik telaffuz değerlendirmesi için konuşma tanıma ekleyebiliriz (istersen kurulum yapayım).'),
      ],
    );
  }

  Widget _buildSentenceStep(WordItem w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Hedef: ${w.english} kelimesiyle İngilizce bir cümle yazın.'),
        const SizedBox(height: 8),
        TextField(
          controller: sentenceController,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Cümle',
            hintText: 'Örn: I had to ${"${w.english}"} my plan due to the weather.',
            errorText: sentenceError,
            border: const OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            _checkSentence();
          },
        ),
      ],
    );
  }
}


