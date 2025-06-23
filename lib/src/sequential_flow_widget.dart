import 'package:flutter/material.dart';

import 'core_types.dart';
import 'flow_controller.dart';

/// A widget that executes and displays a sequential flow of steps.
///
/// This widget manages the lifecycle of a [FlowController] and provides
/// customizable UI for different flow states (loading, error, completion, etc.).
///
/// The widget automatically handles back button behavior based on each step's
/// configuration. **No default dialogs are provided** - developers must
/// implement all UI through the provided builders.
///
/// Example usage:
/// ```dart
/// SequentialFlow<MyStepEnum>(
///   steps: [
///     FlowStep(
///       step: MyStepEnum.init,
///       name: 'Initializing',
///       progressValue: 0.2,
///       onStepCallback: () async {
///         await initializeData();
///       },
///     ),
///     FlowStep(
///       step: MyStepEnum.process,
///       name: 'Processing',
///       progressValue: 0.8,
///       onStepCallback: () async {
///         await processData();
///       },
///       requiresConfirmation: (controller) => AlertDialog(
///         title: Text('Confirm Processing'),
///         content: Text('Are you sure you want to continue?'),
///         actions: [
///           TextButton(
///             onPressed: () => controller.continueFlow(),
///             child: Text('Yes'),
///           ),
///         ],
///       ),
///     ),
///   ],
///   onStepLoading: (step, name, progress) => Column(
///     children: [
///       Text('$name'),
///       LinearProgressIndicator(value: progress),
///     ],
///   ),
///   onStepFinish: (step, name, progress, controller) => Column(
///     children: [
///       Icon(Icons.check_circle, color: Colors.green),
///       Text('Flow completed successfully!'),
///       ElevatedButton(
///         onPressed: () => Navigator.of(context).pop(),
///         child: Text('Close'),
///       ),
///     ],
///   ),
/// )
/// ```
class SequentialFlow<T> extends StatefulWidget {
  /// The list of steps to execute sequentially.
  ///
  /// Each step defines its behavior, UI requirements, and navigation configuration.
  final List<FlowStep<T>> steps;

  /// Builder for the loading state UI.
  ///
  /// Called when a step is currently executing. Receives the current step
  /// identifier, step name, and progress value.
  ///
  /// If not provided, a simple Text widget showing the step name will be displayed.
  final Widget Function(T step, String name, double progress)? onStepLoading;

  /// Builder for the error state UI.
  ///
  /// Called when a step encounters an error during execution. Receives the
  /// current step identifier, step name, error object, stack trace, and controller.
  ///
  /// The controller can be used to retry the flow or access other flow data.
  ///
  /// If not provided, a simple Text widget showing the error will be displayed.
  final Widget Function(T step, String name, Object error, StackTrace stack, FlowController<T> controller)? onStepError;

  /// Builder for the completion state UI.
  ///
  /// Called when all steps have been executed successfully. Receives the
  /// last step identifier, step name, final progress value, and controller.
  ///
  /// If not provided, a simple Text widget indicating completion will be displayed.
  final Widget Function(T step, String name, double progress, FlowController<T> controller)? onStepFinish;

  /// Builder for the cancelled state UI.
  ///
  /// Called when the flow is cancelled by the user. Receives the current
  /// step identifier, step name, and controller.
  ///
  /// If not provided, a simple Text widget indicating cancellation will be displayed.
  final Widget Function(T step, String name, FlowController<T> controller)? onStepCancel;

