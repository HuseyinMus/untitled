import 'package:cloud_firestore/cloud_firestore.dart';

Future<int> seedCatalog() async {
  final List<Map<String, dynamic>> items = [
    {
      'id': 'toefl_abandon',
      'en': 'abandon',
      'tr': 'terk etmek',
      'pos': 'verb',
      'example': 'They had to abandon the car in the snow.',
      'categories': ['TOEFL', 'IELTS'],
      'level': 'B2',
    },
    {
      'id': 'sat_benevolent',
      'en': 'benevolent',
      'tr': 'iyiliksever',
      'pos': 'adjective',
      'example': 'A benevolent donor supported the school.',
      'categories': ['SAT'],
      'level': 'C1',
    },
    {
      'id': 'ielts_contemplate',
      'en': 'contemplate',
      'tr': 'düşünmek, tasarlamak',
      'pos': 'verb',
      'example': 'She contemplated a career change.',
      'categories': ['IELTS'],
      'level': 'B2-C1',
    },
    {
      'id': 'toefl_meticulous',
      'en': 'meticulous',
      'tr': 'titiz, çok dikkatli',
      'pos': 'adjective',
      'example': 'He kept meticulous records of his expenses.',
      'categories': ['TOEFL'],
      'level': 'C1',
    },
    {
      'id': 'toefl_ubiquitous',
      'en': 'ubiquitous',
      'tr': 'her yerde bulunan',
      'pos': 'adjective',
      'example': 'Smartphones have become ubiquitous in modern life.',
      'categories': ['TOEFL'],
      'level': 'C1',
    },
    {
      'id': 'ielts_exacerbate',
      'en': 'exacerbate',
      'tr': 'kötüleştirmek, şiddetlendirmek',
      'pos': 'verb',
      'example': 'The new tax could exacerbate inequality.',
      'categories': ['IELTS'],
      'level': 'C1',
    },
    {
      'id': 'ielts_ameliorate',
      'en': 'ameliorate',
      'tr': 'iyileştirmek, düzeltmek',
      'pos': 'verb',
      'example': 'Policies were introduced to ameliorate poverty.',
      'categories': ['IELTS'],
      'level': 'C1',
    },
    {
      'id': 'sat_astute',
      'en': 'astute',
      'tr': 'zeki, kıvrak zekalı',
      'pos': 'adjective',
      'example': 'An astute investor spotted the opportunity early.',
      'categories': ['SAT'],
      'level': 'B2',
    },
    {
      'id': 'sat_candid',
      'en': 'candid',
      'tr': 'dürüst, açık sözlü',
      'pos': 'adjective',
      'example': 'She was candid about her mistakes.',
      'categories': ['SAT', 'IELTS'],
      'level': 'B2',
    },
    {
      'id': 'sat_elated',
      'en': 'elated',
      'tr': 'çok mutlu, keyifli',
      'pos': 'adjective',
      'example': 'He felt elated after receiving the news.',
      'categories': ['SAT'],
      'level': 'B2',
    },
    {
      'id': 'toefl_inhibit',
      'en': 'inhibit',
      'tr': 'engellemek, dizginlemek',
      'pos': 'verb',
      'example': 'Fear can inhibit learning.',
      'categories': ['TOEFL'],
      'level': 'B2',
    },
    {
      'id': 'toefl_robust',
      'en': 'robust',
      'tr': 'sağlam, güçlü',
      'pos': 'adjective',
      'example': 'The system is robust against faults.',
      'categories': ['TOEFL'],
      'level': 'B2',
    },
    {
      'id': 'ielts_scrutinize',
      'en': 'scrutinize',
      'tr': 'incelemek, didik didik etmek',
      'pos': 'verb',
      'example': 'The data were scrutinized for errors.',
      'categories': ['IELTS'],
      'level': 'C1',
    },
    {
      'id': 'ielts_concise',
      'en': 'concise',
      'tr': 'özlü, kısa ve net',
      'pos': 'adjective',
      'example': 'Please give concise answers.',
      'categories': ['IELTS', 'TOEFL'],
      'level': 'B2',
    },
    {
      'id': 'sat_pragmatic',
      'en': 'pragmatic',
      'tr': 'pragmatik, sonuç odaklı',
      'pos': 'adjective',
      'example': 'She took a pragmatic approach to the problem.',
      'categories': ['SAT'],
      'level': 'B2',
    },
  ];

  final db = FirebaseFirestore.instance;
  int count = 0;
  for (final m in items) {
    final id = m['id'] as String;
    await db.collection('catalog_words').doc(id).set({
      'en': m['en'],
      'tr': m['tr'],
      'pos': m['pos'],
      'example': m['example'],
      'categories': m['categories'],
      'level': m['level'],
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    count++;
  }
  return count;
}


