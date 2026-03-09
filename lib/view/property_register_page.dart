import 'package:app_envio/services/property_service.dart';
import 'package:app_envio/view/components/custom_app_bar.dart';
import 'package:app_envio/view/components/custom_button.dart';
import 'package:app_envio/view/components/custom_scaffold.dart';
import 'package:app_envio/view/components/custom_text_field.dart';
import 'package:flutter/material.dart';

class PropertyRegisterPage extends StatefulWidget {
  const PropertyRegisterPage({super.key});

  @override
  State<PropertyRegisterPage> createState() => _PropertyRegisterPageState();
}

class _PropertyRegisterPageState extends State<PropertyRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ownerController = TextEditingController();
  final _addresController = TextEditingController();
  final _propertyService = PropertyService();
  bool _isLoading = false;

  void _goBack() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    _addresController.dispose();
    super.dispose();
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _propertyService.registerProperty(
        name: _nameController.text.trim(),
        owner: _ownerController.text.trim(),
        addres: _addresController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Propriedade cadastrada com sucesso!')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cadastrar propriedade: $e')),
      );
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
        title: 'Cadastrar Propriedade',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                label: 'Nome da Propriedade',
                hint: 'Digite o nome da propriedade',
                controller: _nameController,
                prefixIcon: const Icon(Icons.home_work_outlined),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome da propriedade';
                  }
                  return null;
                },
              ),
              CustomTextField(
                label: 'Proprietário',
                hint: 'Digite o nome do proprietário',
                controller: _ownerController,
                prefixIcon: const Icon(Icons.person_outline),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o proprietário';
                  }
                  return null;
                },
              ),
              CustomTextField(
                label: 'Endereço',
                hint: 'Digite o endereço da propriedade',
                controller: _addresController,
                prefixIcon: const Icon(Icons.location_on_outlined),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o endereço';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: 'Salvar Propriedade',
                onPressed: _saveProperty,
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
