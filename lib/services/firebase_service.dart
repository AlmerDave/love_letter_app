import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance {
    _instance ??= FirebaseService._();
    return _instance!;
  }

  FirebaseService._();

  FirebaseApp? _app;
  DatabaseReference? _database;

  Future<void> initialize() async {
    if (_app != null) return; // Already initialized

    _app = await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCcOYAuXWHYqfzQe_Dpxitdsqdgn4SvPT8",  // ← PASTE FROM FIREBASE CONFIG
        authDomain: "love-letter-app-3c5b3.firebaseapp.com",
        databaseURL: "https://love-letter-app-3c5b3-default-rtdb.asia-southeast1.firebasedatabase.app/",  // ← IMPORTANT!
        projectId: "love-letter-app-3c5b3",
        storageBucket: "love-letter-app-3c5b3.firebasestorage.app",
        messagingSenderId: "1069598771619",
        appId: "1:1069598771619:web:a6b40cf8e150e731fbb216",
      ),
    );

    _database = FirebaseDatabase.instanceFor(
      app: _app!,
      databaseURL: 'https://love-letter-app-3c5b3-default-rtdb.asia-southeast1.firebasedatabase.app/',  // ← PASTE AGAIN
    ).ref();
  }

  DatabaseReference get locationsRef => _database!.child('locations');

  DatabaseReference get database => _database!;
}