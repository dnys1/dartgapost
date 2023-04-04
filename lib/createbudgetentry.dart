import 'package:dartgapost/models/ModelProvider.dart';
import 'package:flutter/material.dart';

class Createbudgetentry extends StatefulWidget {
  final BudgetEntry? budgetEntry;

  const Createbudgetentry({required this.budgetEntry, Key? key})
      : super(key: key);

  @override
  State<Createbudgetentry> createState() => _CreatebudgetentryState();
}

class _CreatebudgetentryState extends State<Createbudgetentry> {
  @override
  Widget build(BuildContext context) {
    final BudgetEntry? budgetEntry = widget.budgetEntry;

    bool isCreateFlag = budgetEntry == null ? true : false;

    final String titleText =
        isCreateFlag == false ? 'update budget entry' : 'create budget entry';

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
      ),
      body: Container(),
    );
  }
}
