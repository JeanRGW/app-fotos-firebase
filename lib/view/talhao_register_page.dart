import 'package:app_envio/models/property.dart';
import 'package:app_envio/services/talhao_service.dart';
import 'package:app_envio/view/components/custom_app_bar.dart';
import 'package:app_envio/view/components/custom_button.dart';
import 'package:app_envio/view/components/custom_scaffold.dart';
import 'package:app_envio/view/components/custom_text_field.dart';
import 'package:flutter/material.dart';

class TalhaoRegisterPage extends StatefulWidget {
  final Property property;

  const TalhaoRegisterPage({super.key, required this.property});

  @override
  State<TalhaoRegisterPage> createState() => _TalhaoRegisterPageState();
}

class _TalhaoRegisterPageState extends State<TalhaoRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _talhaoService = TalhaoService();
  bool _isLoading = false;

  void _goBack() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveTalhao() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _talhaoService.registerTalhao(
        name: _nameController.text.trim(),
        propertyId: widget.property.id,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Talhão cadastrado com sucesso!')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao cadastrar talhão: $e')));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: CustomAppBar(
        leading: CustomAppBarAction(
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            tooltip: 'Voltar',
            onPressed: _goBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ),
        title: 'Cadastrar Talhão',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Propriedade: ${widget.property.name}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Nome do Talhão',
                hint: 'Digite o nome do talhão',
                controller: _nameController,
                prefixIcon: const Icon(Icons.grid_view_outlined),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome do talhão';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: 'Salvar Talhão',
                onPressed: _saveTalhao,
                isLoading: _isLoading,
                icon: Icons.save_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
