import 'dart:developer' show log;

import 'package:flutter/material.dart';

import 'core_types.dart';

/// Controls the execution and state of a sequential flow.
///
/// This controller manages the execution of multiple [FlowStep]s in sequence,
/// handling state transitions, error management, navigation, and data storage.
///
/// The controller notifies listeners when the state changes, making it suitable
/// for use with [ListenableBuilder] or similar reactive widgets.
///
/// Example usage:
/// ```dart
/// final controller = FlowController<MyStepEnum, KeyObject>(
///   steps: [
///     FlowStep(
///       step: MyStepEnum.init,
///       name: 'Initializing',
///       progressValue: 0.1,
///       onStepCallback: () async {
///         await initializeApp();
///       },
///     ),
///     // ... more steps
///   ],
/// );
///
/// // Start the flow
/// await controller.start();
///
/// // Listen to state changes
/// controller.addListener(() {
///   if (controller.isCompleted) {
///     print('Flow completed successfully!');
///   }
/// });
/// ```
class FlowController<T> extends ChangeNotifier {
  /// The list of steps to execute in sequence.
  final List<FlowStep<T>> steps;

  bool _isLoading = false;
  bool _isCompleted = false;
  bool _hasError = false;
  bool _isWaitingConfirmation = false;
  bool _isCancelled = false;
  T? _currentStep;
  String _currentStepName = '';
  double _currentProgress = 0.0;
  int _currentStepIndex = 0;
  Object? _error;
  StackTrace? _stackTrace;

  /// In-memory data storage for the flow.
  ///
  /// This map stores arbitrary data that can be shared between steps.
  /// Data is automatically cleared when the flow is reset.
  final Map<Object, dynamic> _data = {};

  /// Navigation history for back button functionality.
  ///
  /// Stores the indices of previously visited steps to enable
  /// proper back navigation.
  final List<int> _stepHistory = [];

  /// Creates a new flow controller with the given [steps].
  ///
  /// The [steps] list must not be empty.
  FlowController({required this.steps})
    : assert(steps.isNotEmpty, 'Steps list cannot be empty');

  // State Getters

  /// Whether the flow is currently executing a step.
  bool get isLoading => _isLoading;

  /// Whether the flow has completed all steps successfully.
  bool get isCompleted => _isCompleted;

  /// Whether an error occurred during step execution.
  bool get hasError => _hasError;

  /// Whether the flow is waiting for user confirmation.
  ///
  /// This occurs when a step has a [FlowStep.requiresConfirmation] widget.
  bool get isWaitingConfirmation => _isWaitingConfirmation;

  /// Whether the flow was cancelled by the user.
  bool get isCancelled => _isCancelled;

  /// The current step identifier, or null if no step is active.
  T? get currentStep => _currentStep;

  /// The human-readable name of the current step.
  String get currentStepName => _currentStepName;

  /// Current progress value between 0.0 and 1.0.
  double get currentProgress => _currentProgress;

  /// Index of the currently executing step.
  int get currentStepIndex => _currentStepIndex;

  /// The error object if an error occurred, null otherwise.
  Object? get error => _error;

  /// The stack trace of the error if one occurred, null otherwise.
  StackTrace? get stackTrace => _stackTrace;

  /// Whether back navigation is possible.
  ///
  /// Returns true if there are previous steps in the navigation history.
  bool get canGoBack => _stepHistory.isNotEmpty;

  // Data Management

  /// Stores a value in the flow's data map.
  ///
  /// The [key] should be unique within the flow, and [value] can be any object.
  /// This data persists throughout the flow execution but is cleared on reset.
  ///
  /// Example:
  /// ```dart
  /// controller.setData('userEmail', 'user@example.com');
  /// controller.setData('preferences', {'theme': 'dark'});
  /// controller.setData('user-model', userDataModel);
  /// controller.setData('form-001', formularyModel);
  /// controller.setData(EnumKey.formulary, formularyModel);
  /// ```
  void setData<K extends Object, V>(K key, V value) {
    _data[key] = value;
  }

  /// Retrieves a value from the flow's data map.
  ///
  /// Returns the stored value for [key], or null if the key doesn't exist.
  ///
  /// Example:
  /// ```dart
  /// String? email = controller.getData('userEmail');
  /// Map<String, dynamic>? prefs = controller.getData('preferences');
  /// ```
  V? getData<K extends Object, V>(K key) => _data[key] as V?;

  /// Returns an unmodifiable copy of all stored data.
  ///
  /// This is useful for debugging or when you need to access all
  /// data without the ability to modify it.
  Map<Object, dynamic> getAllData() => Map.unmodifiable(_data);

  // Flow Control

  /// Starts the flow execution from the beginning.
  ///
  /// This method resets the flow state and begins executing steps sequentially.
  /// If the flow is already running, this call is ignored.
  ///
  /// The flow will execute each step's [FlowStep.onStepCallback] in order,
  /// pausing for confirmation when [FlowStep.requiresConfirmation] is provided.
  ///
  /// Throws any exceptions that occur during step execution.
  Future<void> start() async {
    if (_isLoading) return;

    _isLoading = true;
    _isCompleted = false;
    _hasError = false;
    _isWaitingConfirmation = false;
    _isCancelled = false;
    _error = null;
    _stackTrace = null;
    _currentStepIndex = 0;
    _stepHistory.clear();

    notifyListeners();
    await _processSteps();
  }

