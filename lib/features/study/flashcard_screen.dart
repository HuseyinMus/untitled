import 'package:flutter/material.dart';
import 'package:untitled/core/srs/srs.dart';
import 'package:untitled/data/models/word.dart';
import 'package:untitled/data/repositories/repository.dart';
import 'package:untitled/data/repositories/firebase_repository.dart';
import 'package:untitled/data/repositories/stats_repository.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:flutter_tts/flutter_tts.dart';

class FlashcardScreen extends StatefulWidget {
  final Repository repository;
  final List<WordItem> initialQueue;

  const FlashcardScreen({super.key, required this.repository, required this.initialQueue});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  late List<WordItem> queue;
  bool showBack = false;
  late final FlutterTts tts;
  bool ttsReady = false;
  String? ttsLanguage;
  late final int initialTotal;

  @override
  void initState() {
    super.initState();
    queue = List<WordItem>.from(widget.initialQueue);
    initialTotal = queue.length;
    tts = FlutterTts();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      // Bazı platformlarda (özellikle desktop) dil/voice listesi boş dönebilir
      final langsDynamic = await tts.getLanguages;
      final List<String> langs = langsDynamic is List ? List<String>.from(langsDynamic) : <String>[];
      String? lang;
      if (langs.contains('en-US')) {
        lang = 'en-US';
      } else if (langs.isNotEmpty) {
        lang = langs.first;
      }
      // Android'te Google TTS motorunu tercih et
      if (!kIsWeb && Platform.isAndroid) {
        final enginesDynamic = await tts.getEngines;
        final List<dynamic> engines = enginesDynamic is List ? enginesDynamic : <dynamic>[];
        if (engines.map((e) => e.toString()).contains('com.google.android.tts')) {
          try { await tts.setEngine('com.google.android.tts'); } catch (_) {}
        }
        // Kuyruk modunu flush yap
        try { await tts.setQueueMode(0); } catch (_) {}
      }
      // iOS'ta sesi hoparlöre vermek ve sessiz modu bypass etmek için kategori ayarı
      if (!kIsWeb && Platform.isIOS) {
        try {
          await tts.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            [
              IosTextToSpeechAudioCategoryOptions.duckOthers,
              IosTextToSpeechAudioCategoryOptions.allowBluetooth,
              IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            ],
            IosTextToSpeechAudioMode.spokenAudio,
          );
        } catch (_) {}
      }
      if (lang != null) {
        await tts.setLanguage(lang);
        ttsLanguage = lang;
      }
      await tts.setSpeechRate(0.45);
      await tts.setPitch(1.0);
      await tts.setVolume(1.0);
      await tts.awaitSpeakCompletion(true);
      // Handler'lar (debug için)
      try {
        tts.setStartHandler(() {
          debugPrint('TTS start');
        });
        tts.setCompletionHandler(() {
          debugPrint('TTS complete');
        });
        tts.setCancelHandler(() {
          debugPrint('TTS cancel');
        });
        tts.setErrorHandler((msg) {
          debugPrint('TTS error: $msg');
        });
      } catch (_) {}
      setState(() => ttsReady = lang != null);
      if (lang != null && queue.isNotEmpty && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrent());
      }
    } catch (_) {
      setState(() => ttsReady = false);
    }
  }

  Future<void> _answer(ReviewGrade grade) async {
    if (queue.isEmpty) return;
    final current = queue.first;
    final repo = widget.repository;
    try {
      try { HapticFeedback.selectionClick(); } catch (_) {}
      if (repo is FirebaseRepository) {
        await repo.applyReviewAsync(current.id, grade);
      } else {
        repo.applyReview(current.id, grade);
      }
    } catch (_) {}
    await StatsRepository.recordStudyReview(isCorrect: grade != ReviewGrade.again);
    try {
      await FirebaseAnalytics.instance.logEvent(name: 'flashcard_answer', parameters: {
        'grade': grade.toString(),
      });
    } catch (_) {}
    setState(() {
      showBack = false;
      queue.removeAt(0);
    });
    if (queue.isEmpty) {
      if (mounted) Navigator.of(context).pop();
    }
    if (mounted && queue.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrent());
    }
  }

  Future<void> _speakCurrent() async {
    if (queue.isEmpty) return;
    final text = queue.first.english;
    if (!ttsReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('TTS bu platformda veya mevcut dilde kullanılamıyor.')),
      );
      return;
    }
    try {
      // Ön/arka yüze göre dil tercihi: ön yüzde EN, arka yüzde TR (varsa)
      try {
        final langsDynamic = await tts.getLanguages;
        final List<String> langs = langsDynamic is List ? List<String>.from(langsDynamic) : <String>[];
        String? preferred;
        if (showBack && langs.contains('tr-TR')) {
          preferred = 'tr-TR';
        } else if (langs.contains('en-US')) {
          preferred = 'en-US';
        }
        if (preferred != null) {
          await tts.setLanguage(preferred);
        } else if (ttsLanguage != null) {
          await tts.setLanguage(ttsLanguage!);
        }
      } catch (_) {}
      final sayText = showBack ? queue.first.turkish : queue.first.english;
      // Önce varsa devam eden bir konuşmayı durdur
      try { await tts.stop(); } catch (_) {}
      await tts.speak(sayText);
      try {
        await FirebaseAnalytics.instance.logEvent(name: 'tts_play', parameters: {
          'screen': 'flashcard',
          'side': showBack ? 'back_tr' : 'front_en',
        });
      } catch (_) {}
    } catch (_) {}
  }

  @override
  void dispose() {
    try {
      tts.stop();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final WordItem? current = queue.isNotEmpty ? queue.first : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
      body: current == null
          ? const Center(child: Text('Tebrikler! Bugünlük bitti.'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text('${initialTotal - queue.length}/${initialTotal}'),
                          const SizedBox(width: 8),
                          Text('${queue.length} kaldı'),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _speakCurrent,
                            icon: const Icon(Icons.volume_up),
                            tooltip: 'Dinle (TTS)',
                          ),
                          IconButton(
                            onPressed: () => setState(() => showBack = !showBack),
                            icon: Icon(showBack ? Icons.visibility_off : Icons.visibility),
                            tooltip: 'Ön/arka',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: initialTotal == 0 ? 0 : (initialTotal - queue.length) / initialTotal,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: GestureDetector(
                      onHorizontalDragEnd: (details) {
                        final vx = details.primaryVelocity ?? 0;
                        if (vx.abs() < 200) return; // çok küçük hareketleri yok say
                        // sağa hızlı kaydır: Good, sola: Again
                        if (vx > 0) {
                          _answer(ReviewGrade.good);
                        } else {
                          _answer(ReviewGrade.again);
                        }
                      },
                      onTap: () {
                        setState(() => showBack = !showBack);
                        WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrent());
                      },
                      child: _GlassCard(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, anim) {
                                return FadeTransition(
                                  opacity: anim,
                                  child: ScaleTransition(
                                    scale: Tween<double>(begin: 0.92, end: 1.0).animate(anim),
                                    child: child,
                                  ),
                                );
                              },
                              child: showBack
                                  ? Column(
                                      key: const ValueKey('back'),
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(current.turkish, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                                        const SizedBox(height: 12),
                                        Text(current.example, textAlign: TextAlign.center),
                                        const SizedBox(height: 12),
                                        _TagChips(
                                          partOfSpeech: current.partOfSpeech,
                                          level: current.level,
                                          categories: current.categories,
                                        ),
                                        if (current.mnemonic != null) ...[
                                          const SizedBox(height: 12),
                                          Text('Mnemonic: ${current.mnemonic!}', textAlign: TextAlign.center, style: const TextStyle(fontStyle: FontStyle.italic)),
                                        ],
                                      ],
                                    )
                                  : Text(current.english, key: const ValueKey('front'), style: Theme.of(context).textTheme.displaySmall, textAlign: TextAlign.center),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (showBack)
                    _AnswerBar(onSelect: _answer)
                  else
                    FilledButton.icon(
                      onPressed: () {
                        setState(() => showBack = true);
                        WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrent());
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('Cevabı Göster'),
                    ),
                ],
              ),
            ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            scheme.surfaceVariant.withOpacity(0.7),
            scheme.surfaceVariant.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.08),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}