  /// **Required** builder for custom back button handling.
  ///
  /// This builder is **mandatory** when any step uses:
  /// - [ActionOnPressBack.showCancelDialog]
  /// - [ActionOnPressBack.showSaveDialog]
  /// - [ActionOnPressBack.custom]
  ///
  /// The builder receives the flow controller and should return the appropriate UI.
  /// You must implement your own dialogs/widgets that match your app's design system.
  ///
  /// **No default dialogs are provided** - this is intentional to ensure you have
  /// full control over the user experience.
  ///
  /// Example:
  /// ```dart
  /// onPressBack: (controller) {
  ///   final currentStep = steps[controller.currentStepIndex];
  ///
  ///   if (currentStep.actionOnPressBack == ActionOnPressBack.showCancelDialog) {
  ///     return AlertDialog(
  ///       title: Text('Cancel Process'),
  ///       content: Text('Are you sure you want to cancel?'),
  ///       actions: [
  ///         TextButton(
  ///           onPressed: () => Navigator.of(context).pop(),
  ///           child: Text('Continue'),
  ///         ),
  ///         TextButton(
  ///           onPressed: () => controller.cancelFlow(),
  ///           child: Text('Cancel'),
  ///         ),
  ///       ],
  ///     );
  ///   }
  ///
  ///   if (currentStep.actionOnPressBack == ActionOnPressBack.showSaveDialog) {
  ///     return AlertDialog(
  ///       title: Text('Exit'),
  ///       content: Text('What would you like to do?'),
  ///       actions: [
  ///         TextButton(
  ///           onPressed: () => Navigator.of(context).pop(),
  ///           child: Text('Continue'),
  ///         ),
  ///         TextButton(
  ///           onPressed: () => Navigator.of(context).pop(),
  ///           child: Text('Exit'),
  ///         ),
  ///       ],
  ///     );
  ///   }
  ///
  ///   // Handle custom actions
  ///   return YourCustomBackWidget(controller: controller);
  /// }
  /// ```
  final Widget Function(FlowController<T> controller)? onPressBack;

  /// Whether to automatically start the flow when the widget is initialized.
  ///
  /// Defaults to `true`. Set to `false` if you want to control when the flow
  /// starts by calling [FlowController.start] manually.
  final bool autoStart;

  /// Creates a new sequential flow widget.
  ///
  /// The [steps] parameter is required and must contain at least one step.
  ///
  /// All builder functions are optional and will fall back to simple Text widgets
  /// if not provided.
  ///
  /// **Important**: If any step uses [ActionOnPressBack.showCancelDialog],
  /// [ActionOnPressBack.showSaveDialog], or [ActionOnPressBack.custom],
  /// the [onPressBack] builder **must** be provided.
  const SequentialFlow({
    super.key,
    required this.steps,
    this.onStepLoading,
    this.onStepError,
    this.onStepFinish,
    this.onStepCancel,
    this.onPressBack,
    this.autoStart = true,
  }) : assert(steps.length > 0, 'Steps list cannot be empty');

  @override
  State<SequentialFlow<T>> createState() => SequentialFlowState<T>();
}

/// Internal state class for [SequentialFlow].
///
/// Manages the flow controller lifecycle, handles back button navigation,
/// and validates that required builders are provided.
@visibleForTesting
class SequentialFlowState<T> extends State<SequentialFlow<T>> {
  /// The flow controller instance.
  late FlowController<T> controller;

