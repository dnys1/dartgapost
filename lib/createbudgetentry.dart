import 'package:flutter/material.dart';

class Createbudgetentry extends StatefulWidget {
  const Createbudgetentry({Key? key}) : super(key: key);

  @override
  State<Createbudgetentry> createState() => _CreatebudgetentryState();
}

class _CreatebudgetentryState extends State<Createbudgetentry> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create budget entry"),
      ),
      body: Container(),
    );
  }
}
