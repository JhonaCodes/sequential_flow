/// A Flutter library for creating sequential, step-by-step flows with customizable UI and navigation.
///
/// This library provides a declarative way to build multi-step processes such as:
/// - User onboarding flows
/// - Data processing workflows
/// - Form wizards
/// - Setup processes
///
/// ## Core Components
///
/// - [SequentialFlow]: The main widget for displaying and managing flow execution
/// - [FlowController]: Controls flow state, navigation, and data management
/// - [FlowStep]: Defines individual steps with their logic and behavior
/// - [ActionOnPressBack]: Configures back button navigation behavior
///
/// ## Basic Usage
///
/// ```dart
/// import 'package:sequential_flow/sequential_flow.dart';
///
/// SequentialFlow<MySteps>(
///   steps: [
///     FlowStep(
///       step: MySteps.welcome,
///       name: 'Welcome',
///       progressValue: 0.33,
///       onStepCallback: () async {
///         // Your step logic here
///       },
///     ),
///     // ... more steps
///   ],
///   onStepLoading: (step, name, progress) => YourLoadingWidget(),
///   onStepFinish: (step, name, progress, controller) => YourCompletionWidget(),
/// )
/// ```
///
/// For more examples and advanced usage, see the documentation for individual components.
library;

// Core types and enums
export 'src/core_types.dart';

// Flow controller
export 'src/flow_controller.dart';

// Main widget
export 'src/sequential_flow_widget.dart';