import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/transaction_model.dart';
import '../models/card_model.dart';
import '../utils/app_colors.dart';

class TransactionScreen extends StatefulWidget {
  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedType = "Expense";
  String _selectedPaymentMethod = "Cash";
  CardModel? _selectedCard;

  final DbHelper _dbHelper = DbHelper();
  List<CardModel> _cards = [];
  final List<String> _paymentMethods = ["Cash", "Visa Card", "Bank Card", "Trading Card"];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    List<CardModel> cards = await _dbHelper.getAllCards();
    setState(() {
      _cards = cards;
    });
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_categoryController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Category and amount are required")),
      );
      return;
    }

    double? amount = double.tryParse(_amountController.text);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount")),
      );
      return;
    }

    try {
      int? cardId;

      // If a card is selected, get its ID (but don't update balance - it will be calculated dynamically)
      if (_selectedCard != null && _selectedPaymentMethod != "Cash") {
        cardId = _selectedCard!.id;
      }

      // Save transaction (card balance will be calculated dynamically from initial balance + transactions)
      await _dbHelper.insertTransaction(TransactionModel(
        category: _categoryController.text.trim(),
        note: _noteController.text.trim(),
        amount: amount,
        type: _selectedType,
        date: DateTime.now().toString().split(' ')[0],
        cardId: cardId,
        paymentMethod: _selectedPaymentMethod,
      ));

      // Clear form
      _categoryController.clear();
      _amountController.clear();
      _noteController.clear();
      setState(() {
        _selectedCard = null;
        _selectedPaymentMethod = "Cash";
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Transaction saved successfully!")),
      );
      
      if (!mounted) return;
      Navigator.pop(context, true); // Return to home screen
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving transaction: $e")),
      );
    }
  }

  void _onPaymentMethodChanged(String? value) {
    setState(() {
      _selectedPaymentMethod = value ?? "Cash";
      _selectedCard = null; // Reset selected card when payment method changes
    });
  }

  List<CardModel> _getFilteredCards() {
    if (_selectedPaymentMethod == "Cash") {
      return [];
    }

    // Filter cards based on payment method
    String cardTypeFilter = "";
    if (_selectedPaymentMethod == "Visa Card") {
      cardTypeFilter = "Visa Card";
    } else if (_selectedPaymentMethod == "Bank Card") {
      cardTypeFilter = "Normal Bank Card";
    } else if (_selectedPaymentMethod == "Trading Card") {
      cardTypeFilter = "Trading Card";
    }

    if (cardTypeFilter.isEmpty) {
      return _cards;
    }

    return _cards.where((card) => card.cardType == cardTypeFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Add Transaction", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // CHANGED FROM TextField TO TextFormField
                    TextFormField(
                      controller: _categoryController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Category",
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.category, color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.accent,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Category is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    // CHANGED FROM TextField TO TextFormField
                    TextFormField(
                      controller: _amountController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Amount",
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.attach_money, color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.accent,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Amount is required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    // Note doesn't require validation, so TextField is fine, but TextFormField is consistent
                    TextFormField(
                      controller: _noteController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Note / Explain",
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.note, color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.accent,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 15),
                    // Transaction Type
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedType,
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white),
                          dropdownColor: AppColors.surface,
                          items: ["Income", "Expense"].map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e, style: const TextStyle(color: Colors.white)),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedType = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Payment Method
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPaymentMethod,
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white),
                          dropdownColor: AppColors.surface,
                          items: _paymentMethods.map((method) => DropdownMenuItem(
                            value: method,
                            child: Text(method, style: const TextStyle(color: Colors.white)),
                          )).toList(),
                          onChanged: _onPaymentMethodChanged,
                        ),
                      ),
                    ),
                    // Card Selection (only if payment method is not Cash)
                    if (_selectedPaymentMethod != "Cash" && _getFilteredCards().isNotEmpty) ...[
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<CardModel?>(
                            value: _selectedCard,
                            isExpanded: true,
                            style: const TextStyle(color: Colors.white),
                            dropdownColor: AppColors.surface,
                            hint: const Text("Select Card", style: TextStyle(color: Colors.grey)),
                            items: _getFilteredCards().map((card) => DropdownMenuItem(
                              value: card,
                              child: Text(
                                "${card.cardNumber} (Balance: \$${card.balance.toStringAsFixed(2)})",
                                style: const TextStyle(color: Colors.white),
                              ),
                            )).toList(),
                            onChanged: (card) => setState(() => _selectedCard = card),
                          ),
                        ),
                      ),
                    ],
                    if (_selectedPaymentMethod != "Cash" && _getFilteredCards().isEmpty) ...[
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "No ${_selectedPaymentMethod} available. Please add a card first.",
                                style: const TextStyle(color: Colors.orange, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                        onPressed: _saveTransaction,
                        child: const Text(
                          "Save Transaction",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}