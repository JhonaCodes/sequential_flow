# Sequential Flow

A Flutter library for building declarative, step-by-step flows with comprehensive state management and customizable navigation behavior.

## Installation

```yaml
dependencies:
  sequential_flow: ^1.0.0
```

## Core Concepts

Sequential Flow provides three main components:

- **FlowStep**: Defines individual steps with business logic and UI configuration
- **FlowController**: Manages state, navigation, and data persistence
- **SequentialFlow**: Widget that orchestrates execution and renders UI

## Complete Use Case Examples

### User Enrollment Flow

```dart
enum EnrollmentStep {
  welcome,
  emailVerification,
  personalInfo,
  preferences,
  completion,
}

SequentialFlow<EnrollmentStep>(
  steps: [
    // Step 1: Welcome screen with terms acceptance
    FlowStep(
      step: EnrollmentStep.welcome,
      name: 'Welcome',
      progressValue: 0.2,
      onStepCallback: () async {
        await Future.delayed(Duration(seconds: 1));
      },
      requiresConfirmation: (controller) => AlertDialog(
        title: Text('Terms of Service'),
        content: Text('Do you accept our terms?'),
        actions: [
          TextButton(
            onPressed: () => controller.cancelFlow(),
            child: Text('Decline'),
          ),
          TextButton(
            onPressed: () {
              controller.setData('termsAccepted', true);
              controller.continueFlow();
            },
            child: Text('Accept'),
          ),
        ],
      ),
      actionOnPressBack: ActionOnPressBack.cancelFlow,
    ),

    // Step 2: Email verification with retry logic
    FlowStep(
      step: EnrollmentStep.emailVerification,
      name: 'Email Verification',
      progressValue: 0.4,
      onStepCallback: () async {
        final email = controller.getData('email');
        final result = await verifyEmail(email);
        if (!result.verified) {
          throw Exception('Email verification failed: ${result.error}');
        }
      },
      requiresConfirmation: (controller) => AlertDialog(
        title: Text('Enter Email'),
        content: TextField(
          onChanged: (value) => controller.setData('email', value),
          decoration: InputDecoration(hintText: 'your@email.com'),
        ),
        actions: [
          TextButton(
            onPressed: () => controller.continueFlow(),
            child: Text('Verify'),
          ),
        ],
      ),
      actionOnPressBack: ActionOnPressBack.goToPreviousStep,
    ),

    // Step 3: Personal information collection
    FlowStep(
      step: EnrollmentStep.personalInfo,
      name: 'Personal Information',
      progressValue: 0.6,
      onStepCallback: () async {
        final userData = {
          'name': controller.getData('name'),
          'birthDate': controller.getData('birthDate'),
          'phone': controller.getData('phone'),
        };
        await saveUserProfile(userData);
      },
      requiresConfirmation: (controller) => PersonalInfoForm(controller),
      actionOnPressBack: ActionOnPressBack.showSaveDialog,
    ),

    // Step 4: Preferences setup
    FlowStep(
      step: EnrollmentStep.preferences,
      name: 'Setup Preferences',
      progressValue: 0.8,
      onStepCallback: () async {
        await configureUserPreferences(controller.getAllData());
      },
      actionOnPressBack: ActionOnPressBack.goToPreviousStep,
    ),

    // Step 5: Account creation completion
    FlowStep(
      step: EnrollmentStep.completion,
      name: 'Creating Account',
      progressValue: 1.0,
      onStepCallback: () async {
        await createUserAccount(controller.getAllData());
        await sendWelcomeEmail(controller.getData('email'));
      },
      actionOnPressBack: ActionOnPressBack.block,
    ),
  ],
  onStepError: (step, name, error, stack, controller) {
    if (step == EnrollmentStep.emailVerification) {
      return RetryEmailVerification(controller: controller, error: error);
    }
    return GenericErrorWidget(error: error, onRetry: () => controller.retry());
  },
)
```

### App Initialization Flow

