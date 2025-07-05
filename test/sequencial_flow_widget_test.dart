import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sequential_flow/sequential_flow.dart';

enum TestStepType { step1, step2, step3, errorStep, confirmationStep }

void main() {
  group('SequentialFlow Widget Tests', () {
    late List<String> executionOrder;
    late List<String> uiCallbacks;

    setUp(() {
      executionOrder = [];
      uiCallbacks = [];
    });

    List<FlowStep<TestStepType>> createBasicSteps({
      bool includeError = false,
      bool includeConfirmation = false,
      ActionOnPressBack? customBackAction,
    }) {
      return [
        FlowStep<TestStepType>(
          step: TestStepType.step1,
          name: 'Step 1',
          progressValue: 0.33,
          onStepCallback: () async {
            executionOrder.add('step1');
            await Future.delayed(const Duration(milliseconds: 10));
          },
          actionOnPressBack: ActionOnPressBack.block,
        ),
        FlowStep<TestStepType>(
          step: TestStepType.step2,
          name: 'Step 2',
          progressValue: 0.66,
          onStepCallback: () async {
            executionOrder.add('step2');
            if (includeError) throw Exception('Test error');
            await Future.delayed(const Duration(milliseconds: 10));
          },
          actionOnPressBack:
              customBackAction ?? ActionOnPressBack.goToPreviousStep,
        ),
        FlowStep<TestStepType>(
          step: TestStepType.step3,
          name: 'Step 3',
          progressValue: 1.0,
          onStepCallback: () async {
            executionOrder.add('step3');
            await Future.delayed(const Duration(milliseconds: 10));
          },
          requiresConfirmation: includeConfirmation
              ? (controller) => AlertDialog(
                  title: const Text('Confirm'),
                  content: const Text('Are you sure?'),
                  actions: [
                    TextButton(
                      onPressed: () => controller.continueFlow(),
                      child: const Text('Yes'),
                    ),
                  ],
                )
              : null,
          actionOnPressBack: ActionOnPressBack.saveAndExit,
        ),
      ];
    }

    Widget createTestWidget({
      List<FlowStep<TestStepType>>? steps,
      bool autoStart = true,
      Widget Function(TestStepType, String, double)? onStepLoading,
      Widget Function(
        TestStepType,
        String,
        Object,
        StackTrace,
        FlowController<TestStepType>,
      )?
      onStepError,
      Widget Function(
        TestStepType,
        String,
        double,
        FlowController<TestStepType>,
      )?
      onStepFinish,
      Widget Function(TestStepType, String, FlowController<TestStepType>)?
      onStepCancel,
      Widget Function(FlowController<TestStepType>)? onPressBack,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SequentialFlow<TestStepType>(
            steps: steps ?? createBasicSteps(),
            autoStart: autoStart,
            onStepLoading:
                onStepLoading ??
                (step, name, progress) {
                  uiCallbacks.add('loading_${step.name}_$progress');
                  return Text('Loading: $name ($progress)');
                },
            onStepError:
                onStepError ??
                (step, name, error, stack, controller) {
                  uiCallbacks.add('error_${step.name}');
                  return Column(
                    children: [
                      Text('Error in $name: $error'),
                      ElevatedButton(
                        onPressed: () => controller.retry(),
                        child: const Text('Retry'),
                      ),
                    ],
                  );
                },
            onStepFinish:
                onStepFinish ??
                (step, name, progress, controller) {
                  uiCallbacks.add('finish_${step.name}');
                  return Text('Completed: $name');
                },
            onStepCancel:
                onStepCancel ??
                (step, name, controller) {
                  uiCallbacks.add('cancel_${step.name}');
                  return Text('Cancelled: $name');
                },
            onPressBack: onPressBack,
          ),
        ),
      );
    }

    group('Widget Creation and Basic Functionality', () {
      testWidgets('should create widget with required parameters', (
        tester,
      ) async {
        await tester.pumpWidget(createTestWidget());
        expect(find.byType(SequentialFlow<TestStepType>), findsOneWidget);
      });

      testWidgets('should throw assertion error with empty steps', (
        tester,
      ) async {
        expect(
          () => SequentialFlow<TestStepType>(steps: []),
          throwsAssertionError,
        );
      });

      testWidgets('should auto-start flow by default', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Wait for flow to complete
        await tester.pumpAndSettle();

        expect(executionOrder, contains('step1'));
        expect(find.text('Completed: Step 3'), findsOneWidget);
      });

      testWidgets('should not auto-start when autoStart is false', (
        tester,
      ) async {
        await tester.pumpWidget(createTestWidget(autoStart: false));
        await tester.pumpAndSettle();

        expect(executionOrder, isEmpty);
        expect(find.text('Loading:'), findsNothing);
      });
    });

    group('UI State Management', () {
      testWidgets('should display loading state', (tester) async {
        // Create a step that takes longer to complete
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Long Step',
            progressValue: 1.0,
            onStepCallback: () async {
              await Future.delayed(const Duration(milliseconds: 100));
            },
          ),
        ];

        await tester.pumpWidget(createTestWidget(steps: steps));

        // Should show loading state initially
        expect(find.textContaining('Loading: Long Step'), findsOneWidget);

        // Wait for completion
        await tester.pumpAndSettle();
        expect(find.text('Completed: Long Step'), findsOneWidget);
      });

      testWidgets('should display error state and handle retry', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(steps: createBasicSteps(includeError: true)),
        );

        // Wait for error to occur
        await tester.pumpAndSettle();

        expect(find.textContaining('Error in Step 2'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
        expect(uiCallbacks, contains('error_step2'));
      });

      testWidgets('should display completion state', (tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.pumpAndSettle();

        expect(find.text('Completed: Step 3'), findsOneWidget);
        expect(uiCallbacks, contains('finish_step3'));
      });

      testWidgets('should display cancellation state', (tester) async {
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Cancelable Step',
            progressValue: 1.0,
            onStepCallback: () async {
              await Future.delayed(const Duration(milliseconds: 50));
            },
            actionOnPressBack: ActionOnPressBack.cancelFlow,
          ),
        ];

        await tester.pumpWidget(createTestWidget(steps: steps));

        // Simulate back button press to trigger cancel
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/navigation',
          null,
          (data) {},
        );

        await tester.pumpAndSettle();

        // Check if cancellation UI is shown
        expect(uiCallbacks, contains('cancel_cancelableStep'));
      });

      testWidgets('should handle confirmation step', (tester) async {
        await tester.pumpWidget(
          createTestWidget(steps: createBasicSteps(includeConfirmation: true)),
        );

        // Wait for confirmation dialog
        await tester.pumpAndSettle();

        expect(find.text('Confirm'), findsOneWidget);
        expect(find.text('Are you sure?'), findsOneWidget);
        expect(find.text('Yes'), findsOneWidget);

        // Tap yes to continue
        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        expect(find.text('Completed: Step 3'), findsOneWidget);
      });
    });

    group('Back Navigation Handling', () {
      testWidgets('should validate required onPressBack for dialog actions', (
        tester,
      ) async {
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Dialog Step',
            progressValue: 1.0,
            onStepCallback: () async {},
            actionOnPressBack: ActionOnPressBack.custom,
          ),
        ];

        expect(
          () => tester.pumpWidget(createTestWidget(steps: steps)),
          throwsFlutterError,
        );
      });

      testWidgets('should validate required onPressBack for custom actions', (
        tester,
      ) async {
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Custom Step',
            progressValue: 1.0,
            onStepCallback: () async {},
            actionOnPressBack: ActionOnPressBack.custom,
          ),
        ];

        expect(
          () => tester.pumpWidget(createTestWidget(steps: steps)),
          throwsFlutterError,
        );
      });

      testWidgets('should handle custom back action', (tester) async {
        bool customBackCalled = false;
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Custom Step',
            progressValue: 1.0,
            onStepCallback: () async {},
            actionOnPressBack: ActionOnPressBack.custom,
          ),
        ];

        await tester.pumpWidget(
          createTestWidget(
            steps: steps,
            onPressBack: (controller) {
              customBackCalled = true;
              return const Text('Custom Back Widget');
            },
          ),
        );

        await tester.pumpAndSettle();

        expect(customBackCalled, isTrue);
        expect(find.text('Custom Back Widget'), findsOneWidget);
      });

      testWidgets('should handle showCancelDialog action', (tester) async {
        bool cancelDialogShown = false;
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Cancel Dialog Step',
            progressValue: 1.0,
            onStepCallback: () async {},
            actionOnPressBack: ActionOnPressBack.custom,
          ),
        ];

        await tester.pumpWidget(
          createTestWidget(
            steps: steps,
            onPressBack: (controller) {
              cancelDialogShown = true;
              return AlertDialog(
                title: const Text('Cancel?'),
                actions: [
                  TextButton(
                    onPressed: () => controller.cancelFlow(),
                    child: const Text('Cancel Flow'),
                  ),
                ],
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        expect(cancelDialogShown, isTrue);
        expect(find.text('Cancel?'), findsOneWidget);
      });

      testWidgets('should handle showSaveDialog action', (tester) async {
        bool saveDialogShown = false;
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Save Dialog Step',
            progressValue: 1.0,
            onStepCallback: () async {},
            actionOnPressBack: ActionOnPressBack.custom,
          ),
        ];

        await tester.pumpWidget(
          createTestWidget(
            steps: steps,
            onPressBack: (controller) {
              saveDialogShown = true;
              return AlertDialog(
                title: const Text('Save & Exit?'),
                actions: [
                  TextButton(onPressed: () {}, child: const Text('Save')),
                ],
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        expect(saveDialogShown, isTrue);
        expect(find.text('Save & Exit?'), findsOneWidget);
      });

      testWidgets('should handle block navigation', (tester) async {
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Blocked Step',
            progressValue: 1.0,
            onStepCallback: () async {},
            actionOnPressBack: ActionOnPressBack.block,
          ),
        ];

        await tester.pumpWidget(createTestWidget(steps: steps));
        await tester.pumpAndSettle();

        // Try to navigate back - should be blocked
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/navigation',
          null,
          (data) {},
        );

        await tester.pumpAndSettle();

        // Should still be on the same screen
        expect(find.text('Completed: Blocked Step'), findsOneWidget);
      });
    });

    group('Default Widget Fallbacks', () {
      testWidgets(
        'should show default loading widget when no builder provided',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: SequentialFlow<TestStepType>(
                steps: [
                  FlowStep<TestStepType>(
                    step: TestStepType.step1,
                    name: 'Default Loading',
                    progressValue: 1.0,
                    onStepCallback: () async {
                      await Future.delayed(const Duration(milliseconds: 50));
                    },
                  ),
                ],
              ),
            ),
          );

          // Should show default text
          expect(find.text('Default Loading'), findsOneWidget);

          await tester.pumpAndSettle();
        },
      );

      testWidgets('should show default error widget when no builder provided', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SequentialFlow<TestStepType>(
              steps: [
                FlowStep<TestStepType>(
                  step: TestStepType.step1,
                  name: 'Error Step',
                  progressValue: 1.0,
                  onStepCallback: () async {
                    throw Exception('Default error');
                  },
                ),
              ],
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.textContaining('Error: Exception: Default error'),
          findsOneWidget,
        );
      });

      testWidgets(
        'should show default completion widget when no builder provided',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: SequentialFlow<TestStepType>(
                steps: [
                  FlowStep<TestStepType>(
                    step: TestStepType.step1,
                    name: 'Default Complete',
                    progressValue: 1.0,
                    onStepCallback: () async {},
                  ),
                ],
              ),
            ),
          );

          await tester.pumpAndSettle();

          expect(find.text('Completed: Default Complete'), findsOneWidget);
        },
      );

      testWidgets(
        'should show default cancelled widget when no builder provided',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: SequentialFlow<TestStepType>(
                steps: [
                  FlowStep<TestStepType>(
                    step: TestStepType.step1,
                    name: 'Default Cancel',
                    progressValue: 1.0,
                    onStepCallback: () async {
                      await Future.delayed(const Duration(milliseconds: 50));
                    },
                    actionOnPressBack: ActionOnPressBack.cancelFlow,
                  ),
                ],
              ),
            ),
          );

          // Let the step start, then trigger cancellation through controller
          await tester.pump();

          // Find the SequentialFlow widget and access its controller
          final sequentialFlowState = tester
              .state<SequentialFlowState<TestStepType>>(
                find.byType(SequentialFlow<TestStepType>),
              );
          sequentialFlowState.controller.cancelFlow();

          await tester.pumpAndSettle();

          expect(find.text('Cancelled: Default Cancel'), findsOneWidget);
        },
      );
    });

    group('Edge Cases and Error Conditions', () {
      testWidgets('should handle controller disposal', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Remove the widget
        await tester.pumpWidget(const MaterialApp(home: Text('Empty')));

        // Should not throw any errors
        expect(find.text('Empty'), findsOneWidget);
      });

      testWidgets('should handle multiple rapid state changes', (tester) async {
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Rapid Step',
            progressValue: 1.0,
            onStepCallback: () async {
              // Very quick execution
              await Future.delayed(const Duration(milliseconds: 1));
            },
          ),
        ];

        await tester.pumpWidget(createTestWidget(steps: steps));

        // Pump multiple times rapidly
        await tester.pump();
        await tester.pump();
        await tester.pump();

        await tester.pumpAndSettle();

        expect(find.text('Completed: Rapid Step'), findsOneWidget);
      });

      testWidgets('should handle empty step name', (tester) async {
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: '',
            progressValue: 1.0,
            onStepCallback: () async {},
          ),
        ];

        await tester.pumpWidget(createTestWidget(steps: steps));
        await tester.pumpAndSettle();

        expect(find.text('Completed: '), findsOneWidget);
      });

      testWidgets('should handle zero progress value', (tester) async {
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Zero Progress',
            progressValue: 0.0,
            onStepCallback: () async {},
          ),
        ];

        await tester.pumpWidget(createTestWidget(steps: steps));
        await tester.pumpAndSettle();

        expect(find.text('Completed: Zero Progress'), findsOneWidget);
      });

      testWidgets('should handle single step flow', (tester) async {
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Only Step',
            progressValue: 1.0,
            onStepCallback: () async {
              executionOrder.add('single');
            },
          ),
        ];

        await tester.pumpWidget(createTestWidget(steps: steps));
        await tester.pumpAndSettle();

        expect(executionOrder, equals(['single']));
        expect(find.text('Completed: Only Step'), findsOneWidget);
      });
    });

    group('Integration Tests', () {
      testWidgets('should handle complex flow with all features', (
        tester,
      ) async {
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Init',
            progressValue: 0.25,
            onStepCallback: () async {
              executionOrder.add('init');
              await Future.delayed(const Duration(milliseconds: 10));
            },
            actionOnPressBack: ActionOnPressBack.block,
          ),
          FlowStep<TestStepType>(
            step: TestStepType.confirmationStep,
            name: 'Confirm',
            progressValue: 0.5,
            onStepCallback: () async {
              executionOrder.add('confirm');
            },
            requiresConfirmation: (controller) => AlertDialog(
              title: const Text('Please Confirm'),
              actions: [
                TextButton(
                  onPressed: () => controller.continueFlow(),
                  child: const Text('Continue'),
                ),
                TextButton(
                  onPressed: () => controller.cancelFlow(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
            actionOnPressBack: ActionOnPressBack.custom,
          ),
          FlowStep<TestStepType>(
            step: TestStepType.step3,
            name: 'Final',
            progressValue: 1.0,
            onStepCallback: () async {
              executionOrder.add('final');
            },
            actionOnPressBack: ActionOnPressBack.saveAndExit,
          ),
        ];

        await tester.pumpWidget(
          createTestWidget(
            steps: steps,
            onPressBack: (controller) => AlertDialog(
              title: const Text('Really Cancel?'),
              actions: [
                TextButton(
                  onPressed: () => controller.cancelFlow(),
                  child: const Text('Yes, Cancel'),
                ),
              ],
            ),
          ),
        );

        // Wait for confirmation dialog
        await tester.pumpAndSettle();

        expect(find.text('Please Confirm'), findsOneWidget);
        expect(executionOrder, equals(['init']));

        // Continue the flow
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        expect(find.text('Completed: Final'), findsOneWidget);
        expect(executionOrder, equals(['init', 'confirm', 'final']));
      });
    });
  });
}
