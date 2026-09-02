import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/veiculo.dart';
import '../../providers/app_provider.dart';
import 'app_autocomplete_field.dart';
import 'form_styles.dart';

/// Controller/estado dos campos de veículo (marca, modelo, cor, placa, ano,
/// observações). Pode ser criado vazio (novo veículo) ou a partir de um
/// veículo existente (edição), via [VeiculoFormController.fromVeiculo].
///
/// Compartilhado entre o assistente de cadastro de cliente, o cadastro de
/// veículo avulso, a edição de veículo e o atalho de cadastro de veículo
/// dentro do orçamento — fonte única da lógica de marca/modelo custom.
class VeiculoFormController extends ChangeNotifier {
  String? selectedMarca;
  String? selectedModelo;

  final corController = TextEditingController();
  final placaController = TextEditingController();
  final anoController = TextEditingController();
  final observacoesController = TextEditingController();

  final corFocus = FocusNode();
  final placaFocus = FocusNode();
  final anoFocus = FocusNode();

  VeiculoFormController();

  /// Inicializa o controller a partir de um veículo existente, tentando
  /// casar marca/modelo (sem diferenciar maiúscula/acento) contra o
  /// catálogo atual da conta pra manter a grafia "oficial" já usada em
  /// outros veículos — mas aceita o valor bruto salvo mesmo se não achar
  /// correspondência (marca/modelo digitado livremente continua válido).
  factory VeiculoFormController.fromVeiculo(
    Veiculo veiculo,
    AppProvider provider,
  ) {
    final controller = VeiculoFormController();

    final marcaMatch = _findCaseInsensitive(
      provider.marcasDisponiveis,
      veiculo.marca,
    );
    controller.selectedMarca = marcaMatch ??
        (veiculo.marca.trim().isEmpty ? null : veiculo.marca.trim());

    final modelosBase = provider.modelosDisponiveis(controller.selectedMarca);
    final modeloMatch = _findCaseInsensitive(modelosBase, veiculo.modelo);
    controller.selectedModelo = modeloMatch ??
        (veiculo.modelo.trim().isEmpty ? null : veiculo.modelo.trim());

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

  String get marcaFinal => (selectedMarca ?? '').trim();
  String get modeloFinal => (selectedModelo ?? '').trim();

  void setMarca(String value) {
    selectedMarca = value.trim();
    selectedModelo = null;
    notifyListeners();
  }

  void setModelo(String value) {
    selectedModelo = value.trim();
    notifyListeners();
  }

  /// Limpa todos os campos, voltando ao estado de "veículo vazio".
  void reset() {
    selectedMarca = null;
    selectedModelo = null;
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
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Só este trecho (Marca/Modelo) escuta o AppProvider — a
            // sincronização com a FIPE roda em background e chama
            // notifyListeners() quando termina; sem esse Consumer aqui, o
            // campo de Modelo ficava com a lista antiga/vazia até algo
            // FORA do provider forçar rebuild (ex: trocar de marca de
            // novo). Escopo deliberadamente restrito pra não reconstruir
            // Cor/Placa/Ano/Observações toda vez que o AppProvider notificar
            // por qualquer outro motivo (nova transação, orçamento, etc).
            Consumer<AppProvider>(
              builder: (context, provider, _) {
                final marcasDisponiveis = provider.marcasDisponiveis;
                final modelosDisponiveis = controller.selectedMarca == null
                    ? const <String>[]
                    : provider.modelosDisponiveis(controller.selectedMarca);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppAutocompleteField(
                      // Chave muda a cada seleção pra forçar o Autocomplete
                      // a remontar com o initialValue novo — ele só lê
                      // initialValue uma vez, na criação do campo interno.
                      key: ValueKey('marca-${controller.selectedMarca ?? ''}'),
                      label: 'Marca *',
                      prefixIcon: Icons.directions_car,
                      options: marcasDisponiveis,
                      initialValue: controller.selectedMarca,
                      onSelected: (valor) {
                        if (!marcasDisponiveis.any(
                          (m) => m.toLowerCase() == valor.toLowerCase(),
                        )) {
                          unawaited(
                            provider.addMarcaModeloCustom(marca: valor),
                          );
                        }
                        controller.setMarca(valor);
                      },
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Selecione a marca'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    if (controller.selectedMarca == null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Selecione a marca primeiro',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      )
                    else
                      AppAutocompleteField(
                        key: ValueKey(
                          'modelo-${controller.selectedMarca}-${controller.selectedModelo ?? ''}',
                        ),
                        label: 'Modelo *',
                        prefixIcon: Icons.drive_eta,
                        options: modelosDisponiveis,
                        initialValue: controller.selectedModelo,
                        onSelected: (valor) {
                          if (!modelosDisponiveis.any(
                            (m) => m.toLowerCase() == valor.toLowerCase(),
                          )) {
                            unawaited(
                              provider.addMarcaModeloCustom(
                                marca: controller.selectedMarca!,
                                modelo: valor,
                              ),
                            );
                          }
                          controller.setModelo(valor);
                        },
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Selecione o modelo'
                                : null,
                      ),
                  ],
                );
              },
            ),
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
