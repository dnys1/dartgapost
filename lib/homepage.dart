import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:dartgapost/createbudgetentry.dart';
import 'package:dartgapost/models/BudgetEntry.dart';
import 'package:flutter/material.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  Future<List<BudgetEntry?>> _queryListItems() async {
    try {
      final request = ModelQueries.list(BudgetEntry.classType);
      final response = await Amplify.API.query(request: request).response;

      final todos = response.data?.items;
      if (todos == null) {
        safePrint('errors: ${response.errors}');
        return <BudgetEntry?>[];
      }
      return todos;
    } on ApiException catch (e) {
      safePrint('Query failed: $e');
    }
    return <BudgetEntry?>[];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the page to create new budget entries
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const Createbudgetentry(
                      budgetEntry: null,
                    )),
          );
        },
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        title: const Text('Budget Tracker'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'logout',
            onPressed: () async {
              await Amplify.Auth.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<List<BudgetEntry?>>(
          future: _queryListItems(),
          builder: (BuildContext context,
              AsyncSnapshot<List<BudgetEntry?>> snapshot) {
            if (snapshot.hasData) {
              final budgetEntries = snapshot.data!;
              return ListView.builder(
                itemCount: budgetEntries.length,
                itemBuilder: (BuildContext context, int index) {
                  final budgetEntry = budgetEntries[index];
                  return ListTile(
                    onLongPress: () async {
                      final request =
                          ModelMutations.delete<BudgetEntry>(budgetEntry!);

                      final response =
                          await Amplify.API.mutate(request: request).response;
                      setState(() {});
                      safePrint('Response: $response');
                    },
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Createbudgetentry(
                            budgetEntry: budgetEntry,
                          ),
                        ),
                      );
                    },
                    title: Text(budgetEntry?.title ?? 'Unknown title'),
                    subtitle: Text(
                        budgetEntry?.amount?.toString() ?? 'Unknown amount'),
                  );
                },
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return const CircularProgressIndicator();
            }
          },
        ),
      ),
    );
  }
}
