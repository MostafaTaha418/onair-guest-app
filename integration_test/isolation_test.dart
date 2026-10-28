import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _url = String.fromEnvironment('SUPABASE_URL');
const _publishableKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const _phoneA = String.fromEnvironment('STAGING_TEST_PHONE_A');
const _otpA = String.fromEnvironment('STAGING_TEST_OTP_A');
const _phoneB = String.fromEnvironment('STAGING_TEST_PHONE_B');
const _otpB = String.fromEnvironment('STAGING_TEST_OTP_B');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test(
    'profiles and complete_guest_profile are isolated by auth.uid()',
    () async {
      final clientA = SupabaseClient(_url, _publishableKey);
      final clientB = SupabaseClient(_url, _publishableKey);
      final anonymous = SupabaseClient(_url, _publishableKey);

      await _signIn(clientA, _phoneA, _otpA);
      await _signIn(clientB, _phoneB, _otpB);
      final idB = clientB.auth.currentUser!.id;
      final beforeB = await clientB
          .from('profiles')
          .select('id,full_name,accepted_terms_version,accepted_terms_at')
          .eq('id', idB)
          .single();

      final rowsVisibleToA = await clientA
          .from('profiles')
          .select('id')
          .eq('id', idB);
      expect(rowsVisibleToA, isEmpty);

      final config = await clientA
          .from('app_config')
          .select('current_terms_version')
          .limit(1)
          .single();
      await clientA.rpc<void>(
        'complete_guest_profile',
        params: {
          'full_name': 'Isolation Account A',
          'terms_version': config['current_terms_version'],
        },
      );

      final afterB = await clientB
          .from('profiles')
          .select('id,full_name,accepted_terms_version,accepted_terms_at')
          .eq('id', idB)
          .single();
      expect(afterB, beforeB);

      final anonymousRows = await anonymous.from('profiles').select('id');
      expect(anonymousRows, isEmpty);

      await clientA.auth.signOut();
      await clientB.auth.signOut();
      await clientA.dispose();
      await clientB.dispose();
      await anonymous.dispose();
    },
    skip: [
      _url,
      _publishableKey,
      _phoneA,
      _otpA,
      _phoneB,
      _otpB,
    ].any((value) => value.isEmpty),
  );
}

Future<void> _signIn(SupabaseClient client, String phone, String otp) async {
  await client.auth.signInWithOtp(phone: phone, shouldCreateUser: false);
  await client.auth.verifyOTP(phone: phone, token: otp, type: OtpType.sms);
}
