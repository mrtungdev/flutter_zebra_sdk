import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// import 'package:flutter_zebra_sdk/flutter_zebra_sdk.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_zebra_sdk');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });
}
