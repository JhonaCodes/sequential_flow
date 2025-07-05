///
/// This example demonstrates a realistic, production-ready payment flow using
/// the Sequential Flow library. It showcases:
/// - User authentication and verification
/// - Conditional flow navigation based on user choices
/// - Dynamic step progression depending on payment method
/// - Complete error handling and validation
/// - Real-world payment processing simulation
///
/// The complete flow consists of 8 sequential steps:
/// 1. Authentication - User login or guest checkout
/// 2. User Verification - Identity verification for new users
/// 3. Amount Selection - Choose payment amount or enter custom
/// 4. Payment Method - Select from multiple payment options
/// 5. Payment Details - Method-specific information entry
/// 6. Review & Confirm - Final review before processing
/// 7. Processing - Payment processing with real-world delays
/// 8. Confirmation - Success receipt and next actions
///
/// Example usage:
/// ```dart
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       home: CompletePaymentFlow(),
///     );
///   }
/// }
/// ```
library;

import 'package:flutter/material.dart';
import 'package:sequential_flow/sequential_flow.dart';

/// Enum defining all steps in the complete payment flow.
enum PaymentStep {
  /// User authentication or guest checkout selection
  authentication,

  /// Identity verification for security (conditional)
  verification,

  /// Payment amount selection or custom entry
  amountSelection,

  /// Payment method selection (card, bank, digital wallet, etc.)
  paymentMethod,

  /// Payment details entry (varies by method)
  paymentDetails,

  /// Review all information before processing
  reviewConfirm,

  /// Payment processing with real-world simulation
  processing,

  /// Final confirmation and receipt
  confirmation,
}

/// Type-safe keys for comprehensive data storage throughout the flow.
enum PaymentDataKeys {
  // Authentication data
  isAuthenticated,
  userEmail,
  isGuest,

  // Verification data
  needsVerification,
  isVerified,
  verificationMethod,

  // Payment data
  amount,
  isCustomAmount,
  paymentMethod,

  // Card details
  cardNumber,
  expiryDate,
  cvv,
  cardholderName,

  // Bank details
  accountNumber,
  routingNumber,
  bankName,

  // Digital wallet details
  walletEmail,
  walletProvider,

  // Processing data
  transactionId,
  processingTime,

  // Review data
  termsAccepted,
  receiptEmail,
}

