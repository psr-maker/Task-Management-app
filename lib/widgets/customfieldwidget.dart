import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool isEmail;
  final TextInputType? keyboardType;

  const CustomTextField({
    super.key,
    required this.controller,
    this.isEmail = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // get current theme

    return TextField(
      controller: controller,
      style: Theme.of(context).textTheme.headlineSmall,
      keyboardType:
          keyboardType ??
          (isEmail ? TextInputType.emailAddress : TextInputType.text),
      decoration: InputDecoration(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 10,
        ),
      ),
    );
  }
}

class CustomFormWidgets {
  // ---------- Label ----------
  static Widget label(BuildContext context, String text) {
    return Text(text, style: Theme.of(context).textTheme.headlineLarge);
  }

  // ---------- Text Field ----------
  static Widget textField(
    BuildContext context,
    TextEditingController controller, {
    String? hint,
    int maxLines = 5,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Theme.of(context).textTheme.headlineSmall,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color.fromARGB(255, 25, 77, 38)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color.fromARGB(255, 25, 77, 38)),
        ),
      ),
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  // ---------- Dropdown ----------
  static Widget dropdown({
    required BuildContext context,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String hint = "Select",
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color.fromARGB(255, 25, 77, 38)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey),
          ),
          dropdownColor: Colors.white,
          isExpanded: true,
          style: Theme.of(context).textTheme.headlineSmall,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ---------- Date Field ----------
  static Widget dateField({
    required TextEditingController controller,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      enabled: enabled,
      onTap: enabled ? onTap : null,
      decoration: InputDecoration(
        suffixIcon: Icon(
          Icons.calendar_today,
          color: enabled ? const Color.fromARGB(255, 25, 77, 38) : Colors.grey,
          size: 15,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color.fromARGB(255, 25, 77, 38)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color.fromARGB(255, 25, 77, 38)),
        ),
      ),
      style: TextStyle(
        color: enabled ? const Color.fromARGB(255, 25, 77, 38) : Colors.grey,
      ),
    );
  }
}
