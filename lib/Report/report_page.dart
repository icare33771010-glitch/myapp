import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_app/Model/transaction_model.dart';
import 'package:my_app/database_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart'; // rootBundle ഉപയോഗിക്കാൻ ഇത് വേണം

// --- MAIN REPORT PAGE ---
class ReportPage extends StatefulWidget {
  final String groupName;
  ReportPage({required this.groupName});

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  List<Transaction> allData = [];
  List<Transaction> filteredData = [];
  double totalCr = 0;
  double totalDr = 0;
  double totalBal = 0;

  @override
  void initState() {
    super.initState();
    loadDataByGroup(widget.groupName);
  }

  void loadDataByGroup(String groupName) async {
    final data = await DatabaseHelper.instance.queryRowsByGroup(groupName);
    List<Transaction> dbData = data
        .map(
          (item) => Transaction(
            date: item['date'].toString(),
            description: item['description'].toString(),
            subGroupName: item['subgroup_name'] ?? 'General',
            debit: item['type'] == 'Debit'
                ? double.parse(item['amount'].toString())
                : 0,
            credit: item['type'] == 'Credit'
                ? double.parse(item['amount'].toString())
                : 0,
          ),
        )
        .toList();

    setState(() {
      allData = dbData;
      filteredData = allData;
      calculateTotals(filteredData);
    });
  }

  void calculateTotals(List<Transaction> list) {
    double crSum = 0;
    double drSum = 0;
    for (var item in list) {
      crSum += item.credit;
      drSum += item.debit;
    }
    setState(() {
      totalCr = crSum;
      totalDr = drSum;
      totalBal = crSum - drSum;
    });
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    try {
      // 1. ലോഗോ ലോഡ് ചെയ്യുന്നു (assets-ൽ logo.png ഉണ്ടെന്ന് ഉറപ്പുവരുത്തുക)
      final ByteData logoBytes = await rootBundle.load("assets/logo.png");
      final Uint8List logoData = logoBytes.buffer.asUint8List();
      final pdfImage = pw.MemoryImage(logoData);

      // 2. ഫോണ്ട് ലോഡ് ചെയ്യുന്നു
      final fontData = await rootBundle.load("assets/fonts/AnjaliOldLipi.ttf");
      final malayalamFont = pw.Font.ttf(fontData);

      pdf.addPage(
        pw.MultiPage(
          theme: pw.ThemeData.withFont(base: malayalamFont),
          build: (context) => [
            // ഹെഡർ ഭാഗം: ലോഗോയും ടൈറ്റിലും
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "${widget.groupName} Report",
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      "Issue Date: ${DateTime.now().toString().split(' ')[0]}",
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                // ഇവിടെ ലോഗോ വരുന്നു
                pw.Container(height: 50, width: 50, child: pw.Image(pdfImage)),
              ],
            ),
            pw.Divider(), // ഒരു വരി
            pw.SizedBox(height: 10),

            // ടേബിൾ
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.centerLeft,
              data: <List<String>>[
                ['Date', 'Group', 'Discri', 'Amount'],
                ...filteredData.map(
                  (e) => [
                    e.date,
                    e.subGroupName,
                    e.description,
                    e.credit > 0 ? "Cr: ${e.credit}" : "Dr: ${e.debit}",
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  "Total Balance: RS $totalBal",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),

            // താഴെ ബ്രാൻഡ് നെയിം കൂടി നൽകാം
            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Text(
                "Created by i Care Solution",
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ),
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: '${widget.groupName}_Report.pdf',
      );
    } catch (e) {
      print("Error generating PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<Transaction>> grouped = {};
    for (var item in filteredData) {
      grouped.putIfAbsent(item.subGroupName, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.groupName}"),
        backgroundColor: Colors.blueAccent,
        actions: [IconButton(icon: Icon(Icons.share), onPressed: _generatePdf)],
      ),
      body: Column(
        children: [
          _buildSummaryBar(),
          Expanded(
            child: ListView.builder(
              itemCount: grouped.keys.length,
              itemBuilder: (context, index) {
                String subName = grouped.keys.elementAt(index);
                List<Transaction> items = grouped[subName]!;
                double subTotal = items.fold(
                  0,
                  (sum, e) => sum + (e.credit - e.debit),
                );
                return Card(
                  margin: EdgeInsets.all(8),
                  child: ExpansionTile(
                    title: Text(
                      subName,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      "₹$subTotal",
                      style: TextStyle(
                        color: subTotal >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    children: items
                        .map(
                          (item) => ListTile(
                            title: Text(item.description),
                            subtitle: Text(item.date),
                            trailing: Text(
                              item.credit > 0
                                  ? "Cr: ₹${item.credit}"
                                  : "Dr: ₹${item.debit}",
                              style: TextStyle(
                                color: item.credit > 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      padding: EdgeInsets.all(15),
      color: Colors.blueGrey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryColumn("Total Cr", totalCr, Colors.green),
          _summaryColumn("Total Dr", totalDr, Colors.red),
          _summaryColumn("Balance", totalBal, Colors.blue),
        ],
      ),
    );
  }

  Widget _summaryColumn(String label, double amt, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12)),
        Text(
          "₹$amt",
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

// --- MONTHLY REPORT PAGE (വേറെ ക്ലാസ് ആയി താഴെ നൽകുന്നു) ---
class MonthlyReportPage extends StatelessWidget {
  final String month;
  final List<Transaction> data; // List<Map> എന്നുള്ളത് Transaction ആക്കി

  MonthlyReportPage({required this.month, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$month Report"),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _shareMonthlyPdf(context),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          final item = data[index];
          return ListTile(
            title: Text(item.description),
            subtitle: Text(item.date),
            trailing: Text(
              item.credit > 0 ? "Cr: ₹${item.credit}" : "Dr: ₹${item.debit}",
            ),
          );
        },
      ),
    );
  }

  Future<void> _shareMonthlyPdf(BuildContext context) async {
    final pdf = pw.Document();
    try {
      final fontData = await rootBundle.load("assets/fonts/AnjaliOldLipi.ttf");
      final malayalamFont = pw.Font.ttf(fontData);

      pdf.addPage(
        pw.MultiPage(
          theme: pw.ThemeData.withFont(base: malayalamFont),
          build: (context) => [
            pw.Header(level: 0, child: pw.Text("$month Monthly Report")),
            pw.Table.fromTextArray(
              data: [
                ['Date', 'Discri', 'Amount'],
                ...data.map(
                  (e) => [
                    e.date,
                    e.description,
                    e.credit > 0 ? e.credit.toString() : e.debit.toString(),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'Report_$month.pdf',
      );
    } catch (e) {
      print("PDF Error: $e");
    }
  }
}
