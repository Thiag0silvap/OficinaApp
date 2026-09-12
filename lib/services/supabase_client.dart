import 'package:supabase_flutter/supabase_flutter.dart';

/// Ponto único de acesso ao cliente Supabase, no mesmo espírito do
/// gateway único aplicado ao DBService via AppProvider.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;
}
