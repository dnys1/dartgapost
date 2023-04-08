import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:dartgapost/homepage.dart';
import 'package:dartgapost/models/ModelProvider.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';

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

  PlatformFile? _platformFile;

  bool wasImageUpdated = false;

  BudgetEntry? _budgetEntry;

  bool? _isCreateFlag = false;

  String? _titleText;

  @override
  void initState() {
    if (widget.budgetEntry != null) {
      _titleController.text = widget.budgetEntry!.title!;
      _descriptionController.text = widget.budgetEntry!.description ?? '';
      _amountController.text = widget.budgetEntry!.amount?.toString() ?? '';
      _budgetEntry = widget.budgetEntry!;
      _isCreateFlag = false;
      _titleText = 'update budget entry';
      // if (widget.budgetEntry!.attachmentKey != null) {

      // }
    } else {
      _titleText = 'create budget entry';
      _isCreateFlag = true;
    }

    super.initState();
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

  Future<String> uploadToS3() async {
    try {
      final result = await Amplify.Storage.uploadFile(
        localFile: AWSFile.fromData(_platformFile!.bytes!),
        key: _platformFile!.name,
        options:
            const S3UploadFileOptions(accessLevel: StorageAccessLevel.private),
        onProgress: (progress) {
          safePrint('Fraction completed: ${progress.fractionCompleted}');
        },
      ).result;
      safePrint('Successfully uploaded file: ${result.uploadedItem.key}');
      return result.uploadedItem.key;
    } on StorageException catch (e) {
      safePrint('Error uploading file: $e');
    }
    return "";
  }

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      // allowedExtensions: ['jpg', 'png', 'gif'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _platformFile = result.files.single;
        wasImageUpdated = true;
        // final readStream = _platformFile!.readStream;
        // final bytes = <int>[];
        // await for (var chunk in readStream!) {
        //   bytes.addAll(chunk);
        // }
        // _imageBytes = bytes as Uint8List?;
      });
    } else {
      return;
    }
  }

  Future<void> submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Form is valid, submit the data
      final title = _titleController.text;
      final description = _descriptionController.text;
      final amount = double.parse(_amountController.text);

      if (_isCreateFlag != null && _isCreateFlag!) {
        //upload file to S3
        final String key = await uploadToS3();
        //Grab S3 file key

        // Create a new budget entry
        final newEntry = BudgetEntry(
            title: title,
            description: description.isNotEmpty ? description : null,
            amount: amount,
            attachmentKey: key);
        final request = ModelMutations.create(newEntry);
        final response = await Amplify.API.mutate(request: request).response;
        final createdBudgetEntry = response.data;
        if (createdBudgetEntry == null) {
          safePrint('errors: ${response.errors}');
          return;
        }
        safePrint('Mutation result: ${createdBudgetEntry.title}');
        if (!mounted) return;
        navigateToHomepage(context);
      } else {
        //update budgetEntry instead
        final String key = await uploadToS3();
        final updateBudgetEntry = _budgetEntry!.copyWith(
          title: title,
          description: description.isNotEmpty ? description : null,
          amount: amount,
          attachmentKey: key,
        );
        final request = ModelMutations.update(updateBudgetEntry);
        final response = await Amplify.API.mutate(request: request).response;
        safePrint('Response: $response');
        if (!mounted) return;
        navigateToHomepage(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleText!),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
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
                    labelText: 'Description',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
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
                  onPressed: pickImage,
                  child: const Text("upload a file"),
                ),
                const SizedBox(
                  height: 20,
                ),
                _platformFile != null
                    ? Image.memory(
                        _platformFile!.bytes!,
                        height: 200,
                        width: 200,
                      )
                    : Container(),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  onPressed: submitForm,
                  child: Text(_titleText!),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
