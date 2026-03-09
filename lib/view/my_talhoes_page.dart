import 'package:app_envio/models/property.dart';
import 'package:app_envio/models/talhao.dart';
import 'package:app_envio/services/talhao_service.dart';
import 'package:app_envio/view/components/custom_app_bar.dart';
import 'package:app_envio/view/components/custom_button.dart';
import 'package:app_envio/view/components/custom_scaffold.dart';
import 'package:app_envio/view/components/custom_text_field.dart';
import 'package:app_envio/view/talhao_register_page.dart';
import 'package:flutter/material.dart';

class MyTalhoesPage extends StatefulWidget {
  final Property property;

  const MyTalhoesPage({super.key, required this.property});

  @override
  State<MyTalhoesPage> createState() => _MyTalhoesPageState();
}

class _MyTalhoesPageState extends State<MyTalhoesPage> {
  final TalhaoService _talhaoService = TalhaoService();
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
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TalhaoRegisterPage(property: widget.property),
      ),
    );
  }

  Future<void> _showEditDialog(Talhao talhao) async {
    final messenger = ScaffoldMessenger.of(context);
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: talhao.name);
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
                await _talhaoService.updateTalhao(
                  talhaoId: talhao.id,
                  name: nameController.text.trim(),
                  propertyId: widget.property.id,
                );

                if (!mounted) return;
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Talhão atualizado com sucesso!'),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                setDialogState(() => isSaving = false);
                messenger.showSnackBar(
                  SnackBar(content: Text('Erro ao atualizar talhão: $e')),
                );
              }
            }

            return AlertDialog(
              title: const Text('Editar Talhão'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: CustomTextField(
                    label: 'Nome do Talhão',
                    controller: nameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o nome do talhão';
                      }
                      return null;
                    },
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
  }

  Future<void> _confirmDelete(Talhao talhao) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir talhão'),
        content: Text('Deseja excluir "${talhao.name}"?'),
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
      await _talhaoService.deleteTalhao(talhao.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Talhão excluído com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao excluir talhão: $e')));
    }
  }

  List<Talhao> _filterTalhoes(List<Talhao> talhoes) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return talhoes;
    return talhoes
        .where((talhao) => talhao.name.toLowerCase().contains(query))
        .toList();
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Buscar talhão por nome',
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
          const Icon(Icons.grid_view_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _searchController.text.isEmpty
                  ? '$total talhão(ões) nesta propriedade.'
                  : '$filtered resultado(s) de $total talhão(ões).',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTalhaoCard(Talhao talhao) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.grid_view_outlined)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    talhao.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.property.name,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Editar',
              onPressed: () => _showEditDialog(talhao),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Excluir',
              onPressed: () => _confirmDelete(talhao),
              icon: const Icon(Icons.delete_outline),
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
        title: 'Talhões - ${widget.property.name}',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openRegisterPage,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Talhao>>(
        stream: _talhaoService.watchTalhoesByProperty(widget.property.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Erro ao carregar talhões: ${snapshot.error}'),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final talhoes = snapshot.data ?? [];
          final filteredTalhoes = _filterTalhoes(talhoes);

          if (talhoes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.grid_view_outlined,
                      size: 72,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum talhão cadastrado nesta propriedade.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      label: 'Cadastrar Talhão',
                      onPressed: _openRegisterPage,
                      icon: Icons.add_box_outlined,
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              _buildSearchField(),
              _buildSummary(talhoes.length, filteredTalhoes.length),
              if (filteredTalhoes.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Nenhum talhão encontrado para essa busca.',
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
                    itemCount: filteredTalhoes.length,
                    itemBuilder: (context, index) =>
                        _buildTalhaoCard(filteredTalhoes[index]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
