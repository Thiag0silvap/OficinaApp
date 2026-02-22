import 'package:oficina_app/models/orcamento.dart';

class AppConstants {
  static const String appName = 'OficinaApp';
  static const String appSlogan = 'Gestão completa para sua oficina';

  /// URL de um JSON público com a última versão disponível.
  /// Exemplo de formato em `tool/update_manifest_example.json`.
  /// Deixe vazio para desativar o check automático.
    static const String updateManifestUrl =
      'https://thiag0silvap.github.io/OficinaApp/update_manifest.json';
  
  // Logo paths
  // Update to your actual logo file placed in assets/images/
  static const String logoPath = 'assets/images/logo.png';
  static const String logoPlaceholderPath = 'assets/images/placeholder_logo.txt';
  
  // Lista de serviços oferecidos
  static const List<String> servicos = [
    'Funilaria',
    'Pintura',
    'Polimento especializado',
    'Cristalização e recuperação de farol',
    'Higienização interna',
  ];

  // Lista de peças (baseado no modelo fornecido pelo cliente)
  static const List<String> pecas = [
    'Teto',
    'Capô',
    'Porta-malas',
    'Para-choque dianteiro',
    'Painel dianteiro',
    'Painel traseiro',
    'Para-choque traseiro',
    'Para-lama esquerda',
    'Para-lama direita',
    'Porta esquerda',
    'Porta de trás esquerda',
    'Porta direita',
    'Porta de trás direita',
    'Lateral direita',
    'Lateral esquerda',
    'Soleira esquerda',
    'Soleira direita',
    'Para-brisa',
    'Peças para troca',
    'Polimento',
  ];

  // Descrições padrão (opcional) para peças — pode ser extendida conforme necessário
  static const Map<String, String> pecasDescricao = {
    'Teto': '',
    'Capô': '',
    'Porta-malas': '',
    'Para-choque dianteiro': '',
    'Painel dianteiro': '',
    'Painel traseiro': '',
    'Para-choque traseiro': '',
    'Para-lama esquerda': '',
    'Para-lama direita': '',
    'Porta esquerda': '',
    'Porta de trás esquerda': '',
    'Porta direita': '',
    'Porta de trás direita': '',
    'Lateral direita': '',
    'Lateral esquerda': '',
    'Soleira esquerda': '',
    'Soleira direita': '',
    'Para-brisa': '',
    'Peças para troca': '',
    'Polimento': '',
  };

  // Marcas e modelos comuns para facilitar cadastro rápido
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
  
  // Descrições dos serviços
  static const Map<String, String> servicosDescricao = {
    'Funilaria': 'Reparos em lataria, correção de amassados, substituição de peças danificadas e restauração estrutural do veículo.',
    'Pintura': 'Pintura completa ou parcial, correção de riscos, retoques e acabamento profissional com tintas de alta qualidade.',
    'Polimento especializado': 'Polimento técnico para remover riscos superficiais, oxidação e devolver o brilho original da pintura.',
    'Cristalização e recuperação de farol': 'Restauração de faróis amarelados ou opacos, aplicação de cristalização para proteção duradoura.',
    'Higienização interna': 'Limpeza profunda de bancos, carpetes, teto, painel e todos os componentes internos do veículo.',
  };

  // Preços sugeridos para serviços (pode ser ajustado pelo usuário ao adicionar)
  static const Map<String, double> servicosPreco = {
    'Funilaria': 300.00,
    'Pintura': 450.00,
    'Polimento especializado': 150.00,
    'Cristalização e recuperação de farol': 200.00,
    'Higienização interna': 120.00,
  };
  
  // Ícones para cada serviço
  static const Map<String, String> servicosIcones = {
    'Funilaria': '🔧',
    'Pintura': '🎨',
    'Polimento especializado': '✨',
    'Cristalização e recuperação de farol': '💡',
    'Higienização interna': '🧹',
  };
  
  // Status de orçamento (derived from OrcamentoStatus enum)
  static List<String> get statusOrcamento =>
      OrcamentoStatus.values.map((e) => e.displayName).toList();
  
  // Categorias de despesas
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
