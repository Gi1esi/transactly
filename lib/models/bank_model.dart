class Bank {
  int? bankId;
  String name;
  String? longName;
  String smsAddressBox;

  Bank({this.bankId, required this.name, this.longName, required this.smsAddressBox});

  Map<String, dynamic> toMap() {
    return {
      'bank_id': bankId,
      'name': name,
      'long_name': longName,
      'sms_address_box': smsAddressBox,
    };
  }

  factory Bank.fromMap(Map<String, dynamic> map) {
    return Bank(
      bankId: map['bank_id'],
      name: map['name'],
      longName: map['long_name'],
      smsAddressBox: map['sms_address_box'],
    );
  }
}
