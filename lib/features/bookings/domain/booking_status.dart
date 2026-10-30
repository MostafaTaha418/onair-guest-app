/// The wire value of a booking status, tab, refund stage, or payment state.
/// Unknown server values never crash the app: they map to `unknown` and the
/// UI shows the generic copy (data-model §5).
enum BookingStatus {
  paymentPending,
  paymentVerifying,
  awaitingOwner,
  paymentConflict,
  confirmed,
  checkedIn,
  completed,
  rejected,
  expired,
  cancelled,
  noShow,
  abandoned,
  unknown;

  static BookingStatus fromWire(String? value) => switch (value) {
    'payment_pending' => paymentPending,
    'payment_verifying' => paymentVerifying,
    'awaiting_owner' => awaitingOwner,
    'payment_conflict' => paymentConflict,
    'confirmed' => confirmed,
    'checked_in' => checkedIn,
    'completed' => completed,
    'rejected' => rejected,
    'expired' => expired,
    'cancelled' => cancelled,
    'no_show' => noShow,
    'abandoned' => abandoned,
    _ => unknown,
  };

  String get wire => switch (this) {
    paymentPending => 'payment_pending',
    paymentVerifying => 'payment_verifying',
    awaitingOwner => 'awaiting_owner',
    paymentConflict => 'payment_conflict',
    confirmed => 'confirmed',
    checkedIn => 'checked_in',
    completed => 'completed',
    rejected => 'rejected',
    expired => 'expired',
    cancelled => 'cancelled',
    noShow => 'no_show',
    abandoned => 'abandoned',
    unknown => 'unknown',
  };

  /// A terminal booking never moves again; arrival instructions are purged
  /// when a refresh reports one of these (data-model §11).
  bool get isTerminal => switch (this) {
    completed ||
    cancelled ||
    rejected ||
    expired ||
    noShow ||
    paymentConflict ||
    abandoned => true,
    _ => false,
  };

  bool get showsArrivalInstructions => this == confirmed || this == checkedIn;
}

/// The server tab parameter (contract delta D2). `pending` holds only
/// `payment_pending` bookings and feeds the unfinished-payment banner; it is
/// never shown as a tab.
enum BookingTab {
  current,
  past,
  cancelled,
  pending;

  String get wire => name;
}

enum RefundStage {
  requested,
  approved,
  executed,
  verified,
  failed,
  cancelled,
  unknown;

  static RefundStage fromWire(String? value) => switch (value) {
    'requested' => requested,
    'approved' => approved,
    'executed' => executed,
    'verified' => verified,
    'failed' => failed,
    'cancelled' => cancelled,
    _ => unknown,
  };

  String get wire => switch (this) {
    requested => 'requested',
    approved => 'approved',
    executed => 'executed',
    verified => 'verified',
    failed => 'failed',
    cancelled => 'cancelled',
    unknown => 'unknown',
  };
}

enum PaymentState {
  pending,
  failed,
  succeeded;

  static PaymentState fromWire(String? value) => switch (value) {
    'failed' => failed,
    'succeeded' => succeeded,
    _ => pending,
  };

  String get wire => switch (this) {
    pending => 'pending',
    failed => 'failed',
    succeeded => 'succeeded',
  };
}
