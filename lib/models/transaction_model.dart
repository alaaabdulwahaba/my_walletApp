class TransactionModel {
  int? id;
  String category;
  String note;
  double amount;
  String type; // Income or Expense
  String date;
  int? cardId; // ID of card used (null for Cash)
  String paymentMethod; // Cash, Visa Card, Bank Card, Trading Card

  TransactionModel({
    this.id,
    required this.category,
    required this.note,
    required this.amount,
    required this.type,
    required this.date,
    this.cardId,
    required this.paymentMethod,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'note': note,
      'amount': amount,
      'type': type,
      'date': date,
      'cardId': cardId,
      'paymentMethod': paymentMethod,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      category: map['category'],
      note: map['note'],
      amount: (map['amount'] ?? 0.0) is double ? map['amount'] : (map['amount'] ?? 0.0).toDouble(),
      type: map['type'],
      date: map['date'],
      cardId: map['cardId'],
      paymentMethod: map['paymentMethod'] ?? 'Cash',
    );
  }
}