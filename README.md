# Sequential Flow

A Flutter library for building declarative, step-by-step flows with comprehensive state management and customizable navigation behavior.

## Features

- ✅ **Declarative Flow Definition** - Define your flow steps with clear configuration
- ✅ **Type-Safe Data Storage** - Store and retrieve data with full type safety using enums or strings
- ✅ **Flexible Navigation Control** - Multiple back navigation behaviors per step
- ✅ **User Confirmation Steps** - Built-in support for confirmation dialogs
- ✅ **Comprehensive Error Handling** - Custom error UI with retry functionality
- ✅ **Progress Tracking** - Real-time progress updates with customizable UI
- ✅ **Custom Back Button Handling** - Handle back button presses with custom logic
- ✅ **State Management** - Built-in reactive state management with ChangeNotifier
- ✅ **Production Ready** - Thoroughly tested with comprehensive example implementations

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  sequential_flow: ^1.2.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:sequential_flow/sequential_flow.dart';

// Define your flow steps
enum ProcessStep { init, verify, complete }

// Create your flow
SequentialFlow<ProcessStep>(
  steps: [
    FlowStep(
      step: ProcessStep.init,
      name: 'Initializing',
      progressValue: 0.3,
      onStepCallback: (controller) async {
        await Future.delayed(Duration(seconds: 2));
      },
    ),
    FlowStep(
      step: ProcessStep.verify,
      name: 'Verification',
      progressValue: 0.7,
      onStepCallback: (controller) async {
        await Future.delayed(Duration(seconds: 1));
      },
    ),
    FlowStep(
      step: ProcessStep.complete,
      name: 'Complete',
      progressValue: 1.0,
      onStepCallback: (controller) async {
        await Future.delayed(Duration(milliseconds: 500));
      },
    ),
  ],
)
```

## Core Concepts

### FlowStep
Defines individual steps with business logic and UI configuration:

- **step**: Step identifier (typically an enum)
- **name**: Human-readable step name
- **progressValue**: Progress between 0.0 and 1.0
- **onStepCallback**: Main business logic
- **requiresConfirmation**: Optional confirmation UI
- **actionOnPressBack**: Back navigation behavior

### FlowController
Manages state, navigation, and data persistence:

- **State Management**: Loading, completion, error states
- **Data Storage**: Type-safe data storage with flexible keys
- **Navigation**: Back button handling and step transitions
- **Error Recovery**: Built-in retry and error handling

### SequentialFlow Widget
Orchestrates execution and renders UI:

- **Lifecycle Management**: Automatic controller management
- **Custom UI Builders**: Customizable loading, error, and completion states
- **Back Button Integration**: Automatic back button handling

## Type-Safe Data Storage

Use enums for type-safe data keys:

```dart
enum UserKeys { email, name, phone, verified }

// Store data
controller.setData(UserKeys.email, 'user@example.com');
controller.setData(UserKeys.verified, true);

// Retrieve data with type safety
String? email = controller.getData<UserKeys, String>(UserKeys.email);
bool? isVerified = controller.getData<UserKeys, bool>(UserKeys.verified);

