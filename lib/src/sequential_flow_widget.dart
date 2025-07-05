import 'package:flutter/material.dart';

import 'core_types.dart';
import 'flow_controller.dart';

/// A widget that executes and displays a sequential flow of steps.
///
/// This widget manages the lifecycle of a [FlowController] and provides
/// customizable UI for different flow states (loading, error, completion, etc.).
///
/// The widget automatically handles back button behavior based on each step's
/// configuration. Custom back button handling is done through the [onBackPressed]
/// callback, which is only executed when the user actually presses the back button.
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
///       actionOnPressBack: ActionOnPressBack.custom,
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
///   onBackPressed: (controller) {
///     // Option 1: Return a widget to show it as part of the flow
///     return CancelConfirmationWidget(
///       onContinue: () => controller.hideBackWidget(),
///       onCancel: () => Navigator.of(context).pop(),
///     );
///
///     // Option 2: Execute logic and return null to continue with normal flow
///     showDialog(
///       context: context,
///       builder: (context) => AlertDialog(
///         title: Text('Cancel Process'),
///         content: Text('Are you sure you want to cancel?'),
///         actions: [
///           TextButton(
///             onPressed: () => Navigator.of(context).pop(),
///             child: Text('Continue'),
///           ),
///           TextButton(
///             onPressed: () {
///               Navigator.of(context).pop();
///               controller.cancelFlow();
///             },
///             child: Text('Cancel'),
///           ),
///         ],
///       ),
///     );
///     return null;
///   },
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
  final Widget Function(
      T step,
      String name,
      Object error,
      StackTrace stack,
      FlowController<T> controller,
      )?
  onStepError;

  /// Builder for the completion state UI.
  ///
  /// Called when all steps have been executed successfully. Receives the
  /// last step identifier, step name, final progress value, and controller.
  ///
  /// If not provided, a simple Text widget indicating completion will be displayed.
  final Widget Function(
      T step,
      String name,
      double progress,
      FlowController<T> controller,
      )?
  onStepFinish;

  /// Builder for the cancelled state UI.
  ///
  /// Called when the flow is cancelled by the user. Receives the current
  /// step identifier, step name, and controller.
  ///
  /// If not provided, a simple Text widget indicating cancellation will be displayed.
  final Widget Function(T step, String name, FlowController<T> controller)?
  onStepCancel;

  /// Callback executed when back button is pressed on a step with [ActionOnPressBack.custom].
  ///
  /// This callback is only executed when the user actually presses the back button,
  /// not during widget rebuilds. It can either return a widget to display or null
  /// to execute logic without changing the UI.
  ///
  /// **Return Options:**
  /// - `Widget`: The returned widget will be displayed in place of the normal flow content.
  ///   Use `controller.hideBackWidget()` in the widget to return to the normal flow.
  /// - `null`: Only execute logic (like showing dialogs) and continue with the normal flow.
  ///
  /// Example returning a widget:
  /// ```dart
  /// onBackPressed: (controller) {
  ///   return CancelConfirmationWidget(
  ///     onContinue: () => controller.hideBackWidget(),
  ///     onCancel: () => Navigator.of(context).pop(),
  ///   );
  /// }
  /// ```
  ///
  /// Example executing logic only:
  /// ```dart
  /// onBackPressed: (controller) {
  ///   showDialog(
  ///     context: context,
  ///     builder: (context) => AlertDialog(
  ///       title: Text('Cancel?'),
  ///       actions: [
  ///         TextButton(
  ///           onPressed: () => Navigator.pop(context),
  ///           child: Text('Continue'),
  ///         ),
  ///         TextButton(
  ///           onPressed: () {
  ///             Navigator.pop(context);
  ///             controller.cancelFlow();
  ///           },
  ///           child: Text('Cancel'),
  ///         ),
  ///       ],
  ///     ),
  ///   );
  ///   return null; // Continue with normal flow
  /// }
  /// ```
  final Widget? Function(FlowController<T> controller)? onBackPressed;

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
  /// If any step uses [ActionOnPressBack.custom], consider providing the
  /// [onBackPressed] callback to handle the back button press appropriately.
  const SequentialFlow({
    super.key,
    required this.steps,
    this.onStepLoading,
    this.onStepError,
    this.onStepFinish,
    this.onStepCancel,
    this.onBackPressed,
    this.autoStart = true,
  }) : assert(steps.length > 0, 'Steps list cannot be empty');

  @override
  State<SequentialFlow<T>> createState() => SequentialFlowState<T>();
}