  @override
  void initState() {
    super.initState();
    controller = FlowController<T>(steps: widget.steps);

    // Validate that onPressBack is provided when needed
    _validateBackHandlers();

    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.start();
      });
    }
  }

  /// Validates that onPressBack is provided when steps require it.
  ///
  /// Throws a [FlutterError] if any step requires the onPressBack builder
  /// but it wasn't provided.
  void _validateBackHandlers() {
    final needsBackHandler = widget.steps.any((step) =>
    step.actionOnPressBack == ActionOnPressBack.showCancelDialog ||
        step.actionOnPressBack == ActionOnPressBack.showSaveDialog ||
        step.actionOnPressBack == ActionOnPressBack.custom);

    if (needsBackHandler && widget.onPressBack == null) {
      throw FlutterError(
        'onPressBack builder is required when using ActionOnPressBack.showCancelDialog, '
            'ActionOnPressBack.showSaveDialog, or ActionOnPressBack.custom.\n'
            'Please provide an onPressBack builder that handles these cases.\n'
            'No default dialogs are provided - you must implement your own UI.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final currentStep = controller.currentStepIndex < widget.steps.length
            ? widget.steps[controller.currentStepIndex]
            : null;

        if (currentStep == null) return;

        // For dialog-based actions and custom actions, the UI handling is done in the builder
        if (currentStep.actionOnPressBack == ActionOnPressBack.showCancelDialog ||
            currentStep.actionOnPressBack == ActionOnPressBack.showSaveDialog ||
            currentStep.actionOnPressBack == ActionOnPressBack.custom) {
          // These are handled by the onPressBack builder - no action needed here
          return;
        }

        final canPop = await controller.handleBackPress();
        if (canPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, child) => _FlowMainContent<T>(
          controller: controller,
          steps: widget.steps,
          onPressBack: widget.onPressBack,
          onStepCancel: widget.onStepCancel,
          onStepError: widget.onStepError,
          onStepFinish: widget.onStepFinish,
          onStepLoading: widget.onStepLoading,
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}



/// Internal widget that renders the main content based on flow state.
///
/// This widget is responsible for determining which UI to display based on
/// the current state of the [FlowController]. It handles all possible states:
/// - Custom back handling
/// - Cancelled state
/// - Error state
/// - Waiting for confirmation
/// - Completed state
/// - Loading state
///
/// **Default widgets are minimal** - only simple Text widgets are provided
/// as fallbacks. Developers should implement their own UI builders for
/// production applications.
///
/// This is a private widget used internally by [SequentialFlow] and should
/// not be used directly in application code.
class _FlowMainContent<T> extends StatelessWidget {
  /// The flow controller managing the current state.
  final FlowController<T> controller;

  /// The list of flow steps for reference.
  final List<FlowStep<T>> steps;

  /// Custom back press handler builder.
  final Widget Function(FlowController<T> controller)? onPressBack;

  /// Builder for cancelled state UI.
  final Widget Function(T step, String name, FlowController<T> controller)? onStepCancel;

  /// Builder for error state UI.
  final Widget Function(T step, String name, Object error, StackTrace stack, FlowController<T> controller)? onStepError;

  /// Builder for completion state UI.
  final Widget Function(T step, String name, double progress, FlowController<T> controller)? onStepFinish;

  /// Builder for loading state UI.
  final Widget Function(T step, String name, double progress)? onStepLoading;

  /// Creates a new flow main content widget.
  ///
  /// All parameters are required as they are provided by the parent [SequentialFlow].
  const _FlowMainContent({
    required this.controller,
    required this.steps,
    this.onPressBack,
    this.onStepCancel,
    this.onStepError,
    this.onStepFinish,
    this.onStepLoading,
  });

  @override
  Widget build(BuildContext context) {
    // Handle custom back press scenarios
    if (onPressBack != null && controller.currentStepIndex < steps.length) {
      final currentStep = steps[controller.currentStepIndex];
      if (currentStep.actionOnPressBack == ActionOnPressBack.custom ||
          currentStep.actionOnPressBack == ActionOnPressBack.showCancelDialog ||
          currentStep.actionOnPressBack == ActionOnPressBack.showSaveDialog) {
        return onPressBack!(controller);
      }
    }

    // State: Cancelled
    // Display cancellation UI when the flow has been cancelled
    if (controller.isCancelled && controller.currentStep != null) {
      return onStepCancel?.call(
        controller.currentStep as T,
        controller.currentStepName,
        controller,
      ) ?? Text('Cancelled: ${controller.currentStepName}');
    }

    // State: Error
    // Display error UI when a step has failed
    if (controller.hasError && controller.currentStep != null) {
      return onStepError?.call(
        controller.currentStep as T,
        controller.currentStepName,
        controller.error!,
        controller.stackTrace!,
        controller,
      ) ?? Text('Error: ${controller.error}');
    }

    // State: Waiting for Confirmation
    // Display confirmation UI when a step requires user confirmation
    if (controller.isWaitingConfirmation && controller.currentStep != null) {
      final currentStepData = steps[controller.currentStepIndex];
      return currentStepData.requiresConfirmation!(controller);
    }

    // State: Completed
    // Display completion UI when all steps have finished successfully
    if (controller.isCompleted && controller.currentStep != null) {
      return onStepFinish?.call(
        controller.currentStep as T,
        controller.currentStepName,
        controller.currentProgress,
        controller,
      ) ?? Text('Completed: ${controller.currentStepName}');
    }

    // State: Loading
    // Display loading UI when a step is currently executing
    if (controller.isLoading && controller.currentStep != null) {
      return onStepLoading?.call(
        controller.currentStep as T,
        controller.currentStepName,
        controller.currentProgress,
      ) ?? Text(controller.currentStepName);
    }

    // Default: Empty state
    // This should rarely be reached, but provides a safe fallback
    return const SizedBox.shrink();
  }
}