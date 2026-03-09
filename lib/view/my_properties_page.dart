import 'package:app_envio/models/property.dart';
import 'package:app_envio/services/property_service.dart';
import 'package:app_envio/view/components/custom_app_bar.dart';
import 'package:app_envio/view/components/custom_button.dart';
import 'package:app_envio/view/components/custom_scaffold.dart';
import 'package:app_envio/view/components/custom_text_field.dart';
import 'package:app_envio/view/my_talhoes_page.dart';
import 'package:app_envio/view/property_register_page.dart';
import 'package:flutter/material.dart';

class MyPropertiesPage extends StatefulWidget {
  const MyPropertiesPage({super.key});

  @override
  State<MyPropertiesPage> createState() => _MyPropertiesPageState();
}

class _MyPropertiesPageState extends State<MyPropertiesPage> {
  final PropertyService _propertyService = PropertyService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  Future<void> _openRegisterPage() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PropertyRegisterPage()));
  }

  Future<void> _showEditDialog(Property property) async {
    final messenger = ScaffoldMessenger.of(context);
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: property.name);
    final ownerController = TextEditingController(text: property.owner);
    final addresController = TextEditingController(text: property.addres);
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogBodyContext, setDialogState) {
            Future<void> onSave() async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              setDialogState(() => isSaving = true);

              try {
                await _propertyService.updateProperty(
                  propertyId: property.id,
                  name: nameController.text.trim(),
                  owner: ownerController.text.trim(),
                  addres: addresController.text.trim(),
                );

                if (!mounted) return;
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Propriedade atualizada com sucesso!'),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                setDialogState(() => isSaving = false);
                messenger.showSnackBar(
                  SnackBar(content: Text('Erro ao atualizar propriedade: $e')),
                );
              }
            }

            return AlertDialog(
              title: const Text('Editar Propriedade'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomTextField(
                        label: 'Nome da Propriedade',
                        controller: nameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o nome da propriedade';
                          }
                          return null;
                        },
                      ),
                      CustomTextField(
                        label: 'Proprietário',
                        controller: ownerController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o proprietário';
                          }
                          return null;
                        },
                      ),
                      CustomTextField(
                        label: 'Endereço',
                        controller: addresController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o endereço';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: isSaving ? null : onSave,
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    ownerController.dispose();
    addresController.dispose();
  }

  Future<void> _confirmDelete(Property property) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir propriedade'),
        content: Text('Deseja excluir "${property.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await _propertyService.deleteProperty(property.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Propriedade excluída com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir propriedade: $e')),
      );
    }
  }

  Future<void> _openMyTalhoesPage(Property property) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MyTalhoesPage(property: property)),
    );
  }

  List<Property> _filterProperties(List<Property> properties) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return properties;

    return properties.where((property) {
      return property.name.toLowerCase().contains(query) ||
          property.owner.toLowerCase().contains(query) ||
          property.addres.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Buscar por nome, proprietário ou endereço',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildSummary(int total, int filtered) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.home_work_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _searchController.text.isEmpty
                  ? '$total propriedade(s) cadastrada(s).'
                  : '$filtered resultado(s) de $total propriedade(s).',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Property property) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.home_work_outlined)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    property.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(property.owner)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(property.addres)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openMyTalhoesPage(property),
                  icon: const Icon(Icons.grid_view_outlined),
                  label: const Text('Talhões'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showEditDialog(property),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(property),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Excluir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
        title: 'Minhas Propriedades',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openRegisterPage,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Property>>(
        stream: _propertyService.watchMyProperties(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Erro ao carregar propriedades: ${snapshot.error}'),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final properties = snapshot.data ?? [];
          final filteredProperties = _filterProperties(properties);

          if (properties.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.home_work_outlined,
                      size: 72,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Você ainda não cadastrou propriedades.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      label: 'Cadastrar Propriedade',
                      onPressed: _openRegisterPage,
                      icon: Icons.add_home_work_outlined,
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              _buildSearchField(),
              _buildSummary(properties.length, filteredProperties.length),
              if (filteredProperties.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Nenhuma propriedade encontrada para essa busca.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredProperties.length,
                    itemBuilder: (context, index) =>
                        _buildPropertyCard(filteredProperties[index]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
