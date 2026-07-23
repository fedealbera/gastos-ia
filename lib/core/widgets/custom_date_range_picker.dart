import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Only allow digits. Strip everything else.
    final cleanText = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Limit to 8 digits (DDMMYYYY)
    final digits = cleanText.length > 8 ? cleanText.substring(0, 8) : cleanText;

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 4) {
        buffer.write('/');
      }
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();

    // Map the cursor offset from the unformatted text to the formatted text.
    int digitsBeforeCursor = 0;
    for (int i = 0; i < newValue.selection.end && i < newValue.text.length; i++) {
      if (RegExp(r'\d').hasMatch(newValue.text[i])) {
        digitsBeforeCursor++;
      }
    }

    int formattedOffset = 0;
    int digitsCount = 0;
    while (digitsCount < digitsBeforeCursor && formattedOffset < formatted.length) {
      if (formatted[formattedOffset] != '/') {
        digitsCount++;
      }
      formattedOffset++;
    }

    // Move cursor past the slash if we are adding text and the next character is a slash
    if (formattedOffset < formatted.length &&
        formatted[formattedOffset] == '/' &&
        newValue.text.length > oldValue.text.length) {
      formattedOffset++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formattedOffset),
    );
  }
}

Future<DateTimeRange?> showCustomDateRangePicker({
  required BuildContext context,
  DateTimeRange? initialDateRange,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  return showDialog<DateTimeRange>(
    context: context,
    builder: (BuildContext context) {
      return _CustomDateRangeDialog(
        initialDateRange: initialDateRange,
        firstDate: firstDate,
        lastDate: lastDate,
      );
    },
  );
}

class _CustomDateRangeDialog extends StatefulWidget {
  final DateTimeRange? initialDateRange;
  final DateTime firstDate;
  final DateTime lastDate;

  const _CustomDateRangeDialog({
    this.initialDateRange,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_CustomDateRangeDialog> createState() => _CustomDateRangeDialogState();
}

class _CustomDateRangeDialogState extends State<_CustomDateRangeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _startController;
  late TextEditingController _endController;

  @override
  void initState() {
    super.initState();
    final startStr = widget.initialDateRange != null
        ? DateFormat('dd/MM/yyyy').format(widget.initialDateRange!.start)
        : '';
    final endStr = widget.initialDateRange != null
        ? DateFormat('dd/MM/yyyy').format(widget.initialDateRange!.end)
        : '';
    _startController = TextEditingController(text: startStr);
    _endController = TextEditingController(text: endStr);
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String val) {
    try {
      final parts = val.split('/');
      if (parts.length != 3) return null;
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day == null || month == null || year == null) return null;
      if (month < 1 || month > 12) return null;
      if (day < 1 || day > 31) return null;
      
      final testDate = DateTime(year, month, day);
      if (testDate.day != day || testDate.month != month || testDate.year != year) {
        return null;
      }
      return testDate;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickDate(TextEditingController controller, DateTime? initial) async {
    DateTime safeInitial = initial ?? DateTime.now();
    if (safeInitial.isBefore(widget.firstDate)) {
      safeInitial = widget.firstDate;
    } else if (safeInitial.isAfter(widget.lastDate)) {
      safeInitial = widget.lastDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar Período'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8.0),
              TextFormField(
                controller: _startController,
                keyboardType: TextInputType.number,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                inputFormatters: [
                  DateInputFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: 'Fecha Inicio',
                  hintText: 'DD/MM/AAAA',
                  prefixIcon: const Icon(Icons.date_range_rounded),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_month_rounded),
                    onPressed: () {
                      final parsed = _parseDate(_startController.text);
                      _pickDate(_startController, parsed);
                    },
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Ingresa la fecha de inicio';
                  }
                  final parsed = _parseDate(val);
                  if (parsed == null) {
                    return 'Formato inválido (DD/MM/AAAA)';
                  }
                  if (parsed.isBefore(widget.firstDate) || parsed.isAfter(widget.lastDate)) {
                    return 'Fecha fuera de rango';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _endController,
                keyboardType: TextInputType.number,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                inputFormatters: [
                  DateInputFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: 'Fecha Fin',
                  hintText: 'DD/MM/AAAA',
                  prefixIcon: const Icon(Icons.date_range_rounded),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_month_rounded),
                    onPressed: () {
                      final parsed = _parseDate(_endController.text);
                      _pickDate(_endController, parsed);
                    },
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Ingresa la fecha de fin';
                  }
                  final parsed = _parseDate(val);
                  if (parsed == null) {
                    return 'Formato inválido (DD/MM/AAAA)';
                  }
                  if (parsed.isBefore(widget.firstDate) || parsed.isAfter(widget.lastDate)) {
                    return 'Fecha fuera de rango';
                  }
                  final startParsed = _parseDate(_startController.text);
                  if (startParsed != null && parsed.isBefore(startParsed)) {
                    return 'Debe ser posterior a la fecha de inicio';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState?.validate() == true) {
              final start = _parseDate(_startController.text)!;
              final end = _parseDate(_endController.text)!;
              Navigator.of(context).pop(DateTimeRange(start: start, end: end));
            }
          },
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}
