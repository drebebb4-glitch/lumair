import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/auth_provider.dart';
import '../widgets/glass.dart';
import '../../core/app_theme.dart';

/// Layar Masuk/Daftar LUMAIR — satu layar dua tab (email + password),
/// lewat Supabase Auth. Kalau backend belum terhubung (--dart-define
/// kosong), tampil kartu penjelasan alih-alih form yang tak bisa jalan.
class AuthScreen extends ConsumerStatefulWidget {
  /// false = dibuka dari menu Beranda (bisa ditutup bebas).
  /// true  = gate fitur laporan — hanya tombol sistem yang menutup.
  final bool restrictive;
  const AuthScreen({super.key, this.restrictive = false});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirmPass = TextEditingController();
  final _controller = AuthController();
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  bool _busy = false;
  bool _success = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) {
        setState(() {
          _message = null;
          _success = false;
        });
        _formKey.currentState?.reset();
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirmPass.dispose();
    super.dispose();
  }

  Future<void> _submit(bool isLogin) async {
    final form = _formKey.currentState;
    if (!form!.validate()) return;
    setState(() {
      _busy = true;
      _success = false;
      _message = null;
    });
    final outcome = isLogin
        ? await _controller.signIn(_email.text.trim(), _pass.text)
        : await _controller.signUp(
            _email.text.trim(),
            _pass.text,
            fullName: _name.text.trim(),
          );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _success = outcome.success;
      _message = outcome.message;
    });
    if (outcome.success && mounted) {
      final hasSession = ref.read(authUserProvider) != null;
      if (isLogin || hasSession) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.of(context).pop(true); // login/masuk sukses → tutup layar
      }
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final resetEmail = TextEditingController(text: _email.text.trim());
    bool sending = false;
    String? resetMsg;
    bool resetOk = false;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.nightSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
              title: const Row(
                children: [
                  Icon(Icons.lock_reset, color: AppTheme.sky, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Pemulihan Password',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Masukkan email akun kamu. Kami akan mengirim tautan untuk mengatur ulang kata sandi.',
                    style: TextStyle(
                        color: AppTheme.textMuted, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: resetEmail,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Email Akun',
                      hintText: 'nama@email.com',
                      prefixIcon: Icon(Icons.mail_outline, size: 20),
                    ),
                  ),
                  if (resetMsg != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      resetMsg!,
                      style: TextStyle(
                        color: resetOk ? AppTheme.accent : AppTheme.danger,
                        fontSize: 12.5,
                        fontWeight:
                            resetOk ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      sending ? null : () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Tutup',
                      style: TextStyle(color: AppTheme.textMuted)),
                ),
                FilledButton(
                  onPressed: sending
                      ? null
                      : () async {
                          // Golden Rule 5: cegah kirim ke email yang
                          // jelas-jelas tidak valid sebelum panggil API.
                          final email = resetEmail.text.trim();
                          if (email.isEmpty ||
                              !email.contains('@') ||
                              !email.contains('.')) {
                            setDialogState(() {
                              resetMsg = 'Format email belum benar';
                              resetOk = false;
                            });
                            return;
                          }
                          setDialogState(() {
                            sending = true;
                            resetMsg = null;
                          });
                          final res =
                              await _controller.resetPassword(resetEmail.text);
                          setDialogState(() {
                            sending = false;
                            resetOk = res.success;
                            resetMsg = res.message;
                          });
                        },
                  child: sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Kirim Tautan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authUserProvider);
    if (auth != null) return _AccountCardScreen(auth: auth);
    return Scaffold(
      backgroundColor: AppTheme.night,
      appBar: AppBar(
        title: const Text('Masuk LUMAIR'),
        automaticallyImplyLeading: !widget.restrictive,
      ),
      body: !_controller.available
          ? const _NotConfiguredCard()
          : ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
              children: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TabBar(
                          controller: _tabs,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          dividerColor: Colors.transparent,
                          labelColor: AppTheme.accent,
                          unselectedLabelColor: AppTheme.textFaint,
                          labelStyle: const TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w800),
                          tabs: const [
                            Tab(height: 38, text: 'Masuk'),
                            Tab(height: 38, text: 'Daftar'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Form(
                        key: _formKey,
                        child: AnimatedBuilder(
                          animation: _tabs,
                          builder: (context, _) {
                            final isLogin = _tabs.index == 0;
                            return Column(
                              children: [
                                if (!isLogin) ...[
                                  TextFormField(
                                    controller: _name,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: const InputDecoration(
                                      labelText: 'Nama Lengkap',
                                      hintText: 'nama kamu',
                                      prefixIcon:
                                          Icon(Icons.person_outline, size: 20),
                                    ),
                                    validator: (v) {
                                      if ((v ?? '').trim().isEmpty) {
                                        return 'Nama jangan kosong';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                TextFormField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  autocorrect: false,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'nama@email.com',
                                    prefixIcon:
                                        Icon(Icons.mail_outline, size: 20),
                                  ),
                                  validator: (v) {
                                    final value = v?.trim() ?? '';
                                    if (value.isEmpty) {
                                      return 'Email jangan kosong';
                                    }
                                    if (!value.contains('@') ||
                                        !value.contains('.')) {
                                      return 'Format email belum benar';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _pass,
                                  obscureText: _obscurePass,
                                  textInputAction: isLogin
                                      ? TextInputAction.done
                                      : TextInputAction.next,
                                  onFieldSubmitted: (_) {
                                    if (isLogin) _submit(true);
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: 'minimal 6 karakter',
                                    prefixIcon: const Icon(Icons.lock_outline,
                                        size: 20),
                                    suffixIcon: IconButton(
                                      tooltip: _obscurePass
                                          ? 'Tampilkan password'
                                          : 'Sembunyikan password',
                                      icon: Icon(
                                        _obscurePass
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        size: 20,
                                        color: AppTheme.textMuted,
                                      ),
                                      onPressed: () => setState(
                                          () => _obscurePass = !_obscurePass),
                                    ),
                                  ),
                                  validator: (v) => (v ?? '').length < 6
                                      ? 'Minimal 6 karakter'
                                      : null,
                                ),
                                if (isLogin) ...[
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 2),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: _busy
                                          ? null
                                          : () => _showForgotPasswordDialog(
                                              context),
                                      child: const Text(
                                        'Lupa password?',
                                        style: TextStyle(
                                          color: AppTheme.sky,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                if (!isLogin) ...[
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _confirmPass,
                                    obscureText: _obscureConfirmPass,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _submit(false),
                                    decoration: InputDecoration(
                                      labelText: 'Konfirmasi Password',
                                      hintText: 'ulangi password',
                                      prefixIcon: const Icon(
                                          Icons.lock_clock_outlined,
                                          size: 20),
                                      suffixIcon: IconButton(
                                        tooltip: _obscureConfirmPass
                                            ? 'Tampilkan password'
                                            : 'Sembunyikan password',
                                        icon: Icon(
                                          _obscureConfirmPass
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          size: 20,
                                          color: AppTheme.textMuted,
                                        ),
                                        onPressed: () => setState(() =>
                                            _obscureConfirmPass =
                                                !_obscureConfirmPass),
                                      ),
                                    ),
                                    validator: (v) {
                                      if ((v ?? '').isEmpty) {
                                        return 'Konfirmasi password jangan kosong';
                                      }
                                      if (v != _pass.text) {
                                        return 'Konfirmasi password harus sama';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                                const SizedBox(height: 18),
                                FilledButton(
                                  onPressed:
                                      _busy ? null : () => _submit(isLogin),
                                  child: _busy
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : Text(isLogin
                                          ? 'Masuk ke LUMAIR'
                                          : 'Buat akun baru'),
                                ),
                                if (_message != null) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: (_success
                                              ? AppTheme.accent
                                              : AppTheme.danger)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: (_success
                                                ? AppTheme.accent
                                                : AppTheme.danger)
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _success
                                              ? Icons.check_circle_outline
                                              : Icons.error_outline,
                                          size: 18,
                                          color: _success
                                              ? AppTheme.accent
                                              : AppTheme.danger,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _message!,
                                            style: TextStyle(
                                              color: _success
                                                  ? AppTheme.accent
                                                  : AppTheme.danger,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Kenapa perlu akun? Biar laporan banjir & tutup jalan '
                  'punya pemilik yang jelas — laporan semua orang tetap '
                  'bisa dibaca semua pengguna.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppTheme.textFaint, fontSize: 12.5, height: 1.5),
                ),
              ],
            ),
    );
  }
}

/// Papan akun — tampil kalau ternyata user sudah log-in.
class _AccountCardScreen extends ConsumerWidget {
  final AuthUser auth;
  const _AccountCardScreen({required this.auth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.night,
      appBar: AppBar(title: const Text('Akun LUMAIR')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GlassCard(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [AppTheme.accent, AppTheme.skyDeep]),
                  ),
                  child: Text(
                    auth.displayName.isEmpty
                        ? '?'
                        : auth.displayName[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 14),
                Text(auth.displayName,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(auth.email,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13)),
                const SizedBox(height: 18),
                TextButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.nightSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        title: const Text('Keluar dari Akun?',
                            style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700)),
                        content: const Text(
                          'Kamu perlu masuk kembali untuk mengirim laporan banjir atau penutupan jalan.',
                          style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                              height: 1.4),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Batal',
                                style: TextStyle(color: AppTheme.textMuted)),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.danger,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Keluar'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await AuthController().signOut();
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.logout,
                      color: AppTheme.danger, size: 18),
                  label: const Text('Keluar akun',
                      style: TextStyle(color: AppTheme.danger)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu info kalau app dijalankan tanpa kredensial Supabase.
class _NotConfiguredCard extends StatelessWidget {
  const _NotConfiguredCard();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings_input_component_outlined,
                    color: AppTheme.warning, size: 44),
                SizedBox(height: 12),
                Text('Backend belum terhubung',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
                SizedBox(height: 8),
                Text(
                  'Fitur akun & laporan butuh kredensial Supabase. '
                  'Jalankan app dengan --dart-define=SUPABASE_URL=... dan '
                  '--dart-define=SUPABASE_ANON_KEY=... (panduan di README).',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppTheme.textMuted, fontSize: 12.5, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
