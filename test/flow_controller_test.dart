import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sequential_flow/sequential_flow.dart';

enum TestStepType { step1, step2, step3 }

void main() {
  group('FlowController Tests', () {
    late FlowController<TestStepType> controller;
    late List<String> executionOrder;

    setUp(() {
      executionOrder = [];
    });

    group('Basic Flow Tests', () {
      test('should create controller with steps', () {
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Test Step',
            progressValue: 0.5,
            onStepCallback: (controller) async {},
          ),
        ];
        controller = FlowController<TestStepType>(steps: steps);
        expect(controller.steps.length, equals(1));
        expect(controller.isLoading, isFalse);
        expect(controller.isCompleted, isFalse);
        expect(controller.hasError, isFalse);
      });

      test('should start and complete simple flow', () async {
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Step 1',
            progressValue: 0.5,
            onStepCallback: (controller) async {
              executionOrder.add('step1');
            },
          ),
          FlowStep<TestStepType>(
            step: TestStepType.step2,
            name: 'Step 2',
            progressValue: 1.0,
            onStepCallback: (controller) async {
              executionOrder.add('step2');
            },
          ),
        ];
        
        controller = FlowController<TestStepType>(steps: steps);
        await controller.start();
        
        expect(controller.isCompleted, isTrue);
        expect(controller.isLoading, isFalse);
        expect(executionOrder, equals(['step1', 'step2']));
      });

      test('should handle error during execution', () async {
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Error Step',
            progressValue: 1.0,
            onStepCallback: (controller) async {
              throw Exception('Test error');
            },
          ),
        ];
        
        controller = FlowController<TestStepType>(steps: steps);
        await controller.start();
        
        expect(controller.hasError, isTrue);
        expect(controller.isCompleted, isFalse);
        expect(controller.error, isNotNull);
      });

      test('should handle confirmation step', () async {
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Confirm Step',
            progressValue: 1.0,
            onStepCallback: (controller) async {
              executionOrder.add('confirmed');
            },
            requiresConfirmation: (controller) => const Text('Confirm?'),
          ),
        ];
        
        controller = FlowController<TestStepType>(steps: steps);
        await controller.start();
        
        expect(controller.isWaitingConfirmation, isTrue);
        expect(executionOrder, isEmpty);
        
        // Continue flow after confirmation
        await controller.continueFlow();
        
        expect(controller.isCompleted, isTrue);
        expect(controller.isWaitingConfirmation, isFalse);
        expect(executionOrder, equals(['confirmed']));
      });
    });

    group('Data Management Tests', () {
      test('should store and retrieve data with type safety', () {
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Test Step',
            progressValue: 1.0,
            onStepCallback: (controller) async {},
          ),
        ];
        controller = FlowController<TestStepType>(steps: steps);

        // Test string data
        controller.setData('testKey', 'testValue');
        expect(controller.getData<String, String>('testKey'), equals('testValue'));

        // Test numeric data
        controller.setData('numberKey', 42);
        expect(controller.getData<String, int>('numberKey'), equals(42));

        // Test boolean data
        controller.setData('boolKey', true);
        expect(controller.getData<String, bool>('boolKey'), isTrue);

        // Test enum keys
        controller.setData(TestStepType.step1, 'enumValue');
        expect(controller.getData<TestStepType, String>(TestStepType.step1), equals('enumValue'));
      });

      test('should return null for non-existent keys', () {
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Test Step',
            progressValue: 1.0,
            onStepCallback: (controller) async {},
          ),
        ];
        controller = FlowController<TestStepType>(steps: steps);

        expect(controller.getData<String, String>('nonExistent'), isNull);
      });

      test('should clear data on reset', () {
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Test Step',
            progressValue: 1.0,
            onStepCallback: (controller) async {},
          ),
        ];
        controller = FlowController<TestStepType>(steps: steps);

        controller.setData('testKey', 'testValue');
        expect(controller.getData<String, String>('testKey'), equals('testValue'));

        controller.reset();
        expect(controller.getData<String, String>('testKey'), isNull);
      });
    });

    group('Flow Control Tests', () {
      test('should cancel flow', () async {
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Step 1',
            progressValue: 1.0,
            onStepCallback: (controller) async {
              executionOrder.add('step1');
            },
          ),
        ];
        
        controller = FlowController<TestStepType>(steps: steps);
        await controller.start();
        
        controller.cancelFlow();
        
        expect(controller.isCancelled, isTrue);
        expect(controller.isLoading, isFalse);
        expect(controller.isCompleted, isFalse);
      });

      test('should restart flow', () async {
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Step 1',
            progressValue: 1.0,
            onStepCallback: (controller) async {
              executionOrder.add('step1');
            },
          ),
        ];
        
        controller = FlowController<TestStepType>(steps: steps);
        await controller.start();
        
        expect(controller.isCompleted, isTrue);
        expect(executionOrder, equals(['step1']));
        
        executionOrder.clear();
        controller.restart();
        
        // Allow some time for restart to execute
        await Future.delayed(const Duration(milliseconds: 500));
        
        expect(executionOrder, equals(['step1']));
      });

      test('should retry after error', () async {
        bool shouldError = true;
        final steps = [
          FlowStep<TestStepType>(
            step: TestStepType.step1,
            name: 'Error Step',
            progressValue: 1.0,
            onStepCallback: (controller) async {
              if (shouldError) {
                shouldError = false; // Only error once
                throw Exception('Test error');
              }
              executionOrder.add('step1');
            },
          ),
        ];
        
        controller = FlowController<TestStepType>(steps: steps);
        await controller.start();
        
        expect(controller.hasError, isTrue);
        
        // Retry should succeed
        await controller.retry();
        
        expect(controller.hasError, isFalse);
        expect(controller.isCompleted, isTrue);
        expect(executionOrder, equals(['step1']));
      });
    });
  });
}