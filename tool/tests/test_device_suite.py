import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
INTEGRATION = ROOT / "integration_test"
SUITE = INTEGRATION / "device_suite_test.dart"
EXCLUDED = {"device_suite_test.dart", "results_scroll_perf_test.dart"}


class DeviceSuiteTest(unittest.TestCase):
    def test_suite_imports_every_non_performance_integration_target(self):
        source = SUITE.read_text(encoding="utf-8")
        imported = set(re.findall(r"import '([^']+_test\.dart)'", source))
        expected = {
            path.name
            for path in INTEGRATION.glob("*_test.dart")
            if path.name not in EXCLUDED
        }
        self.assertEqual(imported, expected)

    def test_device_scripts_run_only_the_aggregated_target(self):
        for name in ("android_device_check.sh", "ios_device_check.sh"):
            with self.subTest(script=name):
                source = (ROOT / "tool" / "ci" / name).read_text(encoding="utf-8")
                self.assertIn("integration_test/device_suite_test.dart", source)
                self.assertNotIn("integration_targets=()", source)

    def test_device_journeys_never_override_the_native_viewport(self):
        checked = list(INTEGRATION.glob("*.dart"))
        checked.extend(
            path
            for path in (ROOT / "test" / "helpers").glob("*.dart")
            if path.name != "pump_until_found.dart"
        )
        for path in checked:
            with self.subTest(path=path.relative_to(ROOT)):
                source = path.read_text(encoding="utf-8")
                self.assertNotIn("tester.view.physicalSize", source)
                self.assertNotIn("tester.view.devicePixelRatio", source)


if __name__ == "__main__":
    unittest.main()
