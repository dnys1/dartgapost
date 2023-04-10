import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:dartgapost/managebudgetentry.dart';
import 'package:dartgapost/models/BudgetEntry.dart';
import 'package:flutter/material.dart';

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

  double calculateTotalBudget(List<BudgetEntry?> items) {
    double totalAmount = 0;

    for (var item in items) {
      totalAmount += item?.amount ?? 0;
    }

    return totalAmount;
  }

  Future<void> deleteFile(String key) async {
    //delete the S3 file
    try {
      final result = await Amplify.Storage.remove(
        key: key,
      ).result;
      safePrint('Removed file ${result.removedItem}');
    } on StorageException catch (e) {
      safePrint('Error deleting file: $e');
    }
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
                builder: (context) => const Managebudgetentry(
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
              //signout - the Authenticator will route you to the login form
              await Amplify.Auth.signOut();
            },
          ),
        ],
      ),
      body: Center(
        //use FutureBuilder to list out budgetEntries for the signed in user using the API category
        child: FutureBuilder<List<BudgetEntry?>>(
          future: _queryListItems(),
          builder: (BuildContext context,
              AsyncSnapshot<List<BudgetEntry?>> snapshot) {
            if (snapshot.hasData) {
              final budgetEntries = snapshot.data!;
              return Column(
                children: [
                  if (budgetEntries.isNotEmpty) ...[
                    const SizedBox(height: 25.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        //show total budget from the list of all BudgetEntries
                        Text(
                          "Total Budget: \$ ${calculateTotalBudget(budgetEntries)}",
                          style: const TextStyle(fontSize: 24.0),
                        )
                      ],
                    ),
                  ],
                  const SizedBox(height: 25.0),
                  Expanded(
                    child: ListView.builder(
                      itemCount: budgetEntries.length,
                      itemBuilder: (BuildContext context, int index) {
                        final budgetEntry = budgetEntries[index];
                        return ListTile(
                          onLongPress: () async {
                            //delete budgetEntry
                            await deleteFile(budgetEntry!.attachmentKey!);
                            final request =
                                ModelMutations.delete<BudgetEntry>(budgetEntry);
                            final response = await Amplify.API
                                .mutate(request: request)
                                .response;
                            setState(() {});
                            safePrint('Response: $response');
                          },
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Managebudgetentry(
                                  budgetEntry: budgetEntry,
                                ),
                              ),
                            );
                          },
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  budgetEntry?.title ?? 'Unknown title',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  budgetEntry?.description ??
                                      'No description available',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '\$ ${budgetEntry?.amount}',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
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
