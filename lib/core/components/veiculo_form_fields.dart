import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/veiculo.dart';
import '../../providers/app_provider.dart';
import 'form_styles.dart';

/// Controller/estado dos campos de veículo (marca, modelo, cor, placa, ano,
/// observações), incluindo a lógica de "Outra... (digitar)" para marca e
/// modelo. Pode ser criado vazio (novo veículo) ou a partir de um veículo
/// existente (edição), via [VeiculoFormController.fromVeiculo].
///
/// Compartilhado entre o assistente de cadastro de cliente, o cadastro de
/// veículo avulso, a edição de veículo e o atalho de cadastro de veículo
/// dentro do orçamento — fonte única da lógica de marca/modelo custom.
class VeiculoFormController extends ChangeNotifier {
  static const otherOptionValue = '__other__';

  String? selectedMarca;
  String? selectedModelo;

  final marcaCustomController = TextEditingController();
  final modeloCustomController = TextEditingController();
  final corController = TextEditingController();
  final placaController = TextEditingController();
  final anoController = TextEditingController();
  final observacoesController = TextEditingController();

  final corFocus = FocusNode();
  final placaFocus = FocusNode();
  final anoFocus = FocusNode();

  VeiculoFormController();

  /// Inicializa o controller a partir de um veículo existente, detectando
  /// (contra o catálogo atual da conta) se marca/modelo são valores fixos
  /// ou customizados, para pré-selecionar o dropdown corretamente.
  factory VeiculoFormController.fromVeiculo(
    Veiculo veiculo,
    AppProvider provider,
  ) {
    final controller = VeiculoFormController();

    final marcaMatch = _findCaseInsensitive(
      provider.marcasDisponiveis,
      veiculo.marca,
    );
    if (marcaMatch != null) {
      controller.selectedMarca = marcaMatch;
    } else if (veiculo.marca.trim().isNotEmpty) {
      controller.selectedMarca = otherOptionValue;
      controller.marcaCustomController.text = veiculo.marca;
    }

    final modelosBase = controller.selectedMarca == otherOptionValue
        ? const <String>[]
        : provider.modelosDisponiveis(controller.selectedMarca);
    final modeloMatch = _findCaseInsensitive(modelosBase, veiculo.modelo);
    if (controller.selectedMarca == otherOptionValue) {
      controller.modeloCustomController.text = veiculo.modelo;
    } else if (modeloMatch != null) {
      controller.selectedModelo = modeloMatch;
    } else if (veiculo.modelo.trim().isNotEmpty) {
      controller.selectedModelo = otherOptionValue;
      controller.modeloCustomController.text = veiculo.modelo;
    }

    controller.corController.text = veiculo.cor;
    controller.placaController.text = veiculo.placa;
    controller.anoController.text = veiculo.ano?.toString() ?? '';
    controller.observacoesController.text = veiculo.observacoes ?? '';

    return controller;
  }

  static String? _findCaseInsensitive(List<String> options, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    for (final option in options) {
      if (option.toLowerCase() == trimmed.toLowerCase()) return option;
    }
    return null;
  }

  bool get isOtherMarca => selectedMarca == otherOptionValue;
  bool get isOtherModelo => selectedModelo == otherOptionValue;

  String get marcaFinal => isOtherMarca
      ? marcaCustomController.text.trim()
      : (selectedMarca ?? '').trim();

  String get modeloFinal => isOtherMarca
      ? modeloCustomController.text.trim()
      : isOtherModelo
          ? modeloCustomController.text.trim()
          : (selectedModelo ?? '').trim();

  void setMarca(String? value) {
    selectedMarca = value;
    selectedModelo = null;
    if (value != otherOptionValue) {
      marcaCustomController.clear();
    }
    modeloCustomController.clear();
    notifyListeners();
  }

  void setModelo(String? value) {
    selectedModelo = value;
    if (value != otherOptionValue) {
      modeloCustomController.clear();
    }
    notifyListeners();
  }

  /// Limpa todos os campos, voltando ao estado de "veículo vazio".
  void reset() {
    selectedMarca = null;
    selectedModelo = null;
    marcaCustomController.clear();
    modeloCustomController.clear();
    corController.clear();
    placaController.clear();
    anoController.clear();
    observacoesController.clear();
    notifyListeners();
  }

  /// Reconstrói o veículo com os valores atuais do formulário. Chame após
  /// validar o Form ambiente (este widget não cria seu próprio Form).
  Veiculo buildVeiculo({required String id, required String clienteId}) {
    final anoText = anoController.text.trim();
    return Veiculo(
      id: id,
      clienteId: clienteId,
      marca: marcaFinal,
      modelo: modeloFinal,
      cor: corController.text.trim(),
      placa: placaController.text.trim(),
      ano: anoText.isEmpty ? null : int.tryParse(anoText),
      observacoes: observacoesController.text.trim().isEmpty
          ? null
          : observacoesController.text.trim(),
    );
  }

