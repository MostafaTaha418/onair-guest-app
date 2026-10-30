// Generates the mock discovery fixtures (tasks.md Appendix B).
//
// Run: `dart run tool/generate_fixtures.dart`
// Output: lib/features/listings/data/fixtures/*.json (deterministic).
import 'dart:convert';
import 'dart:io';

final Directory _outputDir = Directory('lib/features/listings/data/fixtures');

// Deterministic PRNG so committed fixtures never churn between runs.
int _seed = 42;
int _rnd() => _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;

/// Valid UUID v4 shape with a deterministic tail.
String uuid(int n) =>
    '00000000-0000-4000-8000-${n.toRadixString(16).padLeft(12, '0')}';

const List<Map<String, String>> _amenities = [
  {'key': 'wifi', 'label': 'واي فاي', 'icon': 'wifi'},
  {'key': 'ac', 'label': 'تكييف', 'icon': 'ac_unit'},
  {'key': 'kitchen', 'label': 'مطبخ', 'icon': 'kitchen'},
  {'key': 'washer', 'label': 'غسالة', 'icon': 'local_laundry_service'},
  {'key': 'parking', 'label': 'موقف سيارات', 'icon': 'local_parking'},
  {'key': 'pool', 'label': 'مسبح', 'icon': 'pool'},
  {'key': 'elevator', 'label': 'مصعد', 'icon': 'elevator'},
  {'key': 'tv', 'label': 'تلفزيون', 'icon': 'tv'},
  {'key': 'balcony', 'label': 'بلكونة', 'icon': 'balcony'},
  {'key': 'sea_view', 'label': 'إطلالة بحرية', 'icon': 'waves'},
];

const List<Map<String, String>> _propertyTypes = [
  {'key': 'apartment', 'label': 'شقة'},
  {'key': 'studio', 'label': 'استوديو'},
  {'key': 'villa', 'label': 'فيلا'},
  {'key': 'chalet', 'label': 'شاليه'},
  {'key': 'room', 'label': 'غرفة'},
];

// Location tree: 3 governorates, 4 cities, 6 areas.
// (id, name) / (id, name, parentId)
const List<(int, String)> _governorates = [
  (1, 'القاهرة'),
  (2, 'الجيزة'),
  (3, 'الإسكندرية'),
];
const List<(int, String, int)> _cities = [
  (11, 'القاهرة الجديدة', 1),
  (12, 'مدينة نصر', 1),
  (13, 'الشيخ زايد', 2),
  (14, 'العجمي', 3),
];
const List<(int, String, int)> _areas = [
  (21, 'التجمع الخامس', 11),
  (22, 'الرحاب', 11),
  (23, 'الحي العاشر', 11),
  (24, 'بيفرلي هيلز', 13),
  (25, 'البيطاش', 14),
  (26, 'الهانوفيل', 14),
];

const List<String> _reviewerNames = [
  'أحمد م.',
  'سارة ع.',
  'محمد ك.',
  'منى ح.',
  'يوسف ط.',
  'نور أ.',
  'كريم س.',
  'هدى ف.',
];
const List<String?> _reviewComments = [
  'الشقة كانت نظيفة والموقع ممتاز.',
  'المالك متعاون والتوصيل كان في الموعد.',
  'تجربة حلوة بشكل عام، هكرر الحجز.',
  'الصور مطابقة للواقع.',
  null,
];

String _isoDate(DateTime date) => date.toIso8601String().substring(0, 10);

