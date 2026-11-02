import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../l10n/i18n.dart';
import '../services/account_service.dart';
import '../services/phone.dart';
import '../services/store_settings.dart';
import '../state/auth_state.dart';
import '../widgets/common.dart';

/// Sign in / create account. Phone OTP is primary; email + password is shown
/// only while the admin keeps it enabled (`/store/auth-settings`).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthSettings? _settings;
  Object? _error;
  bool _usePassword = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final s = await StoreSettings.authSettings();
      if (mounted) {
        setState(() {
          _settings = s;
          _usePassword = !s.otpEnabled && s.passwordEnabled;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _done() {
    haptic(Haptic.medium);
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final s = _settings;
    return Scaffold(
      appBar: AppBar(title: Text(i18n.t('signIn'))),
      body: _error != null
          ? ErrorView(onRetry: _load)
          : s == null
              ? const LoadingView()
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Center(child: Image.asset('assets/images/logo_sq.png', width: 84, height: 84)),
                    const SizedBox(height: 12),
                    Text(i18n.t('authWelcome'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(i18n.t('authWelcomeSubtitle'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 24),
                    if (s.otpEnabled && s.passwordEnabled)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SegmentedButton<bool>(
                          segments: [
                            ButtonSegment(value: false, label: Text(i18n.t('phoneOtp')), icon: const Icon(Icons.sms_outlined)),
                            ButtonSegment(value: true, label: Text(i18n.t('emailPassword')), icon: const Icon(Icons.mail_outline)),
                          ],
                          selected: {_usePassword},
                          onSelectionChanged: (v) => setState(() => _usePassword = v.first),
                        ),
                      ),
                    if (_usePassword) _PasswordForm(onDone: _done) else _OtpForm(otpLength: s.otpLength, onDone: _done),
                  ],
                ),
    );
  }
}

/// Port of rukn-site/src/lib/authErrors.ts.
String authErrorMessage(Object error, I18n i18n) {
  if (error is! MedusaError) return i18n.t('authFailed');
  if (error.status == 429) return i18n.t('tryAgainIn', {'s': error.retryAfter ?? 60});
  if (i18n.isAr && error.message != null) return error.message!;
  const byCode = {
    'NO_ACCOUNT': 'authNoAccount',
    'PHONE_REGISTERED': 'authPhoneRegistered',
    'EMAIL_TAKEN': 'authEmailTaken',
    'PHONE_TAKEN': 'authPhoneTaken',
    'PHONE_REJECTED': 'authPhoneRejected',
    'INVALID_EMAIL': 'emailInvalid',
    'INVALID_NAME': 'authInvalidName',
    'INVALID_VERIFICATION': 'otpInvalid',
    'OTP_AUTH_DISABLED': 'authOtpUnavailable',
  };
  final key = byCode[error.code];
  if (key != null) return i18n.t(key);
  if (error.status == 502 || error.status == 503) return i18n.t('otpSendFailed');
  return i18n.t('authFailed');
}

class _OtpForm extends StatefulWidget {
  const _OtpForm({required this.otpLength, required this.onDone});
  final int otpLength;
  final VoidCallback onDone;

  @override
  State<_OtpForm> createState() => _OtpFormState();
}

class _OtpFormState extends State<_OtpForm> {
  bool _register = false;
  String _dial = '966';
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  String? _e164;
  String? _verificationToken;
  bool _codeSent = false;
  bool _needsProfile = false;
  bool _busy = false;
  String? _error;
  int _resendIn = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in [_phone, _code, _first, _last, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    setState(() => _resendIn = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendIn = (_resendIn - 1).clamp(0, 9999));
      if (_resendIn == 0) t.cancel();
    });
  }

  bool get _profileValid =>
      _first.text.trim().isNotEmpty &&
      _last.text.trim().isNotEmpty &&
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim());

  Future<void> _send() async {
    final i18n = context.i18nRead;
    final e164 = normalizeOtpPhone(_phone.text, _dial);
    if (e164 == null) {
      setState(() => _error = i18n.t('phoneInvalid'));
      return;
    }
    if (_register && !_profileValid) {
      setState(() => _error = i18n.t('registerFieldsRequired'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final sent = await AccountService.sendOtp(
        e164,
        name: _register ? '${_first.text.trim()} ${_last.text.trim()}' : null,
        purpose: _register ? 'register' : 'login',
      );
      if (!mounted) return;
      setState(() {
        _e164 = e164;
        _codeSent = true;
        _code.clear();
      });
      _startCountdown(sent.resendAfter);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = authErrorMessage(e, i18n));
      if (e is MedusaError && e.code == 'NO_ACCOUNT') setState(() => _register = true);
      if (e is MedusaError && e.code == 'PHONE_REGISTERED') setState(() => _register = false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    final i18n = context.i18nRead;
    final code = toWesternDigits(_code.text.trim());
    if (code.length != widget.otpLength) {
      setState(() => _error = i18n.t('otpLength', {'n': widget.otpLength}));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final token = _verificationToken ?? await AccountService.verifyOtp(_e164!, code);
      _verificationToken = token;
      if (_register || _needsProfile) {
        await _completeRegistration(token);
        return;
      }
      try {
        final customer = await AccountService.otpLogin(token);
        if (!mounted) return;
        context.read<AuthState>().setCustomer(customer);
        widget.onDone();
      } on MedusaError catch (e) {
        // A verified number with no account: the same token is good for registering.
        if (e.status == 404 || e.code == 'NO_ACCOUNT') {
          setState(() {
            _needsProfile = true;
            _error = null;
          });
        } else {
          rethrow;
        }
      }
    } catch (e) {
      _verificationToken = null;
      if (mounted) setState(() => _error = authErrorMessage(e, i18n));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeRegistration(String token) async {
    final i18n = context.i18nRead;
    if (!_profileValid) {
      setState(() {
        _needsProfile = true;
        _error = i18n.t('registerFieldsRequired');
      });
      return;
    }
    final customer = await AccountService.otpRegister(
      verificationToken: token,
      firstName: _first.text.trim(),
      lastName: _last.text.trim(),
      email: _email.text.trim(),
    );
    if (!mounted) return;
    context.read<AuthState>().setCustomer(customer);
    widget.onDone();
  }

  Widget _profileFields(I18n i18n) => Column(
        children: [
          Row(children: [
            Expanded(child: TextField(controller: _first, decoration: InputDecoration(hintText: i18n.t('firstName')))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _last, decoration: InputDecoration(hintText: i18n.t('lastName')))),
          ]),
          const SizedBox(height: 10),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(hintText: i18n.t('email'))),
          const SizedBox(height: 10),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;

    if (_codeSent) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(i18n.t('otpSentTo', {'phone': nationalPhoneOf(_e164)}), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: widget.otpLength,
            style: const TextStyle(fontSize: 26, letterSpacing: 12, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(counterText: '', hintText: '• • • •'),
            onChanged: (v) {
              if (toWesternDigits(v).length == widget.otpLength && !_needsProfile) _verify();
            },
          ),
          if (_needsProfile) ...[
            const SizedBox(height: 16),
            Text(i18n.t('completeProfile'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _profileFields(i18n),
          ],
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: AppColors.error))),
          const SizedBox(height: 16),
          GoldButton(label: _needsProfile ? i18n.t('createAccount') : i18n.t('verify'), loading: _busy, onPressed: _verify),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _codeSent = false;
                          _needsProfile = false;
                          _verificationToken = null;
                          _error = null;
                        }),
                child: Text(i18n.t('changeNumber')),
              ),
              TextButton(
                onPressed: _resendIn > 0 || _busy ? null : _send,
                child: Text(_resendIn > 0 ? i18n.t('resendIn', {'s': _resendIn}) : i18n.t('resendCode')),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(i18n.t('signIn'))),
            ButtonSegment(value: true, label: Text(i18n.t('createAccount'))),
          ],
          selected: {_register},
          onSelectionChanged: (v) => setState(() {
            _register = v.first;
            _error = null;
          }),
        ),
        const SizedBox(height: 16),
        if (_register) _profileFields(i18n),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _dial,
                  items: [
                    for (final c in otpCountries)
                      DropdownMenuItem(value: c.dialCode, child: Text('${c.flag} +${c.dialCode}', textDirection: TextDirection.ltr)),
                  ],
                  onChanged: (v) => setState(() => _dial = v ?? '966'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(hintText: i18n.t('mobilePlaceholder')),
                onSubmitted: (_) => _send(),
              ),
            ),
          ],
        ),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: AppColors.error))),
        const SizedBox(height: 16),
        GoldButton(label: i18n.t('sendCode'), loading: _busy, onPressed: _send),
        const SizedBox(height: 10),
        Text(i18n.t('otpPrivacyNote'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(i18n.t('legalAgreeNote'), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            TextButton(
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              onPressed: () => context.push('/privacy'),
              child: Text(i18n.t('privacyPolicy'), style: const TextStyle(fontSize: 12)),
            ),
            Text(i18n.t('legalAnd'), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            TextButton(
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              onPressed: () => context.push('/terms'),
              child: Text(i18n.t('termsOfUse'), style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }
}

class _PasswordForm extends StatefulWidget {
  const _PasswordForm({required this.onDone});
  final VoidCallback onDone;

  @override
  State<_PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<_PasswordForm> {
  bool _register = false;
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_first, _last, _phone, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final i18n = context.i18nRead;
    if (_email.text.trim().isEmpty || _password.text.length < 8 || (_register && (_first.text.trim().isEmpty || _last.text.trim().isEmpty))) {
      setState(() => _error = i18n.t('passwordFormInvalid'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final customer = _register
          ? await AccountService.register(
              email: _email.text.trim(),
              password: _password.text,
              firstName: _first.text.trim(),
              lastName: _last.text.trim(),
              phone: _phone.text.trim(),
            )
          : await AccountService.login(_email.text.trim(), _password.text);
      if (!mounted) return;
      context.read<AuthState>().setCustomer(customer);
      widget.onDone();
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e, i18n));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_register) ...[
          TextField(controller: _first, decoration: InputDecoration(hintText: i18n.t('firstName'))),
          const SizedBox(height: 10),
          TextField(controller: _last, decoration: InputDecoration(hintText: i18n.t('lastName'))),
          const SizedBox(height: 10),
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(hintText: i18n.t('phoneNumber'))),
          const SizedBox(height: 10),
        ],
        TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(hintText: i18n.t('email'))),
        const SizedBox(height: 10),
        TextField(controller: _password, obscureText: true, decoration: InputDecoration(hintText: i18n.t('password'))),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: AppColors.error))),
        const SizedBox(height: 16),
        GoldButton(label: _register ? i18n.t('createAccount') : i18n.t('signIn'), loading: _busy, onPressed: _submit),
        TextButton(
          onPressed: () => setState(() {
            _register = !_register;
            _error = null;
          }),
          child: Text(_register ? i18n.t('haveAccount') : i18n.t('needAccount')),
        ),
      ],
    );
  }
}
