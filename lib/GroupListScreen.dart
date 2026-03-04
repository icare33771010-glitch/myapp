// Level 1: മെയിൻ ഗ്രൂപ്പുകളുടെ ലിസ്റ്റ്
import 'package:flutter/material.dart';
import 'package:my_app/Report/report_page.dart';

class GroupListScreen extends StatelessWidget {
  final List<String> groups = [
    "Direct Income",
    "Family Expences",
    "Home Expences",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("All Reports")),
      body: ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.folder),
            title: Text(groups[index]),
            onTap: () {
              // ഇവിടെ നിന്ന് Level 2-ലേക്ക് പോകുന്നു
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportPage(groupName: groups[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
