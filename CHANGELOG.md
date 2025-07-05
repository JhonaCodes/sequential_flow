# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.1.0

### Added
- **Type-Safe Data Storage**: Generic `setData<K, V>()` and `getData<K, V>()` methods
  - Support for any key type: strings, enums, integers, custom objects
  - Type-safe retrieval with compile-time checking
  - Backward compatibility with string keys via `setString()` and `getString()`
- **Improved Back Navigation**: New `onBackPressed` callback for cleaner custom back handling
  - Separates navigation logic from UI rendering
  - Only executes when back button is actually pressed
  - No more side effects during widget rebuilds

### Changed
- **BREAKING**: Replaced `onPressBack` with `onBackPressed` in `SequentialFlow`
  - `onPressBack` returned widgets and caused setState during build errors
  - `onBackPressed` is a void callback that executes logic only when needed
  - Migration: Move dialog logic from return statements to direct `showDialog()` calls
- **Enhanced API Design**: Separated concerns between UI rendering and navigation logic
  - `_FlowMainContent` now only handles state rendering
  - Back navigation is handled exclusively in `PopScope`
  - Cleaner, more predictable behavior

### Fixed
- **setState During Build**: Eliminated crashes caused by setState being called during widget build
- **Navigation Timing**: Back press handlers now execute at the correct time
- **Widget Lifecycle**: Proper separation of rendering and navigation concerns

### Improved
- **Developer Experience**: More intuitive API with clearer separation of responsibilities
- **Type Safety**: Enhanced compile-time checking for data storage operations
- **Documentation**: Updated examples to use new type-safe APIs
- **Error Prevention**: Architecture changes prevent common Flutter anti-patterns

### Migration Guide
```dart
// OLD (v1.0.0) - Caused setState during build errors
onPressBack: (controller) {
  return AlertDialog(
    title: Text('Cancel?'),
    actions: [
      TextButton(
        onPressed: () => controller.cancelFlow(),
        child: Text('Yes'),
      ),
    ],
  );
}

// NEW (v1.1.0) - Clean execution only when needed
onBackPressed: (controller) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Cancel?'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            controller.cancelFlow();
          },
          child: Text('Yes'),
        ),
      ],
    ),
  );
}

// Type-safe data storage
// OLD
controller.setData('amount', 10.0);
double? amount = controller.getData('amount');

// NEW (recommended)
enum Keys { amount, method }
controller.setData(Keys.amount, 10.0);
double? amount = controller.getData<Keys, double>(Keys.amount);
```

### Technical Improvements
- **Architecture**: Cleaner separation between UI rendering and event handling
- **Performance**: Reduced unnecessary widget rebuilds
- **Maintainability**: More predictable code flow and easier debugging
- **Flutter Best Practices**: Eliminated anti-patterns and improved compliance

## 1.0.0

### Added
- Initial release of Sequential Flow library
- **Core Components**:
  - `FlowStep<T>` class for defining individual flow steps
  - `FlowController<T>` for managing flow state and navigation
  - `SequentialFlow<T>` widget for orchestrating flow execution
- **Navigation Control**:
  - `ActionOnPressBack` enum with 8 different back navigation behaviors
  - Custom back action support with `customBackAction` callback
  - Step-specific navigation configuration
- **State Management**:
  - In-memory data storage with `setData()`, `getData()`, and `getAllData()`
  - Flow state tracking (loading, completed, error, cancelled, waiting confirmation)
  - Step history for proper back navigation
- **Error Handling**:
  - Automatic error catching and state management
  - Retry functionality with `controller.retry()`
  - Custom error UI builders
- **User Confirmation**:
  - `requiresConfirmation` widget builder for step confirmation
  - Flow pause/resume functionality
  - Custom confirmation dialogs
- **Customizable UI**:
  - `onStepLoading` builder for loading states
  - `onStepError` builder for error states
  - `onStepFinish` builder for completion states
  - `onStepCancel` builder for cancellation states
  - `onPressBack` builder for custom back navigation UI
- **Flow Control**:
  - Auto-start configuration with `autoStart` parameter
  - Manual flow control with `start()`, `cancel()`, `reset()`
  - Step jumping with `continueFlow(flowIndex: int)`
- **Type Safety**:
  - Generic type support for step identifiers
  - Compile-time type checking for step enums
- **Documentation**:
  - Comprehensive API documentation
  - Complete usage examples
  - Real-world use case demonstrations

### Features
- **Memory Efficient**: Data cleared automatically on reset
- **Flutter Integration**: Full integration with Flutter's widget lifecycle
- **Accessibility Support**: Compatible with screen readers and semantic labels
- **Performance Optimized**: Efficient handling of 50+ steps
- **Platform Support**: iOS, Android, Web, Desktop compatibility
- **State Management Agnostic**: Works with Provider, Bloc, Riverpod, GetX

### Examples Included
- Payment processing flow with error recovery
- User enrollment with email verification
- App initialization with permission handling
- Online exam with time management and auto-save

### Technical Specifications
- **Minimum Flutter Version**: 3.0.0
- **Dart SDK**: >=2.17.0 <4.0.0
- **Dependencies**: Flutter SDK only (no external dependencies)
- **Package Size**: Lightweight implementation
- **Test Coverage**: Comprehensive test suite included

### API Reference
- `FlowStep<T>` constructor with required and optional parameters
- `FlowController<T>` with complete state management API
- `SequentialFlow<T>` widget with customizable builders
- `ActionOnPressBack` enum with all navigation options

## [Unreleased]

### Planned Features
- **Conditional Flows**: Built-in support for branching logic
- **Parallel Steps**: Execute multiple steps simultaneously
- **Persistence Layer**: Optional data persistence between app sessions
- **Analytics Integration**: Built-in flow analytics and tracking
- **Step Templates**: Pre-built step templates for common use cases
- **Visual Flow Builder**: Design-time flow visualization tools
- **Advanced Validation**: Built-in validation framework for step data
- **Localization Support**: Multi-language flow content support

### Under Consideration
- **Flow Composition**: Ability to compose multiple flows
- **Step Dependency Management**: Define dependencies between steps
- **Custom Animations**: Configurable transitions between steps
- **Flow Debugging Tools**: Development-time debugging utilities
- **Performance Metrics**: Built-in performance monitoring
- **Cloud Integration**: Optional cloud-based flow synchronization