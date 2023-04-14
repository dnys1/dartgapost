import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:dartgapost/models/ModelProvider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ManageBudgetEntry extends StatefulWidget {
  const ManageBudgetEntry({
    required this.budgetEntry,
    super.key,
  });

  final BudgetEntry? budgetEntry;

  @override
  State<ManageBudgetEntry> createState() => _ManageBudgetEntryState();
}

class _ManageBudgetEntryState extends State<ManageBudgetEntry> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  var _isCreateFlag = false;
  late String _titleText;

  PlatformFile? _platformFile;
  BudgetEntry? _budgetEntry;

  @override
  void initState() {
    super.initState();

    final budgetEntry = widget.budgetEntry;
    if (budgetEntry != null) {
      _budgetEntry = budgetEntry;
      _titleController.text = budgetEntry.title;
      _descriptionController.text = budgetEntry.description ?? '';
      _amountController.text = budgetEntry.amount.toStringAsFixed(2);
      _isCreateFlag = false;
      _titleText = 'Update budget entry';
    } else {
      _titleText = 'Create budget entry';
      _isCreateFlag = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<String> _uploadToS3() async {
    try {
      // Upload to S3
      final result = await Amplify.Storage.uploadFile(
        localFile: AWSFile.fromData(_platformFile!.bytes!),
        key: _platformFile!.name,
        options: const StorageUploadFileOptions(
          accessLevel: StorageAccessLevel.private,
        ),
        onProgress: (progress) {
          safePrint('Fraction completed: ${progress.fractionCompleted}');
        },
      ).result;
      safePrint('Successfully uploaded file: ${result.uploadedItem.key}');
      return result.uploadedItem.key;
    } on StorageException catch (e) {
      safePrint('Error uploading file: $e');
    }
    return '';
  }

  Future<void> _pickImage() async {
    // Show the file picker to select the images
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _platformFile = result.files.single;
      });
    }
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // If the form is valid, submit the data
    final title = _titleController.text;
    final description = _descriptionController.text;
    final amount = double.parse(_amountController.text);

    // Upload file to S3 if a file was selected
    String? key;
    if (_platformFile != null) {
      final existingImage = _budgetEntry?.attachmentKey;
      if (existingImage != null) {
        await _deleteFile(existingImage);
      }
      key = await _uploadToS3();
    }

    if (_isCreateFlag) {
      // Create a new budget entry
      final newEntry = BudgetEntry(
        title: title,
        description: description.isNotEmpty ? description : null,
        amount: amount,
        attachmentKey: key,
      );
      final request = ModelMutations.create(newEntry);
      final response = await Amplify.API.mutate(request: request).response;
      safePrint('Create result: $response');
    } else {
      // Update budgetEntry instead
      final updateBudgetEntry = _budgetEntry!.copyWith(
        title: title,
        description: description.isNotEmpty ? description : null,
        amount: amount,
        attachmentKey: key,
      );
      final request = ModelMutations.update(updateBudgetEntry);
      final response = await Amplify.API.mutate(request: request).response;
      safePrint('Update ersult: $response');
    }

    // Navigate back to homepage after create/update executes
    if (mounted) {
      context.pop();
    }
  }

  Future<String> _downloadFileData(String key) async {
    // Get download URL to display the budgetEntry image
    try {
      final result = await Amplify.Storage.getUrl(
        key: key,
        options: const StorageGetUrlOptions(
          accessLevel: StorageAccessLevel.private,
          pluginOptions: S3GetUrlPluginOptions(
            validateObjectExistence: true,
            expiresIn: Duration(days: 1),
          ),
        ),
      ).result;
      return result.url.toString();
    } on StorageException catch (e) {
      safePrint('Error downloading image: ${e.message}');
      rethrow;
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

  Widget get _attachmentImage {
    // When creating a new entry, show an image if it was uploaded.
    final localAttachment = _platformFile;
    if (localAttachment != null) {
      return Image.memory(
        localAttachment.bytes!,
        height: 200,
      );
    }
    // Retrieve Image URL and try to display it.
    // Show loading spinner if still loading.
    final remoteAttachment = _budgetEntry?.attachmentKey;
    if (remoteAttachment == null) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<String>(
      future: _downloadFileData(
        _budgetEntry!.attachmentKey!,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.network(
            snapshot.data!,
            height: 200,
          );
        } else if (snapshot.hasError) {
          return const SizedBox.shrink();
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleText),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title (required)',
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
                    ),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: false,
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount (required)',
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
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: const Text('Attach a file'),
                    ),
                    const SizedBox(height: 20),
                    _attachmentImage,
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: submitForm,
                      child: Text(_titleText),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
