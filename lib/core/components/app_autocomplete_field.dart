import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/text_normalize.dart';
import 'form_styles.dart';

/// Campo de texto com sugestões (`Autocomplete<String>`) estilizado
/// conforme o design system do app.
///
/// Suporta texto livre: se o que foi digitado não bate (comparação sem
/// acento/maiúscula) com nenhuma opção de [options], a própria digitação
/// vira mais uma entrada no fim da lista de sugestões — exibida como
/// `Usar '<texto digitado>'` — que o usuário confirma tocando, igual a
/// qualquer outra sugestão. Esse widget só informa ao [onSelected] qual
/// valor foi confirmado (existente ou livre); decidir o que fazer com um
/// valor novo (ex: persistir num catálogo customizado) é responsabilidade
/// de quem usa o campo, não deste widget.
class AppAutocompleteField extends StatelessWidget {
  const AppAutocompleteField({
    super.key,
    required this.label,
    required this.options,
    required this.onSelected,
    this.initialValue,
    this.prefixIcon,
    this.validator,
  });

  final String label;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final String? initialValue;
  final IconData? prefixIcon;
  final FormFieldValidator<String>? validator;

  bool _isLivre(String option) {
    return !options.any((o) => normalizeText(o) == normalizeText(option));
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: initialValue ?? ''),
      displayStringForOption: (option) => option,
      optionsBuilder: (TextEditingValue value) {
        final termos = normalizeText(value.text);
        final filtradas = termos.isEmpty
            ? options
            : options.where((o) => normalizeText(o).contains(termos)).toList();

        final textoDigitado = value.text.trim();
        final existeIgual = options.any(
          (o) => normalizeText(o) == normalizeText(textoDigitado),
        );

        if (textoDigitado.isNotEmpty && !existeIgual) {
          return [...filtradas, textoDigitado];
        }
        return filtradas;
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: formFieldDecoration(label: label, prefixIcon: prefixIcon),
          validator: validator,
          onFieldSubmitted: (_) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelectedOption, optionsResult) {
        final optionsList = optionsResult.toList();

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: AppColors.elevated,
            elevation: 4,
            borderRadius: BorderRadius.circular(AppRadius.modal),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: optionsList.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Nenhum resultado encontrado',
                        style: AppText.bodySecondary,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shrinkWrap: true,
                      itemCount: optionsList.length,
                      separatorBuilder: (_, __) => const Divider(
                        color: AppColors.line,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final option = optionsList[index];
                        final isLivre = _isLivre(option);

                        return ListTile(
                          dense: true,
                          leading: isLivre
                              ? const Icon(Icons.add, color: AppColors.primary)
                              : null,
                          title: Text(
                            isLivre ? "Usar '$option'" : option,
                            style: AppText.body.copyWith(
                              color: isLivre
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontWeight: isLivre
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          subtitle: isLivre
                              ? Text('Adicionar novo', style: AppText.caption)
                              : null,
                          onTap: () => onSelectedOption(option),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }
}
