import 'package:flutter/services.dart';

const platform = MethodChannel('sms_watcher');

Future<void> startListening() async {
  await platform.invokeMethod('startSmsListener');
}

Future<void> stopListening() async {
  await platform.invokeMethod('stopSmsListener');
}

Future<List<Map<String, dynamic>>> getSmsMessages(
  String address,
  int sinceTimestamp,
) async {
  final List<dynamic> result = await platform.invokeMethod(
    'getSmsMessages',
    {
      'address': address,
      'since': sinceTimestamp,
    },
  );
  return List<Map<String, dynamic>>.from(result);
}

Future<List<Map<String, dynamic>>> getSmsMessagesInRange(
  String address,
  int start,
  int end,
) async {
  final List<dynamic> result = await platform.invokeMethod(
    'getSmsMessagesInRange',
    {
      'address': address,
      'startDate': start,
      'endDate': end,
    },
  );
  return List<Map<String, dynamic>>.from(result);
}
