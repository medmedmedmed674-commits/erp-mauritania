import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../theme/app_theme.dart';
import '../utils/auth_state.dart';
import '../utils/validators.dart';
import '../widgets/responsive.dart';
import '../widgets/shared_widgets.dart';
import 'retail_dashboard.dart';
import 'wholesale_dashboard.dart';

/// Module 2 — Authentication & Routing.
///
/// Two-tab switcher (Login / Register). On desktop the form is paired
/// with an illustrated branding side-panel; on mobile the form is the
/// primary surface.
///
/// On submit, validation runs and the user is routed via
/// [Navigator.pushReplacement] to either [RetailDashboard] or
/// [WholesaleDashboard] based on the [role] passed in from the
/// welcome screen.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.role});

  final BusinessRole role;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this, initialIndex: 0);
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // ----- form keys -----
  final _loginKey = GlobalKey<FormState>();
  final _registerKey = GlobalKey<FormState>();

  // ----- controllers -----
  final _loginIdentifier = TextEditingController(text: '22334455');
  final _loginPassword = TextEditingController(text: 'demo1234');

  final _rBusiness = TextEditingController(text: 'بقالة السلام');
  final _rOwner = TextEditingController(text: 'أحمد محمد سيد');
  final _rPhone = TextEditingController(text: '22334455');
  final _rPassword = TextEditingController(text: 'demo1234');
  final _rConfirm = TextEditingController(text: 'demo1234');
  final _rEmail = TextEditingController();
  String? _rCity;

  @override
  void dispose() {
    _tab.dispose();
    _loginIdentifier.dispose();
    _loginPassword.dispose();
    _rBusiness.dispose();
    _rOwner.dispose();
    _rPhone.dispose();
    _rPassword.dispose();
    _rConfirm.dispose();
    _rEmail.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (!(_loginKey.currentState?.validate() ?? false)) return;
    context.read<AuthState>().login(
          identifier: _loginIdentifier.text.trim(),
          password: _loginPassword.text,
          role: widget.role,
        );
    _routeToDashboard();
  }

  void _submitRegister() {
    if (!(_registerKey.currentState?.validate() ?? false)) return;
    context.read<AuthState>().register(
          businessName: _rBusiness.text.trim(),
          ownerName: _rOwner.text.trim(),
          phone: _rPhone.text.trim(),
          city: _rCity ?? 'نواكشوط',
          role: widget.role,
          email: _rEmail.text.trim().isEmpty ? null : _rEmail.text.trim(),
        );
    _routeToDashboard();
  }

  void _routeToDashboard() {
    final target = widget.role == BusinessRole.retail
        ? const RetailDashboard()
        : const WholesaleDashboard();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => target),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Responsive(
          builder: (context, device, _) {
            if (device == DeviceType.desktop) {
              return Row(
                children: [
                  Expanded(flex: 5, child: _BrandingPanel(role: widget.role)),
                  Expanded(
                    flex: 6,
                    child: _AuthBody(
                      tab: _tab,
                      loginKey: _loginKey,
                      registerKey: _registerKey,
                      role: widget.role,
                      loginIdentifier: _loginIdentifier,
                      loginPassword: _loginPassword,
                      rBusiness: _rBusiness,
                      rOwner: _rOwner,
                      rPhone: _rPhone,
                      rPassword: _rPassword,
                      rConfirm: _rConfirm,
                      rEmail: _rEmail,
                      rCity: _rCity,
                      onCityChanged: (v) => setState(() => _rCity = v),
                      onLogin: _submitLogin,
                      onRegister: _submitRegister,
                      obscurePassword: _obscurePassword,
                      obscureConfirm: _obscureConfirm,
                      togglePassword: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                      toggleConfirm: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ],
              );
            }
            // Mobile + Tablet — focused form layout
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 24),
                child: _AuthBody(
                  tab: _tab,
                  loginKey: _loginKey,
                  registerKey: _registerKey,
                  role: widget.role,
                  loginIdentifier: _loginIdentifier,
                  loginPassword: _loginPassword,
                  rBusiness: _rBusiness,
                  rOwner: _rOwner,
                  rPhone: _rPhone,
                  rPassword: _rPassword,
                  rConfirm: _rConfirm,
                  rEmail: _rEmail,
                  rCity: _rCity,
                  onCityChanged: (v) => setState(() => _rCity = v),
                  onLogin: _submitLogin,
                  onRegister: _submitRegister,
                  obscurePassword: _obscurePassword,
                  obscureConfirm: _obscureConfirm,
                  togglePassword: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  toggleConfirm: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  compact: true,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Branding side panel (desktop only)
// ---------------------------------------------------------------------------
class _BrandingPanel extends StatelessWidget {
  const _BrandingPanel({required this.role});
  final BusinessRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primaryDark, AppTheme.primary],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.accent.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: const Icon(Icons.storefront,
                        color: AppTheme.accent, size: 26),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'نظام ERP Mauritania',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(role.icon, color: AppTheme.accent, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'النشاط: ${role.arabicLabel}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'سجّل دخولك أو أنشئ حساباً جديداً للمتابعة إلى لوحة التحكم',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ..._features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.check,
                              color: AppTheme.accent, size: 14),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                f.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                f.description,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
              const Spacer(),
              const Divider(color: Colors.white24),
              const SizedBox(height: 12),
              const Text(
                'نظام آمن ومشفّر بالكامل لحماية بياناتك المالية',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature {
  const _Feature(this.title, this.description);
  final String title;
  final String description;
}

const List<_Feature> _features = [
  _Feature(
    'حسابات بأمان كامل',
    'كلمات المرور مشفّرة ولا يتم تخزينها محلياً على الجهاز.',
  ),
  _Feature(
    'مزامنة فورية',
    'كل العمليات تظهر مباشرة على كل أجهزتك: الهاتف، اللوحي، الحاسوب.',
  ),
  _Feature(
    'دعم RTL كامل',
    'واجهة عربية أصيلة تتكيّف مع كل أحجام الشاشات.',
  ),
];

// ---------------------------------------------------------------------------
// Auth body — shared between mobile + desktop
// ---------------------------------------------------------------------------
class _AuthBody extends StatelessWidget {
  const _AuthBody({
    required this.tab,
    required this.loginKey,
    required this.registerKey,
    required this.role,
    required this.loginIdentifier,
    required this.loginPassword,
    required this.rBusiness,
    required this.rOwner,
    required this.rPhone,
    required this.rPassword,
    required this.rConfirm,
    required this.rEmail,
    required this.rCity,
    required this.onCityChanged,
    required this.onLogin,
    required this.onRegister,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.togglePassword,
    required this.toggleConfirm,
    this.compact = false,
  });

  final TabController tab;
  final GlobalKey<FormState> loginKey;
  final GlobalKey<FormState> registerKey;
  final BusinessRole role;
  final TextEditingController loginIdentifier;
  final TextEditingController loginPassword;
  final TextEditingController rBusiness;
  final TextEditingController rOwner;
  final TextEditingController rPhone;
  final TextEditingController rPassword;
  final TextEditingController rConfirm;
  final TextEditingController rEmail;
  final String? rCity;
  final ValueChanged<String?> onCityChanged;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final bool obscurePassword;
  final bool obscureConfirm;
  final VoidCallback togglePassword;
  final VoidCallback toggleConfirm;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 0 : 48,
          vertical: compact ? 0 : 40,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle(
                title: 'تسجيل الدخول',
                subtitle: 'أدخل بياناتك للوصول إلى لوحة التحكم',
                icon: Icons.lock_open_outlined,
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: tab,
                  indicator: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textSecondary,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                  tabs: const [
                    Tab(text: 'تسجيل الدخول'),
                    Tab(text: 'إنشاء حساب جديد'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: tab,
                builder: (context, _) {
                  return IndexedStack(
                    index: tab.index,
                    children: [
                      _LoginForm(
                        key: const ValueKey('login'),
                        formKey: loginKey,
                        identifier: loginIdentifier,
                        password: loginPassword,
                        obscurePassword: obscurePassword,
                        togglePassword: togglePassword,
                        onSubmit: onLogin,
                        rememberMe: auth.rememberMe,
                        onRememberMeChanged: auth.setRememberMe,
                      ),
                      _RegisterForm(
                        key: const ValueKey('register'),
                        formKey: registerKey,
                        business: rBusiness,
                        owner: rOwner,
                        phone: rPhone,
                        password: rPassword,
                        confirm: rConfirm,
                        email: rEmail,
                        city: rCity,
                        onCityChanged: onCityChanged,
                        obscurePassword: obscurePassword,
                        obscureConfirm: obscureConfirm,
                        togglePassword: togglePassword,
                        toggleConfirm: toggleConfirm,
                        onSubmit: onRegister,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                'بالمتابعة أنت توافق على سياسة الخصوصية وشروط الاستخدام',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Login form
// ---------------------------------------------------------------------------
class _LoginForm extends StatelessWidget {
  const _LoginForm({
    super.key,
    required this.formKey,
    required this.identifier,
    required this.password,
    required this.obscurePassword,
    required this.togglePassword,
    required this.onSubmit,
    required this.rememberMe,
    required this.onRememberMeChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController identifier;
  final TextEditingController password;
  final bool obscurePassword;
  final VoidCallback togglePassword;
  final VoidCallback onSubmit;
  final bool rememberMe;
  final ValueChanged<bool> onRememberMeChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: identifier,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(
              labelText: 'رقم الهاتف أو البريد الإلكتروني',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'يرجى إدخال الهاتف أو البريد';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: password,
            obscureText: obscurePassword,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              labelText: 'كلمة المرور',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: togglePassword,
              ),
            ),
            validator: AppValidators.password,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: rememberMe,
                onChanged: (v) => onRememberMeChanged(v ?? false),
                visualDensity: VisualDensity.compact,
              ),
              const Text('تذكّرني', style: TextStyle(fontSize: 13)),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('نسيت كلمة المرور؟'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PrimaryActionButton(
            label: 'دخول',
            icon: Icons.login,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Register form
// ---------------------------------------------------------------------------
class _RegisterForm extends StatelessWidget {
  const _RegisterForm({
    super.key,
    required this.formKey,
    required this.business,
    required this.owner,
    required this.phone,
    required this.password,
    required this.confirm,
    required this.email,
    required this.city,
    required this.onCityChanged,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.togglePassword,
    required this.toggleConfirm,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController business;
  final TextEditingController owner;
  final TextEditingController phone;
  final TextEditingController password;
  final TextEditingController confirm;
  final TextEditingController email;
  final String? city;
  final ValueChanged<String?> onCityChanged;
  final bool obscurePassword;
  final bool obscureConfirm;
  final VoidCallback togglePassword;
  final VoidCallback toggleConfirm;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: business,
            decoration: const InputDecoration(
              labelText: 'اسم المؤسسة / المتجر',
              prefixIcon: Icon(Icons.storefront_outlined, size: 20),
            ),
            validator: (v) =>
                AppValidators.requiredField('اسم المؤسسة', v),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: owner,
            decoration: const InputDecoration(
              labelText: 'اسم المالك',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
            validator: (v) => AppValidators.requiredField('اسم المالك', v),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: phone,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(
              labelText: 'رقم الهاتف الموريتاني (8 أرقام)',
              hintText: '2XXX XXXX أو 3XXX XXXX أو 4XXX XXXX',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
            ),
            validator: AppValidators.phone,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: city,
            decoration: const InputDecoration(
              labelText: 'المدينة / المنطقة',
              prefixIcon: Icon(Icons.location_on_outlined, size: 20),
            ),
            items: _mauritanianCities
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: onCityChanged,
            validator: (v) =>
                v == null ? 'يرجى اختيار المدينة' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(
              labelText: 'البريد الإلكتروني (اختياري)',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
            validator: AppValidators.email,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: password,
            obscureText: obscurePassword,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              labelText: 'كلمة المرور',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: togglePassword,
              ),
            ),
            validator: AppValidators.password,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: confirm,
            obscureText: obscureConfirm,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              labelText: 'تأكيد كلمة المرور',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: toggleConfirm,
              ),
            ),
            validator: (v) => AppValidators.matchPassword(v, password.text),
          ),
          const SizedBox(height: 18),
          PrimaryActionButton(
            label: 'إنشاء الحساب',
            icon: Icons.person_add_alt_outlined,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

const List<String> _mauritanianCities = [
  'نواكشوط',
  'نواذيبو',
  'روصو',
  'كيفه',
  'نواكشوط الشمالية',
  'أطار',
  'زويرات',
  'ألاق',
  'بوتلميت',
  'اكجوجت',
];