```dart
enum InitStep {
  splash,
  permissions,
  dataSync,
  configuration,
  ready,
}

SequentialFlow<InitStep>(
  steps: [
    // Step 1: Splash screen with app loading
    FlowStep(
      step: InitStep.splash,
      name: 'Loading Application',
      progressValue: 0.2,
      onStepCallback: () async {
        await loadApplicationResources();
        await initializeServices();
      },
      actionOnPressBack: ActionOnPressBack.block,
    ),

    // Step 2: Request required permissions
    FlowStep(
      step: InitStep.permissions,
      name: 'Requesting Permissions',
      progressValue: 0.4,
      onStepCallback: () async {
        await Future.delayed(Duration(milliseconds: 500));
      },
      requiresConfirmation: (controller) => PermissionRequestDialog(
        permissions: ['camera', 'location', 'storage'],
        onGranted: (grantedPermissions) {
          controller.setData('permissions', grantedPermissions);
          controller.continueFlow();
        },
        onDenied: () => controller.cancelFlow(),
      ),
      actionOnPressBack: ActionOnPressBack.showCancelDialog,
    ),

    // Step 3: Sync user data from cloud
    FlowStep(
      step: InitStep.dataSync,
      name: 'Syncing Data',
      progressValue: 0.6,
      onStepCallback: () async {
        try {
          final userData = await syncUserDataFromCloud();
          controller.setData('userData', userData);
          
          final appSettings = await downloadAppConfiguration();
          controller.setData('settings', appSettings);
        } on NetworkException catch (e) {
          // Continue with cached data if network fails
          final cachedData = await loadCachedUserData();
          controller.setData('userData', cachedData);
        }
      },
      actionOnPressBack: ActionOnPressBack.block,
    ),

    // Step 4: Apply configuration and setup
    FlowStep(
      step: InitStep.configuration,
      name: 'Configuring Application',
      progressValue: 0.8,
      onStepCallback: () async {
        final settings = controller.getData('settings');
        await applyAppConfiguration(settings);
        
        final userData = controller.getData('userData');
        await setupUserEnvironment(userData);
        
        await initializeAnalytics();
        await preloadCriticalData();
      },
      actionOnPressBack: ActionOnPressBack.block,
    ),

    // Step 5: Finalization
    FlowStep(
      step: InitStep.ready,
      name: 'Finalizing Setup',
      progressValue: 1.0,
      onStepCallback: () async {
        await markAppAsInitialized();
        await triggerInitializationComplete();
      },
      actionOnPressBack: ActionOnPressBack.saveAndExit,
    ),
  ],
  onStepLoading: (step, name, progress) => SplashScreen(
    progress: progress,
    message: name,
    showSkipButton: step == InitStep.dataSync,
  ),
  onStepError: (step, name, error, stack, controller) {
    if (step == InitStep.dataSync && error is NetworkException) {
      return NetworkErrorWidget(
        onRetry: () => controller.retry(),
        onContinueOffline: () => controller.continueFlow(),
      );
    }
    return CriticalErrorWidget(error: error);
  },
)
```

### Online Exam Flow