class _AnswerBar extends StatelessWidget {
  final void Function(ReviewGrade) onSelect;
  const _AnswerBar({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: FilledButton.tonal(
            style: FilledButton.styleFrom(backgroundColor: scheme.errorContainer),
            onPressed: () => onSelect(ReviewGrade.again),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(Icons.close_rounded, size: 16), SizedBox(width: 6), Text('Again')],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.tonal(
            style: FilledButton.styleFrom(backgroundColor: scheme.tertiaryContainer),
            onPressed: () => onSelect(ReviewGrade.hard),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(Icons.timer, size: 16), SizedBox(width: 6), Text('Hard')],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton(
            onPressed: () => onSelect(ReviewGrade.good),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(Icons.check_rounded, size: 16), SizedBox(width: 6), Text('Good')],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: scheme.primaryContainer),
            onPressed: () => onSelect(ReviewGrade.easy),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(Icons.thumb_up_rounded, size: 16), SizedBox(width: 6), Text('Easy')],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TagChips extends StatelessWidget {
  final String partOfSpeech;
  final String? level;
  final List<String> categories;
  const _TagChips({required this.partOfSpeech, required this.level, required this.categories});

  @override
  Widget build(BuildContext context) {
    final List<Widget> chips = [];
    if (partOfSpeech.isNotEmpty) {
      chips.add(Chip(label: Text(partOfSpeech)));
    }
    if ((level ?? '').trim().isNotEmpty) {
      chips.add(Chip(label: Text(level!.trim())));
    }
    for (final c in categories.take(3)) {
      chips.add(Chip(label: Text(c)));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: chips);
  }
}


