import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/db_helper.dart';
import '../models/transaction_model.dart';
import '../models/card_model.dart';
import '../utils/app_colors.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatefulWidget {
  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  DbHelper db = DbHelper();
  String selectedPeriod = "Week";
  List<TransactionModel> allTransactions = [];
  List<TransactionModel> filteredTransactions = [];
  Map<String, double> aggregatedData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    List<TransactionModel> data = await db.getAllTransactions();
    setState(() {
      allTransactions = data;
      _filterData();
    });
  }

  void _filterData() {
    DateTime now = DateTime.now();
    List<TransactionModel> filtered = allTransactions.where((item) {
      try {
        DateTime itemDate = DateTime.parse(item.date);
        if (selectedPeriod == "Day") {
          return itemDate.day == now.day && itemDate.month == now.month && itemDate.year == now.year;
        } else if (selectedPeriod == "Week") {
          DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));
          return itemDate.isAfter(weekStart.subtract(const Duration(days: 1))) && itemDate.isBefore(now.add(const Duration(days: 1)));
        } else if (selectedPeriod == "Month") {
          return itemDate.month == now.month && itemDate.year == now.year;
        } else if (selectedPeriod == "Year") {
          return itemDate.year == now.year;
        }
        return true;
      } catch (e) {
        return false;
      }
    }).toList();

    setState(() {
      filteredTransactions = filtered;
    });
    _aggregateData();
  }

  Future<void> _aggregateData() async {
    aggregatedData.clear();
    
    // Get all cards and transactions for total balance calculation
    List<CardModel> allCards = await db.getAllCards();
    double initialCardBalance = 0.0;
    for (var card in allCards) {
      initialCardBalance += card.balance;
    }
    
    // Calculate starting balance: initial card balances + all transactions before the filtered period
    DateTime now = DateTime.now();
    DateTime periodStart = now;
    
    if (selectedPeriod == "Day") {
      periodStart = DateTime(now.year, now.month, now.day);
    } else if (selectedPeriod == "Week") {
      periodStart = now.subtract(Duration(days: now.weekday - 1));
      periodStart = DateTime(periodStart.year, periodStart.month, periodStart.day);
    } else if (selectedPeriod == "Month") {
      periodStart = DateTime(now.year, now.month, 1);
    } else if (selectedPeriod == "Year") {
      periodStart = DateTime(now.year, 1, 1);
    }
    
    // Add transactions before the period to get starting balance
    double startingBalance = initialCardBalance;
    for (var transaction in allTransactions) {
      try {
        DateTime txDate = DateTime.parse(transaction.date);
        if (txDate.isBefore(periodStart)) {
          if (transaction.type == "Income") {
            startingBalance += transaction.amount;
          } else {
            startingBalance -= transaction.amount;
          }
        }
      } catch (e) {
        continue;
      }
    }
    
    if (filteredTransactions.isEmpty) {
      setState(() {});
      return;
    }

    // Sort filtered transactions by date
    List<TransactionModel> sortedTransactions = List.from(filteredTransactions);
    sortedTransactions.sort((a, b) {
      try {
        return DateTime.parse(a.date).compareTo(DateTime.parse(b.date));
      } catch (e) {
        return 0;
      }
    });
    
    // Calculate cumulative balance over time
    double runningBalance = startingBalance;
    Map<String, double> balanceByKey = {};
    
    for (var transaction in sortedTransactions) {
      try {
        DateTime date = DateTime.parse(transaction.date);
        String key = "";
        
        if (selectedPeriod == "Day") {
          key = DateFormat('HH:00').format(date);
        } else if (selectedPeriod == "Week") {
          key = DateFormat('EEE').format(date);
        } else if (selectedPeriod == "Month") {
          key = DateFormat('MMM dd').format(date);
        } else if (selectedPeriod == "Year") {
          key = DateFormat('MMM').format(date);
        }
        
        if (transaction.type == "Income") {
          runningBalance += transaction.amount;
        } else {
          runningBalance -= transaction.amount;
        }
        
        // Store the cumulative balance for this time period (keep the latest value for each period)
        balanceByKey[key] = runningBalance;
      } catch (e) {
        continue;
      }
    }
    
    aggregatedData = balanceByKey;
    setState(() {});
  }

  List<FlSpot> _getChartSpots() {
    if (aggregatedData.isEmpty) {
      return [FlSpot(0, 0)];
    }
    
    List<FlSpot> spots = [];
    List<String> keys = aggregatedData.keys.toList()..sort();
    
    for (int i = 0; i < keys.length; i++) {
      spots.add(FlSpot(i.toDouble(), aggregatedData[keys[i]]!));
    }
    
    return spots;
  }

  List<String> _getChartLabels() {
    if (aggregatedData.isEmpty) {
      return [];
    }
    
    List<String> keys = aggregatedData.keys.toList()..sort();
    return keys;
  }

  double _getMaxValue() {
    if (aggregatedData.isEmpty) return 100;
    double max = aggregatedData.values.reduce((a, b) => a > b ? a : b);
    return max > 0 ? max : 100;
  }

  double _getMinValue() {
    if (aggregatedData.isEmpty) return 0;
    double min = aggregatedData.values.reduce((a, b) => a < b ? a : b);
    return min < 0 ? min * 1.1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Statistics", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Period filter buttons
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ["Day", "Week", "Month", "Year"].map((e) {
                  bool isSelected = selectedPeriod == e;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedPeriod = e;
                          _filterData();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          e,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 30),
            // Chart with proper aggregation
            AspectRatio(
              aspectRatio: 1.7,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _getMaxValue() / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          List<String> labels = _getChartLabels();
                          if (value.toInt() >= 0 && value.toInt() < labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                labels[value.toInt()],
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${value.toInt()}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getChartSpots(),
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: AppColors.primary,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: false,
                      ),
                    ),
                  ],
                  minY: _getMinValue(),
                  maxY: _getMaxValue() * 1.1,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Total Balance
            FutureBuilder<List<CardModel>>(
              future: db.getAllCards(),
              builder: (context, cardsSnapshot) {
                return FutureBuilder<List<TransactionModel>>(
                  future: db.getAllTransactions(),
                  builder: (context, allTxSnapshot) {
                    double totalBalance = 0.0;
                    if (cardsSnapshot.hasData && allTxSnapshot.hasData) {
                      // Sum all card initial balances
                      for (var card in cardsSnapshot.data!) {
                        totalBalance += card.balance;
                      }
                      // Add/subtract all transactions (including cash)
                      for (var tx in allTxSnapshot.data!) {
                        if (tx.type == "Income") {
                          totalBalance += tx.amount;
                        } else {
                          totalBalance -= tx.amount;
                        }
                      }
                    }
                    return Container(
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
                          Text(
                            "\$${totalBalance.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "including cash transactions",
                            style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Transactions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    "${filteredTransactions.length} items",
                    style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Filtered transactions list
            Expanded(
              child: filteredTransactions.isEmpty
                  ? Center(
                      child: Text(
                        "No transactions for this period",
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        var item = filteredTransactions[index];
                        return _item(
                          item.category,
                          item.date,
                          "${item.type == "Income" ? "+" : "-"} \$${item.amount.toStringAsFixed(2)}",
                          item.type == "Income" ? Colors.green : Colors.red,
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }

  Widget _item(String title, String date, String price, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.2),
          child: Icon(Icons.receipt_long, size: 20, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
        ),
        subtitle: Text(
          date,
          style: TextStyle(fontSize: 12, color: AppColors.textGrey),
        ),
        trailing: Text(
          price,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }
}

