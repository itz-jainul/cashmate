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
      if (!_nameFocus.hasFocus) setState(() => _nameTouched = true);
    });
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus) setState(() => _emailTouched = true);
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
    });
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _nameTouched = true;
      _emailTouched = true;
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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.line, width: 1),
      ),
      padding: const EdgeInsets.all(20),
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
              hasError: showNameError,
              errorText: showNameError ? 'Enter your full name.' : null,
            ),
            const SizedBox(height: 14),
          ],

          // Email Address Field
          _buildField(
            label: 'Email address',
            controller: _emailController,
            focusNode: _emailFocus,
            placeholder: 'you@example.com',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            hasError: showEmailError,
            errorText: showEmailError
                ? 'Enter a valid email, like name@example.com.'
                : null,
          ),
          const SizedBox(height: 14),

          // Password Field
          _buildField(
            label: 'Password',
            controller: _passwordController,
            focusNode: _passwordFocus,
            placeholder:
                _isSignUp ? 'Create a password' : 'Enter your password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffixWidget: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.mute,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),

          // Password Strength Meter & Rules (Sign up only)
          if (_isSignUp) ...[
            const SizedBox(height: 8),
            _buildStrengthMeter(),
            const SizedBox(height: 8),
            _buildStrengthRules(),
          ],
          const SizedBox(height: 14),

          // Login: Remember Me & Forgot Password Row
          if (!_isSignUp) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  child: Row(
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
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
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
            const SizedBox(height: 16),
          ],

          // Sign up: Terms & Conditions Checkbox
          if (_isSignUp) ...[
            Row(
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
                    onChanged: (v) =>
                        setState(() => _agreeTerms = v ?? false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 14,
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
            const SizedBox(height: 16),
          ],

          // Primary Action Button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _canSubmit ? _handleSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.jade,
                disabledBackgroundColor: AppColors.jade.withValues(alpha: 0.45),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // OR Divider
          Row(
            children: [
              Expanded(
                child: Container(height: 1, color: AppColors.line),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
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
          const SizedBox(height: 16),

          // Google Button
          SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: _isLoading ? null : _handleGoogleAuth,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: AppColors.line, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GoogleLogo(size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 16,
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
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.red,
              ),
            ),
          ],
          if (_successMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _successMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.jade,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Reusable Input Field Widget ---
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
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.field,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError
                  ? AppColors.red
                  : (isFocused ? AppColors.jade : AppColors.line),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(
                prefixIcon,
                color: hasError ? AppColors.red : AppColors.mute,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                  decoration: InputDecoration(
                    hintText: placeholder,
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: AppColors.mute.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              ?suffixWidget,
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 5),
          Text(
            errorText,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.red,
            ),
          ),
        ],
      ],
    );
  }

  // --- Password Strength Meter Widget ---
  Widget _buildStrengthMeter() {
    final score = _strengthScore;
    final color = score > 0
        ? AppColors.strengthColors[(score - 1).clamp(0, 3)]
        : AppColors.line;

    return Row(
      children: List.generate(4, (index) {
        final isActive = index < score;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
            decoration: BoxDecoration(
              color: isActive ? color : AppColors.line,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }

  // --- Password Strength Rules Checklist ---
  Widget _buildStrengthRules() {
    return Wrap(
      spacing: 14,
      runSpacing: 4,
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
        Text(
          isOk ? '✓ ' : '○ ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: isOk ? FontWeight.w700 : FontWeight.w500,
            color: isOk ? AppColors.jade : AppColors.mute,
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
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
