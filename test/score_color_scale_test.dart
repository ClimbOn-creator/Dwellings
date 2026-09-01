import 'package:dwelling_iq/theme/score_color_scale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('score color runs red through orange to green from 1 to 99', () {
    expect(scoreColor(1), scoreRed);
    expect(scoreColor(50), scoreOrange);
    expect(scoreColor(99), scoreGreen);
    expect(scoreColor(-20), scoreRed);
    expect(scoreColor(120), scoreGreen);
    expect(scoreColor(25), isNot(anyOf(scoreRed, scoreOrange)));
    expect(scoreColor(75), isNot(anyOf(scoreOrange, scoreGreen)));
  });
}
