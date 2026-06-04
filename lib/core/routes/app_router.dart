import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/expenses/presentation/pages/expense_form_page.dart';
import '../../features/expenses/presentation/pages/expenses_list_page.dart';
import '../../features/expenses/presentation/pages/category_expenses_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/splash/presentation/pages/onboarding_page.dart';

class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String dashboard = '/dashboard';
  static const String categories = '/categories';
  static const String expenses = '/expenses';
  static const String expenseForm = '/expenses/form';
  static const String categoryExpenses = '/expenses/category';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: dashboard,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DashboardPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: categories,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CategoriesPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: CurveTween(curve: Curves.easeInOut)
                  .animate(animation)
                  .drive(Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: expenses,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ExpensesListPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: CurveTween(curve: Curves.easeInOut)
                  .animate(animation)
                  .drive(Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: expenseForm,
        pageBuilder: (context, state) {
          final expenseId = state.uri.queryParameters['expenseId'];
          return CustomTransitionPage(
            key: state.pageKey,
            child: ExpenseFormPage(expenseId: expenseId),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: CurveTween(curve: Curves.easeInOut)
                    .animate(animation)
                    .drive(Tween<Offset>(
                      begin: const Offset(0.0, 1.0),
                      end: Offset.zero,
                    )),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: categoryExpenses,
        pageBuilder: (context, state) {
          final params = state.uri.queryParameters;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CategoryExpensesPage(
              categoryId: params['categoryId'] ?? '',
              categoryName: params['categoryName'] ?? '',
              categoryColorHex: params['categoryColorHex'] ?? '#000000',
              categoryIconCodePoint: params['categoryIconCodePoint'] != null
                  ? int.tryParse(params['categoryIconCodePoint']!)
                  : null,
              startDate: DateTime.tryParse(params['startDate'] ?? '') ?? DateTime.now(),
              endDate: DateTime.tryParse(params['endDate'] ?? '') ?? DateTime.now(),
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: CurveTween(curve: Curves.easeInOut)
                    .animate(animation)
                    .drive(Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    )),
                child: child,
              );
            },
          );
        },
      ),
    ],
  );
}