```dart
enum ExamStep {
  instructions,
  identityVerification,
  examQuestions,
  review,
  submission,
}

class ExamFlowWidget extends StatefulWidget {
  final Exam exam;
  
  const ExamFlowWidget({required this.exam});

  @override
  State<ExamFlowWidget> createState() => _ExamFlowWidgetState();
}

class _ExamFlowWidgetState extends State<ExamFlowWidget> {
  late Timer examTimer;
  late FlowController<ExamStep> controller;

  @override
  void initState() {
    super.initState();
    controller = FlowController<ExamStep>(steps: _buildExamSteps());
    _startExamTimer();
  }

  List<FlowStep<ExamStep>> _buildExamSteps() {
    return [
      // Step 1: Exam instructions and rules
      FlowStep(
        step: ExamStep.instructions,
        name: 'Exam Instructions',
        progressValue: 0.1,
        onStepCallback: () async {
          controller.setData('examStartTime', DateTime.now());
          await logExamEvent('instructions_viewed');
        },
        requiresConfirmation: (controller) => ExamInstructionsDialog(
          exam: widget.exam,
          onAccept: () {
            controller.setData('instructionsAccepted', true);
            controller.continueFlow();
          },
          onDecline: () => controller.cancelFlow(),
        ),
        actionOnPressBack: ActionOnPressBack.showCancelDialog,
      ),

      // Step 2: Identity verification (camera/photo)
      FlowStep(
        step: ExamStep.identityVerification,
        name: 'Identity Verification',
        progressValue: 0.2,
        onStepCallback: () async {
          await Future.delayed(Duration(seconds: 2));
        },
        requiresConfirmation: (controller) => IdentityVerificationWidget(
          onVerified: (verificationData) {
            controller.setData('identity', verificationData);
            controller.continueFlow();
          },
          onFailed: () => throw Exception('Identity verification failed'),
        ),
        actionOnPressBack: ActionOnPressBack.block,
      ),

      // Step 3: Exam questions (main content)
      FlowStep(
        step: ExamStep.examQuestions,
        name: 'Taking Exam',
        progressValue: 0.7,
        onStepCallback: () async {
          // Auto-save answers periodically
          final answers = controller.getData('answers') ?? {};
          await autoSaveExamAnswers(answers);
        },
        requiresConfirmation: (controller) => ExamQuestionsWidget(
          exam: widget.exam,
          onAnswersChanged: (answers) {
            controller.setData('answers', answers);
          },
          onComplete: () => controller.continueFlow(),
          timeRemaining: _getTimeRemaining(),
        ),
        actionOnPressBack: ActionOnPressBack.custom,
        customBackAction: (controller) async {
          // Show warning about losing progress
          final shouldExit = await showExitExamDialog();
          if (shouldExit) {
            await saveExamDraft(controller.getAllData());
            return true;
          }
          return false;
        },
      ),

      // Step 4: Review answers before submission
      FlowStep(
        step: ExamStep.review,
        name: 'Review Answers',
        progressValue: 0.9,
        onStepCallback: () async {
          final answers = controller.getData('answers');
          await validateAnswers(answers);
        },
        requiresConfirmation: (controller) => ReviewAnswersWidget(
          answers: controller.getData('answers'),
          onEdit: (questionId) {
            // Go back to questions for editing
            controller.continueFlow(flowIndex: 2);
          },
          onSubmit: () => controller.continueFlow(),
        ),
        actionOnPressBack: ActionOnPressBack.goToPreviousStep,
      ),

      // Step 5: Final submission
      FlowStep(
        step: ExamStep.submission,
        name: 'Submitting Exam',
        progressValue: 1.0,
        onStepCallback: () async {
          final examData = controller.getAllData();
          examData['submissionTime'] = DateTime.now();
          
          await submitExam(examData);
          await clearExamDraft();
          examTimer.cancel();
        },
        actionOnPressBack: ActionOnPressBack.block,
      ),
    ];
  }

  void _startExamTimer() {
    examTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (_getTimeRemaining() <= 0) {
        // Auto-submit when time expires
        controller.continueFlow(flowIndex: 4);
      }
    });
  }

  Duration _getTimeRemaining() {
    final startTime = controller.getData('examStartTime') as DateTime?;
    if (startTime == null) return widget.exam.duration;
    
    final elapsed = DateTime.now().difference(startTime);
    return widget.exam.duration - elapsed;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent accidental exit
      child: SequentialFlow<ExamStep>(
        steps: controller.steps,
        autoStart: true,
        onStepError: (step, name, error, stack, controller) {
          if (step == ExamStep.submission) {
            return SubmissionErrorWidget(
              error: error,
              onRetry: () => controller.retry(),
              onSaveDraft: () async {
                await saveExamDraft(controller.getAllData());
                Navigator.of(context).pop();
              },
            );
          }
          return ExamErrorWidget(error: error);
        },
        onStepFinish: (step, name, progress, controller) {
          return ExamSubmittedWidget(
            examId: widget.exam.id,
            submissionTime: controller.getData('submissionTime'),
            onExit: () => Navigator.of(context).pop(),
          );
        },
        onPressBack: (controller) {
          // Custom handling for exam-specific dialogs
          return ExamExitConfirmationDialog(
            onExit: () => controller.cancelFlow(),
            onContinue: () => Navigator.of(context).pop(),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    examTimer.cancel();
    controller.dispose();
    super.dispose();
  }
}
```

## Basic Usage

### Simple Linear Flow

```dart
SequentialFlow<String>(
  steps: [
    FlowStep(
      step: 'init',
      name: 'Initializing',
      progressValue: 0.5,
      onStepCallback: () async {
        await initializeData();
      },
    ),
    FlowStep(
      step: 'complete',
      name: 'Complete',
      progressValue: 1.0,
      onStepCallback: () async {
        await finalizeProcess();
      },
    ),
  ],
)
```

### With Custom UI States

```dart
SequentialFlow<ProcessStep>(
  steps: steps,
  onStepLoading: (step, name, progress) => Column(
    children: [
      CircularProgressIndicator(value: progress),
      Text(name),
    ],
  ),
  onStepError: (step, name, error, stack, controller) => Column(
    children: [
      Text('Error: $error'),
      ElevatedButton(
        onPressed: () => controller.retry(),
        child: Text('Retry'),
      ),
    ],
  ),
)
```

## Navigation Behavior Configuration