/// Main complete payment flow widget.
///
/// This demonstrates a production-ready payment flow with all the complexity
/// of real-world payment processing including authentication, verification,
/// multiple payment methods, and proper error handling.
class CompletePaymentFlow extends StatelessWidget {
  const CompletePaymentFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Payment'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: SequentialFlow<PaymentStep>(
        steps: [

          // ========================================
          // STEP 1: AUTHENTICATION
          // ========================================
          /// User authentication or guest checkout selection.
          /// Determines if user needs verification in next step.
          FlowStep<PaymentStep>(
            step: PaymentStep.authentication,
            name: 'Authentication',
            progressValue: 0.125, // 1/8
            onStepCallback: (controller) async {
              // Simulate authentication check
              await Future.delayed(const Duration(milliseconds: 800));
            },
            requiresConfirmation: (controller) => _AuthenticationWidget(
              controller: controller,
            ),
            actionOnPressBack: ActionOnPressBack.custom,
          ),

          // ========================================
          // STEP 2: USER VERIFICATION (CONDITIONAL)
          // ========================================
          /// Identity verification - only shown for new users or high amounts.
          /// Can be skipped based on user authentication status.
          FlowStep<PaymentStep>(
            step: PaymentStep.verification,
            name: 'Identity Verification',
            progressValue: 0.25, // 2/8
            onStepCallback: (controller) async {
              final needsVerification = controller.getData<PaymentDataKeys, bool>(
                PaymentDataKeys.needsVerification,
              ) ?? false;

              if (!needsVerification) {
                // Skip verification for authenticated users
                return;
              }

              // Simulate verification process
              await Future.delayed(const Duration(seconds: 2));
              controller.setData(PaymentDataKeys.isVerified, true);
            },
            requiresConfirmation: (controller) {
              final needsVerification = controller.getData<PaymentDataKeys, bool>(
                PaymentDataKeys.needsVerification,
              ) ?? false;

              if (!needsVerification) {
                // Auto-continue if verification not needed
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  controller.continueFlow();
                });
                return const SizedBox.shrink();
              }

              return _VerificationWidget(controller: controller);
            },
            actionOnPressBack: ActionOnPressBack.goToPreviousStep,
          ),

          // ========================================
          // STEP 3: AMOUNT SELECTION
          // ========================================
          /// Payment amount selection with predefined options and custom entry.
          FlowStep<PaymentStep>(
            step: PaymentStep.amountSelection,
            name: 'Select Amount',
            progressValue: 0.375, // 3/8
            onStepCallback: (controller) async {
              await Future.delayed(const Duration(milliseconds: 600));
            },
            requiresConfirmation: (controller) => _AmountSelectionWidget(
              controller: controller,
            ),
            actionOnPressBack: ActionOnPressBack.custom,
          ),

          // ========================================
          // STEP 4: PAYMENT METHOD SELECTION
          // ========================================
          /// Comprehensive payment method selection including cards, banks, and digital wallets.
          FlowStep<PaymentStep>(
            step: PaymentStep.paymentMethod,
            name: 'Payment Method',
            progressValue: 0.5, // 4/8
            onStepCallback: (controller) async {
              await Future.delayed(const Duration(milliseconds: 500));
            },
            requiresConfirmation: (controller) => _PaymentMethodWidget(
              controller: controller,
            ),
            actionOnPressBack: ActionOnPressBack.goToPreviousStep,
          ),

          // ========================================
          // STEP 5: PAYMENT DETAILS (DYNAMIC)
          // ========================================
          /// Dynamic payment details entry based on selected method.
          /// Shows different forms for card, bank, or digital wallet.
          FlowStep<PaymentStep>(
            step: PaymentStep.paymentDetails,
            name: 'Payment Details',
            progressValue: 0.625, // 5/8
            onStepCallback: (controller) async {
              await Future.delayed(const Duration(milliseconds: 800));
            },
            requiresConfirmation: (controller) => _PaymentDetailsWidget(
              controller: controller,
            ),
            actionOnPressBack: ActionOnPressBack.goToPreviousStep,
          ),

          // ========================================
          // STEP 6: REVIEW & CONFIRM
          // ========================================
          /// Complete transaction review with all details and terms acceptance.
          FlowStep<PaymentStep>(
            step: PaymentStep.reviewConfirm,
            name: 'Review & Confirm',
            progressValue: 0.75, // 6/8
            onStepCallback: (controller) async {
              final termsAccepted = controller.getData<PaymentDataKeys, bool>(
                PaymentDataKeys.termsAccepted,
              ) ?? false;

              if (!termsAccepted) {
                throw Exception('Please accept the terms and conditions to continue.');
              }

              // Generate transaction ID
              final transactionId = 'TXN${DateTime.now().millisecondsSinceEpoch}';
              controller.setData(PaymentDataKeys.transactionId, transactionId);

              await Future.delayed(const Duration(milliseconds: 500));
            },
            requiresConfirmation: (controller) => _ReviewConfirmWidget(
              controller: controller,
            ),
            actionOnPressBack: ActionOnPressBack.goToPreviousStep,
          ),

          // ========================================
          // STEP 7: PAYMENT PROCESSING
          // ========================================
          /// Realistic payment processing with method-specific delays and potential failures.
          FlowStep<PaymentStep>(
            step: PaymentStep.processing,
            name: 'Processing Payment',
            progressValue: 0.875, // 7/8
            onStepCallback: (controller) async {
              final paymentMethod = controller.getData<PaymentDataKeys, String>(
                PaymentDataKeys.paymentMethod,
              );

              // Different processing times for different methods
              Duration processingTime;
              switch (paymentMethod) {
                case 'card':
                  processingTime = const Duration(seconds: 3);
                  break;
                case 'bank':
                  processingTime = const Duration(seconds: 5);
                  break;
                case 'paypal':
                case 'applepay':
                case 'googlepay':
                  processingTime = const Duration(seconds: 2);
                  break;
                default:
                  processingTime = const Duration(seconds: 4);
              }

              controller.setData(PaymentDataKeys.processingTime, processingTime.inSeconds);

              // Simulate processing
              await Future.delayed(processingTime);

              // Simulate potential failures (10% chance)
              if (DateTime.now().millisecond % 10 == 0) {
                final failures = [
                  'Insufficient funds in account',
                  'Card declined by issuer',
                  'Network timeout - please try again',
                  'Payment gateway temporarily unavailable',
                  'Invalid payment details',
                ];
                final randomFailure = failures[DateTime.now().millisecond % failures.length];
                throw Exception(randomFailure);
              }
            },
            actionOnPressBack: ActionOnPressBack.block,
          ),

          // ========================================
          // STEP 8: CONFIRMATION & RECEIPT
          // ========================================
          /// Final confirmation with transaction details and next actions.
          FlowStep<PaymentStep>(
            step: PaymentStep.confirmation,
            name: 'Payment Complete',
            progressValue: 1.0, // 8/8
            onStepCallback: (controller) async {
              // Simulate receipt generation
              await Future.delayed(const Duration(milliseconds: 800));
            },
            actionOnPressBack: ActionOnPressBack.block,
          ),
        ],

        // ========================================
        // CUSTOM UI BUILDERS
        // ========================================

        onStepLoading: (step, name, progress) => _LoadingWidget(
          step: step,
          name: name,
          progress: progress,
        ),

        onStepFinish: (step, name, progress, controller) => _PaymentSuccessWidget(
          controller: controller,
        ),

        onStepError: (step, name, error, stack, controller) => _PaymentErrorWidget(
          stepName: name,
          error: error,
          controller: controller,
        ),

        onBackPressed: (controller) => _ExitConfirmationWidget(
          controller: controller,
        ),
      ),
    );
  }
}

