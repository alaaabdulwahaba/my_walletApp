import 'package:flutter/material.dart';
import 'package:wallet_app/database/db_helper.dart';
import 'package:wallet_app/models/transaction_model.dart';
import 'package:wallet_app/models/card_model.dart';
import 'package:wallet_app/utils/app_colors.dart';
import 'package:wallet_app/screens/transaction_screen.dart';
import 'package:wallet_app/screens/card_detail_screen.dart';
import 'package:wallet_app/utils/card_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DbHelper db = DbHelper();
  String _userName = 'User';
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadNotificationsState();
  }

  Future<void> _loadUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'User';
    });
  }

  Future<void> _loadNotificationsState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadNotificationsState(); // Reload when returning to this screen
  }

  // دالة لحساب الرصيد الإجمالي
  Future<double> _calculateTotalBalance() async {
    double total = 0.0;
    
    // Add all card initial balances
    List<CardModel> cards = await db.getAllCards();
    for (var card in cards) {
      total += card.balance;
    }
    
    // Add all transactions (including cash)
    List<TransactionModel> transactions = await db.getAllTransactions();
    for (var transaction in transactions) {
      if (transaction.type == "Income") {
        total += transaction.amount;
      } else {
        total -= transaction.amount;
      }
    }
    
    return total;
  }

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    if (transaction.id != null) {
      await db.deleteTransaction(transaction.id!);
      setState(() {}); // Refresh the screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<List<TransactionModel>>(
        future: db.getAllTransactions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // 1. Header with user name
              _buildHeader(),

              // 2. Cards Section (vertical layout)
              Expanded(
                flex: 3,
                child: _buildCardsSection(),
              ),

              // 3. Total Balance (moved below cards)
              FutureBuilder<double>(
                future: _calculateTotalBalance(),
                builder: (context, balanceSnapshot) {
                  if (!balanceSnapshot.hasData) {
                    return const SizedBox(height: 80);
                  }
                  return _buildTotalBalance(balanceSnapshot.data!);
                },
              ),

              // 4. Transactions title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Transactions",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.textMain,
                      ),
                    ),
                    Text(
                      "See all",
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
              ),

              // 5. Transactions list
              Expanded(
                flex: 4,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    var item = snapshot.data![index];
                    return _buildTransactionItem(item);
                  },
                ),
              )
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => TransactionScreen()),
        ).then((value) {
          setState(() {});
          _loadUserName(); // Reload user name in case it was updated
        }),
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- Cards Section (Vertical Layout) ---
  Widget _buildCardsSection() {
    return FutureBuilder<List<CardModel>>(
      future: db.getAllCards(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                "No cards added. Go to Cards to add one.",
                style: TextStyle(color: AppColors.textGrey),
              ),
            ),
          );
        }

        return ListView.builder(
          scrollDirection: Axis.vertical,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final card = snapshot.data![index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CardDetailScreen(card: card),
                  ),
                ).then((value) => setState(() {}));
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 15),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        card.cardType,
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      Row(
                        children: [
                          Icon(CardIcons.getCardIcon(card.cardType), color: Colors.white70, size: 20),
                          const SizedBox(width: 10),
                          const Icon(Icons.wifi, color: Colors.white70),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    card.cardNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "CARD HOLDER",
                            style: TextStyle(color: Colors.white60, fontSize: 10),
                          ),
                          Text(
                            _userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "PIN",
                            style: TextStyle(color: Colors.white60, fontSize: 10),
                          ),
                          Text(
                            "****",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            );
          },
        );
      },
    );
  }

  // --- Header with User Name ---
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.background,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Good afternoon,",
                style: TextStyle(color: AppColors.textGrey, fontSize: 14),
              ),
              Text(
                _userName,
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              // Navigate to settings to toggle notifications
            },
            child: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.surface,
                  child: Icon(
                    _notificationsEnabled ? Icons.notifications : Icons.notifications_off,
                    color: _notificationsEnabled ? AppColors.primary : Colors.grey,
                  ),
                ),
                if (!_notificationsEnabled)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 30,
                          height: 2,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Total Balance (Below Cards) ---
  Widget _buildTotalBalance(double balance) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            "Total Balance",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 5),
          Text(
            "\$ ${balance.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- Transaction Item with Delete ---
  Widget _buildTransactionItem(TransactionModel item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.date,
              style: TextStyle(color: AppColors.textGrey),
            ),
            const SizedBox(height: 2),
            FutureBuilder<CardModel?>(
              future: item.cardId != null ? db.getCardById(item.cardId!) : Future.value(null),
              builder: (context, cardSnapshot) {
                if (item.cardId == null) {
                  return Text(
                    "Cash",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }
                if (!cardSnapshot.hasData) {
                  return Text(
                    "Loading...",
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 11,
                    ),
                  );
                }
                return Text(
                  cardSnapshot.data?.cardNumber ?? "Cash",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ],
        ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "${item.type == 'Expense' ? '- ' : '+ '}\$${item.amount.toStringAsFixed(2)}",
            style: TextStyle(
              color: item.type == "Income" ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text("Delete Transaction", style: TextStyle(color: Colors.white)),
                  content: Text("Are you sure you want to delete ${item.category}?", style: const TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel", style: TextStyle(color: AppColors.textGrey)),
                    ),
                    TextButton(
                      onPressed: () {
                        _deleteTransaction(item);
                        Navigator.pop(context);
                      },
                      child: const Text("Delete", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      ),
    );
  }
}