### ActionOnPressBack Options

```dart
FlowStep(
  step: MyStep.critical,
  name: 'Critical Process',
  progressValue: 0.8,
  onStepCallback: () async { /* ... */ },
  actionOnPressBack: ActionOnPressBack.block, // Prevent navigation
)
```

Available options:

| ActionOnPressBack | Behavior | Use Case |
|-------------------|----------|----------|
| `block` | Prevents back navigation | Critical operations, payments |
| `goToPreviousStep` | Returns to previous step | Standard navigation |
| `cancelFlow` | Immediately cancels flow | Quick exit scenarios |
| `showCancelDialog` | Shows custom dialog | Confirmation before exit |
| `showSaveDialog` | Shows save/exit dialog | Draft preservation |
| `saveAndExit` | Allows normal exit | Completed processes |
| `custom` | Executes custom function | Complex navigation logic |
| `goToSpecificStep` | Jumps to specified step | Non-linear flows |

### Custom Back Navigation

```dart
FlowStep(
  step: MyStep.complex,
  actionOnPressBack: ActionOnPressBack.custom,
  customBackAction: (controller) async {
    // Save draft data
    await saveDraft(controller.getAllData());
    return true; // Allow exit
  },
)
```

### Dialog-Based Navigation

```dart
SequentialFlow(
  steps: steps,
  onPressBack: (controller) {
    final currentStep = controller.steps[controller.currentStepIndex];
    
    if (currentStep.actionOnPressBack == ActionOnPressBack.showCancelDialog) {
      return AlertDialog(
        title: Text('Cancel Process?'),
        actions: [
          TextButton(
            onPressed: () => controller.cancelFlow(),
            child: Text('Cancel'),
          ),
        ],
      );
    }
    
    return SizedBox.shrink();
  },
)
```

## User Confirmation and Input

### Confirmation Steps

```dart
FlowStep(
  step: ProcessStep.confirmation,
  name: 'Confirm Action',
  progressValue: 0.7,
  onStepCallback: () async {
    await processConfirmation();
  },
  requiresConfirmation: (controller) => AlertDialog(
    title: Text('Proceed?'),
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

### Data Collection Between Steps

```dart
// Step 1: Collect user input
FlowStep(
  step: ProcessStep.input,
  requiresConfirmation: (controller) => AlertDialog(
    content: TextField(
      onChanged: (value) => controller.setData('userInput', value),
    ),
    actions: [
      TextButton(
        onPressed: () => controller.continueFlow(),
        child: Text('Next'),
      ),
    ],
  ),
)

// Step 2: Use collected data
FlowStep(
  step: ProcessStep.process,
  onStepCallback: () async {
    final input = controller.getData('userInput');
    await processWithInput(input);
  },
)
```

## Error Handling and Recovery

### Automatic Retry Logic

```dart
FlowStep(
  step: ProcessStep.networkCall,
  onStepCallback: () async {
    final response = await api.call();
    if (!response.isSuccess) {
      throw ApiException(response.error);
    }
  },
)

// In the widget:
onStepError: (step, name, error, stack, controller) {
  if (error is ApiException) {
    return Column(
      children: [
        Text('Network error occurred'),
        ElevatedButton(
          onPressed: () => controller.retry(),
          child: Text('Retry'),
        ),
      ],
    );
  }
  return DefaultErrorWidget(error);
}
```

### Conditional Flow Navigation

```dart
FlowStep(
  step: ProcessStep.validation,
  onStepCallback: () async {
    final isValid = await validateData();
    if (!isValid) {
      // Jump to error correction step
      controller.continueFlow(flowIndex: 2);
      return;
    }
    // Continue normal flow
  },
)
```

## Advanced Customization

### Manual Flow Control

```dart
class CustomFlowWidget extends StatefulWidget {
  @override
  State<CustomFlowWidget> createState() => _CustomFlowWidgetState();
}

class _CustomFlowWidgetState extends State<CustomFlowWidget> {
  late FlowController<MyStep> controller;

  @override
  void initState() {
    super.initState();
    controller = FlowController<MyStep>(steps: steps);
    // Don't auto-start
  }

  void startFlow() async {
    await controller.start();
  }

  void pauseFlow() {
    // Custom pause logic
    controller.cancelFlow();
  }

