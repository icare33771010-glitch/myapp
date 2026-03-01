import 'package:flutter/material.dart';
import 'database_helper.dart';

void main() => runApp(ExpenseApp());

class ExpenseApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: ExpenseHome());
  }
}

class ExpenseHome extends StatefulWidget {
  @override
  _ExpenseHomeState createState() => _ExpenseHomeState();
}

class _ExpenseHomeState extends State<ExpenseHome> {
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _subgroups = [];

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String _type = 'Debit';
  String? _selectedSubgroup;

  @override
  void initState() {
    super.initState();
    _refreshTransactions();
    _refreshSubgroups();
  }

  void _refreshTransactions() async {
    final data = await DatabaseHelper.instance.queryAllRows();
    setState(() {
      _transactions = data;
    });
  }

  void _refreshSubgroups() async {
    final data = await DatabaseHelper.instance.queryAllSubgroups();
    setState(() {
      _subgroups = data;
    });
  }

  double get _totalBalance {
    double total = 0;
    for (var tx in _transactions) {
      if (tx['type'] == 'Credit')
        total += tx['amount'];
      else
        total -= tx['amount'];
    }
    return total;
  }

  void _deleteTransaction(int id) async {
    await DatabaseHelper.instance.delete(id);
    _refreshTransactions();
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Delete Entry?"),
        content: Text("ഈ കണക്ക് ഡിലീറ്റ് ചെയ്യണോ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("No")),
          TextButton(
            onPressed: () {
              _deleteTransaction(id);
              Navigator.pop(ctx);
            },
            child: Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addSubGroupPopup() {
    final _subGroupNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add New Subgroup"),
        content: TextField(
          controller: _subGroupNameController,
          decoration: InputDecoration(
            hintText: "Enter name (e.g. Salary, Rent)",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_subGroupNameController.text.isNotEmpty) {
                await DatabaseHelper.instance.insertSubgroup({
                  'name': _subGroupNameController.text,
                });
                _refreshSubgroups();
                Navigator.pop(context);
              }
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  void _addTransaction() async {
    final amt = double.tryParse(_amountController.text);
    if (_nameController.text.isEmpty || amt == null) return;

    String formattedDate = DateTime.now().toString().split(' ')[0];

    final data = {
      'title': _nameController.text,
      'subgroup': _selectedSubgroup,
      'description': _descriptionController.text,
      'amount': amt,
      'type': _type,
      'date': formattedDate,
    };

    await DatabaseHelper.instance.insert(data);
    _nameController.clear();
    _descriptionController.clear();
    _amountController.clear();
    setState(() => _selectedSubgroup = null);
    _refreshTransactions();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accounting Ledger'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ReportScreen(transactions: _transactions),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.category, color: Colors.orange),
            onPressed: _addSubGroupPopup,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(15),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "INR Balance: ₹ $_totalBalance",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.indigo,
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            child: Row(
              children: [
                _tableHeader("ID", 1),
                _vLine(),
                _tableHeader("Name", 2),
                _vLine(),
                _tableHeader("Sub", 2),
                _vLine(),
                _tableHeader("Desc", 3),
                _vLine(),
                _tableHeader("Amount", 2),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _transactions.length,
              itemBuilder: (ctx, index) {
                final tx = _transactions[index];
                return GestureDetector(
                  onLongPress: () => _confirmDelete(tx['id']),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Center(child: Text("${tx['id']}")),
                        ),
                        _vLineGrey(),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: Text("${tx['title']}"),
                          ),
                        ),
                        _vLineGrey(),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: Text("${tx['subgroup'] ?? ''}"),
                          ),
                        ),
                        _vLineGrey(),
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: Text("${tx['description'] ?? ''}"),
                          ),
                        ),
                        _vLineGrey(),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "${tx['amount']}",
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: tx['type'] == 'Credit'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                minimumSize: Size(double.infinity, 45),
              ),
              onPressed: () => _showForm(context),
              child: Text(
                "ADD TRANSACTION",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text, int flex) => Expanded(
    flex: flex,
    child: Center(
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    ),
  );
  Widget _vLine() => Container(width: 1, height: 20, color: Colors.white24);
  Widget _vLineGrey() =>
      Container(width: 1, height: 25, color: Colors.grey.shade300);

  void _showForm(BuildContext ctx) {
    _refreshSubgroups();
    showModalBottomSheet(
      isScrollControlled: true,
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 15,
              right: 15,
              top: 15,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                DropdownButton<String>(
                  value: _selectedSubgroup,
                  hint: Text("Select Subgroup"),
                  isExpanded: true,
                  items: _subgroups
                      .map(
                        (sub) => DropdownMenuItem(
                          value: sub['name'].toString(),
                          child: Text(sub['name'].toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setModalState(() => _selectedSubgroup = val),
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: _amountController,
                  decoration: InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButton<String>(
                  value: _type,
                  items: ['Debit', 'Credit']
                      .map(
                        (val) => DropdownMenuItem(value: val, child: Text(val)),
                      )
                      .toList(),
                  onChanged: (val) => setModalState(() => _type = val!),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _addTransaction,
                  child: Text('SAVE TO TABLE'),
                ),
                SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

// 1. മന്ത്‌ലി സമ്മറി കാണിക്കുന്ന സ്ക്രീൻ
// 1. മന്ത്‌ലി സമ്മറി കാണിക്കുന്ന സ്ക്രീൻ
class ReportScreen extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  ReportScreen({required this.transactions});

  @override
  Widget build(BuildContext context) {
    Map<String, Map<String, double>> monthlySummary = {};

    for (var tx in transactions) {
      String fullDate = tx['date'] ?? DateTime.now().toString().split(' ')[0];
      String monthYear = fullDate.substring(0, 7); // ഉദാഹരണത്തിന്: 2026-03

      if (!monthlySummary.containsKey(monthYear)) {
        monthlySummary[monthYear] = {'In': 0.0, 'Out': 0.0};
      }

      double amt = double.tryParse(tx['amount'].toString()) ?? 0.0;
      if (tx['type'] == 'Credit') {
        monthlySummary[monthYear]!['In'] =
            monthlySummary[monthYear]!['In']! + amt;
      } else {
        monthlySummary[monthYear]!['Out'] =
            monthlySummary[monthYear]!['Out']! + amt;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Monthly Summary"),
        backgroundColor: Colors.indigo,
      ),
      body: ListView(
        children: monthlySummary.entries.map((entry) {
          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              title: Text(
                entry.key,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: Text(
                "കണക്കുകൾ കാണാൻ ക്ലിക്ക് ചെയ്യുക",
                style: TextStyle(fontSize: 12),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "In: ₹${entry.value['In']}",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Out: ₹${entry.value['Out']}",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              onTap: () {
                // ആ മാസത്തെ ട്രാൻസാക്ഷനുകൾ മാത്രം ഫിൽട്ടർ ചെയ്യുന്നു
                List<Map<String, dynamic>> filteredList = transactions.where((
                  tx,
                ) {
                  String date = tx['date'] ?? "";
                  return date.startsWith(entry.key);
                }).toList();

                // ലിസ്റ്റ് കാണിക്കാൻ പുതിയ പേജിലേക്ക് പോകുന്നു
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MonthDetailsScreen(
                      monthName: entry.key,
                      monthTransactions: filteredList,
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

// 2. ക്ലിക്ക് ചെയ്താൽ വരുന്ന ഡീറ്റെയിൽസ് സ്ക്രീൻ
class MonthDetailsScreen extends StatelessWidget {
  final String monthName;
  final List<Map<String, dynamic>> monthTransactions;

  MonthDetailsScreen({
    required this.monthName,
    required this.monthTransactions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Transactions: $monthName"),
        backgroundColor: Colors.indigo,
      ),
      body: ListView.builder(
        itemCount: monthTransactions.length,
        itemBuilder: (context, index) {
          final tx = monthTransactions[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: ListTile(
              leading: Icon(
                tx['type'] == 'Credit'
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                color: tx['type'] == 'Credit' ? Colors.green : Colors.red,
              ),
              title: Text("${tx['title']}"),
              subtitle: Text("${tx['date']} | ${tx['subgroup'] ?? ''}"),
              trailing: Text(
                "₹${tx['amount']}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: tx['type'] == 'Credit' ? Colors.green : Colors.red,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
