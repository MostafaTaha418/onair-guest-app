// One device entrypoint keeps Flutter/Xcode from rebuilding the application
// once per integration file. Each imported main still registers its original
// tests and setup/teardown hooks.
import 'account_settings_mock_test.dart' as account_settings;
import 'booking_isolation_test.dart' as booking_isolation;
import 'booking_journey_mock_test.dart' as booking_journey;
import 'booking_outcomes_staging_test.dart' as booking_outcomes;
import 'booking_payment_staging_test.dart' as booking_payment;
import 'delete_account_mock_test.dart' as delete_account;
import 'discovery_journey_test.dart' as discovery_journey;
import 'discovery_rules_test.dart' as discovery_rules;
import 'email_register_phone_mock_test.dart' as email_register_phone;
import 'isolation_test.dart' as profile_isolation;
import 'phone_otp_limits_mock_test.dart' as phone_otp_limits;
import 'sign_out_test.dart' as sign_out;
import 'social_sign_in_mock_test.dart' as social_sign_in;
import 'stay_journey_mock_test.dart' as stay_journey;
import 'stay_staging_test.dart' as stay_staging;
import 'support_case_mock_test.dart' as support_case;
import 'support_isolation_staging_test.dart' as support_isolation;

void main() {
  account_settings.main();
  booking_isolation.main();
  booking_journey.main();
  booking_outcomes.main();
  booking_payment.main();
  delete_account.main();
  discovery_journey.main();
  discovery_rules.main();
  email_register_phone.main();
  profile_isolation.main();
  phone_otp_limits.main();
  sign_out.main();
  social_sign_in.main();
  stay_journey.main();
  stay_staging.main();
  support_case.main();
  support_isolation.main();
}
