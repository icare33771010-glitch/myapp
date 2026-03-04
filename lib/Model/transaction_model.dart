class Transaction {
  final String date;
  final String description;
  final String subGroupName; // ഇത് പുതുതായി ചേർക്കുക
  final double debit;
  final double credit;
  double runningBalance;

  Transaction({
    required this.date,
    required this.description,
    this.subGroupName = "", // Default ആയി കാലി സ്ട്രിംഗ് നൽകാം
    required this.debit,
    required this.credit,
    this.runningBalance = 0.0,
  });
}
