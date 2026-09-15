import 'dart:async';

import 'package:flutter/material.dart';

class DiscoverySearchField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool autofocus;
  final Duration debounce;
  final String hintText;
  const DiscoverySearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.autofocus = false,
    this.debounce = const Duration(milliseconds: 250),
    this.hintText = 'Search what you want to explore',
  });

  @override
  State<DiscoverySearchField> createState() => _DiscoverySearchFieldState();
}

class _DiscoverySearchFieldState extends State<DiscoverySearchField> {
  Timer? timer;
  void changed(String value) {
    timer?.cancel();
    setState(() {});
    if (value.trim().length < 2 || widget.debounce == Duration.zero) {
      widget.onChanged(value);
    } else {
      timer = Timer(widget.debounce, () => widget.onChanged(value));
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x100F766E),
          blurRadius: 12,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: TextField(
      controller: widget.controller,
      autofocus: widget.autofocus,
      onChanged: changed,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: const TextStyle(fontSize: 14),
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: widget.controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close),
                onPressed: () {
                  widget.controller.clear();
                  changed('');
                },
              ),
      ),
    ),
  );
}