// ========================================
// AUTHENTICATION WIDGETS
// ========================================

/// Authentication step widget with login and guest options.
class _AuthenticationWidget extends StatelessWidget {
  final FlowController<PaymentStep> controller;

  const _AuthenticationWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.security, size: 80, color: Colors.blue),
          const SizedBox(height: 24),
          const Text(
            'Welcome to Secure Payment',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Choose how you\'d like to proceed with your payment',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          _AuthMethodButton(
            icon: Icons.person,
            title: 'Login to Account',
            subtitle: 'Faster checkout with saved details',
            onPressed: () => _selectAuthMethod(true),
          ),
          const SizedBox(height: 16),
          _AuthMethodButton(
            icon: Icons.person_outline,
            title: 'Continue as Guest',
            subtitle: 'Quick checkout without account',
            onPressed: () => _selectAuthMethod(false),
          ),
        ],
      ),
    );
  }

  void _selectAuthMethod(bool isLogin) {
    if (isLogin) {
      controller.setData(PaymentDataKeys.isAuthenticated, true);
      controller.setData(PaymentDataKeys.userEmail, 'user@example.com');
      controller.setData(PaymentDataKeys.needsVerification, false);
      controller.setData(PaymentDataKeys.isGuest, false);
    } else {
      controller.setData(PaymentDataKeys.isAuthenticated, false);
      controller.setData(PaymentDataKeys.needsVerification, true);
      controller.setData(PaymentDataKeys.isGuest, true);
    }
    controller.continueFlow();
  }
}

class _AuthMethodButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  const _AuthMethodButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 32, color: Colors.blue),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========================================
// VERIFICATION WIDGETS
// ========================================

