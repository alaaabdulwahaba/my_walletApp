import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/card_model.dart';
import '../models/transaction_model.dart';
import '../utils/app_colors.dart';
import '../utils/card_icons.dart';

class CardDetailScreen extends StatefulWidget {
  final CardModel card;

  CardDetailScreen({required this.card});

  @override
  _CardDetailScreenState createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  final DbHelper _dbHelper = DbHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Card Details", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<TransactionModel>>(
        future: widget.card.id != null ? _dbHelper.getTransactionsByCardId(widget.card.id!) : Future.value([]),
        builder: (context, transactionSnapshot) {
          // Calculate card balance from transactions
          double cardBalance = widget.card.balance;
          if (transactionSnapshot.hasData && widget.card.id != null) {
            for (var transaction in transactionSnapshot.data!) {
              if (transaction.type == "Income") {
                cardBalance += transaction.amount;
              } else {
                cardBalance -= transaction.amount;
              }
            }
          }

          return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card Display
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.card.cardType,
                                style: const TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                              Row(
                                children: [
                                  Icon(CardIcons.getCardIcon(widget.card.cardType), color: Colors.white70),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.wifi, color: Colors.white70),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            widget.card.cardNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Card Balance: \$${cardBalance.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Total Balance
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Total Balance",
                            style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                          ),
                          const SizedBox(height: 5),
                          FutureBuilder<List<CardModel>>(
                            future: _dbHelper.getAllCards(),
                            builder: (context, cardsSnapshot) {
                              return FutureBuilder<List<TransactionModel>>(
                                future: _dbHelper.getAllTransactions(),
                                builder: (context, allTxSnapshot) {
                                  double total = 0.0;
                                  if (cardsSnapshot.hasData && allTxSnapshot.hasData) {
                                    // Sum all card initial balances
                                    for (var card in cardsSnapshot.data!) {
                                      total += card.balance;
                                    }
                                    // Add/subtract all transactions
                                    for (var tx in allTxSnapshot.data!) {
                                      if (tx.type == "Income") {
                                        total += tx.amount;
                                      } else {
                                        total -= tx.amount;
                                      }
                                    }
                                  }
                                  return Text(
                                    "\$${total.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "including cash transactions",
                            style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Transactions
                    Text(
                      "Card Transactions",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (!transactionSnapshot.hasData)
                      const Center(child: CircularProgressIndicator())
                    else if (transactionSnapshot.data!.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          "No transactions for this card yet.",
                          style: TextStyle(color: AppColors.textGrey),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: transactionSnapshot.data!.length,
                        itemBuilder: (context, index) {
                          var item = transactionSnapshot.data![index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(0.2),
                                child: Icon(
                                  item.type == "Income" ? Icons.arrow_downward : Icons.arrow_upward,
                                  color: AppColors.primary,
                                ),
                              ),
                              title: Text(
                                item.category,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.date,
                                    style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.card.cardNumber,
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                "${item.type == 'Expense' ? '- ' : '+ '}\$${item.amount.toStringAsFixed(2)}",
                                style: TextStyle(
                                  color: item.type == "Income" ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
        },
      ),
    );
  }
}



