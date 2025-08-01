import '../database_helper.dart';

Future<void> insertDummyData() async {
  final db = DatabaseHelper.instance;

  // Insert user: Grace Gausi
  final userId = await db.insert('users', {
    'first_name': 'Grace',
    'last_name': 'Gausi',
  });

  // Insert bank: NBM with sms_address_box 626626
  final bankId = await db.insert('banks', {
    'name': 'NBM',
    'sms_address_box': '626626',
  });

  // Insert account: account_number 1007135544 linked to userId and bankId
  await db.insert('accounts', {
    'account_number': '1007135544',
    'bank': bankId,
    'user': userId,
  });

  // Insert category: Meals, expense, icon_key and color_hex arbitrary
  await db.insert('categories', {
    'name': 'Meals',
    'type': 'expense',
    'icon_key': 'food_icon',      
    'color_hex': '#FF6347',       
  });
}
