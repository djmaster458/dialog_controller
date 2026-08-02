import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dialog_controller/dialog_controller.dart';

import 'src/framework/bloc_dialog_cubit.dart';
import 'src/framework/dialog_controller_provider.dart';
import 'src/presentation/demo_dialog_builder.dart';
import 'src/presentation/demo_home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _AppShell());
  }
}

class _AppShell extends ConsumerWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DialogController controller = ref.watch(dialogControllerProvider);

    return MaterialApp(
      title: 'Flutter Dialog Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: DialogScope(
        controller: controller,
        child: DialogHost(
          controller: controller,
          builder: buildDemoDialog,
          child: BlocProvider<BlocDialogCubit>(
            create: (_) => BlocDialogCubit(),
            child: const DemoHomePage(),
          ),
        ),
      ),
    );
  }
}
