import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // App Check en modo debug-token: ver docs/APP_CHECK.md para el plan de
  // migración a Play Integrity enforced antes de una release pública. La
  // protección real de los datos la dan las reglas de Firestore/Storage,
  // no App Check.
  await FirebaseAppCheck.instance.activate(
    providerAndroid: const AndroidDebugProvider(),
  );

  await initializeDateFormatting('es_PY');
  await initializeDateFormatting('es');

  runApp(const BitersApp());
}