// Backward compatibility with strings
controller.setData('legacy-key', 'value');
String? value = controller.getData('legacy-key');
```

## User Confirmation Steps

Create interactive confirmation dialogs:

```dart
FlowStep(
  step: ProcessStep.confirm,
  name: 'Confirmation',
  progressValue: 0.8,
  onStepCallback: (controller) async {
    // Process after confirmation
    await processData();
  },
  requiresConfirmation: (controller) => AlertDialog(
    title: Text('Confirm Action'),
    content: Text('Are you sure you want to continue?'),
    actions: [
      TextButton(
        onPressed: () => controller.continueFlow(),
        child: Text('Yes'),
      ),
      TextButton(
        onPressed: () => controller.cancelFlow(),
        child: Text('No'),
      ),
    ],
  ),
)
```

## Back Navigation Control

Configure how each step handles back navigation:

```dart
FlowStep(
  step: ProcessStep.critical,
  name: 'Critical Step',
  onStepCallback: (controller) async {
    await criticalOperation();
  },
  actionOnPressBack: ActionOnPressBack.block, // Prevent going back
)
```

### Available Back Navigation Options:

| ActionOnPressBack | Behavior |
|---|---|
| `block` | Prevents back navigation completely |
| `goToPreviousStep` | Returns to previous step |
| `cancelFlow` | Cancels entire flow |
| `saveAndExit` | Allows normal exit |
| `custom` | Triggers custom `onBackPressed` callback |
| `goToSpecificStep` | Jumps to specified step index |

## Custom Back Button Handling

Handle back button presses with custom logic:

```dart
SequentialFlow<ProcessStep>(
  steps: steps,
  onBackPressed: (controller) {
    // Return a widget to show it as part of the flow
    return AlertDialog(
      title: Text('Exit Process?'),
      content: Text('Your progress will be lost.'),
      actions: [
        TextButton(
          onPressed: () => controller.hideBackWidget(),
          child: Text('Continue'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Exit'),
        ),
      ],
    );
  },
)
```

## Error Handling

Provide custom error UI with retry functionality:

```dart
SequentialFlow<ProcessStep>(
  steps: steps,
  onStepError: (step, name, error, stack, controller) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.error, size: 64, color: Colors.red),
      Text('Error in $name'),
      Text(error.toString()),
      SizedBox(height: 16),
      ElevatedButton(
        onPressed: () => controller.retry(),
        child: Text('Retry'),
      ),
    ],
  ),
)
```

## Custom UI States

Customize the appearance of different flow states:

```dart
SequentialFlow<ProcessStep>(
  steps: steps,
  onStepLoading: (step, name, progress) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      CircularProgressIndicator(value: progress),
      SizedBox(height: 16),
      Text(name),
      Text('${(progress * 100).toInt()}% Complete'),
    ],
  ),
  onStepFinish: (step, name, progress, controller) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.check_circle, size: 64, color: Colors.green),
      Text('Process Complete!'),
      SizedBox(height: 16),
      ElevatedButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Done'),
      ),
    ],
  ),
)
```

## Real-World Example: Payment Flow

See the complete payment flow example in `/example/example.dart` for a production-ready implementation featuring:

- User authentication and verification
- Conditional flow navigation
- Dynamic step progression
- Multiple payment methods
- Complete error handling
- Real-world payment processing simulation

Key features demonstrated:
- 8 sequential steps with complex logic
- Type-safe data storage with enums
- Conditional step execution
- Method-specific UI forms
- Comprehensive error recovery
- Custom back navigation handling

## Best Practices

### Data Management
- Use enums for type-safe keys: `controller.setData(MyKeys.email, value)`
- Clean up data after completion: `controller.reset()`
- Validate required data in `onStepCallback`

### Error Handling
- Always provide `onStepError` for user-friendly error messages
- Use `controller.retry()` for recoverable errors
- Implement proper fallbacks for network-dependent steps

### Navigation
- Use `ActionOnPressBack.block` for critical operations
- Implement `onBackPressed` for custom confirmation dialogs
- Consider user experience when choosing navigation behavior

### Performance
- Dispose controllers in `StatefulWidget.dispose()`
- Use `autoStart: false` for manual flow control
- Avoid heavy operations in `requiresConfirmation` builders

## Common Use Cases

**Perfect for:**
- User onboarding and registration flows
- Payment processing workflows
- File upload/download processes
- Multi-step forms and wizards
- App setup and configuration
- Data migration workflows
- Survey and questionnaire forms
- Checkout processes

## API Reference

### FlowController Methods

```dart
// Flow Control
await controller.start()           // Start flow execution
await controller.continueFlow()    // Continue after confirmation
controller.cancelFlow()            // Cancel flow
controller.reset()                 // Reset to initial state
controller.restart()               // Restart from beginning
await controller.retry()           // Retry after error

// Data Management
controller.setData(key, value)     // Store data
controller.getData<K, V>(key)      // Retrieve data
controller.getAllData()            // Get all data

// State Properties
controller.isLoading              // Currently executing
controller.isCompleted            // Successfully finished
controller.hasError               // Error occurred
controller.isCancelled            // User cancelled
controller.isWaitingConfirmation  // Waiting for user input
controller.currentStep            // Current step identifier
controller.currentStepName        // Current step name
controller.currentProgress        // Current progress (0.0-1.0)
```

### FlowStep Properties

```dart
FlowStep<T>(
  required T step,                    // Step identifier
  required String name,               // Display name
  required double progressValue,      // Progress (0.0-1.0)
  required Future<void> Function(FlowController<T>) onStepCallback,
  Future<void> Function(FlowController<T>)? onStartStep,
  Widget Function(FlowController<T>)? requiresConfirmation,
  ActionOnPressBack actionOnPressBack = ActionOnPressBack.block,
  int? goToStepIndex,                // For goToSpecificStep
  Future<bool> Function(FlowController<T>)? customBackAction,
)
```

### SequentialFlow Properties

```dart
SequentialFlow<T>(
  required List<FlowStep<T>> steps,
  bool autoStart = true,
  Widget Function(T, String, double)? onStepLoading,
  Widget Function(T, String, Object, StackTrace, FlowController<T>)? onStepError,
  Widget Function(T, String, double, FlowController<T>)? onStepFinish,
  Widget Function(T, String, FlowController<T>)? onStepCancel,
  Widget? Function(FlowController<T>)? onBackPressed,
  FlowController<T>? controller,     // Optional external controller
)
```

## Requirements

- **Flutter**: >=3.0.0
- **Dart**: >=2.17.0
- **Platforms**: iOS, Android, Web, Desktop

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes and version history.