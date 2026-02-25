import 'package:app_envio/services/auth_service.dart';
import 'package:app_envio/view/components/custom_button.dart';
import 'package:app_envio/view/components/custom_scaffold.dart';
import 'package:app_envio/view/components/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class EditUserPage extends StatefulWidget {
  const EditUserPage({super.key});

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _authService = AuthService();

  String _email = '';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _authService.currentUser;

      if (user == null) {
        throw 'Usuário não autenticado.';
      }

      _email = user.email?.trim() ?? '';
      _nameController.text = user.displayName ?? '';

      final userData = await _authService.getUserData(user.uid);
      if (userData != null) {
        final firestoreEmail = (userData['email'] as String?)?.trim() ?? '';
        _nameController.text =
            (userData['fullName'] as String?) ?? _nameController.text;
        final rawPhone = (userData['phoneNumber'] as String?) ?? '';
        _phoneController.text = _phoneMask.maskText(rawPhone);

        if (firestoreEmail.isNotEmpty) {
          _email = firestoreEmail;
        }
      }

      _emailController.text = _email;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _authService.updateCurrentUserProfile(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneMask.getUnmaskedText(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informações atualizadas com sucesso!')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      hasAppBar: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      tooltip: 'Voltar',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Editar Perfil',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Atualize seus dados cadastrais',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 20.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informações pessoais',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Atualize seus dados para manter seu cadastro completo.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 20),
                            CustomTextField(
                              label: 'Nome Completo',
                              hint: 'Digite seu nome completo',
                              controller: _nameController,
                              prefixIcon: const Icon(Icons.person_outline),
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor, insira seu nome';
                                }
                                if (value.trim().length < 3) {
                                  return 'O nome deve ter pelo menos 3 caracteres';
                                }
                                return null;
                              },
                            ),
                            CustomTextField(
                              label: 'Telefone',
                              hint: 'Insira seu número de telefone',
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [_phoneMask],
                              prefixIcon: const Icon(Icons.phone_outlined),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor, insira seu número de telefone';
                                }
                                if (_phoneMask.getUnmaskedText().length != 11) {
                                  return 'O telefone deve ter 11 dígitos';
                                }
                                return null;
                              },
                            ),
                            CustomTextField(
                              label: 'Email (somente leitura)',
                              hint: 'Email da conta',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              readOnly: true,
                              prefixIcon: const Icon(Icons.email_outlined),
                              suffixIcon: const Icon(Icons.lock_outline),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        label: 'Salvar Alterações',
                        onPressed: _handleSave,
                        isLoading: _isSaving,
                        icon: Icons.save_outlined,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
