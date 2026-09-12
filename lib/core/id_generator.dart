import 'package:uuid/uuid.dart';

/// Gera um id único (UUID v4) para uso como chave primária TEXT
/// em inserts feitos pelo client em tabelas do Supabase.
String gerarId() => const Uuid().v4();
