import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/cash_mate_logo.dart';
import '../../../core/widgets/google_logo.dart';
import '../../../core/widgets/hero_exchange_pair.dart';
import '../providers/auth_provider.dart';
import 'forgot_password_screen.dart';
import 'onboarding_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool initialIsSignUp;
  const LoginScreen({super.key, this.initialIsSignUp = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late bool _isSignUp;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _rememberMe = true;
  bool _agreeTerms = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  bool _nameTouched = false;
  bool _emailTouched = false;
  bool _passwordTouched = false;

  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;

    _nameController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));

    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) _nameTouched = true;
      setState(() {});
    });
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus) _emailTouched = true;
      setState(() {});
    });
    _passwordFocus.addListener(() {
      if (!_passwordFocus.hasFocus) _passwordTouched = true;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // --- Password Strength & Validation Calculations ---
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasLettersAndNumbers =>
      RegExp(r'[A-Za-z]').hasMatch(_passwordController.text) &&
      RegExp(r'\d').hasMatch(_passwordController.text);

  int get _strengthScore {
    final p = _passwordController.text;
    if (p.isEmpty) return 0;
    int score = 1;
    if (_hasMinLength) score++;
    if (_hasLettersAndNumbers) score++;
    if (p.length >= 12 && RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++;
    return score.clamp(0, 4);
  }

  bool get _isEmailValid =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_emailController.text.trim());
  bool get _isNameValid => _nameController.text.trim().length >= 2;
  bool get _isPasswordValid =>
      _isSignUp ? (_hasMinLength && _hasLettersAndNumbers) : _passwordController.text.isNotEmpty;

  bool get _canSubmit {
    if (_isLoading) return false;
    if (!_isEmailValid || !_isPasswordValid) return false;
    if (_isSignUp) {
      return _isNameValid && _agreeTerms;
    }
    return true;
  }

  void _switchTab(bool toSignUp) {
    setState(() {
      _isSignUp = toSignUp;
      _errorMessage = null;
      _successMessage = null;
      _nameTouched = false;
      _emailTouched = false;
      _passwordTouched = false;
    });
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _nameTouched = true;
      _emailTouched = true;
      _passwordTouched = true;
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_canSubmit) return;

    setState(() => _isLoading = true);

    final authService = ref.read(authServiceProvider);

    try {
      if (_isSignUp) {
        await authService.registerWithEmail(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) {
          setState(() {
            _successMessage = 'Account created. Welcome to CashMate!';
          });
        }
      } else {
        await authService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) {
          setState(() {
            _successMessage = 'Logged in. Finding your matches…';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppStrings.cleanError(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleAuth() async {
    if (_isSignUp && !_agreeTerms) {
      setState(() {
        _errorMessage = 'Please agree to the Terms and Privacy Policy first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppStrings.cleanError(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Top Logo Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const CashMateLogo(iconSize: 36, fontSize: 20),
                      IconButton(
                        tooltip: 'How CashMate Works',
                        icon: const Icon(
                          Icons.help_outline_rounded,
                          color: AppColors.mute,
                          size: 22,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const OnboardingScreen(isFromSettings: true),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // 2. Vector Hero Exchange Pair (Cash & Digital tiles)
                  const HeroExchangePair(),

                  // 3. Headline & Subtitle
                  Text(
                    _isSignUp ? 'Create your account' : 'Welcome back',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: -0.6,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUp
                        ? 'Swap cash and digital money with people near you.'
                        : 'Log in to find your cash exchange match.',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.mute,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 4. Segmented Tabs [Log in] | [Sign up]
                  _buildTabs(),
                  const SizedBox(height: 18),

                  // 5. White Form Card
                  _buildFormCard(),
                  const SizedBox(height: 18),

                  // 6. Bottom Trust Badge
                  _buildTrustBadge(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Segmented Tabs Widget ---
  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line, width: 1),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          // Log in Tab
          Expanded(
            child: GestureDetector(
              onTap: () => _switchTab(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: !_isSignUp ? AppColors.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Log in',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: !_isSignUp ? AppColors.card : AppColors.mute,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Sign up Tab
          Expanded(
            child: GestureDetector(
              onTap: () => _switchTab(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: _isSignUp ? AppColors.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Sign up',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _isSignUp ? AppColors.card : AppColors.mute,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- White Form Card Widget ---
  Widget _buildFormCard() {
    final showNameError = _isSignUp && _nameTouched && !_isNameValid;
    final showEmailError = _emailTouched && !_isEmailValid;
    final showPasswordError = _passwordTouched && !_isPasswordValid;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Full Name Field (Sign up only)
            if (_isSignUp) ...[
              _buildField(
                label: 'Full name',
                controller: _nameController,
                focusNode: _nameFocus,
                placeholder: 'As on your ID',
                prefixIcon: Icons.person_outline_rounded,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _emailFocus.requestFocus(),
                autofillHints: const [AutofillHints.name],
                hasError: showNameError,
                errorText:
                    showNameError ? 'Enter your full name (2+ characters).' : null,
                suffixWidget: _buildNameSuffix(),
              ),
              const SizedBox(height: 16),
            ],

            // Email Address Field
            _buildField(
              label: 'Email address',
              controller: _emailController,
              focusNode: _emailFocus,
              placeholder: 'you@example.com',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _passwordFocus.requestFocus(),
              autofillHints: const [AutofillHints.email, AutofillHints.username],
              hasError: showEmailError,
              errorText: showEmailError
                  ? 'Enter a valid email address (e.g. name@example.com).'
                  : null,
              suffixWidget: _buildEmailSuffix(),
            ),
            const SizedBox(height: 16),

            // Password Field
            _buildField(
              label: 'Password',
              controller: _passwordController,
              focusNode: _passwordFocus,
              placeholder:
                  _isSignUp ? 'Create a secure password' : 'Enter your password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              textInputAction:
                  _isSignUp ? TextInputAction.done : TextInputAction.go,
              onSubmitted: (_) {
                if (_canSubmit) {
                  _handleSubmit();
                } else {
                  setState(() {
                    _nameTouched = true;
                    _emailTouched = true;
                    _passwordTouched = true;
                  });
                }
              },
              autofillHints: _isSignUp
                  ? const [AutofillHints.newPassword]
                  : const [AutofillHints.password],
              hasError: showPasswordError,
              errorText: showPasswordError
                  ? (_isSignUp
                      ? 'Password must have 8+ characters, letters and numbers.'
                      : 'Please enter your password.')
                  : null,
              suffixWidget: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                splashRadius: 20,
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color:
                      _passwordFocus.hasFocus ? AppColors.jade : AppColors.mute,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),

            // Password Strength Meter & Rules (Sign up only)
            if (_isSignUp) ...[
              const SizedBox(height: 10),
              _buildStrengthMeter(),
              const SizedBox(height: 10),
              _buildStrengthRules(),
            ],
            const SizedBox(height: 16),

            // Login: Remember Me & Forgot Password Row
            if (!_isSignUp) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _rememberMe,
                              activeColor: AppColors.jade,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              side: const BorderSide(
                                  color: AppColors.line, width: 1.5),
                              onChanged: (v) =>
                                  setState(() => _rememberMe = v ?? true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Remember me',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.ink,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: AppColors.jade,
                    ),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.jade,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],

            // Sign up: Terms & Conditions Checkbox
            if (_isSignUp) ...[
              InkWell(
                onTap: () => setState(() => _agreeTerms = !_agreeTerms),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _agreeTerms,
                          activeColor: AppColors.jade,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: const BorderSide(
                              color: AppColors.line, width: 1.5),
                          onChanged: (v) =>
                              setState(() => _agreeTerms = v ?? false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 13.5,
                              color: AppColors.mute,
                              height: 1.35,
                            ),
                            children: [
                              TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms',
                                style: TextStyle(
                                  color: AppColors.jade,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: AppColors.jade,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Primary Action Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_canSubmit) {
                          _handleSubmit();
                        } else {
                          setState(() {
                            _nameTouched = true;
                            _emailTouched = true;
                            _passwordTouched = true;
                            if (_isSignUp && !_agreeTerms) {
                              _errorMessage =
                                  'Please agree to the Terms and Privacy Policy to continue.';
                            }
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canSubmit
                      ? AppColors.jade
                      : AppColors.jade.withValues(alpha: 0.72),
                  disabledBackgroundColor: AppColors.jade.withValues(alpha: 0.45),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _isSignUp ? 'Create account' : 'Log in',
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 18),

            // OR Divider
            Row(
              children: [
                Expanded(
                  child: Container(height: 1, color: AppColors.line),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'or',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.mute,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(height: 1, color: AppColors.line),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Google Button
            SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _handleGoogleAuth,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.line, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GoogleLogo(size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Continue with Google',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Feedback Messages
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.redBg,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.red.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 17, color: AppColors.red),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_successMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.okBg,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.jade.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 17, color: AppColors.jade),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.jade,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- Suffix Helpers for Interactive Feedback ---
  Widget? _buildNameSuffix() {
    if (_nameController.text.isNotEmpty && _nameFocus.hasFocus) {
      return IconButton(
        tooltip: 'Clear name',
        icon: const Icon(Icons.cancel_rounded, size: 18, color: AppColors.mute),
        splashRadius: 18,
        onPressed: () {
          _nameController.clear();
          setState(() {});
        },
      );
    }
    if (_isNameValid) {
      return const Padding(
        padding: EdgeInsets.only(right: 14),
        child: Icon(
          Icons.check_circle_rounded,
          size: 19,
          color: AppColors.jade,
        ),
      );
    }
    return null;
  }

  Widget? _buildEmailSuffix() {
    if (_emailController.text.isNotEmpty && _emailFocus.hasFocus) {
      return IconButton(
        tooltip: 'Clear email',
        icon: const Icon(Icons.cancel_rounded, size: 18, color: AppColors.mute),
        splashRadius: 18,
        onPressed: () {
          _emailController.clear();
          setState(() {});
        },
      );
    }
    if (_isEmailValid) {
      return const Padding(
        padding: EdgeInsets.only(right: 14),
        child: Icon(
          Icons.check_circle_rounded,
          size: 19,
          color: AppColors.jade,
        ),
      );
    }
    return null;
  }

  // --- Reusable Input Field Widget with Unified Border and High-Fidelity UX ---
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String placeholder,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixWidget,
    bool hasError = false,
    String? errorText,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
    Iterable<String>? autofillHints,
  }) {
    final isFocused = focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          autofillHints: autofillHints,
          cursorColor: AppColors.jade,
          cursorWidth: 2,
          cursorRadius: const Radius.circular(2),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              fontSize: 15,
              color: AppColors.mute.withValues(alpha: 0.6),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: hasError
                  ? AppColors.red
                  : (isFocused ? AppColors.jade : AppColors.mute),
              size: 20,
            ),
            suffixIcon: suffixWidget,
            filled: true,
            fillColor: isFocused
                ? Colors.white
                : (hasError
                    ? AppColors.redBg.withValues(alpha: 0.45)
                    : AppColors.field),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.line, width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasError ? AppColors.red : AppColors.line,
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasError ? AppColors.red : AppColors.jade,
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.red, width: 2.0),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: AppColors.red,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  errorText,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // --- Password Strength Meter Widget ---
  Widget _buildStrengthMeter() {
    final score = _strengthScore;
    final labels = ['Weak', 'Fair', 'Good', 'Strong'];
    final label = score > 0 ? labels[(score - 1).clamp(0, 3)] : 'Enter password';
    final color = score > 0
        ? AppColors.strengthColors[(score - 1).clamp(0, 3)]
        : AppColors.mute;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Password strength',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.mute,
              ),
            ),
            if (score > 0)
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(4, (index) {
            final isActive = index < score;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 4,
                margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                decoration: BoxDecoration(
                  color: isActive ? color : AppColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // --- Password Strength Rules Checklist ---
  Widget _buildStrengthRules() {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        _buildRuleItem('8+ characters', _hasMinLength),
        _buildRuleItem('Letters and numbers', _hasLettersAndNumbers),
      ],
    );
  }

  Widget _buildRuleItem(String text, bool isOk) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: isOk ? AppColors.okBg : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isOk ? AppColors.jade : AppColors.line,
              width: 1.2,
            ),
          ),
          child: Center(
            child: Icon(
              isOk ? Icons.check_rounded : Icons.circle,
              size: isOk ? 11 : 4,
              color: isOk ? AppColors.jade : AppColors.mute.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.5,
            color: isOk ? AppColors.jade : AppColors.mute,
            fontWeight: isOk ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // --- Bottom Trust Badge ---
  Widget _buildTrustBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.shield_outlined,
          size: 16,
          color: AppColors.mute,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Money moves directly between people. CashMate never holds your funds.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mute,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
