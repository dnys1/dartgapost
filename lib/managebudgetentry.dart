import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:dartgapost/homepage.dart';
import 'package:dartgapost/models/ModelProvider.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';

class ManageBudgetEntry extends StatefulWidget {
  final BudgetEntry? budgetEntry;

  const ManageBudgetEntry({required this.budgetEntry, Key? key})
      : super(key: key);

  @override
  State<ManageBudgetEntry> createState() => _ManageBudgetEntryState();
}

class _ManageBudgetEntryState extends State<ManageBudgetEntry> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  PlatformFile? _platformFile;

  bool _wasImageUpdated = false;

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

  void _navigateToHomepage(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Homepage()),
      (route) => false,
    );
  }

  Future<String> _uploadToS3() async {
    try {
      //upload to S3
      final result = await Amplify.Storage.uploadFile(
        localFile: AWSFile.fromData(_platformFile!.bytes!),
        key: _platformFile!.name,
        options: const StorageUploadFileOptions(
            accessLevel: StorageAccessLevel.private),
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

  Future<void> _pickImage() async {
    //show the file picker to select the images
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _platformFile = result.files.single;
        _wasImageUpdated = true;
      });
    } else {
      return;
    }
  }

  Future<void> submitForm() async {
    if (_formKey.currentState!.validate()) {
      // if the form Form is valid, submit the data
      final title = _titleController.text;
      final description = _descriptionController.text;
      final amount = double.parse(_amountController.text);

      if (_isCreateFlag != null && _isCreateFlag!) {
        //upload file to S3 if file was selected
        String key = '';
        if (_platformFile != null) {
          key = await _uploadToS3();
        }
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
        //navigate back to homepage after create executes
        if (!mounted) return;
        _navigateToHomepage(context);
      } else {
        //update budgetEntry instead
        //Upload new file
        final String key = await _uploadToS3();
        //delete old S3 file
        await _deleteFile(widget.budgetEntry!.attachmentKey!);
        //update budgetEntry new file
        final updateBudgetEntry = _budgetEntry!.copyWith(
          title: title,
          description: description.isNotEmpty ? description : null,
          amount: amount,
          attachmentKey: key,
        );
        final request = ModelMutations.update(updateBudgetEntry);
        final response = await Amplify.API.mutate(request: request).response;
        safePrint('Response: $response');
        //navigate back to homepage after update executes
        if (!mounted) return;
        _navigateToHomepage(context);
      }
    }
  }

  Future<void> _deleteFile(String key) async {
    try {
      final result = await Amplify.Storage.remove(
        key: key,
      ).result;
      safePrint('Removed file ${result.removedItem}');
    } on StorageException catch (e) {
      safePrint('Error deleting file: $e');
    }
  }

  Future<String>? _downloadFileData() async {
    //get download URL to display the budgetEntry image
    try {
      final result = await Amplify.Storage.getUrl(
        key: widget.budgetEntry!.attachmentKey!,
        options: const S3GetUrlOptions(
          accessLevel: StorageAccessLevel.private,
          checkObjectExistence: true,
          expiresIn: Duration(days: 1),
        ),
      ).result;
      return result.url.toString();
    } on StorageException catch (e) {
      safePrint(e.message);
      rethrow;
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
                  onPressed: _pickImage,
                  child: const Text("upload a file"),
                ),
                const SizedBox(
                  height: 20,
                ),
                //retrieve Image URL and try to display it. Show loading spinner if still loading
                if (widget.budgetEntry != null && _platformFile == null)
                  FutureBuilder<String>(
                    future: _downloadFileData(),
                    builder: (context, AsyncSnapshot<String> snapshot) {
                      if (snapshot.hasData) {
                        return Image.network(
                          snapshot.data ?? '',
                          height: 200,
                          width: 200,
                        );
                      } else if (snapshot.hasError) {
                        return Container();
                      } else {
                        return const CircularProgressIndicator();
                      }
                    },
                  )

                //when creating a new entry, show an image if it was uploaded
                else if (_platformFile != null)
                  Image.memory(_platformFile!.bytes!, height: 200, width: 200),
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
