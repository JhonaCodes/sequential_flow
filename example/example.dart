library;
/// Payment Flow Example for Sequential Flow
///
/// This example demonstrates how to create a complete payment processing flow
/// using the Sequential Flow library. It showcases:
/// - Multi-step flow with different UI states
/// - User input collection and validation
/// - Error handling with retry functionality
/// - Custom back navigation behavior
/// - Data persistence between steps
///
/// The payment flow consists of 5 steps:
/// 1. Amount selection
/// 2. Payment method selection
/// 3. Payment details entry
/// 4. Payment processing
/// 5. Confirmation screen

import 'package:flutter/material.dart';
import 'package:sequential_flow/sequential_flow.dart';

/// Enum defining the different steps in the payment flow.
///
/// Each step represents a distinct phase of the payment process,
/// from initial amount selection to final confirmation.
enum PaymentStep {
  /// User selects the payment amount from predefined options
  selectAmount,

  /// User chooses between credit card or bank transfer
  selectMethod,

  /// User enters payment details (card info or bank details)
  enterDetails,

  /// System processes the payment (with simulated success/failure)
  processing,

  /// Final confirmation screen showing payment success
  confirmation,
}

/// Main payment flow widget that orchestrates the entire payment process.
///
/// This widget demonstrates a real-world use case of the Sequential Flow library,
/// showing how to handle user input, data validation, error recovery, and
/// different navigation behaviors throughout a multi-step process.
///
/// Example usage:
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute(
///     builder: (context) => const PaymentFlowWidget(),
///   ),
/// );
/// ```
class PaymentFlowWidget extends StatelessWidget {
  const PaymentFlowWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Process'),
        backgroundColor: Colors.blue,
      ),
      body: SequentialFlow<PaymentStep>(
        steps: [
          // Step 1: Amount Selection
          // Users choose from predefined amounts with confirmation dialog
          FlowStep<PaymentStep>(
            step: PaymentStep.selectAmount,
            name: 'Select Amount',
            progressValue: 0.2,
            onStepCallback: () async {
              // Simulate amount selection processing
              await Future.delayed(const Duration(seconds: 1));
            },
            requiresConfirmation: (controller) => AlertDialog(
              title: const Text('Select Amount'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('\$10.00'),
                    onTap: () {
                      controller.setData('amount', 10.00);
                      controller.continueFlow();
                    },
                  ),
                  ListTile(
                    title: const Text('\$25.00'),
                    onTap: () {
                      controller.setData('amount', 25.00);
                      controller.continueFlow();
                    },
                  ),
                  ListTile(
                    title: const Text('\$50.00'),
                    onTap: () {
                      controller.setData('amount', 50.00);
                      controller.continueFlow();
                    },
                  ),
                ],
              ),
            ),
            // Show cancel dialog if user tries to go back
            actionOnPressBack: ActionOnPressBack.showCancelDialog,
          ),

          // Step 2: Payment Method Selection
          // Users choose between credit card and bank transfer
          FlowStep<PaymentStep>(
            step: PaymentStep.selectMethod,
            name: 'Payment Method',
            progressValue: 0.4,
            onStepCallback: () async {
              await Future.delayed(const Duration(milliseconds: 500));
            },
            requiresConfirmation: (controller) => AlertDialog(
              title: const Text('Select Payment Method'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.credit_card),
                    title: const Text('Credit Card'),
                    onTap: () {
                      controller.setData('method', 'card');
                      controller.continueFlow();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_balance),
                    title: const Text('Bank Transfer'),
                    onTap: () {
                      controller.setData('method', 'bank');
                      controller.continueFlow();
                    },
                  ),
                ],
              ),
            ),
            // Allow going back to previous step
            actionOnPressBack: ActionOnPressBack.goToPreviousStep,
          ),

          // Step 3: Payment Details Entry
          // Dynamic form based on selected payment method
          FlowStep<PaymentStep>(
            step: PaymentStep.enterDetails,
            name: 'Enter Details',
            progressValue: 0.6,
            onStepCallback: () async {
              await Future.delayed(const Duration(milliseconds: 800));
            },
            requiresConfirmation: (controller) {
              final method = controller.getData('method');
              return AlertDialog(
                title: Text('Enter ${method == 'card' ? 'Card' : 'Bank'} Details'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Show different fields based on payment method
                    if (method == 'card') ...[
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Card Number',
                          hintText: '1234 5678 9012 3456',
                        ),
                        onChanged: (value) => controller.setData('cardNumber', value),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          hintText: '123',
                        ),
                        onChanged: (value) => controller.setData('cvv', value),
                      ),
                    ] else ...[
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Account Number',
                          hintText: '1234567890',
                        ),
                        onChanged: (value) => controller.setData('accountNumber', value),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Routing Number',
                          hintText: '987654321',
                        ),
                        onChanged: (value) => controller.setData('routingNumber', value),
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => controller.continueFlow(),
                    child: const Text('Continue'),
                  ),
                ],
              );
            },
            actionOnPressBack: ActionOnPressBack.goToPreviousStep,
          ),

          // Step 4: Payment Processing
          // Simulates actual payment processing with potential failure
          FlowStep<PaymentStep>(
            step: PaymentStep.processing,
            name: 'Processing Payment',
            progressValue: 0.8,
            onStepCallback: () async {
              // Simulate payment processing time
              await Future.delayed(const Duration(seconds: 3));

              // Simulate random failure (20% chance)
              // This demonstrates error handling in the flow
              if (DateTime.now().millisecond % 5 == 0) {
                throw Exception('Payment failed. Please try again.');
              }
            },
            // Block navigation during payment processing for security
            actionOnPressBack: ActionOnPressBack.block,
          ),

          // Step 5: Payment Confirmation
          // Final step showing successful payment completion
          FlowStep<PaymentStep>(
            step: PaymentStep.confirmation,
            name: 'Payment Confirmation',
            progressValue: 1.0,
            onStepCallback: () async {
              await Future.delayed(const Duration(milliseconds: 500));
            },
            // Allow exiting after successful payment
            actionOnPressBack: ActionOnPressBack.saveAndExit,
          ),
        ],

        /// Custom loading widget displayed during step execution.
        ///
        /// Shows progress indicator, step name, and completion percentage.
        /// Includes special messaging for the payment processing step.
        onStepLoading: (step, name, progress) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
              ),
              const SizedBox(height: 24),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toInt()}% Complete',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              // Special message during payment processing
              if (step == PaymentStep.processing) ...[
                const SizedBox(height: 16),
                const Text(
                  'Please wait while we process your payment...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ],
          ),
        ),

        /// Success screen displayed when the flow completes successfully.
        ///
        /// Shows payment confirmation with details from the flow data,
        /// demonstrating how data persists throughout the entire process.
        onStepFinish: (step, name, progress, controller) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              // Display payment details collected during the flow
              Text(
                'Amount: \$${controller.getData('amount')?.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                'Method: ${controller.getData('method') == 'card' ? 'Credit Card' : 'Bank Transfer'}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),

        /// Error screen with retry functionality.
        ///
        /// Displays when a step fails (e.g., payment processing failure).
        /// Provides options to retry the failed step or cancel the entire flow.
        onStepError: (step, name, error, stack, controller) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                'Error in $name',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => controller.retry(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text('Retry'),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),

        /// Custom back button handling.
        ///
        /// Provides a custom cancel dialog for the first step,
        /// demonstrating how to implement custom navigation behavior.
        onPressBack: (controller) {
          final currentStep = controller.steps[controller.currentStepIndex];

          // Handle cancel dialog for the first step
          if (currentStep.actionOnPressBack == ActionOnPressBack.showCancelDialog) {
            return AlertDialog(
              title: const Text('Cancel Payment?'),
              content: const Text('Are you sure you want to cancel this payment?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Continue'),
                ),
                TextButton(
                  onPressed: () {
                    controller.cancelFlow();
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Cancel Payment'),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

/// Demo widget to launch the payment flow.
///
/// This widget provides a simple entry point to test the payment flow.
/// In a real application, this would typically be integrated into
/// a shopping cart, subscription signup, or other payment context.
///
/// Example usage in your main app:
/// ```dart
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       home: PaymentFlowDemo(),
///     );
///   }
/// }
/// ```
class PaymentFlowDemo extends StatelessWidget {
  const PaymentFlowDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sequential Flow Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.payment,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Flow Example',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Demonstrates a complete payment process using Sequential Flow library',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PaymentFlowWidget(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Start Payment Flow',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}