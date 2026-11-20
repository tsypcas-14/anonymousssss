import 'package:flutter_test/flutter_test.dart';
import 'package:smartfarm/ui.dart';

void main() {
  test('numbers become the words of the design', () {
    expect(tankPhrase(2.5, 41, false), 'Water for 2 and a half days');
    expect(tankPhrase(4.1, 41, false), 'Water for 4 days');
    expect(tankPhrase(null, 10, true), 'Empty: the pump is stopped');
    expect(soilWord(420), 'Well watered');
    expect(soilWord(630), 'A bit dry');
    expect(soilWord(700), 'Dry');
    expect(soilWord(null), 'No news');
  });
}
