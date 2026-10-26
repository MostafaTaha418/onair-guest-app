abstract interface class PersonalDataResetter {
  Future<void> resetPersonalData();
}

final class NoopPersonalDataResetter implements PersonalDataResetter {
  const NoopPersonalDataResetter();

  @override
  Future<void> resetPersonalData() async {}
}

final class CompositePersonalDataResetter implements PersonalDataResetter {
  const CompositePersonalDataResetter(this._resetters);

  final List<Future<void> Function()> _resetters;

  @override
  Future<void> resetPersonalData() async {
    for (final reset in _resetters) {
      await reset();
    }
  }
}
