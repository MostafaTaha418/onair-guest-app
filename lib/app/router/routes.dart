abstract final class AppRoutes {
  static const home = '/home';
  static const search = '/search';
  static const bookings = '/bookings';
  static const favorites = '/favorites';
  static const account = '/account';
  static const splash = '/splash';
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const otp = '/auth/otp';
  static const completeProfile = '/auth/complete-profile';
  static const forgotPassword = '/auth/forgot-password';
  static const newPassword = '/auth/new-password';
  static const notAvailable = '/not-available';
  static const updateRequired = '/update-required';

  static const propertyPattern = '/property/:id';
  static const propertyGalleryPattern = '/property/:id/gallery';
  static const propertyReviewsPattern = '/property/:id/reviews';
  static const searchResults = '/search/results';
  static const bookingEntryPattern = '/book/:propertyId/dates';
  static const supportNew = '/support/new';
  static const bookingDetailsPattern = '/bookings/:id';
  static const remainingPaymentPattern = '/bookings/:id/remaining-payment';
  static const damageClaimPattern = '/bookings/:id/damage-claim/:claimId';
  static const bookingReviewPattern = '/bookings/:id/review';
  static const supportCasePattern = '/support/:caseId';
  static const paymentReturn = '/payment/return';

  static final _uuidV4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  static final _property = RegExp(r'^/property/([^/]+)$');
  static final _propertyGallery = RegExp(r'^/property/([^/]+)/gallery$');
  static final _propertyReviews = RegExp(r'^/property/([^/]+)/reviews$');
  static final _bookingEntry = RegExp(r'^/book/([^/]+)/dates$');
  static final _bookingDetails = RegExp(r'^/bookings/([^/]+)$');
  static final _remainingPayment = RegExp(
    r'^/bookings/([^/]+)/remaining-payment$',
  );
  static final _damageClaim = RegExp(
    r'^/bookings/([^/]+)/damage-claim/([^/]+)$',
  );
  static final _bookingReview = RegExp(r'^/bookings/([^/]+)/review$');
  static final _supportCase = RegExp(r'^/support/([^/]+)$');

  static bool isRegisteredLocation(String? location) {
    final uri = location == null ? null : Uri.tryParse(location);
    if (uri == null ||
        uri.scheme.isNotEmpty ||
        uri.hasAuthority ||
        uri.fragment.isNotEmpty ||
        !uri.path.startsWith('/') ||
        uri.path.startsWith('//')) {
      return false;
    }
    const staticPaths = {
      home,
      search,
      bookings,
      favorites,
      account,
      splash,
      login,
      register,
      otp,
      completeProfile,
      forgotPassword,
      newPassword,
      notAvailable,
      updateRequired,
      searchResults,
      supportNew,
      paymentReturn,
    };
    return staticPaths.contains(uri.path) || _validDynamicPath(uri.path);
  }

  static bool isAuthLocation(String location) =>
      switch (Uri.tryParse(location)?.path) {
        login ||
        register ||
        otp ||
        completeProfile ||
        forgotPassword ||
        newPassword => true,
        _ => false,
      };

  static bool requiresAccount(String location) {
    final path = Uri.tryParse(location)?.path;
    if (path == bookings || path == favorites || path == account) return true;
    if (path == supportNew) return true;
    return path != null &&
        (_validMatch(_bookingDetails, path) ||
            _validMatch(_remainingPayment, path) ||
            _validMatch(_damageClaim, path, idCount: 2) ||
            _validMatch(_bookingReview, path) ||
            _validMatch(_supportCase, path) ||
            _validMatch(_bookingEntry, path) ||
            path == paymentReturn);
  }

  static bool isLinkablePath(String path) =>
      path == searchResults ||
      path == paymentReturn ||
      _validMatch(_property, path) ||
      _validMatch(_bookingDetails, path) ||
      _validMatch(_remainingPayment, path) ||
      _validMatch(_damageClaim, path, idCount: 2) ||
      _validMatch(_bookingReview, path) ||
      _validMatch(_supportCase, path);

  static bool _validDynamicPath(String path) =>
      _validMatch(_property, path) ||
      _validMatch(_propertyGallery, path) ||
      _validMatch(_propertyReviews, path) ||
      _validMatch(_bookingEntry, path) ||
      _validMatch(_bookingDetails, path) ||
      _validMatch(_remainingPayment, path) ||
      _validMatch(_damageClaim, path, idCount: 2) ||
      _validMatch(_bookingReview, path) ||
      _validMatch(_supportCase, path);

  // -- Builders for in-app navigation ---------------------------------------

  static String property(String id) => '/property/$id';
  static String propertyGallery(String id) => '/property/$id/gallery';
  static String propertyReviews(String id) => '/property/$id/reviews';
  static String bookingEntry(String propertyId) => '/book/$propertyId/dates';

  static bool _validMatch(RegExp pattern, String path, {int idCount = 1}) {
    final match = pattern.firstMatch(path);
    if (match == null) return false;
    for (var index = 1; index <= idCount; index++) {
      if (!_uuidV4.hasMatch(match.group(index)!)) return false;
    }
    return true;
  }
}
