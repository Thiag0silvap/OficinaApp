import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/empresa.dart';

class EmpresaService {

  static const _key = 'empresa_config';

  static Future<void> salvarEmpresa(Empresa empresa) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_key, jsonEncode(empresa.toMap()));
  }

  static Future<Empresa?> carregarEmpresa() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);

    if (data == null) return null;

    return Empresa.fromMap(jsonDecode(data));
  }
}