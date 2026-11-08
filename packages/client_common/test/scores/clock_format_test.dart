import "package:another_mine_common/scores/clock_format.dart";
import "package:test/test.dart";

void main() {
  group("formatClock", () {
    test("shows hours and minutes", () {
      expect(formatClock(DateTime(2026, 11, 7, 13, 42, 59)), "13:42");
    });

    test("pads the parts and uses a 24 hour clock", () {
      expect(formatClock(DateTime(2026, 1, 2, 3, 4)), "03:04");
      expect(formatClock(DateTime(2026, 1, 2, 23, 5)), "23:05");
    });

    test("shows a moment in UTC in local time", () {
      final DateTime utc = DateTime.utc(2026, 11, 7, 13, 42);

      expect(formatClock(utc), formatClock(utc.toLocal()));
    });
  });

  group("formatFullTime", () {
    test("shows the date and time to the second", () {
      expect(
        formatFullTime(DateTime(2026, 11, 7, 13, 42, 9)),
        "2026-11-07 13:42:09",
      );
    });

    test("pads every part", () {
      expect(
        formatFullTime(DateTime(2026, 1, 2, 3, 4, 5)),
        "2026-01-02 03:04:05",
      );
    });
  });

  group("formatDay", () {
    test("shows the weekday, month and day", () {
      expect(formatDay(DateTime(2026, 11, 7)), "Sat, Nov 7");
      expect(formatDay(DateTime(2026, 1, 5)), "Mon, Jan 5");
      expect(formatDay(DateTime(2026, 12, 31)), "Thu, Dec 31");
    });
  });
}