void main() {
  _outputDir.createSync(recursive: true);
  _seed = 42;

  final locationNames = {
    for (final (n, name) in _governorates) n: name,
    for (final (n, name, _) in _cities) n: name,
    for (final (n, name, _) in _areas) n: name,
  };
  final locationParents = {
    for (final (n, _, parent) in _cities) n: parent,
    for (final (n, _, parent) in _areas) n: parent,
  };

  List<Map<String, dynamic>> variants(String url) => [
    for (final width in const [320, 720])
      {'width': width, 'url': '$url-$width.jpg'},
  ];

  List<Map<String, dynamic>> propertyImages(int seed, int count) => [
    for (var index = 0; index < count; index++)
      {
        'variants': variants(
          'https://cdn.mock.onair.test/${seed * 10 + index}',
        ),
        'blurhash': null,
      },
  ];

  Map<String, dynamic> buildProperty({
    required int n,
    required String name,
    required bool published,
    required int areaN,
    required int price,
    required int bedrooms,
    required int bathrooms,
    required int maxGuests,
    required int imageCount,
    required String type,
    required List<String> amenityKeys,
    required String createdAt,
    bool noAddress = false,
    Map<String, dynamic>? policy,
    Map<String, dynamic>? busyOffsets,
  }) {
    final area = locationNames[areaN]!;
    final city = locationNames[locationParents[areaN]!]!;
    final gov = locationNames[locationParents[locationParents[areaN]!]!]!;
    return {
      'id': uuid(n),
      'title': 'شقة $bedrooms غرف في $area',
      'description': 'شقة مفروشة بالكامل في $area، $city. مناسبة للعائلات.',
      'property_type': type,
      'governorate_name': gov,
      'city_name': city,
      'area_name': area,
      'address_text': noAddress
          ? null
          : 'شارع ${n % 90 + 1}، عمارة ${n % 20 + 1}، الدور ${n % 5 + 1}',
      'images': propertyImages(n, imageCount),
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'max_guests': maxGuests,
      'area_sqm': 90 + (n % 8) * 10,
      'amenities': [
        for (final key in amenityKeys)
          _amenities.firstWhere((amenity) => amenity['key'] == key),
      ],
      'rules': {
        'check_in_time': '14:00',
        'check_out_time': '12:00',
        'visitors_allowed': n.isEven,
        'max_visitors': n.isEven ? 2 : null,
        'house_rules':
            'ممنوع التدخين داخل الشقة، ويُرجى الاطمئنان على النوافذ.',
      },
      'policy':
          policy ??
          {
            'deposit_type': 'percent',
            'deposit_percent_bp': 2500,
            'deposit_amount_minor': null,
            'free_cancellation_hours': 72,
          },
      'nightly_price_minor': price,
      'currency': 'EGP',
      'rating_avg': null,
      'review_count': 0,
      'latest_reviews': <dynamic>[],
      'terms_version': 'mock-terms-1',
      '_fixture_name': name,
      '_published': published,
      '_location_ids': [
        uuid(areaN),
        uuid(locationParents[areaN]!),
        uuid(locationParents[locationParents[areaN]!]!),
      ],
      '_created_at': createdAt,
      '_busy_offsets': busyOffsets,
      '_amenity_keys': amenityKeys,
    };
  }

  Map<String, dynamic> named({
    required int n,
    required String name,
    required int areaN,
    required String createdAt,
    bool published = true,
    Map<String, dynamic>? policy,
    Map<String, dynamic>? busyOffsets,
    int price = 100000,
    bool noAddress = false,
  }) => buildProperty(
    n: n,
    name: name,
    published: published,
    areaN: areaN,
    price: price,
    bedrooms: 3,
    bathrooms: 2,
    maxGuests: 6,
    imageCount: 6,
    type: 'apartment',
    amenityKeys: ['wifi', 'ac', 'kitchen', 'tv', 'elevator'],
    createdAt: createdAt,
    noAddress: noAddress,
    policy: policy,
    busyOffsets: busyOffsets,
  );

  final properties = [
    named(
      n: 31,
      name: 'prop-deposit-percent',
      areaN: 21,
      createdAt: '2026-09-01',
      price: 150000,
    ),
    named(
      n: 32,
      name: 'prop-deposit-fixed',
      areaN: 22,
      createdAt: '2026-09-05',
      price: 80000,
      policy: {
        'deposit_type': 'fixed',
        'deposit_percent_bp': null,
        'deposit_amount_minor': 100000,
        'free_cancellation_hours': 48,
      },
    ),
    named(
      n: 33,
      name: 'prop-full-payment',
      areaN: 24,
      createdAt: '2026-09-10',
      price: 220000,
      policy: {
        'deposit_type': 'full',
        'deposit_percent_bp': null,
        'deposit_amount_minor': null,
        'free_cancellation_hours': 24,
      },
      noAddress: true,
    ),
    named(
      n: 34,
      name: 'prop-busy',
      areaN: 21,
      createdAt: '2026-09-15',
      price: 120000,
      busyOffsets: {
        'booked': [10],
        'held': [12],
        'blocked': [14],
      },
    ),
    named(
      n: 35,
      name: 'prop-draft',
      areaN: 21,
      createdAt: '2026-09-16',
      published: false,
    ),
    named(
      n: 36,
      name: 'prop-paused',
      areaN: 22,
      createdAt: '2026-09-17',
      published: false,
    ),
    named(
      n: 37,
      name: 'prop-rejected',
      areaN: 24,
      createdAt: '2026-09-18',
      published: false,
    ),
    named(
      n: 38,
      name: 'prop-unapproved-workspace',
      areaN: 26,
      createdAt: '2026-09-19',
      published: false,
    ),
    // 120 generic apartments spread over the 6 areas (Appendix B).
    for (var index = 1; index <= 120; index++)
      buildProperty(
        n: 100 + index - 1,
        name: 'prop-generic-${index.toString().padLeft(3, '0')}',
        published: true,
        areaN: _areas[index % _areas.length].$1,
        price: 50000 + _rnd() % 1450001,
        bedrooms: 1 + index % 5,
        bathrooms: 1 + index % 3,
        maxGuests: 2 + index % 6,
        imageCount: 1 + index % 2,
        type: _propertyTypes[index % _propertyTypes.length]['key']!,
        amenityKeys: [
          'wifi',
          // 1 in 5 has no AC so amenity counts differ meaningfully.
          if (index % 5 != 0) 'ac',
          for (var extra = 0; extra < 1 + index % 4; extra++)
            _amenities[(index + extra + 2) % _amenities.length]['key']!,
        ],
        createdAt: _isoDate(DateTime.utc(2026).add(Duration(days: index))),
      ),
  ];

  // --- Reviews --------------------------------------------------------------
  // prop-deposit-percent: 26 approved (for pagination) + 2 pending + 1
  // rejected; prop-full-payment: 2 approved.
  Map<String, dynamic> review(
    int n,
    int rating,
    String? comment,
    String createdOn,
    String reviewer,
    String status,
  ) => {
    'id': uuid(n),
    'rating': rating,
    'comment': comment,
    'created_on': createdOn,
    'reviewer_short_name': reviewer,
    'status': status,
  };

  final reviews = {
    uuid(31): [
      for (var index = 0; index < 26; index++)
        review(
          500 + index,
          3 + index % 3,
          _reviewComments[index % _reviewComments.length],
          _isoDate(DateTime.utc(2026, 10, 20).subtract(Duration(days: index))),
          _reviewerNames[index % _reviewerNames.length],
          'approved',
        ),
      review(
        600,
        1,
        'تعليق في انتظار المراجعة.',
        '2026-10-21',
        _reviewerNames[0],
        'pending',
      ),
      review(
        601,
        2,
        'تعليق مرفوض.',
        '2026-10-22',
        _reviewerNames[1],
        'rejected',
      ),
    ],
    uuid(33): [
      review(
        610,
        5,
        'إقامة رائعة.',
        '2026-10-01',
        _reviewerNames[2],
        'approved',
      ),
      review(611, 4, null, '2026-09-28', _reviewerNames[3], 'approved'),
    ],
  };

  // Embed review summaries into the property fixtures.
  for (final property in properties) {
    final approved =
        [
          for (final reviewJson
              in reviews[property['id'] as String] ??
                  const <Map<String, dynamic>>[])
            if (reviewJson['status'] == 'approved') reviewJson,
        ]..sort(
          (a, b) =>
              (b['created_on'] as String).compareTo(a['created_on'] as String),
        );
    if (approved.isEmpty) continue;
    property['review_count'] = approved.length;
    property['rating_avg'] =
        approved
            .map((reviewJson) => reviewJson['rating'] as int)
            .reduce(
              (a, b) => a + b,
            ) /
        approved.length;
    property['latest_reviews'] = [
      for (final reviewJson in approved.take(3))
        {
          'id': reviewJson['id'],
          'rating': reviewJson['rating'],
          'comment': reviewJson['comment'],
          'created_on': reviewJson['created_on'],
          'reviewer_short_name': reviewJson['reviewer_short_name'],
        },
    ];
  }

  // --- Locations ------------------------------------------------------------
  final publishedByArea = <int, int>{};
  for (final property in properties) {
    if (property['_published'] != true) continue;
    final areaId = (property['_location_ids'] as List<dynamic>).first as String;
    final areaN = int.parse(areaId.split('-').last, radix: 16);
    publishedByArea[areaN] = (publishedByArea[areaN] ?? 0) + 1;
  }
  int countUnder(int n) {
    if (n >= 20) return publishedByArea[n] ?? 0;
    if (n >= 10) {
      return _areas
          .where((area) => area.$3 == n)
          .fold(0, (sum, area) => sum + (publishedByArea[area.$1] ?? 0));
    }
    return _cities
        .where((city) => city.$3 == n)
        .fold(0, (sum, city) => sum + countUnder(city.$1));
  }

  final locations = [
    for (final (n, name) in _governorates)
      {
        'id': uuid(n),
        'level': 'governorate',
        'name': name,
        'parent_id': null,
        'listing_count': countUnder(n),
      },
    for (final (n, name, parent) in _cities)
      {
        'id': uuid(n),
        'level': 'city',
        'name': name,
        'parent_id': uuid(parent),
        'listing_count': countUnder(n),
      },
    for (final (n, name, parent) in _areas)
      {
        'id': uuid(n),
        'level': 'area',
        'name': name,
        'parent_id': uuid(parent),
        'listing_count': countUnder(n),
      },
  ];

  // --- Reference ------------------------------------------------------------
  final publishedPrices = [
    for (final property in properties)
      if (property['_published'] == true)
        property['nightly_price_minor'] as int,
  ];
  final reference = {
    'version': 'mock-ref-1',
    'amenities': _amenities,
    'property_types': _propertyTypes,
    'price_bounds': {
      'min_minor': publishedPrices.reduce((a, b) => a < b ? a : b),
      'max_minor': publishedPrices.reduce((a, b) => a > b ? a : b),
      'currency': 'EGP',
    },
    'price_step_minor': 5000,
  };

  // --- Home feed ------------------------------------------------------------
  final published = properties
      .where((property) => property['_published'] == true)
      .toList();
  Map<String, dynamic> cardOf(Map<String, dynamic> property) => {
    'id': property['id'],
    'title': property['title'],
    'property_type': property['property_type'],
    'area_name': property['area_name'],
    'city_name': property['city_name'],
    'cover': (property['images'] as List).isEmpty
        ? null
        : (property['images'] as List).first,
    'nightly_price_minor': property['nightly_price_minor'],
    'currency': 'EGP',
    'rating_avg': property['rating_avg'],
    'review_count': property['review_count'],
  };
  final newestFirst = [...published]
    ..sort(
      (a, b) =>
          (b['_created_at'] as String).compareTo(a['_created_at'] as String),
    );
  final homeFeed = {
    'reference_version': 'mock-ref-1',
    'areas': {
      'status': 'ready',
      'items': [
        for (final (n, name, _) in _areas)
          {
            'location_id': uuid(n),
            'name': name,
            'listing_count': countUnder(n),
            'image': {
              'variants': variants('https://cdn.mock.onair.test/area-$n'),
              'blurhash': null,
            },
          },
      ],
    },
    'suggested': {
      'status': 'ready',
      'items': published.take(10).map(cardOf).toList(),
    },
    'newest': {
      'status': 'ready',
      'items': newestFirst.take(10).map(cardOf).toList(),
    },
    'upcoming_booking': {'status': 'ready', 'item': null},
  };

  void write(String fileName, Object json) => File(
    '${_outputDir.path}${Platform.pathSeparator}$fileName',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(json));

  write('locations.json', locations);
  write('reference.json', reference);
  write('properties.json', properties);
  write('reviews.json', reviews);
  write('home_feed.json', homeFeed);

  stderr.writeln(
    'Wrote ${properties.length} properties, ${locations.length} locations, '
    'and the home feed to ${_outputDir.path}',
  );
}