class _VerificationWidget extends StatelessWidget {
  final FlowController<PaymentStep> controller;

  const _VerificationWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified_user, size: 80, color: Colors.green),
          const SizedBox(height: 24),
          const Text(
            'Identity Verification',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'For your security, we need to verify your identity before processing payments',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          _VerificationMethodButton(
            icon: Icons.email,
            title: 'Email Verification',
            subtitle: 'Send code to your email',
            onPressed: () => _selectVerificationMethod('email'),
          ),
          const SizedBox(height: 16),
          _VerificationMethodButton(
            icon: Icons.sms,
            title: 'SMS Verification',
            subtitle: 'Send code to your phone',
            onPressed: () => _selectVerificationMethod('sms'),
          ),
        ],
      ),
    );
  }

  void _selectVerificationMethod(String method) {
    controller.setData(PaymentDataKeys.verificationMethod, method);
    controller.continueFlow();
  }
}

class _VerificationMethodButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  const _VerificationMethodButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 28, color: Colors.green),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========================================
// AMOUNT SELECTION WIDGETS
// ========================================

class _AmountSelectionWidget extends StatefulWidget {
  final FlowController<PaymentStep> controller;

  const _AmountSelectionWidget({required this.controller});

  @override
  State<_AmountSelectionWidget> createState() => _AmountSelectionWidgetState();
}

class _AmountSelectionWidgetState extends State<_AmountSelectionWidget> {
  final _customAmountController = TextEditingController();
  bool _isCustomAmount = false;
  double? _selectedAmount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.attach_money, size: 80, color: Colors.green),
          const SizedBox(height: 24),
          const Text(
            'Select Payment Amount',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),

          // Predefined amounts
          if (!_isCustomAmount) ...[
            _AmountButton(amount: 25.0, onPressed: () => _selectAmount(25.0)),
            const SizedBox(height: 12),
            _AmountButton(amount: 50.0, onPressed: () => _selectAmount(50.0)),
            const SizedBox(height: 12),
            _AmountButton(amount: 100.0, onPressed: () => _selectAmount(100.0)),
            const SizedBox(height: 12),
            _AmountButton(amount: 250.0, onPressed: () => _selectAmount(250.0)),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => setState(() => _isCustomAmount = true),
              icon: const Icon(Icons.edit),
              label: const Text('Enter Custom Amount'),
            ),
          ],

          // Custom amount entry
          if (_isCustomAmount) ...[
            TextField(
              controller: _customAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter Amount',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final amount = double.tryParse(value);
                setState(() => _selectedAmount = amount);
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _isCustomAmount = false;
                      _selectedAmount = null;
                      _customAmountController.clear();
                    }),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedAmount != null && _selectedAmount! > 0
                        ? () => _selectAmount(_selectedAmount!)
                        : null,
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _selectAmount(double amount) {
    widget.controller.setData(PaymentDataKeys.amount, amount);
    widget.controller.setData(PaymentDataKeys.isCustomAmount, _isCustomAmount);
    widget.controller.continueFlow();
  }
}

class _AmountButton extends StatelessWidget {
  final double amount;
  final VoidCallback onPressed;