  @override
  void dispose() {
    marcaCustomController.dispose();
    modeloCustomController.dispose();
    corController.dispose();
    placaController.dispose();
    anoController.dispose();
    observacoesController.dispose();
    corFocus.dispose();
    placaFocus.dispose();
    anoFocus.dispose();
    super.dispose();
  }
}

/// Campos de formulário de veículo (marca, modelo, cor, placa, ano,
/// observações). Deve ser usado dentro de um `Form` ambiente fornecido pelo
/// widget pai — não cria seu próprio `Form` (para poder ser embutido em
/// formulários maiores, como o assistente de cadastro de cliente).
class VeiculoFormFields extends StatelessWidget {
  final VeiculoFormController controller;

  const VeiculoFormFields({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: controller.selectedMarca,
              decoration: formFieldDecoration(
                label: 'Marca *',
                prefixIcon: Icons.directions_car,
              ),
              items: [
                ...provider.marcasDisponiveis.map<DropdownMenuItem<String>>(
                  (m) => DropdownMenuItem<String>(value: m, child: Text(m)),
                ),
                const DropdownMenuItem<String>(
                  value: VeiculoFormController.otherOptionValue,
                  child: Text('Outra... (digitar)'),
                ),
              ],
              onChanged: controller.setMarca,
              validator: (value) =>
                  (value == null || value.trim().isEmpty)
                      ? 'Selecione a marca'
                      : null,
            ),
            if (controller.isOtherMarca) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.marcaCustomController,
                decoration: formFieldDecoration(
                  label: 'Digite a marca *',
                  prefixIcon: Icons.edit,
                ),
                validator: (_) {
                  if (!controller.isOtherMarca) return null;
                  return controller.marcaCustomController.text.trim().isEmpty
                      ? 'Informe a marca'
                      : null;
                },
              ),
            ],
            const SizedBox(height: 16),
            if (controller.selectedMarca == null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Selecione a marca primeiro',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else if (controller.isOtherMarca)
              TextFormField(
                controller: controller.modeloCustomController,
                decoration: formFieldDecoration(
                  label: 'Modelo *',
                  prefixIcon: Icons.drive_eta,
                ),
                validator: (_) =>
                    controller.modeloCustomController.text.trim().isEmpty
                        ? 'Modelo é obrigatório'
                        : null,
              )
            else
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: controller.selectedModelo,
                decoration: formFieldDecoration(
                  label: 'Modelo *',
                  prefixIcon: Icons.drive_eta,
                ),
                items: [
                  ...provider
                      .modelosDisponiveis(controller.selectedMarca)
                      .map<DropdownMenuItem<String>>(
                        (m) =>
                            DropdownMenuItem<String>(value: m, child: Text(m)),
                      ),
                  const DropdownMenuItem<String>(
                    value: VeiculoFormController.otherOptionValue,
                    child: Text('Outro... (digitar)'),
                  ),
                ],
                onChanged: controller.setModelo,
                hint: const Text('Selecione o modelo'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Selecione o modelo'
                        : null,
              ),
            if (!controller.isOtherMarca && controller.isOtherModelo) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.modeloCustomController,
                decoration: formFieldDecoration(
                  label: 'Digite o modelo *',
                  prefixIcon: Icons.edit,
                ),
                validator: (_) {
                  if (!controller.isOtherModelo) return null;
                  return controller.modeloCustomController.text.trim().isEmpty
                      ? 'Digite o modelo'
                      : null;
                },
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.corController,
              focusNode: controller.corFocus,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => controller.placaFocus.requestFocus(),
              decoration: formFieldDecoration(
                label: 'Cor *',
                prefixIcon: Icons.color_lens,
              ),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Cor é obrigatória'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.placaController,
              focusNode: controller.placaFocus,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => controller.anoFocus.requestFocus(),
              decoration: formFieldDecoration(
                label: 'Placa *',
                prefixIcon: Icons.confirmation_number,
              ),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Placa é obrigatória'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.anoController,
              focusNode: controller.anoFocus,
              textInputAction: TextInputAction.next,
              decoration: formFieldDecoration(
                label: 'Ano',
                prefixIcon: Icons.calendar_today,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isNotEmpty && int.tryParse(v) == null) {
                  return 'Ano inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.observacoesController,
              decoration: formFieldDecoration(
                label: 'Observações',
                prefixIcon: Icons.note,
              ),
              maxLines: 3,
            ),
          ],
        );
      },
    );
  }
}
