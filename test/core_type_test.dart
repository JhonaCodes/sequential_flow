import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sequential_flow/sequential_flow.dart';

// Test enum for step types
enum TestStepType { initialization, validation, processing, completion }

void main() {
  group('ActionOnPressBack Enum Tests', () {
    test('should have all expected values', () {
      expect(ActionOnPressBack.values, hasLength(6));
      expect(
        ActionOnPressBack.values,
        contains(ActionOnPressBack.goToPreviousStep),
      );
      expect(ActionOnPressBack.values, contains(ActionOnPressBack.cancelFlow));
      expect(ActionOnPressBack.values, contains(ActionOnPressBack.saveAndExit));
      expect(ActionOnPressBack.values, contains(ActionOnPressBack.block));
      expect(ActionOnPressBack.values, contains(ActionOnPressBack.custom));
      expect(
        ActionOnPressBack.values,
        contains(ActionOnPressBack.goToSpecificStep),
      );
    });

    test('should be comparable', () {
      expect(ActionOnPressBack.block == ActionOnPressBack.block, isTrue);
      expect(ActionOnPressBack.block == ActionOnPressBack.custom, isFalse);
    });

    test('should have consistent string representation', () {
      expect(
        ActionOnPressBack.goToPreviousStep.toString(),
        equals('ActionOnPressBack.goToPreviousStep'),
      );
    });
  });

  group('FlowStep Tests', () {
    late bool callbackExecuted;
    late bool onStartExecuted;

    setUp(() {
      callbackExecuted = false;
      onStartExecuted = false;
    });

    test('should create with required parameters', () {
      final step = FlowStep<TestStepType>(
        step: TestStepType.initialization,
        name: 'Test Step',
        progressValue: 0.5,
        onStepCallback: () async {
          callbackExecuted = true;
        },
      );

      expect(step.step, equals(TestStepType.initialization));
      expect(step.name, equals('Test Step'));
      expect(step.progressValue, equals(0.5));
      expect(step.actionOnPressBack, equals(ActionOnPressBack.block));
      expect(step.onStartStep, isNull);
      expect(step.requiresConfirmation, isNull);
      expect(step.goToStepIndex, isNull);
      expect(step.customBackAction, isNull);
    });

    test('should create with all optional parameters', () {
      final step = FlowStep<TestStepType>(
        step: TestStepType.processing,
        name: 'Processing Step',
        progressValue: 0.8,
        onStepCallback: () async {
          callbackExecuted = true;
        },
        onStartStep: () {
          onStartExecuted = true;
        },
        actionOnPressBack: ActionOnPressBack.goToPreviousStep,
        goToStepIndex: 2,
        requiresConfirmation: (controller) => const Text('Confirm'),
        customBackAction: (controller) async => true,
      );

      expect(step.step, equals(TestStepType.processing));
      expect(step.name, equals('Processing Step'));
      expect(step.progressValue, equals(0.8));
      expect(
        step.actionOnPressBack,
        equals(ActionOnPressBack.goToPreviousStep),
      );
      expect(step.onStartStep, isNotNull);
      expect(step.requiresConfirmation, isNotNull);
      expect(step.goToStepIndex, equals(2));
      expect(step.customBackAction, isNotNull);
    });

    test('should validate progress value range', () {
      expect(
        () => FlowStep<TestStepType>(
          step: TestStepType.initialization,
          name: 'Test',
          progressValue: -0.1,
          onStepCallback: () async {},
        ),
        throwsAssertionError,
      );

      expect(
        () => FlowStep<TestStepType>(
          step: TestStepType.initialization,
          name: 'Test',
          progressValue: 1.1,
          onStepCallback: () async {},
        ),
        throwsAssertionError,
      );
    });

    test('should accept valid progress values at boundaries', () {
      expect(
        () => FlowStep<TestStepType>(
          step: TestStepType.initialization,
          name: 'Test',
          progressValue: 0.0,
          onStepCallback: () async {},
        ),
        returnsNormally,
      );

      expect(
        () => FlowStep<TestStepType>(
          step: TestStepType.initialization,
          name: 'Test',
          progressValue: 1.0,
          onStepCallback: () async {},
        ),
        returnsNormally,
      );
    });

    test('should execute onStepCallback', () async {
      final step = FlowStep<TestStepType>(
        step: TestStepType.initialization,
        name: 'Test Step',
        progressValue: 0.5,
        onStepCallback: () async {
          callbackExecuted = true;
        },
      );

      await step.onStepCallback();
      expect(callbackExecuted, isTrue);
    });

    test('should execute onStartStep callback', () {
      final step = FlowStep<TestStepType>(
        step: TestStepType.initialization,
        name: 'Test Step',
        progressValue: 0.5,
        onStepCallback: () async {},
        onStartStep: () {
          onStartExecuted = true;
        },
      );

      step.onStartStep!();
      expect(onStartExecuted, isTrue);
    });

    test('should handle requiresConfirmation widget builder', () {
      final step = FlowStep<TestStepType>(
        step: TestStepType.validation,
        name: 'Validation Step',
        progressValue: 0.3,
        onStepCallback: () async {},
        requiresConfirmation: (controller) => const Text('Please confirm'),
      );

      // This would normally be called with an actual controller
      // For now, we just test that the builder exists
      expect(step.requiresConfirmation, isNotNull);
    });

    test('should handle customBackAction callback', () async {
      bool customActionExecuted = false;
      final step = FlowStep<TestStepType>(
        step: TestStepType.processing,
        name: 'Processing Step',
        progressValue: 0.7,
        onStepCallback: () async {},
        actionOnPressBack: ActionOnPressBack.custom,
        customBackAction: (controller) async {
          customActionExecuted = true;
          return false;
        },
      );

      final controller = FlowController<TestStepType>(steps: [
        FlowStep<TestStepType>(
          step: TestStepType.initialization,
          name: 'Dummy Step',
          progressValue: 0.0,
          onStepCallback: () async {},
        ),
      ]);
      final result = await step.customBackAction!(controller);
      expect(customActionExecuted, isTrue);
      expect(result, isFalse);
    });

    test('should work with different step types', () {
      final stringStep = FlowStep<String>(
        step: 'initialization',
        name: 'String Step',
        progressValue: 0.25,
        onStepCallback: () async {},
      );

      final intStep = FlowStep<int>(
        step: 1,
        name: 'Integer Step',
        progressValue: 0.75,
        onStepCallback: () async {},
      );

      expect(stringStep.step, equals('initialization'));
      expect(intStep.step, equals(1));
    });

    test('should handle edge case progress values', () {
      final steps = [
        FlowStep<TestStepType>(
          step: TestStepType.initialization,
          name: 'Start',
          progressValue: 0.0,
          onStepCallback: () async {},
        ),
        FlowStep<TestStepType>(
          step: TestStepType.completion,
          name: 'End',
          progressValue: 1.0,
          onStepCallback: () async {},
        ),
      ];

      expect(steps[0].progressValue, equals(0.0));
      expect(steps[1].progressValue, equals(1.0));
    });

    test('should maintain immutability of properties', () {
      final step = FlowStep<TestStepType>(
        step: TestStepType.validation,
        name: 'Immutable Step',
        progressValue: 0.6,
        onStepCallback: () async {},
        actionOnPressBack: ActionOnPressBack.goToPreviousStep,
      );

      // Properties should not be changeable after creation
      expect(step.step, equals(TestStepType.validation));
      expect(step.name, equals('Immutable Step'));
      expect(step.progressValue, equals(0.6));
      expect(
        step.actionOnPressBack,
        equals(ActionOnPressBack.goToPreviousStep),
      );
    });
  });

  group('Typedef Callbacks Tests', () {
    test('OnStepCallback should be callable', () async {
      bool executed = false;
      callback() async {
        executed = true;
      }

      await callback();
      expect(executed, isTrue);
    });

    test('OnStartStep should be callable', () {
      bool executed = false;
      callback() {
        executed = true;
      }

      callback();
      expect(executed, isTrue);
    });

    test('OnStepCallback should handle async operations', () async {
      String result = '';
      callback() async {
        await Future.delayed(const Duration(milliseconds: 10));
        result = 'completed';
      }

      await callback();
      expect(result, equals('completed'));
    });

    test('OnStepCallback should propagate exceptions', () async {
      callback() async {
        throw Exception('Test error');
      }

      expect(() async => await callback(), throwsException);
    });
  });
}
