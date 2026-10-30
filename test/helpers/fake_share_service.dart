import 'package:on_air/core/share/share_service.dart';

/// Records every text passed to [share], so widget tests can assert on the
/// share sheet input without opening a real platform sheet.
final class FakeShareService implements ShareService {
  final List<String> shared = [];

  @override
  Future<void> share(String text) async {
    shared.add(text);
  }
}
