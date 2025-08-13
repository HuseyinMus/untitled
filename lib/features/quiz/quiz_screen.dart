import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:untitled/data/models/word.dart';
import 'package:untitled/data/repositories/repository.dart';
import 'package:untitled/data/repositories/firebase_repository.dart';
import 'package:untitled/core/srs/srs.dart';
import 'package:untitled/data/repositories/stats_repository.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:untitled/ads/ads_service.dart';

enum QuizMode { multipleChoice, writing }

class QuizScreen extends StatefulWidget {
  final Repository repository;
  final String? selectedCategory;
  final String? selectedLevel;
  const QuizScreen({super.key, required this.repository, this.selectedCategory, this.selectedLevel});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<WordItem> pool;
  int index = 0;
  int score = 0;
  List<WordItem> options = [];
  WordItem? correct;
  QuizMode mode = QuizMode.multipleChoice;
  final TextEditingController answerController = TextEditingController();
  InterstitialAd? _interstitial;
  int _answersSinceAd = 0;
  int _adsShown = 0;

  @override
  void initState() {
    super.initState();
    // Seçili kategori/level varsa filtrele
    pool = widget.repository.catalog.where((w) {
      if (widget.selectedCategory != null && !w.categories.contains(widget.selectedCategory)) return false;
      if (widget.selectedLevel != null && (w.level ?? '') != widget.selectedLevel) return false;
      return true;
    }).toList(growable: true);
    pool.shuffle();
    _next(allowDialog: false);
    _loadInterstitial();
  }

  void _next({bool allowDialog = true}) {
    if (pool.isEmpty) {
      setState(() {});
      return;
    }
    if (index >= pool.length) {
      if (allowDialog) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Quiz bitti'),
              content: Text('Puan: $score'),
              actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Kapat'))],
            ),
          );
        });
      }
      index = 0; score = 0; pool.shuffle();
    }
    correct = pool[index++];
    final rnd = Random();
    final set = <WordItem>{correct!};
    while (set.length < 4 && set.length < pool.length) {
      set.add(pool[rnd.nextInt(pool.length)]);
    }
    options = set.toList()..shuffle();
    answerController.clear();
    setState(() {});
  }

  Future<void> _loadInterstitial() async {
    await AdsService.init();
    InterstitialAd.load(
      adUnitId: AdsService.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) async {
              try {
                await FirebaseAnalytics.instance.logEvent(name: 'ad_shown', parameters: {'type': 'interstitial'});
              } catch (_) {}
            },
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitial = null;
              _loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, err) async {
              try {
                await FirebaseAnalytics.instance.logEvent(name: 'ad_failed_to_show', parameters: {'type': 'interstitial', 'code': err.code});
              } catch (_) {}
              ad.dispose();
              _interstitial = null;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  void _maybeShowAd({required bool onlyOnCorrect, required bool isCorrect}) {
    // Sadece doğru cevaplarda tetiklemek istiyorsak ve yanlışsa çık
    if (onlyOnCorrect && !isCorrect) return;
    _answersSinceAd += 1;
    final canShow = _interstitial != null && _adsShown < 8 && _answersSinceAd >= 3;
    if (canShow) {
      _answersSinceAd = 0;
      _adsShown += 1;
      _interstitial!.show();
      _interstitial = null;
      _loadInterstitial();
    }
  }

  Future<void> _answer(WordItem selected) async {
    if (correct == null) return;
    final isCorrect = selected.id == correct!.id;
    if (isCorrect) {
      score += 10;
      // Çoktan seçmeli doğru cevap için "good" yerine kolay sorularda "easy"e terfi ettirelim
      final ReviewGrade grade = pool.length <= 4 ? ReviewGrade.easy : ReviewGrade.good;
      if (widget.repository is FirebaseRepository) {
        await (widget.repository as FirebaseRepository).applyReviewAsync(correct!.id, grade);
      } else {
        widget.repository.applyReview(correct!.id, grade);
      }
    } else {
      // Yanlış cevapta "again" olarak işaretleyelim
      if (widget.repository is FirebaseRepository) {
        await (widget.repository as FirebaseRepository).applyReviewAsync(correct!.id, ReviewGrade.again);
      } else {
        widget.repository.applyReview(correct!.id, ReviewGrade.again);
      }
    }
    await StatsRepository.recordQuizAnswer(isCorrect: isCorrect);
    try {
      await FirebaseAnalytics.instance.logEvent(name: 'quiz_answer', parameters: {
        'mode': 'multiple_choice',
        'correct': isCorrect,
      });
    } catch (_) {}
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isCorrect ? 'Doğru! +10' : 'Yanlış')));
    _maybeShowAd(onlyOnCorrect: true, isCorrect: isCorrect);
    _next();
  }

  Future<void> _submitWriting() async {
    if (correct == null) return;
    final typed = answerController.text.trim().toLowerCase();
    final expected = correct!.turkish.trim().toLowerCase();
    final isCorrect = typed == expected;
    if (isCorrect) {
      score += 12;
      if (widget.repository is FirebaseRepository) {
        await (widget.repository as FirebaseRepository).applyReviewAsync(correct!.id, ReviewGrade.good);
      } else {
        widget.repository.applyReview(correct!.id, ReviewGrade.good);
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isCorrect ? 'Doğru! +12' : 'Yanıt: $expected')));
    try {
      await FirebaseAnalytics.instance.logEvent(name: 'quiz_answer', parameters: {
        'mode': 'writing',
        'correct': isCorrect,
      });
    } catch (_) {}
    _maybeShowAd(onlyOnCorrect: true, isCorrect: isCorrect);
    _next();
  }

  @override
  Widget build(BuildContext context) {
    if (correct == null) {
      if (pool.isEmpty) {
        return const Scaffold(body: Center(child: Text('Quiz için katalog boş.')));
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'Ad Inspector',
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: () {
                MobileAds.instance.openAdInspector((error) {
                  if (!mounted) return;
                  final msg = error == null ? 'Ad Inspector açıldı' : 'Ad Inspector hata: ${error.message ?? error.toString()}';
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                });
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Puan: $score'),
                const Spacer(),
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<QuizMode>(
                      segments: const [
                        ButtonSegment(value: QuizMode.multipleChoice, label: Text('Çoktan Seçmeli'), icon: Icon(Icons.list)),
                        ButtonSegment(value: QuizMode.writing, label: Text('Yazma'), icon: Icon(Icons.edit)),
                      ],
                      selected: {mode},
                      onSelectionChanged: (s) => setState(() => mode = s.first),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(correct!.english, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Text(
                      mode == QuizMode.multipleChoice
                          ? 'Bu kelimenin Türkçe karşılığını seçiniz:'
                          : 'Bu kelimenin Türkçe karşılığını yazınız:',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (mode == QuizMode.multipleChoice)
              ...options.map((o) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: ElevatedButton(onPressed: () => _answer(o), child: Text(o.turkish)),
                  ))
            else ...[
              TextField(
                controller: answerController,
                decoration: const InputDecoration(labelText: 'Yanıtı yazın'),
                onSubmitted: (_) => _submitWriting(),
              ),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _submitWriting, child: const Text('Gönder')),
            ],
          ],
        ),
      ),
    );
  }
}


