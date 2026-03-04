import 'package:flutter/material.dart';
import 'package:my_app/Report/report_page.dart';
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

  // ലിസ്റ്റുകൾ രണ്ടായി തിരിച്ചു
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _subgroups = [];

  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String _type = 'Debit';

  String? _selectedGroup;
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

  // ഗ്രൂപ്പും സബ്ഗ്രൂപ്പും ഡാറ്റാബേസിൽ നിന്ന് പ്രത്യേകം എടുക്കുന്നു
  void _refreshSubgroups() async {
    final data = await DatabaseHelper.instance.queryAllSubgroups();
    setState(() {
      // ഇവിടെ നിന്റെ ഡാറ്റാബേസിൽ 'type' എന്ന കോളം ഉണ്ടെങ്കിൽ അത് വെച്ച് ഫിൽട്ടർ ചെയ്യാം
      // തൽക്കാലം എല്ലാ ഡാറ്റയും രണ്ട് ലിസ്റ്റിലും വരും, യൂസർ ആഡ് ചെയ്യുന്നതിനനുസരിച്ച് ഇത് മാറും
      _groups = data.where((element) => element['type'] == 'group').toList();
      _subgroups = data
          .where((element) => element['type'] == 'subgroup')
          .toList();

      // ഒരുപക്ഷേ നിന്റെ പഴയ ഡാറ്റയിൽ 'type' ഇല്ലെങ്കിൽ എല്ലാം കാണിക്കാൻ വേണ്ടി താഴെ ഉള്ളത് ഉപയോഗിക്കാം:
      if (_groups.isEmpty && _subgroups.isEmpty && data.isNotEmpty) {
        _groups = data;
        _subgroups = data;
      }
    });
  }

  // --- പുതുക്കിയ സെർച്ച് ഡയലോഗ് ---
  Future<String?> _showSearchDialog(String label) async {
    String? selection;
    // ലേബൽ നോക്കി ഏത് ലിസ്റ്റ് കാണിക്കണം എന്ന് തീരുമാനിക്കുന്നു
    List<Map<String, dynamic>> masterList = (label == "Group")
        ? _groups
        : _subgroups;

    await showDialog(
      context: context,
      builder: (context) {
        List<Map<String, dynamic>> filtered = masterList;
        TextEditingController searchCtrl = TextEditingController();

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text("Select $label"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    hintText: "Search or add new...",
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (val) {
                    setDialogState(() {
                      filtered = masterList
                          .where(
                            (s) => s['name'].toString().toLowerCase().contains(
                              val.toLowerCase(),
                            ),
                          )
                          .toList();
                    });
                  },
                ),
                SizedBox(height: 10),
                Container(
                  height: 200,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => ListTile(
                      title: Text(filtered[i]['name']),
                      onTap: () {
                        selection = filtered[i]['name'];
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (searchCtrl.text.isNotEmpty) {
                    // പുതിയത് ആഡ് ചെയ്യുമ്പോൾ അത് ഗ്രൂപ്പാണോ സബ്ഗ്രൂപ്പാണോ എന്ന് കൂടി ഡാറ്റാബേസിൽ അറിയിക്കുന്നു
                    await DatabaseHelper.instance.insertSubgroup({
                      'name': searchCtrl.text,
                      'type': (label == "Group") ? 'group' : 'subgroup',
                    });
                    _refreshSubgroups();
                    selection = searchCtrl.text;
                    Navigator.pop(context);
                  }
                },
                child: Text("Add New"),
              ),
            ],
          ),
        );
      },
    );
    return selection;
  }

  double get _totalBalance {
    double total = 0;
    for (var tx in _transactions) {
      double amt = double.tryParse(tx['amount'].toString()) ?? 0;
      if (tx['type'] == 'Credit')
        total += amt;
      else
        total -= amt;
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
        content: Text("Are you sure?"),
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

  // ഇത് മെയിൻ പേജിലെ കാറ്റഗറി ബട്ടൺ വഴി ആഡ് ചെയ്യാൻ
  void _addSubGroupPopup() {
    final _nameController = TextEditingController();
    String _tempType = 'group'; // default

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setPopupState) => AlertDialog(
          title: Text("Add New Category"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: _tempType,
                isExpanded: true,
                items: [
                  DropdownMenuItem(child: Text("Main Group"), value: 'group'),
                  DropdownMenuItem(child: Text("Subgroup"), value: 'subgroup'),
                ],
                onChanged: (val) => setPopupState(() => _tempType = val!),
              ),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(hintText: "Enter name"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isNotEmpty) {
                  await DatabaseHelper.instance.insertSubgroup({
                    'name': _nameController.text,
                    'type': _tempType,
                  });
                  _refreshSubgroups();
                  Navigator.pop(context);
                }
              },
              child: Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _addTransaction() async {
    final amt = double.tryParse(_amountController.text);
    if (_selectedGroup == null || amt == null) return;

    final data = {
      'group_name': _selectedGroup,
      'subgroup_name': _selectedSubgroup ?? '',
      'description': _descriptionController.text,
      'amount': amt,
      'type': _type,
      'date': DateTime.now().toString().split(' ')[0],
    };

    await DatabaseHelper.instance.insert(data);
    _descriptionController.clear();
    _amountController.clear();
    setState(() {
      _selectedGroup = null;
      _selectedSubgroup = null;
    });
    _refreshTransactions();
    Navigator.of(context).pop();
  }

  void _showForm(BuildContext ctx) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 15,
            right: 15,
            top: 15,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Add Transaction",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              ListTile(
                leading: Icon(Icons.account_balance_wallet, color: Colors.blue),
                title: Text(_selectedGroup ?? "Select Main Group *"),
                trailing: Icon(Icons.arrow_drop_down),
                onTap: () async {
                  final res = await _showSearchDialog("Group");
                  if (res != null) setModalState(() => _selectedGroup = res);
                },
              ),
              ListTile(
                leading: Icon(Icons.label, color: Colors.orange),
                title: Text(_selectedSubgroup ?? "Select Subgroup (Optional)"),
                trailing: Icon(Icons.arrow_drop_down),
                onTap: () async {
                  final res = await _showSearchDialog("Subgroup");
                  if (res != null) setModalState(() => _selectedSubgroup = res);
                },
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description ()'),
              ),
              TextField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              DropdownButton<String>(
                value: _type,
                isExpanded: true,
                items: ['Debit', 'Credit']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (val) => setModalState(() => _type = val!),
              ),
              SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: Size(double.infinity, 45),
                ),
                onPressed: _addTransaction,
                child: Text(
                  'SAVE TRANSACTION',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accounting Ledger'),
        backgroundColor: Colors.blueAccent,
        // AppBar-ലെ actions ഭാഗത്ത് ഇത് മാറ്റുക
        actions: [
          IconButton(
            icon: Icon(Icons.list_alt),
            onPressed: () {
              // ഇതാണ് പുതിയ Navigation
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupListScreen(groups: _groups),
                ),
              );
            },
          ),
          // ... നിങ്ങളുടെ മറ്റു ഐക്കണുകൾ (bar_chart, category തുടങ്ങിയവ)
          // AppBar-ൽ ഈ ഭാഗം അപ്ഡേറ്റ് ചെയ്യുക
          IconButton(
            icon: Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      MonthListScreen(transactions: _transactions),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') _confirmClearAll();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 10),
                    Text("Clear All"),
                  ],
                ),
              ),
            ],
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
                  "Balance: ₹ $_totalBalance",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _transactions.isEmpty
                ? Center(child: Text("No Data"))
                : ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (ctx, index) {
                      final tx = _transactions[index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: ListTile(
                          onLongPress: () => _confirmDelete(tx['id']),
                          title: Text(
                            "${tx['group_name']} ${tx['subgroup_name'] != '' ? '- ' + tx['subgroup_name'] : ''}",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "${tx['description'] != '' ? tx['description'] : 'No Description'}\nDate: ${tx['date']}",
                          ),
                          trailing: Text(
                            "₹${tx['amount']}",
                            style: TextStyle(
                              color: tx['type'] == 'Credit'
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
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
                minimumSize: Size(double.infinity, 45),
                backgroundColor: Colors.blueAccent,
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

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Clear All Data ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("No")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DatabaseHelper.instance.clearDatabase();
              _refreshTransactions();
              _refreshSubgroups();
              Navigator.pop(ctx);
            },
            child: Text("Yes", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class ReportScreen extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  ReportScreen({required this.transactions});

  @override
  Widget build(BuildContext context) {
    // 1. ഗ്രൂപ്പ് പേരുകൾ കണ്ടെത്തുന്നു
    final groups = transactions
        .map((item) => item['group_name']?.toString() ?? 'Unknown')
        .toSet()
        .toList();
    print(transactions);
    return Scaffold(
      appBar: AppBar(title: Text("Monthly Report")),
      body: groups.isEmpty
          ? Center(child: Text("ഡാറ്റ ലഭ്യമല്ല"))
          : ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final categoryName = groups[index];

                // ഈ ഗ്രൂപ്പിലുള്ള ഐറ്റങ്ങൾ മാത്രം ഫിൽട്ടർ ചെയ്യുന്നു
                final categoryItems = transactions
                    .where(
                      (item) => item['group_name']?.toString() == categoryName,
                    )
                    .toList();

                // ടോട്ടൽ കണക്കാക്കുന്നു
                double total = categoryItems.fold(
                  0,
                  (sum, item) =>
                      sum + (double.tryParse(item['amount'].toString()) ?? 0),
                );

                return ExpansionTile(
                  title: Text(categoryName),
                  trailing: Text(
                    "₹${total.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: total >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // ക്ലിക്ക് ചെയ്യുമ്പോൾ വരുന്ന വരികൾ
                  children: categoryItems.map((data) {
                    return ListTile(
                      // സബ്ഗ്രൂപ്പ് നെയിം കാണിക്കുന്നു
                      title: Text(
                        data['subgroup_name']?.toString() ?? "No Title",
                      ),
                      // തീയതിയും ഡിസ്ക്രിപ്ഷനും കാണിക്കുന്നു
                      subtitle: Text(
                        "${data['date']} ${data['description'] ?? ''}",
                      ),
                      trailing: Text("₹${data['amount']}"),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }
}

// ഈ ഭാഗം ഫയലിന്റെ ഏറ്റവും താഴെ ചേർക്കുക
class GroupListScreen extends StatelessWidget {
  final List<Map<String, dynamic>> groups;

  GroupListScreen({required this.groups});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Group"),
        backgroundColor: Colors.blueAccent,
      ),
      body: groups.isEmpty
          ? Center(child: Text("ഗ്രൂപ്പുകൾ ലഭ്യമല്ല."))
          : ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                String gName = groups[index]['name'].toString();
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(Icons.folder)),
                    title: Text(
                      gName,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportPage(groupName: gName),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// 1. മാസങ്ങളുടെ ലിസ്റ്റ് കാണിക്കാൻ
class MonthListScreen extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  MonthListScreen({required this.transactions});

  @override
  Widget build(BuildContext context) {
    // തീയതികളിൽ നിന്ന് മാസങ്ങൾ വേർതിരിക്കുന്നു
    final months = transactions
        .map((item) {
          DateTime date = DateTime.parse(item['date'].toString());
          return "${date.year}-${date.month.toString().padLeft(2, '0')}";
        })
        .toSet()
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text("Select Month")),
      body: months.isEmpty
          ? Center(child: Text("No Data"))
          : ListView.builder(
              itemCount: months.length,
              itemBuilder: (context, index) {
                String currentMonth = months[index];

                // ആ മാസത്തെ ട്രാൻസാക്ഷനുകൾ മാത്രം ഫിൽട്ടർ ചെയ്യുന്നു
                final monthlyData = transactions
                    .where(
                      (item) =>
                          item['date'].toString().startsWith(currentMonth),
                    )
                    .toList();

                // വരുമാനവും ചെലവും കണക്കാക്കുന്നു
                double totalCredit = 0; // വരവ്
                double totalDebit = 0; // ചെലവ്

                for (var item in monthlyData) {
                  double amt = double.tryParse(item['amount'].toString()) ?? 0;
                  if (item['type'] == 'Credit') {
                    totalCredit += amt;
                  } else {
                    totalDebit += amt;
                  }
                }

                double monthlyBalance = totalCredit - totalDebit;

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: Icon(
                      Icons.calendar_month,
                      color: Colors.blue,
                      size: 30,
                    ),
                    title: Text(
                      currentMonth,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    // താഴെ സബ് ടൈറ്റിലിൽ ടോട്ടൽ വിവരങ്ങൾ കാണിക്കുന്നു
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Row(
                        children: [
                          Text(
                            "In: ₹$totalCredit",
                            style: TextStyle(color: Colors.green, fontSize: 12),
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Out: ₹$totalDebit",
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Bal: ₹$monthlyBalance",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MonthlyReportPage(
                            month: currentMonth,
                            data: monthlyData,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// 2. തിരഞ്ഞെടുത്ത മാസത്തെ റിപ്പോർട്ട് കാണിക്കാൻ
class MonthlyReportPage extends StatelessWidget {
  final String month;
  final List<Map<String, dynamic>> data;

  MonthlyReportPage({required this.month, required this.data});

  @override
  Widget build(BuildContext context) {
    // ആ മാസത്തെ ഗ്രൂപ്പുകൾ കണ്ടെത്തുന്നു
    final groups = data
        .map((item) => item['group_name'].toString())
        .toSet()
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text("$month Report")),
      body: data.isEmpty
          ? Center(child: Text("ഈ മാസത്തിൽ ഡാറ്റ ലഭ്യമല്ല"))
          : ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final categoryName = groups[index];
                final categoryItems = data
                    .where((item) => item['group_name'] == categoryName)
                    .toList();

                double total = categoryItems.fold(
                  0,
                  (sum, item) =>
                      sum + (double.tryParse(item['amount'].toString()) ?? 0),
                );

                return ExpansionTile(
                  title: Text(
                    categoryName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Text(
                    "₹${total.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: categoryItems.map((item) {
                    return ListTile(
                      title: Text(item['subgroup_name'] ?? "No Subgroup"),
                      subtitle: Text(
                        "${item['date']} - ${item['description']}",
                      ),
                      trailing: Text("₹${item['amount']}"),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }
}
