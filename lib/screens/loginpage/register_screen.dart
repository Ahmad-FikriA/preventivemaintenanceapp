import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _phone = TextEditingController();
  final _department = TextEditingController();
  final _auth = AuthService();

  bool _obscure = true;
  bool _loading = false;
  String _role = 'technician'; // default

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _phone.dispose();
    _department.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
  await _auth.register(
        email: _email.text.trim(),
        password: _password.text,
        name: _name.text.trim(),
        role: _role,
        phone: _phone.text.trim(),
        department: _department.text.trim(),
      );
  if (!mounted) return;
  // User is automatically signed in after createUserWithEmailAndPassword
  // Let RoleGate decide their landing page
  context.go('/');
    } on AuthException catch (e) {
      _showSnack(e.message, const Color(0xFFB91C1C)); // red-700
    } catch (e) {
      _showSnack('Gagal mendaftar: $e', const Color(0xFFB91C1C));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: bg,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Clean gradient, no .withOpacity()
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: _card(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const _Header(),
              const SizedBox(height: 24),
              _textField(controller: _name, label: 'Nama Lengkap', icon: Icons.badge_outlined, validator: _req),
              const SizedBox(height: 14),
              _textField(
                controller: _email,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: _emailVal,
              ),
              const SizedBox(height: 14),
              _passwordField(),
              const SizedBox(height: 14),
              _textField(
                controller: _confirm,
                label: 'Konfirmasi Password',
                icon: Icons.verified_outlined,
                obscure: true,
                validator: (v) => v != _password.text ? 'Konfirmasi tidak cocok' : null,
              ),
              const SizedBox(height: 14),
              _textField(controller: _phone, label: 'No. Telepon (opsional)', icon: Icons.phone_outlined),
              const SizedBox(height: 14),
              _textField(controller: _department, label: 'Departemen (opsional)', icon: Icons.apartment_outlined),
              const SizedBox(height: 14),
              _roleDropdown(),
              const SizedBox(height: 24),
              _submitBtn(),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loading ? null : () => context.go('/login'),
                child: const Text('Sudah punya akun? Masuk'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        color: const Color(0xFFFFFFFF),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF1D4ED8)),
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF6B7280)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _passwordField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        color: const Color(0xFFFFFFFF),
      ),
      child: TextFormField(
        controller: _password,
        obscureText: _obscure,
        validator: (v) => (v ?? '').length < 6 ? 'Minimal 6 karakter' : null,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1D4ED8)),
          labelText: 'Password',
          labelStyle: const TextStyle(color: Color(0xFF6B7280)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: IconButton(
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF6B7280)),
          ),
        ),
      ),
    );
  }

  Widget _roleDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        color: const Color(0xFFFFFFFF),
      ),
      child: DropdownButtonFormField<String>(
        value: _role,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.engineering_outlined, color: Color(0xFF1D4ED8)),
          labelText: 'Peran',
          labelStyle: TextStyle(color: Color(0xFF6B7280)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: const [
          DropdownMenuItem(value: 'technician', child: Text('Teknisi')),
          DropdownMenuItem(value: 'admin', child: Text('Admin')),
        ],
        onChanged: (v) => setState(() => _role = v ?? 'technician'),
      ),
    );
  }

  Widget _submitBtn() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB), // blue-600
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: _loading
            ? const SizedBox(
                width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.person_add_alt_1_outlined),
        label: Text(_loading ? 'Mendaftarkan...' : 'Daftar'),
      ),
    );
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;
  String? _emailVal(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Wajib diisi';
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(s);
    return ok ? null : 'Email tidak valid';
    }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Icon(Icons.precision_manufacturing_outlined, size: 56, color: Color(0xFF1D4ED8)),
        SizedBox(height: 12),
        Text('Buat Akun Maintenance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        SizedBox(height: 4),
        Text('Akses formulir checklist & manajemen equipment', style: TextStyle(color: Color(0xFF6B7280))),
      ],
    );
  }
}
