import 'package:flutter/material.dart';

class CardIcons {
  static IconData getCardIcon(String cardType) {
    switch (cardType) {
      case 'Visa Card':
        return Icons.credit_card; 
      case 'Normal Bank Card':
        return Icons.account_balance; 
      case 'Trading Card':
        return Icons.trending_up; 
      default:
        return Icons.credit_card;
    }
  }
}