  const _AmountButton({required this.amount, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          '\$${amount.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}

// ========================================
// PAYMENT METHOD WIDGETS
// ========================================

class _PaymentMethodWidget extends StatelessWidget {
  final FlowController<PaymentStep> controller;

  const _PaymentMethodWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.payment, size: 80, color: Colors.blue),
          const SizedBox(height: 24),
          const Text(
            'Choose Payment Method',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          _PaymentMethodCard(
            icon: Icons.credit_card,
            title: 'Credit/Debit Card',
            subtitle: 'Visa, Mastercard, American Express',
            onPressed: () => _selectMethod('card'),
          ),
          const SizedBox(height: 12),
          _PaymentMethodCard(
            icon: Icons.account_balance,
            title: 'Bank Transfer',
            subtitle: 'Direct bank account transfer',
            onPressed: () => _selectMethod('bank'),
          ),
          const SizedBox(height: 12),
          _PaymentMethodCard(
            icon: Icons.paypal,
            title: 'PayPal',
            subtitle: 'Pay with your PayPal account',
            onPressed: () => _selectMethod('paypal'),
          ),
          const SizedBox(height: 12),
          _PaymentMethodCard(
            icon: Icons.apple,
            title: 'Apple Pay',
            subtitle: 'Touch ID or Face ID',
            onPressed: () => _selectMethod('applepay'),
          ),
          const SizedBox(height: 12),
          _PaymentMethodCard(
            icon: Icons.g_mobiledata,
            title: 'Google Pay',
            subtitle: 'Pay with Google',
            onPressed: () => _selectMethod('googlepay'),
          ),
        ],
      ),
    );
  }

  void _selectMethod(String method) {
    controller.setData(PaymentDataKeys.paymentMethod, method);
    controller.continueFlow();
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  const _PaymentMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 32, color: Colors.blue),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========================================
// PAYMENT DETAILS WIDGETS
// ========================================

class _PaymentDetailsWidget extends StatelessWidget {
  final FlowController<PaymentStep> controller;

  const _PaymentDetailsWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    final method = controller.getData<PaymentDataKeys, String>(PaymentDataKeys.paymentMethod);

    switch (method) {
      case 'card':
        return _CreditCardDetailsWidget(controller: controller);
      case 'bank':
        return _BankDetailsWidget(controller: controller);
      case 'paypal':
        return _PayPalDetailsWidget(controller: controller);
      case 'applepay':
      case 'googlepay':
        return _DigitalWalletDetailsWidget(controller: controller, method: method!);
      default:
        return _GenericPaymentDetailsWidget(controller: controller);
    }
  }
}

class _CreditCardDetailsWidget extends StatefulWidget {
  final FlowController<PaymentStep> controller;

  const _CreditCardDetailsWidget({required this.controller});

  @override
  State<_CreditCardDetailsWidget> createState() => _CreditCardDetailsWidgetState();
}

