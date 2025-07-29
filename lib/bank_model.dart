
class Bank {
  int? bankId;
  String name;
  String smsAddressBox;

  Bank({this.bankId, required this.name, required this.smsAddressBox});

  Map<String, dynamic> toMap() {
    return {
      'bank_id': bankId,
      'name': name,
      'sms_address_box': smsAddressBox,
    };
  }

  factory Bank.fromMap(Map<String, dynamic> map) {
    return Bank(
      bankId: map['bank_id'],
      name: map['name'],
      smsAddressBox: map['sms_address_box'],
    );
  }
}
