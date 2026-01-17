class CardModel {
  int? id;
  String cardNumber;
  String pin;
  String holderName;
  double balance; // Card balance
  String cardType; // Normal Bank Card, Trading Card, Visa Card

  CardModel({
    this.id,
    required this.cardNumber,
    required this.pin,
    this.holderName = '',
    this.balance = 0.0,
    required this.cardType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cardNumber': cardNumber,
      'pin': pin,
      'holderName': holderName,
      'balance': balance,
      'cardType': cardType,
    };
  }

  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      id: map['id'],
      cardNumber: map['cardNumber'],
      pin: map['pin'],
      holderName: map['holderName'] ?? '',
      balance: (map['balance'] ?? 0.0) is double ? map['balance'] : (map['balance'] ?? 0.0).toDouble(),
      cardType: map['cardType'] ?? 'Normal Bank Card',
    );
  }
}