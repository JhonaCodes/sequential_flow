import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sequential_flow/sequential_flow.dart';

// Real-world use case enums
enum OnboardingStep {
  welcome,
  permissions,
  userProfile,
  preferences,
  tutorial,
  completion,
}

enum DataMigrationStep { backup, validation, migration, verification, cleanup }

enum PaymentFlowStep {
  selectPayment,
  enterDetails,
  verification,
  processing,
  confirmation,
}

void main() {
  group('Integration Tests - Real Use Cases', () {
    group('User Onboarding Flow', () {
      testWidgets('should complete full onboarding successfully', (
        tester,
      ) async {
        final executionOrder = <String>[];
        final userData = <String, dynamic>{};

        final onboardingSteps = [
          FlowStep<OnboardingStep>(
            step: OnboardingStep.welcome,
            name: 'Welcome Screen',
            progressValue: 0.16,
            onStepCallback: (controller) async {
              executionOrder.add('welcome');
              await Future.delayed(const Duration(milliseconds: 50));
            },
            actionOnPressBack: ActionOnPressBack.block,
          ),
          FlowStep<OnboardingStep>(
            step: OnboardingStep.permissions,
            name: 'Request Permissions',
            progressValue: 0.33,
            onStepCallback: (controller) async {
              executionOrder.add('permissions');
              // Simulate permission request
              await Future.delayed(const Duration(milliseconds: 100));
            },
            requiresConfirmation: (controller) {
              controller.setData('permissions_requested', true);
              return AlertDialog(
                title: const Text('Allow Camera Access?'),
                content: const Text(
                  'This app needs camera access for QR scanning.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      controller.setData('camera_permission', false);
                      controller.cancelFlow();
                    },
                    child: const Text('Deny'),
                  ),
                  TextButton(
                    onPressed: () {
                      controller.setData('camera_permission', true);
                      controller.continueFlow();
                    },
                    child: const Text('Allow'),
                  ),
                ],
              );
            },
            actionOnPressBack: ActionOnPressBack.goToPreviousStep,
          ),
          FlowStep<OnboardingStep>(
            step: OnboardingStep.userProfile,
            name: 'Create Profile',
            progressValue: 0.5,
            onStepCallback: (controller) async {
              executionOrder.add('profile');
              await Future.delayed(const Duration(milliseconds: 75));
            },
            requiresConfirmation: (controller) {
              return AlertDialog(
                title: const Text('Create Profile'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (value) =>
                          controller.setData('username', value),
                      decoration: const InputDecoration(hintText: 'Username'),
                    ),
                    TextField(
                      onChanged: (value) => controller.setData('email', value),
                      decoration: const InputDecoration(hintText: 'Email'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => controller.continueFlow(),
                    child: const Text('Create'),
                  ),
                ],
              );
            },
            actionOnPressBack: ActionOnPressBack.goToPreviousStep,
          ),
          FlowStep<OnboardingStep>(
            step: OnboardingStep.preferences,
            name: 'Set Preferences',
            progressValue: 0.67,
            onStepCallback: (controller) async {
              executionOrder.add('preferences');
              await Future.delayed(const Duration(milliseconds: 50));
            },
            actionOnPressBack: ActionOnPressBack.custom,
          ),
          FlowStep<OnboardingStep>(
            step: OnboardingStep.tutorial,
            name: 'Quick Tutorial',
            progressValue: 0.83,
            onStepCallback: (controller) async {
              executionOrder.add('tutorial');
              await Future.delayed(const Duration(milliseconds: 100));
            },
            actionOnPressBack: ActionOnPressBack.goToPreviousStep,
          ),
          FlowStep<OnboardingStep>(
            step: OnboardingStep.completion,
            name: 'Setup Complete',
            progressValue: 1.0,
            onStepCallback: (controller) async {
              executionOrder.add('completion');
              await Future.delayed(const Duration(milliseconds: 25));
            },
            actionOnPressBack: ActionOnPressBack.saveAndExit,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: SequentialFlow<OnboardingStep>(
              steps: onboardingSteps,
              onStepLoading: (step, name, progress) => Scaffold(
                appBar: AppBar(title: Text('Onboarding')),
                body: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(value: progress),
                    const SizedBox(height: 16),
                    Text(name),
                    Text('${(progress * 100).toInt()}% Complete'),
                  ],
                ),
              ),
              onStepFinish: (step, name, progress, controller) => Scaffold(
                appBar: AppBar(title: const Text('Welcome!')),
                body: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 64,
                      color: Colors.green,
                    ),
                    Text(
                      'Welcome, ${controller.getData('username') ?? 'User'}!',
                    ),
                    Text(
                      'Email: ${controller.getData('email') ?? 'Not provided'}',
                    ),
                    Text(
                      'Camera: ${controller.getData('camera_permission') == true ? 'Allowed' : 'Denied'}',
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Get Started'),
                    ),
                  ],
                ),
              ),
              onBackPressed: (controller) {
                final currentStep =
                    controller.steps[controller.currentStepIndex];
                if (currentStep.actionOnPressBack == ActionOnPressBack.custom) {
                  return AlertDialog(
                    title: const Text('Save Progress?'),
                    content: const Text('You can continue setup later.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(
                          tester.element(find.byType(AlertDialog)),
                        ).pop(),
                        child: const Text('Continue Setup'),
                      ),
                      TextButton(
                        onPressed: () {
                          controller.setData('onboarding_saved', true);
                          Navigator.of(
                            tester.element(find.byType(AlertDialog)),
                          ).pop();
                        },
                        child: const Text('Save & Exit'),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        // Wait for welcome screen
        await tester.pumpAndSettle();
        expect(find.text('Welcome Screen'), findsOneWidget);

        // Wait for permissions dialog
        await tester.pumpAndSettle();
        expect(find.text('Allow Camera Access?'), findsOneWidget);

        // Grant permission
        await tester.tap(find.text('Allow'));
        await tester.pumpAndSettle();

        // Fill profile information
        expect(find.text('Create Profile'), findsOneWidget);
        await tester.enterText(find.byType(TextField).first, 'testuser');
        await tester.enterText(find.byType(TextField).last, 'test@example.com');
        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        // Complete the flow
        await tester.pumpAndSettle();

        expect(find.text('Welcome, testuser!'), findsOneWidget);
      });
    });
  });
}
