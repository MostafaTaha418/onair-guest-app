import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/support/data/faq_cache.dart';
import 'package:on_air/features/support/presentation/faq/faq_cubit.dart';

import '../../../helpers/fake_support_repository.dart';

Map<String, dynamic> row({
  required String id,
  required int order,
  required String questionAr,
  required String answerAr,
  String? questionEn,
  String? answerEn,
}) => {
  'id': id,
  'question_ar': questionAr,
  'answer_ar': answerAr,
  'question_en': questionEn,
  'answer_en': answerEn,
  'sort_order': order,
};

void main() {
  final arabicRows = <Map<String, dynamic>>[
    row(
      id: 'faq-2',
      order: 2,
      questionAr: 'إيه طرق الدفع؟',
      answerAr: 'فيزا أو كاش.',
      questionEn: 'What are the payment methods?',
      answerEn: 'Visa or cash.',
    ),
    row(
      id: 'faq-1',
      order: 1,
      questionAr: 'إزاي أحجز شقة؟',
      answerAr: 'اختار الشقة وحدد المواعيد وادفع.',
      questionEn: 'How do I book an apartment?',
      answerEn: 'Pick an apartment, set the dates and pay.',
    ),
    row(
      id: 'faq-3',
      order: 3,
      // No English translation: English falls back to Arabic.
      questionAr: 'الاسترداد بيرجع أمتى؟',
      answerAr: 'خلال 5-7 أيام عمل.',
    ),
  ];

  late FakeSupportRepository repository;
  late FaqCache cache;
  late Directory cacheDirectory;

  setUp(() {
    repository = FakeSupportRepository()..faqRows = arabicRows;
    cacheDirectory = Directory.systemTemp.createTempSync('on_air_faq_test');
    cache = FaqCache(
      JsonFileCache(
        directory: cacheDirectory,
        fileName: 'faq_v1.json',
        schema: 1,
      ),
    );
  });

  tearDown(() => cacheDirectory.deleteSync(recursive: true));

  Future<FaqCubit> bootedCubit({String locale = 'ar'}) async {
    final cubit = FaqCubit(
      repository: repository,
      cache: cache,
      locale: locale,
    );
    addTearDown(cubit.close);
    await cubit.load();
    return cubit;
  }

  test('load sorts by sortOrder and localizes by the current locale', () async {
    final cubit = await bootedCubit();
    final ready = cubit.state as FaqReady;
    expect(ready.items.map((item) => item.id), ['faq-1', 'faq-2', 'faq-3']);
    expect(ready.items.first.question, 'إزاي أحجز شقة؟');
    expect(ready.stale, isFalse);
  });

  test(
    'English locale reads the English columns with an Arabic fallback',
    () async {
      final cubit = await bootedCubit(locale: 'en');
      final ready = cubit.state as FaqReady;
      expect(ready.items.first.question, 'How do I book an apartment?');
      // faq-3 has no English translation.
      expect(ready.items.last.question, 'الاسترداد بيرجع أمتى؟');
    },
  );

  test('the result is written to the cache', () async {
    await bootedCubit();
    final snapshot = await cache.load();
    expect(snapshot, isNotNull);
    expect(snapshot!.items, hasLength(3));
    expect(snapshot.locale, 'ar');
    expect(snapshot.items.first.question, 'إزاي أحجز شقة؟');
  });

  test('offline with a cache shows the cached items and stale', () async {
    await bootedCubit();
    // A fresh cubit whose server read fails but the cache survives.
    final offlineRepository = FakeSupportRepository()
      ..nextFaqError = const AppFailure(
        ApiError(code: ErrorCode.network, messageKey: 'errorNoConnection'),
      );
    final offline = FaqCubit(
      repository: offlineRepository,
      cache: cache,
    );
    addTearDown(offline.close);
    await offline.load();
    final ready = offline.state as FaqReady;
    expect(ready.stale, isTrue);
    expect(ready.items, hasLength(3));
    expect(ready.items.first.question, 'إزاي أحجز شقة؟');
  });

  test('offline without a cache is the offline error', () async {
    repository.nextFaqError = const AppFailure(
      ApiError(code: ErrorCode.network, messageKey: 'errorNoConnection'),
    );
    final cubit = await bootedCubit();
    expect(cubit.state, isA<FaqFailed>());
    final failed = cubit.state as FaqFailed;
    expect(failed.error.code, ErrorCode.network);
  });

  test('search normalizes Arabic over question and answer', () async {
    final cubit = await bootedCubit();
    // ة→ه folding: «شقة» matches «شقه».
    cubit.search('شقه');
    expect((cubit.state as FaqReady).items.map((item) => item.id), ['faq-1']);
    // أ/ى folding: «أىام» matches «أيام».
    cubit.search('أىام');
    expect((cubit.state as FaqReady).items.map((item) => item.id), ['faq-3']);
    // Diacritics are stripped on both sides.
    cubit.search('اِزَاي');
    expect((cubit.state as FaqReady).items.map((item) => item.id), ['faq-1']);
    // The answer body is searched too.
    cubit.search('كاش');
    expect((cubit.state as FaqReady).items.map((item) => item.id), ['faq-2']);
  });

  test('search is case-insensitive over the English text', () async {
    final cubit = await bootedCubit(locale: 'en');
    cubit.search('VISA');
    expect((cubit.state as FaqReady).items.map((item) => item.id), ['faq-2']);
  });

  test(
    'an empty query clears the filter and an unmatched one is noResults',
    () async {
      final cubit = await bootedCubit();
      cubit.search('مفيش حاجة زي دي');
      final empty = cubit.state as FaqReady;
      expect(empty.items, isEmpty);
      expect(empty.noResults, isTrue);
      cubit.search('   ');
      expect((cubit.state as FaqReady).noResults, isFalse);
      expect((cubit.state as FaqReady).items, hasLength(3));
    },
  );

  test('setLocale re-localizes the loaded rows live', () async {
    final cubit = await bootedCubit();
    cubit.setLocale('en');
    final ready = cubit.state as FaqReady;
    expect(ready.items.first.question, 'How do I book an apartment?');
    // The cached snapshot keeps the fetch-time locale.
    expect((await cache.load())!.locale, 'ar');
  });
}
