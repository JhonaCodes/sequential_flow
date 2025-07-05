# Sequential Flow

A Flutter library for building declarative, step-by-step flows with comprehensive state management and customizable navigation behavior.

## Installation

```yaml
dependencies:
  sequential_flow: ^1.1.0
```

## Core Concepts

Sequential Flow provides three main components:

- **FlowStep**: Defines individual steps with business logic and UI configuration
- **FlowController**: Manages state, navigation, and data persistence
- **SequentialFlow**: Widget that orchestrates execution and renders UI


## Quick Start

```dart
import 'package:sequential_flow/sequential_flow.dart';

enum ProcessStep { init, verify, complete }

SequentialFlow<ProcessStep>(
  steps: [
    FlowStep(
      step: ProcessStep.init,
      name: 'Initializing',
      progressValue: 0.3,
      onStepCallback: () async {
        await Future.delayed(Duration(seconds: 2));
      },
    ),
    FlowStep(
      step: ProcessStep.verify,
      name: 'Verification',
      progressValue: 0.7,
      onStepCallback: () async {
        await Future.delayed(Duration(seconds: 1));
      },
    ),
    FlowStep(
      step: ProcessStep.complete,
      name: 'Complete',
      progressValue: 1.0,
      onStepCallback: () async {
        await Future.delayed(Duration(milliseconds: 500));
      },
    ),
  ],
)
```

## Core Features

### Type-Safe Data Storage

```dart
// Use enums for type-safe keys
enum DataKeys { username, email, preferences }

// Store data
controller.setData(DataKeys.username, 'john_doe');
controller.setData(DataKeys.email, 'john@example.com');

// Retrieve data with type safety
String? username = controller.getData<DataKeys, String>(DataKeys.username);
String? email = controller.getData<DataKeys, String>(DataKeys.email);

// Backward compatibility with strings
controller.setData('legacy-key', 'value');
String? value = controller.getData('legacy-key');
```

### User Confirmation Steps

```dart
FlowStep(
  step: ProcessStep.confirm,
  name: 'Confirmation',
  progressValue: 0.8,
  onStepCallback: () async {
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

### Back Navigation Control

```dart
FlowStep(
  step: ProcessStep.critical,
  name: 'Critical Step',
  progressValue: 0.9,
  onStepCallback: () async {
    await criticalOperation();
  },
  actionOnPressBack: ActionOnPressBack.block, // Prevent going back
)

// Available options:
// - ActionOnPressBack.block              // Block navigation
// - ActionOnPressBack.goToPreviousStep   // Normal back navigation
// - ActionOnPressBack.cancelFlow         // Cancel entire flow
// - ActionOnPressBack.saveAndExit        // Allow exit
// - ActionOnPressBack.custom             // Custom handling
```

### Custom Back Button Handling

```dart
SequentialFlow<ProcessStep>(
  steps: steps,
  onBackPressed: (controller) {
    // Only executes when back button is actually pressed
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exit Process?'),
        content: Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit flow
            },
            child: Text('Exit'),
          ),
        ],
      ),
    );
  },
)
```

### Error Handling

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

### Custom UI States

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

## Real-World Examples

### User Registration Flow

```dart
enum RegistrationStep { welcome, details, verify, complete }

enum UserKeys { email, name, phone, verified }

SequentialFlow<RegistrationStep>(
  steps: [
    FlowStep(
      step: RegistrationStep.welcome,
      name: 'Welcome',
      progressValue: 0.25,
      onStepCallback: () async {
        await Future.delayed(Duration(seconds: 1));
      },
      requiresConfirmation: (controller) => AlertDialog(
        title: Text('Welcome!'),
        content: Text('Ready to create your account?'),
        actions: [
          TextButton(
            onPressed: () => controller.continueFlow(),
            child: Text('Get Started'),
          ),
        ],
      ),
    ),
    FlowStep(
      step: RegistrationStep.details,
      name: 'Enter Details',
      progressValue: 0.5,
      onStepCallback: () async {
        // Validate data
        final email = controller.getData<UserKeys, String>(UserKeys.email);
        if (email?.isEmpty ?? true) {
          throw Exception('Email is required');
        }
      },
      requiresConfirmation: (controller) => AlertDialog(
        title: Text('User Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Email'),
              onChanged: (value) => controller.setData(UserKeys.email, value),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Name'),
              onChanged: (value) => controller.setData(UserKeys.name, value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => controller.continueFlow(),
            child: Text('Next'),
          ),
        ],
      ),
      actionOnPressBack: ActionOnPressBack.goToPreviousStep,
    ),
    FlowStep(
      step: RegistrationStep.verify,
      name: 'Email Verification',
      progressValue: 0.75,
      onStepCallback: () async {
        final email = controller.getData<UserKeys, String>(UserKeys.email);
        await sendVerificationEmail(email!);
        // Simulate verification check
        await Future.delayed(Duration(seconds: 2));
        controller.setData(UserKeys.verified, true);
      },
      actionOnPressBack: ActionOnPressBack.goToPreviousStep,
    ),
    FlowStep(
      step: RegistrationStep.complete,
      name: 'Creating Account',
      progressValue: 1.0,
      onStepCallback: () async {
        final userData = {
          'email': controller.getData<UserKeys, String>(UserKeys.email),
          'name': controller.getData<UserKeys, String>(UserKeys.name),
          'verified': controller.getData<UserKeys, bool>(UserKeys.verified),
        };
        await createUserAccount(userData);
      },
      actionOnPressBack: ActionOnPressBack.block,
    ),
  ],
)
```

### File Upload Process

```dart
enum UploadStep { select, validate, upload, complete }

