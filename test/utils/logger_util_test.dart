import 'package:flutter_test/flutter_test.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

void main() {
  test('secrets never reach the log, at any depth', () {
    final redacted = BatasphLogger.redactSecrets({
      'email': 'chris@example.com',
      'password': 'hunter2',
      'clientSecret': 'ek_123',
      'session': {
        'token': 'jwt',
        'user': {'name': 'Chris'},
      },
      'items': [
        {'code': '123456', 'savedName': 'Chris'},
      ],
    });
    expect(redacted, {
      'email': 'chris@example.com',
      'password': '***',
      'clientSecret': '***',
      'session': {
        'token': '***',
        'user': {'name': 'Chris'},
      },
      'items': [
        {'code': '***', 'savedName': 'Chris'},
      ],
    });
  });

  test('non-map bodies pass through', () {
    expect(BatasphLogger.redactSecrets('plain'), 'plain');
    expect(BatasphLogger.redactSecrets(null), isNull);
  });
}
