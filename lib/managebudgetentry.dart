import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:dartgapost/homepage.dart';
import 'package:dartgapost/models/ModelProvider.dart';
import 'package:flutter/material.dart';

class Managebudgetentry extends StatefulWidget {
  final BudgetEntry? budgetEntry;

  const Managebudgetentry({required this.budgetEntry, Key? key})
      : super(key: key);

  @override
  State<Managebudgetentry> createState() => _ManagebudgetentryState();
}

class _ManagebudgetentryState extends State<Managebudgetentry> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.budgetEntry != null) {
      _titleController.text = widget.budgetEntry!.title!;
      _descriptionController.text = widget.budgetEntry!.description ?? '';
      _amountController.text = widget.budgetEntry!.amount?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void navigateToHomepage(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Homepage()),
      (route) => false,
    );
  }

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // Form is valid, submit the data
                    final title = _titleController.text;
                    final description = _descriptionController.text;
                    final amount = double.parse(_amountController.text);

                    if (isCreateFlag) {
                      // Create a new budget entry
                      final newEntry = BudgetEntry(
                        title: title,
                        description:
                            description.isNotEmpty ? description : null,
                        amount: amount,
                      );
                      final request = ModelMutations.create(newEntry);
                      final response =
                          await Amplify.API.mutate(request: request).response;
                      final createdBudgetEntry = response.data;
                      if (createdBudgetEntry == null) {
                        safePrint('errors: ${response.errors}');
                        return;
                      }
                      safePrint('Mutation result: ${createdBudgetEntry.title}');
                      if (!mounted) return;
                      navigateToHomepage(currentContext);
                    } else {
                      //update budgetEntry instead
                      final updateBudgetEntry = budgetEntry.copyWith(
                          title: title,
                          description:
                              description.isNotEmpty ? description : null,
                          amount: amount);
                      final request = ModelMutations.update(updateBudgetEntry);
                      final response =
                          await Amplify.API.mutate(request: request).response;
                      safePrint('Response: $response');
                      if (!mounted) return;
                      navigateToHomepage(context);
                    }
                  }
                },
                child: Text(titleText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