/// Internal state class for [SequentialFlow].
///
/// Manages the flow controller lifecycle and handles back button navigation.
/// Back button handling is done in [PopScope] to ensure it only executes
/// when the user actually presses back, not during widget rebuilds.
@visibleForTesting
class SequentialFlowState<T> extends State<SequentialFlow<T>> {
  /// The flow controller instance.
  late FlowController<T> controller;

  @override
  void initState() {
    super.initState();
    controller = FlowController<T>(steps: widget.steps);

    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.start();
      });
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

        // Handle custom back press - execute callback only when back is actually pressed
        if (currentStep.actionOnPressBack == ActionOnPressBack.custom) {
          if (widget.onBackPressed != null) {
            final backWidget = widget.onBackPressed!(controller);
            if (backWidget != null) {
              // Show the custom widget by updating controller state
              controller.showBackWidget();
            }
            // If null, the callback executed logic (like showDialog) but didn't return a widget
          }
          return;
        }

        // Handle other back press behaviors through the controller
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
          onBackPressed: widget.onBackPressed,
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
/// - Custom back widget display
/// - Cancelled state
/// - Error state
/// - Waiting for confirmation
/// - Completed state
/// - Loading state
///
/// **This widget only handles rendering, not navigation logic.**
/// Navigation is handled in the [PopScope] of the parent widget.
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
  final Widget? Function(FlowController<T> controller)? onBackPressed;

  /// Builder for cancelled state UI.
  final Widget Function(T step, String name, FlowController<T> controller)?
  onStepCancel;

  /// Builder for error state UI.
  final Widget Function(
      T step,
      String name,
      Object error,
      StackTrace stack,
      FlowController<T> controller,
      )?
  onStepError;

  /// Builder for completion state UI.
  final Widget Function(
      T step,
      String name,
      double progress,
      FlowController<T> controller,
      )?
  onStepFinish;

  /// Builder for loading state UI.
  final Widget Function(T step, String name, double progress)? onStepLoading;

  /// Creates a new flow main content widget.
  ///
  /// All parameters are required as they are provided by the parent [SequentialFlow].
  const _FlowMainContent({
    required this.controller,
    required this.steps,
    this.onBackPressed,
    this.onStepCancel,
    this.onStepError,
    this.onStepFinish,
    this.onStepLoading,
  });

  @override
  Widget build(BuildContext context) {
    // State: Custom Back Widget
    // Display custom back widget when user pressed back and onBackPressed returned a widget
    if (controller.isShowingBackWidget && onBackPressed != null) {
      final backWidget = onBackPressed!(controller);
      if (backWidget != null) {
        return backWidget;
      }
    }

    // State: Cancelled
    // Display cancellation UI when the flow has been cancelled
    if (controller.isCancelled && controller.currentStep != null) {
      return onStepCancel?.call(
        controller.currentStep as T,
        controller.currentStepName,
        controller,
      ) ??
          Text('Cancelled: ${controller.currentStepName}');
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
      ) ??
          Text('Error: ${controller.error}');
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
      ) ??
          Text('Completed: ${controller.currentStepName}');
    }

    // State: Loading
    // Display loading UI when a step is currently executing
    if (controller.isLoading && controller.currentStep != null) {
      return onStepLoading?.call(
        controller.currentStep as T,
        controller.currentStepName,
        controller.currentProgress,
      ) ??
          Text(controller.currentStepName);
    }

    // Default: Empty state
    // This should rarely be reached, but provides a safe fallback
    return const SizedBox.shrink();
  }
}