enum FileKeys { selectedFile, uploadProgress, uploadedUrl }

SequentialFlow<UploadStep>(
  steps: [
    FlowStep(
      step: UploadStep.select,
      name: 'Select File',
      progressValue: 0.2,
      onStepCallback: () async {
        // File selection logic would be here
        await Future.delayed(Duration(milliseconds: 500));
      },
      requiresConfirmation: (controller) => AlertDialog(
        title: Text('Choose File'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo),
              title: Text('Select Image'),
              onTap: () {
                controller.setData(FileKeys.selectedFile, 'image.jpg');
                controller.continueFlow();
              },
            ),
            ListTile(
              leading: Icon(Icons.description),
              title: Text('Select Document'),
              onTap: () {
                controller.setData(FileKeys.selectedFile, 'document.pdf');
                controller.continueFlow();
              },
            ),
          ],
        ),
      ),
    ),
    FlowStep(
      step: UploadStep.validate,
      name: 'Validating File',
      progressValue: 0.4,
      onStepCallback: () async {
        final file = controller.getData<FileKeys, String>(FileKeys.selectedFile);
        await validateFile(file!);
      },
    ),
    FlowStep(
      step: UploadStep.upload,
      name: 'Uploading',
      progressValue: 0.8,
      onStepCallback: () async {
        final file = controller.getData<FileKeys, String>(FileKeys.selectedFile);
        
        // Simulate upload with progress
        for (int i = 0; i <= 100; i += 10) {
          controller.setData(FileKeys.uploadProgress, i / 100);
          await Future.delayed(Duration(milliseconds: 200));
        }
        
        controller.setData(FileKeys.uploadedUrl, 'https://example.com/uploaded-file');
      },
      actionOnPressBack: ActionOnPressBack.block,
    ),
    FlowStep(
      step: UploadStep.complete,
      name: 'Upload Complete',
      progressValue: 1.0,
      onStepCallback: () async {
        await Future.delayed(Duration(milliseconds: 500));
      },
    ),
  ],
  onStepLoading: (step, name, progress) {
    if (step == UploadStep.upload) {
      final uploadProgress = controller.getData<FileKeys, double>(FileKeys.uploadProgress) ?? 0.0;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(value: uploadProgress),
          SizedBox(height: 16),
          Text('Uploading... ${(uploadProgress * 100).toInt()}%'),
        ],
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(value: progress),
        SizedBox(height: 16),
        Text(name),
      ],
    );
  },
)
```

## Navigation Options

| ActionOnPressBack | Behavior |
|---|---|
| `block` | Prevents back navigation |
| `goToPreviousStep` | Returns to previous step |
| `cancelFlow` | Cancels entire flow |
| `saveAndExit` | Allows normal exit |
| `custom` | Triggers `onBackPressed` callback |
| `goToSpecificStep` | Jumps to specified step index |

## Integration with State Management

Sequential Flow works with any state management solution

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

✅ **Ideal for:**
- User onboarding and registration
- Payment processing flows
- File upload/download processes
- Multi-step forms and wizards
- App setup and configuration
- Data migration workflows
- Menu, etc


## Requirements

- **Flutter**: >=3.0.0
- **Dart**: >=2.17.0
- **Platforms**: iOS, Android, Web, Desktop

## License

MIT License - see LICENSE file for details