  /// Internal method to process steps sequentially.
  Future<void> _processSteps() async {
    try {
      while (_currentStepIndex < steps.length) {
        final step = steps[_currentStepIndex];

        _currentStep = step.step;
        _currentStepName = step.name;
        _currentProgress = step.progressValue;

        step.onStartStep?.call();
        notifyListeners();

        if (step.requiresConfirmation != null) {
          _isWaitingConfirmation = true;
          _isLoading = false;
          notifyListeners();
          return;
        }

        await _executeCurrentStep();
        _currentStepIndex++;
      }

      _isLoading = false;
      _isCompleted = true;
      notifyListeners();
    } catch (e, stack) {
      _error = e;
      _stackTrace = stack;
      _isLoading = false;
      _hasError = true;
      _isWaitingConfirmation = false;
      log('Flow execution error: $e');
      notifyListeners();
    }
  }

  /// Executes the current step with small delays for UI smoothness.
  Future<void> _executeCurrentStep() async {
    await Future.delayed(const Duration(milliseconds: 100));
    await steps[_currentStepIndex].onStepCallback();
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// Continues the flow after a confirmation step.
  ///
  /// This method should be called when the user confirms a step that
  /// requires confirmation. The flow will resume from the current step.
  ///
  /// If [flowIndex] is provided, the flow will jump to that specific step
  /// instead of continuing to the next step sequentially.
  ///
  /// [flowIndex] must be a valid index within the steps list if provided.
  Future<void> continueFlow({int? flowIndex}) async {
    if (!_isWaitingConfirmation) return;

    _stepHistory.add(_currentStepIndex);

    _isWaitingConfirmation = false;
    _isLoading = true;
    notifyListeners();

    try {
      await _executeCurrentStep();

      if (flowIndex != null && flowIndex >= 0 && flowIndex < steps.length) {
        _currentStepIndex = flowIndex;
      } else {
        _currentStepIndex++;
      }

      await _processSteps();
    } catch (e, stack) {
      _error = e;
      _stackTrace = stack;
      _isLoading = false;
      _hasError = true;
      _isWaitingConfirmation = false;
      log('Flow continuation error: $e');
      notifyListeners();
    }
  }

  /// Handles back button press based on the current step's configuration.
  ///
  /// Returns `true` if the app should handle the back press normally (exit),
  /// or `false` if the back press was handled by the flow.
  ///
  /// The behavior depends on the current step's [FlowStep.actionOnPressBack] setting:
  /// - [ActionOnPressBack.goToPreviousStep]: Navigate to previous step
  /// - [ActionOnPressBack.cancelFlow]: Cancel the flow immediately
  /// - [ActionOnPressBack.saveAndExit]: Return true (allow exit)
  /// - [ActionOnPressBack.block]: Return false (prevent exit)
  /// - [ActionOnPressBack.custom]: Execute custom action
  /// - [ActionOnPressBack.goToSpecificStep]: Jump to specified step
  Future<bool> handleBackPress() async {
    if (_currentStepIndex < 0 || _currentStepIndex >= steps.length) return true;

    final currentStep = steps[_currentStepIndex];

    switch (currentStep.actionOnPressBack) {
      case ActionOnPressBack.goToPreviousStep:
        return await _goToPreviousStep();

      case ActionOnPressBack.cancelFlow:
        cancelFlow();
        return false;

      case ActionOnPressBack.saveAndExit:
        return true;

      case ActionOnPressBack.block:
        return false;

      case ActionOnPressBack.custom:
        if (currentStep.customBackAction != null) {
          return await currentStep.customBackAction!(this);
        }
        return false;

      case ActionOnPressBack.goToSpecificStep:
        if (currentStep.goToStepIndex != null) {
          await _goToStep(currentStep.goToStepIndex!);
        }
        return false;
    }
  }

  /// Navigates to the previous step in the history.
  Future<bool> _goToPreviousStep() async {
    if (_stepHistory.isNotEmpty) {
      final previousIndex = _stepHistory.removeLast();
      await _goToStep(previousIndex);
      return false;
    } else if (_currentStepIndex > 0) {
      await _goToStep(_currentStepIndex - 1);
      return false;
    }
    return true;
  }

  /// Navigates to a specific step by index.
  Future<void> _goToStep(int index) async {
    if (index >= 0 && index < steps.length) {
      _currentStepIndex = index;
      _isWaitingConfirmation = false;
      _isLoading = true;
      notifyListeners();
      await _processSteps();
    }
  }

  /// Cancels the flow execution.
  ///
  /// This sets the flow state to cancelled and stops any ongoing execution.
  /// The flow can be restarted using [start()].
  void cancelFlow() {
    _isWaitingConfirmation = false;
    _isLoading = false;
    _hasError = false;
    _isCompleted = false;
    _isCancelled = true;
    notifyListeners();
  }

  /// Retries the flow after an error.
  ///
  /// This is equivalent to calling [start()] when the flow is in an error state.
  /// If the flow is not in an error state, this method does nothing.
  void retry() {
    if (_hasError) {
      start();
    }
  }

  /// Resets the flow to its initial state.
  ///
  /// This clears all state, data, and history, returning the controller
  /// to the same state as when it was first created.
  ///
  /// After calling reset, you can call [start()] to begin a new flow execution.
  void reset() {
    _isLoading = false;
    _isCompleted = false;
    _hasError = false;
    _isWaitingConfirmation = false;
    _isCancelled = false;
    _currentStep = null;
    _currentStepName = '';
    _currentProgress = 0.0;
    _currentStepIndex = 0;
    _error = null;
    _stackTrace = null;
    _data.clear();
    _stepHistory.clear();
    notifyListeners();
  }
}
