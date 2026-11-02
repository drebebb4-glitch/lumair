import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/auth_provider.dart';
import '../widgets/glass.dart';

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
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _controller = AuthController();
  bool _busy = false;
  bool _success = false;
  String? _message;

  @override
  void dispose() {
    _tabs.dispose();
    _email.dispose();
    _pass.dispose();
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
        : await _controller.signUp(_email.text.trim(), _pass.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _success = outcome.success && isLogin;
      _message = outcome.message;
    });
    if (outcome.success && isLogin && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      Navigator.of(context).pop(true); // login sukses → tutup layar
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authUserProvider);
    if (auth != null) return _AccountCardScreen(auth: auth);
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
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
                            color:
                                const Color(0xFF34D399).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          dividerColor: Colors.transparent,
                          labelColor: const Color(0xFF34D399),
                          unselectedLabelColor: const Color(0xFF64748B),
                          titleTextStyle: const TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w800),
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
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'nama@email.com',
                                prefixIcon: Icon(Icons.mail_outline, size: 20),
                              ),
                              validator: (v) {
                                final value = v?.trim() ?? '';
                                if (value.isEmpty) return 'Email jangan kosong';
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
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                hintText: 'minimal 6 karakter',
                                prefixIcon: Icon(Icons.lock_outline, size: 20),
                              ),
                              validator: (v) => (v ?? '').length < 6
                                  ? 'Minimal 6 karakter'
                                  : null,
                            ),
                            const SizedBox(height: 18),
                            AnimatedBuilder(
                              animation: _tabs,
                              builder: (context, _) {
                                final isLogin = _tabs.index == 0;
                                return FilledButton(
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
                                );
                              },
                            ),
                            if (_success) ...[
                              const SizedBox(height: 12),
                              Center(
                                child: GlassChip(
                                  icon: Icons.check_circle_outline,
                                  label: 'Berhasil masuk — kembali ke halaman',
                                  color: const Color(0xFF34D399),
                                ),
                              ),
                            ],
                            if (_message != null && !_success) ...[
                              const SizedBox(height: 12),
                              Text(
                                _message!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontSize: 13,
                                    height: 1.4),
                              ),
                            ],
                          ],
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
                      color: Color(0xFF64748B), fontSize: 12.5, height: 1.5),
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
      backgroundColor: const Color(0xFF070B14),
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
                    gradient:
                        LinearGradient(colors: [Color(0xFF34D399), Color(0xFF0EA5E9)]),
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
                        color: Color(0xFFE2E8F0),
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
                    await AuthController().signOut();
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.logout, color: Color(0xFFEF4444), size: 18),
                  label: const Text('Keluar akun',
                      style: TextStyle(color: Color(0xFFEF4444))),
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
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.settings_input_component_outlined,
                    color: Color(0xFFFBBF24), size: 44),
                const SizedBox(height: 12),
                const Text('Backend belum terhubung',
                    style: TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
                const SizedBox(height: 8),
                const Text(
                  'Fitur akun & laporan butuh kredensial Supabase. '
                  'Jalankan app dengan --dart-define=SUPABASE_URL=... dan '
                  '--dart-define=SUPABASE_ANON_KEY=... (panduan di README).',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Color(0xFF94A3B8), fontSize: 12.5, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
