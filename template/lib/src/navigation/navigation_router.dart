import 'package:feature_home/presentation/home_bloc.dart';
import 'package:feature_home/presentation/home_event.dart';
import 'package:feature_home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:shared/presentation/navigation/routes.dart';

import 'package:__APP_NAME__/src/di/service_locator.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: "root");

@singleton
class NavigationRouter {
  late final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: NavigationRoute.home.path,
    routes: [
      GoRoute(
        path: NavigationRoute.home.path,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<HomeBloc>()..add(const HomeStarted()),
          child: const HomeScreen(),
        ),
      ),
    ],
  );
}
