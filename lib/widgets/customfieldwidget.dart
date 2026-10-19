import 'package:flutter/material.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';

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
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType ?? TextInputType.text,
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
      style: Theme.of(context).textTheme.headlineMedium,
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
    final ink = WebTheme.inkOf(context);
    final accent = WebTheme.brandOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : null,
          hint: Text(
            hint,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: WebTheme.mutedOf(context),
            ),
          ),
          isExpanded: true,
          dropdownColor: WebTheme.surfaceOf(context),
          iconEnabledColor: accent,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          selectedItemBuilder: (context) {
            return items.map((item) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              );
            }).toList();
          },
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                ),
              )
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

  static Widget timeField({
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
          Icons.access_time,
          color: enabled ? const Color.fromARGB(255, 25, 77, 38) : Colors.grey,
          size: 18,
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
