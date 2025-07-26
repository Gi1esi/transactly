import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  String account;

  @HiveField(1)
  String type;

  @HiveField(2)
  double amount;

  @HiveField(3)
  bool isDebit;

  @HiveField(4)
  String counterAccount;

  @HiveField(5)
  DateTime dateTime;

  @HiveField(6)
  String description;

  @HiveField(7)
  String reference;

  Transaction({
    required this.account,
    required this.type,
    required this.amount,
    required this.isDebit,
    required this.counterAccount,
    required this.dateTime,
    required this.description,
    required this.reference,
  });
}

Transaction? parseSms(String sms) {
  try {
    final accountReg = RegExp(r'Acc:\s*(\d{10})');
    final amountReg = RegExp(r'MWK([\d,]+\.\d{2})(DR|CR)');
    final toAcctReg = RegExp(r'To Acct:\s*(\d{10})');
    final dateReg = RegExp(r'Date/Time:\s*([\d/]+\s[\d:]+)');
    final descReg = RegExp(r'Desc:\s*([\w\s\.]+)');
    final refReg = RegExp(r'Ref:\s*([^\n]+)');

    final account = accountReg.firstMatch(sms)?.group(1) ?? '';
    final amountMatch = amountReg.firstMatch(sms);
    final amountStr = amountMatch?.group(1)?.replaceAll(',', '') ?? '0';
    final amount = double.parse(amountStr);
    final isDebit = amountMatch?.group(2) == 'DR';
    final counterAccount = toAcctReg.firstMatch(sms)?.group(1) ?? '';
    final dateString = dateReg.firstMatch(sms)?.group(1) ?? '';
    final description = descReg.firstMatch(sms)?.group(1)?.trim() ?? '';
    final reference = refReg.firstMatch(sms)?.group(1)?.trim() ?? '';

    final dateParts = dateString.split(' ');
    final date = dateParts[0];
    final time = dateParts[1];

    final dateTime = DateTime.parse(
      '20${date.split('/')[2]}-${date.split('/')[1]}-${date.split('/')[0]}T$time:00',
    );

    return Transaction(
      account: account,
      type: 'Funds Transfer',
      amount: amount,
      isDebit: isDebit,
      counterAccount: counterAccount,
      dateTime: dateTime,
      description: description,
      reference: reference,
    );
  } catch (e) {
    print('Failed to parse SMS: $e');
    return null;
  }
}

