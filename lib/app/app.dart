import 'package:flutter/material.dart';
import 'package:production_chat_prop/app/router.dart';
import 'package:production_chat_prop/core/theme/app_theme.dart';

class ProductionChatPropApp extends StatelessWidget {
  const ProductionChatPropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Production Chat Prop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
