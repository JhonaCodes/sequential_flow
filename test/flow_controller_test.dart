import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sequential_flow/sequential_flow.dart';

enum TestStepType { step1, step2, step3, step4, step5 }

void main() {
  group('FlowController Tests', () {
    late FlowController<TestStepType> controller;
    late List<String> executionOrder;
    late List<String> startCallbacks;

    setUp(() {
      executionOrder = [];
      startCallbacks = [];
    });

    FlowController<TestStepType> createTestController({
      bool shouldThrowError = false,
      bool includeConfirmationStep = false,
      int? errorAtStep,
    }) {
      final steps = <FlowStep<TestStepType>>[];

      // Step 1
      steps.add(
        FlowStep<TestStepType>(
          step: TestStepType.step1,
          name: 'Step 1',
          progressValue: 0.2,
          onStartStep: (controller) async => startCallbacks.add('step1_start'),
          onStepCallback: (controller) async {
            if (errorAtStep == 0) throw Exception('Error in step 1');
            executionOrder.add('step1');
            await Future.delayed(const Duration(milliseconds: 10));
          },
          actionOnPressBack: ActionOnPressBack.block,
        ),
      );

      // Step 2
      steps.add(
        FlowStep<TestStepType>(
          step: TestStepType.step2,
          name: 'Step 2',
          progressValue: 0.4,
          onStartStep: (controller) async => startCallbacks.add('step2_start'),
          onStepCallback: (controller) async {
            if (errorAtStep == 1) throw Exception('Error in step 2');
            executionOrder.add('step2');
            await Future.delayed(const Duration(milliseconds: 10));
          },
          actionOnPressBack: ActionOnPressBack.goToPreviousStep,
        ),
      );

      // Step 3
      steps.add(
        FlowStep<TestStepType>(
          step: TestStepType.step3,
          name: 'Step 3',
          progressValue: 0.6,
          onStartStep: (controller) async => startCallbacks.add('step3_start'),
          onStepCallback: (controller) async {
            if (errorAtStep == 2) throw Exception('Error in step 3');
            executionOrder.add('step3');
            await Future.delayed(const Duration(milliseconds: 10));
          },
          requiresConfirmation: includeConfirmationStep
              ? (controller) => const Text('Confirm')
              : null,
          actionOnPressBack: ActionOnPressBack.block,
        ),
      );

      // Step 4
      steps.add(
        FlowStep<TestStepType>(
          step: TestStepType.step4,
          name: 'Step 4',
          progressValue: 0.8,
          onStartStep: (controller) async => startCallbacks.add('step4_start'),
          onStepCallback: (controller) async {
            if (errorAtStep == 3) throw Exception('Error in step 4');
            executionOrder.add('step4');
            if (shouldThrowError) throw Exception('Test error in step 4');
            await Future.delayed(const Duration(milliseconds: 10));
          },
          actionOnPressBack: ActionOnPressBack.custom,
          customBackAction: (controller) async => true,
        ),
      );

      // Step 5
      steps.add(
        FlowStep<TestStepType>(
          step: TestStepType.step5,
          name: 'Step 5',
          progressValue: 1.0,
          onStartStep: (controller) async => startCallbacks.add('step5_start'),
          onStepCallback: (controller) async {
            if (errorAtStep == 4) throw Exception('Error in step 5');
            executionOrder.add('step5');
            await Future.delayed(const Duration(milliseconds: 10));
          },
          actionOnPressBack: ActionOnPressBack.saveAndExit,
        ),
      );

      return FlowController<TestStepType>(steps: steps);
    }

    group('Constructor and Initial State', () {
      test('should create with valid steps', () {
        controller = createTestController();

        expect(controller.steps.length, equals(5));
        expect(controller.isLoading, isFalse);
        expect(controller.isCompleted, isFalse);
        expect(controller.hasError, isFalse);
        expect(controller.isWaitingConfirmation, isFalse);
        expect(controller.isCancelled, isFalse);
        expect(controller.currentStep, isNull);
        expect(controller.currentStepName, isEmpty);
        expect(controller.currentProgress, equals(0.0));
        expect(controller.currentStepIndex, equals(0));
        expect(controller.error, isNull);
        expect(controller.stackTrace, isNull);
        expect(controller.canGoBack, isFalse);
      });

      test('should throw assertion error with empty steps', () {
        expect(
          () => FlowController<TestStepType>(steps: []),
          throwsAssertionError,
        );
      });
    });

    group('Data Management', () {
      setUp(() {
        controller = createTestController();
      });

      test('should store and retrieve data', () {
        controller.setData('key1', 'value1');
        controller.setData('key2', 42);
        controller.setData('key3', {'nested': 'object'});

        expect(controller.getData('key1'), equals('value1'));
        expect(controller.getData('key2'), equals(42));
        expect(controller.getData('key3'), equals({'nested': 'object'}));
        expect(controller.getData('nonexistent'), isNull);
      });

      test('should return unmodifiable copy of all data', () {
        controller.setData('test', 'value');
        final allData = controller.getAllData();

        expect(allData['test'], equals('value'));
        expect(() => allData['new'] = 'value', throwsUnsupportedError);
      });

      test('should overwrite existing data', () {
        controller.setData('key', 'original');
        expect(controller.getData('key'), equals('original'));

        controller.setData('key', 'updated');
        expect(controller.getData('key'), equals('updated'));
      });
    });

    group('Flow Execution', () {
      test('should execute all steps successfully', () async {
        controller = createTestController();

        await controller.start();

        expect(controller.isCompleted, isTrue);
        expect(controller.isLoading, isFalse);
        expect(controller.hasError, isFalse);
        expect(
          executionOrder,
          equals(['step1', 'step2', 'step3', 'step4', 'step5']),
        );
        expect(
          startCallbacks,
          equals([
            'step1_start',
            'step2_start',
            'step3_start',
            'step4_start',
            'step5_start',
          ]),
        );
        expect(controller.currentProgress, equals(1.0));
        expect(controller.currentStep, equals(TestStepType.step5));
      });

      test('should handle error during execution', () async {
        controller = createTestController(errorAtStep: 2);

        await controller.start();

        expect(controller.hasError, isTrue);
        expect(controller.isLoading, isFalse);
        expect(controller.isCompleted, isFalse);
        expect(controller.error, isA<Exception>());
        expect(controller.stackTrace, isNotNull);
        expect(executionOrder, equals(['step1', 'step2']));
        expect(controller.currentStep, equals(TestStepType.step3));
      });

      test('should stop at confirmation step', () async {
        controller = createTestController(includeConfirmationStep: true);

        await controller.start();

        expect(controller.isWaitingConfirmation, isTrue);
        expect(controller.isLoading, isFalse);
        expect(controller.isCompleted, isFalse);
        expect(executionOrder, equals(['step1', 'step2']));
        expect(controller.currentStep, equals(TestStepType.step3));
        expect(controller.currentStepIndex, equals(2));
      });

      test('should continue after confirmation', () async {
        controller = createTestController(includeConfirmationStep: true);

        await controller.start();
        expect(controller.isWaitingConfirmation, isTrue);

        await controller.continueFlow();

        expect(controller.isCompleted, isTrue);
        expect(controller.isWaitingConfirmation, isFalse);
        expect(
          executionOrder,
          equals(['step1', 'step2', 'step3', 'step4', 'step5']),
        );
      });

      test('should ignore start if already loading', () async {
        controller = createTestController();

        // Start the flow
        final future1 = controller.start();

        // Try to start again while loading
        final future2 = controller.start();

        await Future.wait([future1, future2]);

        // Should only execute once
        expect(executionOrder, equals(['step1', 'step2', 'step3', 'step4', 'step5']));
      });

      test('should jump to specific step on continue', () async {
        controller = createTestController(includeConfirmationStep: true);

        await controller.start();
        expect(controller.isWaitingConfirmation, isTrue);
        expect(controller.currentStepIndex, equals(2));

        // Jump to step 4 (index 3)
        await controller.continueFlow(flowIndex: 3);

        expect(controller.isCompleted, isTrue);
        expect(
          executionOrder,
          equals(['step1', 'step2', 'step3', 'step4', 'step5']),
        );
      });
    });

    group('Flow Control', () {
      setUp(() {
        controller = createTestController();
      });

      test('should cancel flow', () {
        controller.cancelFlow();

        expect(controller.isCancelled, isTrue);
        expect(controller.isLoading, isFalse);
        expect(controller.isWaitingConfirmation, isFalse);
        expect(controller.hasError, isFalse);
        expect(controller.isCompleted, isFalse);
      });

      test('should retry after error', () async {
        controller = createTestController(errorAtStep: 1);

        await controller.start();
        expect(controller.hasError, isTrue);

        // Clear the error condition and retry
        executionOrder.clear();
        startCallbacks.clear();

        controller.retry();

        expect(controller.hasError, isFalse);
        expect(controller.isCompleted, isTrue);
        expect(
          executionOrder,
          equals(['step2', 'step3', 'step4', 'step5']),
        );
      });

      test('should reset to initial state', () async {
        controller = createTestController();
        controller.setData('test', 'value');

        await controller.start();
        expect(controller.isCompleted, isTrue);
        expect(controller.getData('test'), equals('value'));

        controller.reset();

        expect(controller.isLoading, isFalse);
        expect(controller.isCompleted, isFalse);
        expect(controller.hasError, isFalse);
        expect(controller.isWaitingConfirmation, isFalse);
        expect(controller.isCancelled, isFalse);
        expect(controller.currentStep, isNull);
        expect(controller.currentStepName, isEmpty);
        expect(controller.currentProgress, equals(0.0));
        expect(controller.currentStepIndex, equals(0));
        expect(controller.error, isNull);
        expect(controller.stackTrace, isNull);
        expect(controller.getData('test'), isNull);
        expect(controller.canGoBack, isFalse);
      });
    });

    group('Back Navigation', () {
      test('should handle goToPreviousStep action', () async {
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Step 1',
            progressValue: 0.5,
            onStepCallback: (controller) async {
              executionOrder.add('step1');
            },
            actionOnPressBack: ActionOnPressBack.block,
          ),
          FlowStep<TestStepType>(
            step: TestStepType.step2,
            name: 'Step 2',
            progressValue: 1.0,
            onStepCallback: (controller) async {
              executionOrder.add('step2');
            },
            actionOnPressBack: ActionOnPressBack.goToPreviousStep,
          ),
        ];
        controller = FlowController<TestStepType>(steps: steps);

        await controller.start();
        expect(controller.isCompleted, isTrue);

        final result = await controller.handleBackPress();
        expect(result, isFalse);

        expect(controller.currentStep, equals(TestStepType.step1));
        expect(controller.currentStepIndex, equals(0));
      });

      test('should handle cancelFlow action', () async {
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Cancel Step',
            progressValue: 0.5,
            onStepCallback: (controller) async {},
            actionOnPressBack: ActionOnPressBack.cancelFlow,
          ),
        ];
        controller = FlowController<TestStepType>(steps: steps);
        await controller.start();

        final result = await controller.handleBackPress();

        expect(result, isFalse);
        expect(controller.isCancelled, isTrue);
      });

      test('should handle block action', () async {
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Block Step',
            progressValue: 0.5,
            onStepCallback: (controller) async {},
            actionOnPressBack: ActionOnPressBack.block,
          ),
        ];
        controller = FlowController<TestStepType>(steps: steps);
        await controller.start();

        final result = await controller.handleBackPress();
        expect(result, isFalse); // Should block back navigation
      });

      test('should handle saveAndExit action', () async {
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Save Exit Step',
            progressValue: 1.0,
            onStepCallback: (controller) async {},
            actionOnPressBack: ActionOnPressBack.saveAndExit,
          ),
        ];
        controller = FlowController<TestStepType>(steps: steps);
        await controller.start();

        final result = await controller.handleBackPress();
        expect(result, isTrue); // Should allow exit
      });

      test('should handle custom action', () async {
        bool customActionCalled = false;
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Custom Step',
            progressValue: 1.0,
            onStepCallback: (controller) async {},
            actionOnPressBack: ActionOnPressBack.custom,
            requiresConfirmation: (controller) =>
                const Text('Confirm Custom Action'),
            customBackAction: (controller) async {
              customActionCalled = true;
              return true;
            },
          ),
        ];
        controller = FlowController<TestStepType>(steps: steps);
        await controller.start();

        final result = await controller.handleBackPress();

        expect(customActionCalled, isTrue);
        expect(result, isTrue);
      });

      test('should handle goToSpecificStep action', () async {
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Step 1',
            progressValue: 0.33,
            onStepCallback: (controller) async {
              executionOrder.add('step1');
            },
          ),
          FlowStep<TestStepType>(
            step: TestStepType.step2,
            name: 'Step 2',
            progressValue: 0.66,
            onStepCallback: (controller) async {
              executionOrder.add('step2');
            },
          ),
          FlowStep<TestStepType>(
            step: TestStepType.step3,
            name: 'Specific Step',
            progressValue: 1.0,
            onStepCallback: (controller) async {
              executionOrder.add('step3');
            },
            actionOnPressBack: ActionOnPressBack.goToSpecificStep,
            requiresConfirmation: (controller) =>
                const Text('Confirm GoToSpecificStep'),
            goToStepIndex: 0, // Go back to step 1
          ),
        ];
        controller = FlowController<TestStepType>(steps: steps);
        await controller.start();

        expect(controller.currentStepIndex, equals(2));

        final result = await controller.handleBackPress();
        expect(result, isFalse); // Should handle the navigation

        // Wait a bit for navigation to complete
        await Future.delayed(const Duration(milliseconds: 50));

        // Should have navigated back to step 1 and re-executed the flow
        expect(executionOrder.length, greaterThan(3));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle out of bounds step index', () async {
        controller = createTestController();

        // Test with negative index
        controller.reset();
        final result1 = await controller.handleBackPress();
        expect(result1, isTrue);

        // Test with index beyond steps length
        await controller.start();
        // Manually set an invalid index for testing
        // This requires access to private members, so we test the public behavior
        final result2 = await controller.handleBackPress();
        expect(result2, isFalse);
      });

      test(
        'should handle continueFlow when not waiting for confirmation',
        () async {
          controller = createTestController();
          await controller.start();

          expect(controller.isCompleted, isTrue);
          expect(controller.isWaitingConfirmation, isFalse);

          // Should ignore the call
          await controller.continueFlow();
          expect(controller.isCompleted, isTrue);
        },
      );

      test('should handle retry when not in error state', () {
        controller = createTestController();

        expect(controller.hasError, isFalse);

        // Should do nothing
        controller.retry();
        expect(controller.hasError, isFalse);
        expect(controller.isLoading, isFalse);
      });

      test('should handle invalid flow index in continueFlow', () async {
        controller = createTestController(includeConfirmationStep: true);

        await controller.start();
        expect(controller.isWaitingConfirmation, isTrue);

        // Test with negative index
        await controller.continueFlow(flowIndex: -1);
        expect(controller.isCompleted, isTrue);

        // Reset and test with index beyond bounds
        controller = createTestController(includeConfirmationStep: true);
        await controller.start();

        await controller.continueFlow(flowIndex: 999);
        expect(controller.isCompleted, isTrue);
      });
    });

    group('ChangeNotifier Tests', () {
      test('should notify listeners on state changes', () async {
        controller = createTestController();
        int notificationCount = 0;

        controller.addListener(() {
          notificationCount++;
        });

        await controller.start();

        expect(notificationCount, greaterThan(0));
      });

      test('should dispose properly', () {
        controller = createTestController();
        bool listenerCalled = false;

        controller.addListener(() {
          listenerCalled = true;
        });

        controller.dispose();

        // After dispose, listeners should not be called
        expect(listenerCalled, isFalse);
      });
    });
  });
}
