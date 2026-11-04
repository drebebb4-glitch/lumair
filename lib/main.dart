import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_theme.dart';
import 'data/services/supabase_service.dart';
import 'presentation/root_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.init();
  runApp(const ProviderScope(child: LumairApp()));
}

class LumairApp extends StatelessWidget {
  const LumairApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LUMAIR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const RootGate(),
    );
  }
}