  @override
  Widget build(BuildContext context) {
    return SequentialFlow<MyStep>(
      steps: controller.steps,
      autoStart: false,
      // ... other configuration
    );
  }
}
```

### Dynamic Step Generation

```dart
List<FlowStep<String>> buildDynamicSteps(List<Task> tasks) {
  return tasks.asMap().entries.map((entry) {
    final index = entry.key;
    final task = entry.value;
    
    return FlowStep<String>(
      step: task.id,
      name: task.name,
      progressValue: (index + 1) / tasks.length,
      onStepCallback: () async {
        await executeTask(task);
      },
      actionOnPressBack: task.isCritical 
          ? ActionOnPressBack.block 
          : ActionOnPressBack.goToPreviousStep,
    );
  }).toList();
}
```

## Recommended Use Cases

### Highly Suitable For

- **Onboarding flows**: User registration, app setup, permissions
- **Data migration**: Multi-step import/export processes
- **Payment processing**: Amount selection, method, details, processing
- **Wizard-style forms**: Complex multi-page data collection
- **Setup processes**: Configuration workflows, installation steps
- **Content creation**: Multi-step publishing, form builders

### Technical Requirements

- **Sequential operations**: When steps must execute in order
- **State persistence**: Data needs to persist between steps
- **Error recovery**: Ability to retry failed operations
- **Custom navigation**: Non-standard back button behavior required
- **Progress indication**: Visual feedback for multi-step processes

### Less Suitable For

- **Simple forms**: Single-page forms with basic validation
- **Real-time updates**: Live data streaming or chat interfaces
- **Media players**: Audio/video playback controls
- **Gaming interfaces**: Rapid user interactions, real-time feedback
- **Dashboard widgets**: Static data display components

## Complex Implementation Patterns

### Multi-Branch Flows

```dart
FlowStep(
  step: ProcessStep.decision,
  onStepCallback: () async {
    final userType = await determineUserType();
    final nextStepIndex = userType == 'premium' ? 3 : 5;
    controller.continueFlow(flowIndex: nextStepIndex);
  },
)
```

### Nested Sub-Flows

```dart
FlowStep(
  step: ProcessStep.subProcess,
  requiresConfirmation: (controller) => SequentialFlow<SubStep>(
    steps: subSteps,
    onStepFinish: (step, name, progress, subController) {
      // Transfer data from sub-flow to main flow
      final subData = subController.getAllData();
      controller.setData('subFlowResult', subData);
      controller.continueFlow();
      
      return SizedBox.shrink();
    },
  ),
)
```

### Background Processing with Updates

```dart
FlowStep(
  step: ProcessStep.backgroundTask,
  onStepCallback: () async {
    await for (final progress in processLargeFile()) {
      controller.setData('currentProgress', progress);
      // Trigger UI update without completing step
      controller.notifyListeners();
    }
  },
)

// Custom loading widget that reads progress
onStepLoading: (step, name, progress) {
  final currentProgress = controller.getData('currentProgress') ?? 0.0;
  return Column(
    children: [
      LinearProgressIndicator(value: currentProgress),
      Text('Processing: ${(currentProgress * 100).toInt()}%'),
    ],
  );
}
```

### Integration with External State Management

```dart
class FlowWithBloc extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        return SequentialFlow<ProcessStep>(
          steps: _buildStepsFromState(state),
          onStepFinish: (step, name, progress, controller) {
            // Update external state
            context.read<AppBloc>().add(
              FlowCompleted(controller.getAllData())
            );
            
            return CompletionWidget();
          },
        );
      },
    );
  }
}
```

## Performance Considerations

### Memory Management

- Flow data is stored in memory only
- Call `controller.reset()` to clear data after completion
- Dispose controllers properly in `StatefulWidget.dispose()`

### Large Step Counts

- Library handles 50+ steps efficiently
- Consider pagination for 100+ steps
- Use lazy loading for dynamic step generation

### Resource Cleanup

```dart
@override
void dispose() {
  controller.dispose();
  super.dispose();
}
```

## Limitations

- **Memory-only storage**: Data doesn't persist across app restarts
- **Flutter dependency**: Requires Flutter framework, not pure Dart

## Migration and Compatibility

- **Minimum Flutter version**: 3.0.0
- **Dart SDK**: >=2.17.0
- **Platform support**: iOS, Android, Web (html, wasm), Desktop
- **State management**: Any

## Testing

```dart
testWidgets('should complete payment flow', (tester) async {
  await tester.pumpWidget(PaymentFlowWidget());
  
  // Wait for first step
  await tester.pumpAndSettle();
  
  // Interact with flow
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  
  // Verify completion
  expect(find.text('Payment Successful'), findsOneWidget);
});
```

