import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Spanish date localization
  await initializeDateFormatting('es_ES', null);
  
  runApp(const MyApp());
}
