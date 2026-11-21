import 'package:flutter/services.dart';

/// Extrai apenas dígitos (0-9) de uma string.
String digitsOnly(String input) => input.replaceAll(RegExp(r'[^0-9]'), '');

/// Formata uma string de dígitos como CPF (`000.000.000-00`).
String formatCpf(String input) {
  final digits = digitsOnly(input);
  final capped = digits.length > 11 ? digits.substring(0, 11) : digits;
  final buffer = StringBuffer();
  for (var i = 0; i < capped.length; i++) {
    if (i == 3 || i == 6) buffer.write('.');
    if (i == 9) buffer.write('-');
    buffer.write(capped[i]);
  }
  return buffer.toString();
}

/// Formata uma string de dígitos como data brasileira (`dd/mm/aaaa`).
String formatDateBrDigits(String input) {
  final digits = digitsOnly(input);
  final capped = digits.length > 8 ? digits.substring(0, 8) : digits;
  final buffer = StringBuffer();
  for (var i = 0; i < capped.length; i++) {
    if (i == 2 || i == 4) buffer.write('/');
    buffer.write(capped[i]);
  }
  return buffer.toString();
}

/// Converte data ISO (`YYYY-MM-DD` ou timestamp) ou `dd/mm/aaaa` para `dd/mm/aaaa`.
String formatBirthDateToBr(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return '';

  final isoMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(trimmed);
  if (isoMatch != null) {
    return '${isoMatch.group(3)}/${isoMatch.group(2)}/${isoMatch.group(1)}';
  }

  final brMatch = RegExp(r'^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})$')
      .firstMatch(trimmed);
  if (brMatch != null) {
    final day = brMatch.group(1)!.padLeft(2, '0');
    final month = brMatch.group(2)!.padLeft(2, '0');
    final year = brMatch.group(3)!;
    return '$day/$month/$year';
  }

  return formatDateBrDigits(trimmed);
}

/// Converte `dd/mm/aaaa` ou `YYYY-MM-DD` em `YYYY-MM-DD` validado para envio à API.
/// Retorna `null` se a data estiver vazia ou inválida.
String? formatBirthDateToIso(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;

  int? day;
  int? month;
  int? year;

  final brMatch = RegExp(r'^(\d{2})\/(\d{2})\/(\d{4})$').firstMatch(trimmed);
  if (brMatch != null) {
    day = int.tryParse(brMatch.group(1)!);
    month = int.tryParse(brMatch.group(2)!);
    year = int.tryParse(brMatch.group(3)!);
  } else {
    final isoMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(trimmed);
    if (isoMatch != null) {
      year = int.tryParse(isoMatch.group(1)!);
      month = int.tryParse(isoMatch.group(2)!);
      day = int.tryParse(isoMatch.group(3)!);
    }
  }

  if (day == null || month == null || year == null) return null;
  final now = DateTime.now();
  if (year < 1900 || year > now.year) return null;
  if (month < 1 || month > 12) return null;
  if (day < 1 || day > 31) return null;

  final parsed = DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }
  if (parsed.isAfter(now)) return null;

  return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

/// Formata número do Cartão SUS (15 dígitos: `000 0000 0000 0000`).
String formatSusCard(String input) {
  final digits = digitsOnly(input);
  final capped = digits.length > 15 ? digits.substring(0, 15) : digits;
  final buffer = StringBuffer();
  for (var i = 0; i < capped.length; i++) {
    if (i == 3 || i == 7 || i == 11) buffer.write(' ');
    buffer.write(capped[i]);
  }
  return buffer.toString();
}

/// Formata telefone brasileiro (`(00) 0000-0000` ou `(00) 00000-0000`).
String formatPhoneBr(String input) {
  final digits = digitsOnly(input);
  final capped = digits.length > 11 ? digits.substring(0, 11) : digits;
  final buffer = StringBuffer();
  for (var i = 0; i < capped.length; i++) {
    if (i == 0) buffer.write('(');
    if (i == 2) buffer.write(') ');
    if ((capped.length <= 10 && i == 6) || (capped.length > 10 && i == 7)) {
      buffer.write('-');
    }
    buffer.write(capped[i]);
  }
  return buffer.toString();
}

/// Máscara de CPF: `000.000.000-00`.
class CpfInputFormatter extends TextInputFormatter {
  const CpfInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = formatCpf(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Máscara de Data de Nascimento: `dd/mm/aaaa`.
class DateBrInputFormatter extends TextInputFormatter {
  const DateBrInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = formatDateBrDigits(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Máscara de Cartão SUS (CNS): `000 0000 0000 0000`.
class SusCardInputFormatter extends TextInputFormatter {
  const SusCardInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = formatSusCard(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Máscara de Telefone: `(00) 00000-0000`.
class PhoneBrInputFormatter extends TextInputFormatter {
  const PhoneBrInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = formatPhoneBr(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
