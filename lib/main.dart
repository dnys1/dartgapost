import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'homepage.dart';
import 'package:flutter/material.dart';
import 'package:amplify_api/amplify_api.dart';
import 'models/ModelProvider.dart';
import 'package:go_router/go_router.dart';
import 'amplifyconfiguration.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _configureAmplify();
  }

// GoRouter configuration
  final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Homepage(),
      ),
    ],
  );

  void _configureAmplify() async {
    try {
      //authentication
      final auth = AmplifyAuthCognito();
      //API
      final api = AmplifyAPI(modelProvider: ModelProvider.instance);
      //Storage
      final storage = AmplifyStorageS3();

      await Amplify.addPlugins([api, auth, storage]);

      await Amplify.configure(amplifyconfig);
      safePrint('Successfully configured');
    } on Exception catch (e) {
      safePrint('Error configuring Amplify: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Authenticator(
      child: MaterialApp.router(
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
        builder: Authenticator.builder(),
      ),
    );
  }
}
