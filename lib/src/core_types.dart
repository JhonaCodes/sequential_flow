import 'package:flutter/material.dart';

import 'flow_controller.dart';

/// A callback function that is executed when a step is processed.
///
/// This function should contain the main logic for the step and return
/// a Future that completes when the step is finished.
typedef OnStepCallback = Future<void> Function();

/// A callback function that is executed when a step starts.
///
/// This function is called before the step's main logic ([OnStepCallback])
/// is executed and can be used for initialization or UI updates.
typedef OnStartStep = void Function();

/// Defines the behavior when the back button is pressed during flow execution.
///
/// This enum controls how the flow should respond to back navigation attempts,
/// providing various options from simple navigation to custom behaviors.
enum ActionOnPressBack {
  /// Navigate to the previous step in the flow history.
  /// If no previous step exists, allows normal back navigation.
  goToPreviousStep,

  /// Immediately cancel the entire flow without confirmation.
  cancelFlow,

  /// Save current progress and exit the flow.
  saveAndExit,

  /// Block back navigation completely.
  block,

  /// Execute a custom back action defined in the step.
  /// This will trigger the onBackPressed callback in SequentialFlow.
  custom,

  /// Navigate to a specific step index.
  goToSpecificStep,
}

/// Represents a single step in a sequential flow.
///
/// Each step contains the business logic, UI configuration, and navigation
/// behavior needed to execute one part of a multi-step process.
///
/// Example:
/// ```dart
/// FlowStep<MyStepEnum>(
///   step: MyStepEnum.validation,
///   name: 'Validating Data',
///   progressValue: 0.3,
///   onStepCallback: () async {
///     await validateUserData();
///   },
///   actionOnPressBack: ActionOnPressBack.goToPreviousStep,
/// )
/// ```
class FlowStep<T> {
  /// The step identifier, typically an enum value representing the current step.
  final T step;

  /// Human-readable name for this step, displayed in the UI.
  final String name;

  /// Progress value between 0.0 and 1.0 representing completion percentage.
  final double progressValue;

  /// Optional callback executed when the step starts, before the main logic.
  final OnStartStep? onStartStep;

  /// Main callback containing the step's business logic.
  /// This function is executed when the step is processed.
  final OnStepCallback onStepCallback;

  /// Optional widget builder for confirmation dialogs.
  ///
  /// When provided, the flow will pause and display this widget,
  /// waiting for user confirmation before proceeding.
  final Widget Function(FlowController<T> controller)? requiresConfirmation;

  /// Defines how back navigation behaves for this step.
  final ActionOnPressBack actionOnPressBack;

  /// Target step index when [actionOnPressBack] is [ActionOnPressBack.goToSpecificStep].
  ///
  /// Must be a valid index within the steps list.
  final int? goToStepIndex;

  /// Custom back action function when [actionOnPressBack] is [ActionOnPressBack.custom].
  ///
  /// Should return `true` to allow normal back navigation,
  /// or `false` to prevent it.
  final Future<bool> Function(FlowController<T> controller)? customBackAction;

  /// Creates a new flow step.
  ///
  /// The [step], [name], [progressValue], and [onStepCallback] parameters are required.
  ///
  /// [progressValue] should be between 0.0 and 1.0.
  ///
  /// When [actionOnPressBack] is [ActionOnPressBack.goToSpecificStep],
  /// [goToStepIndex] must be provided.
  ///
  /// When [actionOnPressBack] is [ActionOnPressBack.custom],
  /// [customBackAction] should be provided.
  const FlowStep({
    required this.step,
    required this.name,
    required this.progressValue,
    required this.onStepCallback,
    this.onStartStep,
    this.requiresConfirmation,
    this.actionOnPressBack = ActionOnPressBack.block,
    this.goToStepIndex,
    this.customBackAction,
  }) : assert(
  progressValue >= 0.0 && progressValue <= 1.0,
  'progressValue must be between 0.0 and 1.0',
  );
}