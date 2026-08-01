import 'package:oficina_app/models/orcamento.dart';

class AppConstants {
  static const String appName = 'OficinaApp';
  static const String appSlogan = 'Gestão completa para sua oficina';

  /// URL de um JSON público com a última versão disponível.
  /// Deixe vazio para desativar o check automático.
  static const String updateManifestUrl =
      'https://thiag0silvap.github.io/OficinaApp/update_manifest.json';

  // Logo paths
  static const String logoPath = 'assets/images/logo.png';
  static const String logoPlaceholderPath =
      'assets/images/placeholder_logo.txt';

  // =========================
  // SERVIÇOS
  // =========================
  static const List<String> servicos = [
    'Funilaria',
    'Pintura',
    'Retoque',
    'Polimento especializado',
    'Cristalização',
    'Recuperação de farol',
    'Higienização interna',
    'Troca de peça',
    'Desamassado',
    'Outro',
  ];

  // Descrições institucionais dos serviços
  // Úteis para referência, PDF, ajuda ou descrição longa
  static const Map<String, String> servicosDescricao = {
    'Funilaria':
        'Reparos em lataria, correção de amassados, substituição de peças danificadas e restauração estrutural do veículo.',
    'Pintura':
        'Pintura completa ou parcial, correção de riscos, retoques e acabamento profissional com tintas de alta qualidade.',
    'Retoque':
        'Correções localizadas de pintura, pequenos reparos visuais e ajustes finos de acabamento.',
    'Polimento especializado':
        'Polimento técnico para remover riscos superficiais, oxidação e devolver o brilho original da pintura.',
    'Cristalização':
        'Aplicação de proteção e acabamento para preservar a pintura e manter o brilho por mais tempo.',
    'Recuperação de farol':
        'Restauração de faróis amarelados ou opacos com acabamento e proteção.',
    'Higienização interna':
        'Limpeza profunda de bancos, carpetes, teto, painel e todos os componentes internos do veículo.',
    'Troca de peça':
        'Substituição e ajuste de peças danificadas conforme necessidade do orçamento.',
    'Desamassado':
        'Correção de pequenos e médios amassados com acabamento adequado.',
    'Outro': 'Serviço personalizado definido manualmente pelo usuário.',
  };

  // Preços sugeridos
  static const Map<String, double> servicosPreco = {
    'Funilaria': 300.00,
    'Pintura': 450.00,
    'Retoque': 150.00,
    'Polimento especializado': 150.00,
    'Cristalização': 200.00,
    'Recuperação de farol': 120.00,
    'Higienização interna': 120.00,
    'Troca de peça': 200.00,
    'Desamassado': 180.00,
  };

  // Ícones dos serviços
  static const Map<String, String> servicosIcones = {
    'Funilaria': '🔧',
    'Pintura': '🎨',
    'Retoque': '🛠',
    'Polimento especializado': '✨',
    'Cristalização': '🧴',
    'Recuperação de farol': '💡',
    'Higienização interna': '🧹',
    'Troca de peça': '🚗',
    'Desamassado': '🔩',
    'Outro': '📋',
  };

  // =========================
  // PEÇAS
  // =========================
  static const List<String> pecas = [
    'Teto',
    'Capô',
    'Porta-malas',
    'Para-choque dianteiro',
    'Para-choque traseiro',
    'Painel dianteiro',
    'Painel traseiro',
    'Para-lama esquerdo',
    'Para-lama direito',
    'Porta dianteira esquerda',
    'Porta traseira esquerda',
    'Porta dianteira direita',
    'Porta traseira direita',
    'Lateral esquerda',
    'Lateral direita',
    'Soleira esquerda',
    'Soleira direita',
    'Para-brisa',
    'Peça para troca',
  ];

  // Descrições padrão de peças
  static const Map<String, String> pecasDescricao = {
    'Teto': '',
    'Capô': '',
    'Porta-malas': '',
    'Para-choque dianteiro': '',
    'Para-choque traseiro': '',
    'Painel dianteiro': '',
    'Painel traseiro': '',
    'Para-lama esquerdo': '',
    'Para-lama direito': '',
    'Porta dianteira esquerda': '',
    'Porta traseira esquerda': '',
    'Porta dianteira direita': '',
    'Porta traseira direita': '',
    'Lateral esquerda': '',
    'Lateral direita': '',
    'Soleira esquerda': '',
    'Soleira direita': '',
    'Para-brisa': '',
    'Peça para troca': '',
  };

  // =========================
  // MARCAS E MODELOS
  // =========================
  static const List<String> marcas = [
    'Chevrolet',
    'Fiat',
    'Ford',
    'Volkswagen',
    'Honda',
    'Toyota',
    'Hyundai',
    'Renault',
  ];

  static const Map<String, List<String>> modelosPorMarca = {
    'Chevrolet': ['Onix', 'Prisma', 'Celta', 'Cruze', 'S10'],
    'Fiat': ['Uno', 'Palio', 'Cronos', 'Toro', 'Mobi'],
    'Ford': ['Ka', 'Fiesta', 'EcoSport', 'Ranger', 'Focus'],
    'Volkswagen': ['Gol', 'Fox', 'Voyage', 'Golf', 'Polo'],
    'Honda': ['Civic', 'City', 'Fit', 'HR-V'],
    'Toyota': ['Corolla', 'Yaris', 'Hilux', 'Etios'],
    'Hyundai': ['HB20', 'i30', 'Tucson', 'Creta'],
    'Renault': ['Kwid', 'Sandero', 'Logan', 'Duster'],
  };

  // =========================
  // ORÇAMENTO
  // =========================
  static List<String> get statusOrcamento =>
      OrcamentoStatus.values.map((e) => e.displayName).toList();

  // =========================
  // FINANCEIRO
  // =========================
  static const List<String> categoriasDespesas = [
    'Material',
    'Ferramentas',
    'Aluguel',
    'Energia',
    'Água',
    'Internet/Telefone',
    'Salários',
    'Impostos',
    'Manutenção',
    'Outros',
  ];
}