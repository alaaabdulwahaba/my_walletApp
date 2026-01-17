import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/card_model.dart';
import '../utils/app_colors.dart';
import 'card_detail_screen.dart';

class CardsScreen extends StatefulWidget {
  @override
  _CardsScreenState createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final DbHelper _dbHelper = DbHelper();
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _pinController = TextEditingController();
  final _initialValueController = TextEditingController();
  
  String _selectedCardType = 'Normal Bank Card';
  final List<String> _cardTypes = [
    'Normal Bank Card',
    'Trading Card',
    'Visa Card',
  ];

  @override
  void dispose() {
    _cardNumberController.dispose();
    _pinController.dispose();
    _initialValueController.dispose();
    super.dispose();
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_cardNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter card number')),
      );
      return;
    }

    double initialValue = 0.0;
    if (_initialValueController.text.isNotEmpty) {
      initialValue = double.tryParse(_initialValueController.text) ?? 0.0;
    }

    try {
      CardModel card = CardModel(
        cardNumber: _cardNumberController.text.trim(),
        pin: _pinController.text.trim(),
        balance: initialValue,
        cardType: _selectedCardType,
      );

      await _dbHelper.insertCard(card);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card saved successfully!')),
      );

      // Clear form
      _cardNumberController.clear();
      _pinController.clear();
      _initialValueController.clear();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving card: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Cards", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Add Card Form
            Text(
              "Add New Card",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 15),
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextField(
                        controller: _cardNumberController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Card Number",
                          labelStyle: const TextStyle(color: Colors.grey),
                          hintText: "XXXX XXXX XXXX XXXX",
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.credit_card, color: AppColors.primary),
                          filled: true,
                          fillColor: AppColors.accent,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _pinController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Secret PIN",
                          labelStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.lock, color: AppColors.primary),
                          filled: true,
                          fillColor: AppColors.accent,
                        ),
                        keyboardType: TextInputType.number,
                        obscureText: true,
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _initialValueController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Initial Card Value",
                          labelStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.attach_money, color: AppColors.primary),
                          filled: true,
                          fillColor: AppColors.accent,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCardType,
                            isExpanded: true,
                            style: const TextStyle(color: Colors.white),
                            dropdownColor: AppColors.surface,
                            items: _cardTypes.map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type, style: const TextStyle(color: Colors.white)),
                            )).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCardType = value!;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _saveCard,
                          child: const Text("Save Card", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Existing Cards
            Text(
              "Your Cards",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 15),
            FutureBuilder<List<CardModel>>(
              future: _dbHelper.getAllCards(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      "No cards added yet.",
                      style: TextStyle(color: AppColors.textGrey),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final card = snapshot.data![index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      child: Card(
                        color: AppColors.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          leading: Icon(Icons.credit_card, color: AppColors.primary, size: 32),
                          title: Text(
                            card.cardNumber,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.cardType,
                                style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                              ),
                              Text(
                                "Balance: \$${card.balance.toStringAsFixed(2)}",
                                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: AppColors.surface,
                                      title: const Text("Delete Card", style: TextStyle(color: Colors.white)),
                                      content: Text(
                                        "Are you sure you want to delete card ${card.cardNumber}? This action cannot be undone.",
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: Text("Cancel", style: TextStyle(color: AppColors.textGrey)),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true && card.id != null) {
                                    await _dbHelper.deleteCard(card.id!);
                                    setState(() {});
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Card deleted successfully")),
                                      );
                                    }
                                  }
                                },
                              ),
                              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CardDetailScreen(card: card),
                              ),
                            ).then((value) => setState(() {}));
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}