class _CreditCardDetailsWidgetState extends State<_CreditCardDetailsWidget> {
  final _formKey = GlobalKey<FormState>();
  bool _canContinue = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.credit_card, size: 80, color: Colors.blue),
          const SizedBox(height: 24),
          const Text(
            'Credit Card Details',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Cardholder Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  onChanged: (value) {
                    widget.controller.setData(PaymentDataKeys.cardholderName, value);
                    _checkFormValidity();
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Card Number',
                    hintText: '1234 5678 9012 3456',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  onChanged: (value) {
                    widget.controller.setData(PaymentDataKeys.cardNumber, value);
                    _checkFormValidity();
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'MM/YY',
                          hintText: '12/25',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                        onChanged: (value) {
                          widget.controller.setData(PaymentDataKeys.expiryDate, value);
                          _checkFormValidity();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          hintText: '123',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                        onChanged: (value) {
                          widget.controller.setData(PaymentDataKeys.cvv, value);
                          _checkFormValidity();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canContinue ? () => widget.controller.continueFlow() : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _checkFormValidity() {
    setState(() {
      _canContinue = _formKey.currentState?.validate() ?? false;
    });
  }
}

class _BankDetailsWidget extends StatefulWidget {
  final FlowController<PaymentStep> controller;

  const _BankDetailsWidget({required this.controller});

  @override
  State<_BankDetailsWidget> createState() => _BankDetailsWidgetState();
}

class _BankDetailsWidgetState extends State<_BankDetailsWidget> {
  final _formKey = GlobalKey<FormState>();
  bool _canContinue = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_balance, size: 80, color: Colors.blue),
          const SizedBox(height: 24),
          const Text(
            'Bank Account Details',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Bank Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  onChanged: (value) {
                    widget.controller.setData(PaymentDataKeys.bankName, value);
                    _checkFormValidity();
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Account Number',
                    hintText: '1234567890',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  onChanged: (value) {
                    widget.controller.setData(PaymentDataKeys.accountNumber, value);
                    _checkFormValidity();
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Routing Number',
                    hintText: '987654321',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  onChanged: (value) {
                    widget.controller.setData(PaymentDataKeys.routingNumber, value);
                    _checkFormValidity();
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canContinue ? () => widget.controller.continueFlow() : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _checkFormValidity() {
    setState(() {
      _canContinue = _formKey.currentState?.validate() ?? false;
    });
  }
}

class _PayPalDetailsWidget extends StatelessWidget {
  final FlowController<PaymentStep> controller;

  const _PayPalDetailsWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.paypal, size: 80, color: Colors.blue),
          const SizedBox(height: 24),
          const Text(
            'PayPal Account',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'PayPal Email',
              hintText: 'your@paypal.com',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              controller.setData(PaymentDataKeys.walletEmail, value);
              controller.setData(PaymentDataKeys.walletProvider, 'paypal');
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => controller.continueFlow(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Continue with PayPal',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DigitalWalletDetailsWidget extends StatelessWidget {
  final FlowController<PaymentStep> controller;
  final String method;

  const _DigitalWalletDetailsWidget({
    required this.controller,
    required this.method,
  });

  @override
  Widget build(BuildContext context) {
    final isApplePay = method == 'applepay';
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isApplePay ? Icons.apple : Icons.g_mobiledata,
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          Text(
            '${isApplePay ? 'Apple' : 'Google'} Pay',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Use your ${isApplePay ? 'Touch ID, Face ID, or passcode' : 'fingerprint or PIN'} to complete the payment',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isApplePay ? Icons.fingerprint : Icons.fingerprint,
              size: 80,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                controller.setData(PaymentDataKeys.walletProvider, method);
                controller.continueFlow();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Authenticate with ${isApplePay ? 'Apple Pay' : 'Google Pay'}',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenericPaymentDetailsWidget extends StatelessWidget {
  final FlowController<PaymentStep> controller;

  const _GenericPaymentDetailsWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.payment, size: 80, color: Colors.blue),
          const SizedBox(height: 24),
          const Text(
            'Payment Method Setup',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Complete the payment setup for your selected method',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => controller.continueFlow(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================
// REVIEW & CONFIRM WIDGETS
// ========================================

class _ReviewConfirmWidget extends StatefulWidget {
  final FlowController<PaymentStep> controller;

  const _ReviewConfirmWidget({required this.controller});

  @override
  State<_ReviewConfirmWidget> createState() => _ReviewConfirmWidgetState();
}

class _ReviewConfirmWidgetState extends State<_ReviewConfirmWidget> {
  bool _termsAccepted = false;
  bool _receiptByEmail = true;

  @override
  Widget build(BuildContext context) {
    final amount = widget.controller.getData<PaymentDataKeys, double>(PaymentDataKeys.amount);
    final method = widget.controller.getData<PaymentDataKeys, String>(PaymentDataKeys.paymentMethod);
    final userEmail = widget.controller.getData<PaymentDataKeys, String>(PaymentDataKeys.userEmail);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Icon(Icons.receipt_long, size: 80, color: Colors.green),
          const SizedBox(height: 24),
          const Text(
            'Review Your Payment',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),

          // Payment Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _SummaryRow('Amount:', amount?.toStringAsFixed(2) ?? 'N/A'),
                  _SummaryRow('Method:', _getMethodDisplayName(method)),
                  _SummaryRow('Processing Fee:', '\$2.99'),
                  const Divider(),
                  _SummaryRow('Total:', '${((amount ?? 0) + 2.99).toStringAsFixed(2)}', isTotal: true),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Terms and receipt options
          CheckboxListTile(
            value: _termsAccepted,
            onChanged: (value) {
              setState(() => _termsAccepted = value ?? false);
              widget.controller.setData(PaymentDataKeys.termsAccepted, _termsAccepted);
            },
            title: const Text('I accept the Terms and Conditions'),
            controlAffinity: ListTileControlAffinity.leading,
          ),

          if (userEmail != null)
            CheckboxListTile(
              value: _receiptByEmail,
              onChanged: (value) {
                setState(() => _receiptByEmail = value ?? false);
                widget.controller.setData(PaymentDataKeys.receiptEmail, _receiptByEmail ? userEmail : null);
              },
              title: Text('Send receipt to $userEmail'),
              controlAffinity: ListTileControlAffinity.leading,
            ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _termsAccepted ? () => widget.controller.continueFlow() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Confirm Payment',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMethodDisplayName(String? method) {
    switch (method) {
      case 'card': return 'Credit/Debit Card';
      case 'bank': return 'Bank Transfer';
      case 'paypal': return 'PayPal';
      case 'applepay': return 'Apple Pay';
      case 'googlepay': return 'Google Pay';
      default: return 'Unknown';
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow(this.label, this.value, {this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================
// UI STATE WIDGETS
// ========================================

class _LoadingWidget extends StatelessWidget {
  final PaymentStep step;
  final String name;
  final double progress;

  const _LoadingWidget({
    required this.step,
    required this.name,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(value: progress, strokeWidth: 6),
          const SizedBox(height: 24),
          Text(
            name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('${(progress * 100).toInt()}% Complete'),
          if (step == PaymentStep.processing) ...[
            const SizedBox(height: 16),
            const Text(
              'Securely processing your payment...\nPlease do not close this window.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentSuccessWidget extends StatelessWidget {
  final FlowController<PaymentStep> controller;

  const _PaymentSuccessWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    final amount = controller.getData<PaymentDataKeys, double>(PaymentDataKeys.amount);
    final method = controller.getData<PaymentDataKeys, String>(PaymentDataKeys.paymentMethod);
    final transactionId = controller.getData<PaymentDataKeys, String>(PaymentDataKeys.transactionId);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 100, color: Colors.green),
          const SizedBox(height: 24),
          const Text(
            'Payment Successful!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 16),
          Text(
            'Your payment of ${((amount ?? 0) + 2.99).toStringAsFixed(2)} has been processed successfully.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SummaryRow('Transaction ID:', transactionId ?? 'N/A'),
                  _SummaryRow('Amount:', amount?.toStringAsFixed(2) ?? 'N/A'),
                  _SummaryRow('Method:', _getMethodDisplayName(method)),
                  _SummaryRow('Date:', DateTime.now().toString().split(' ')[0]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    controller.restart();
                  },
                  child: const Text('New Payment'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMethodDisplayName(String? method) {
    switch (method) {
      case 'card': return 'Credit/Debit Card';
      case 'bank': return 'Bank Transfer';
      case 'paypal': return 'PayPal';
      case 'applepay': return 'Apple Pay';
      case 'googlepay': return 'Google Pay';
      default: return 'Unknown';
    }
  }
}

class _PaymentErrorWidget extends StatelessWidget {
  final String stepName;
  final Object error;
  final FlowController<PaymentStep> controller;

  const _PaymentErrorWidget({
    required this.stepName,
    required this.error,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 24),
          Text(
            'Payment Failed',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 16),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => controller.reset(),
                  child: const Text('Start Over'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => controller.retry(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Try Again'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExitConfirmationWidget extends StatelessWidget {
  final FlowController<PaymentStep> controller;

  const _ExitConfirmationWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.exit_to_app, size: 80, color: Colors.orange),
          const SizedBox(height: 24),
          const Text(
            'Exit Payment Flow?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Are you sure you want to exit? Your progress will be saved and you can continue later.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => controller.hideBackWidget(),
                  child: const Text('Continue Payment'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async{
                    await controller.continueFlow(flowIndex: 2);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('Exit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}