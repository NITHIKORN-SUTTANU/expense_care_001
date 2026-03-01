import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable text field with inline validation display (per requirements).
/// Error shown below field, border changes to error color on invalid state.
/// Validates live only while the field is focused.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
    this.prefixText,
    this.maxLength,
    this.inputFormatters,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.focusNode,
    this.autovalidateMode,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? prefixText;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final bool autofocus;
  final int maxLines;
  final FocusNode? focusNode;
  /// Override the default focus-based autovalidate behaviour.
  final AutovalidateMode? autovalidateMode;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  FocusNode? _internalFocusNode;
  bool _isFocused = false;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);
      if (oldWidget.focusNode == null) {
        _internalFocusNode?.removeListener(_onFocusChange);
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      }
      _effectiveFocusNode.addListener(_onFocusChange);
      setState(() => _isFocused = _effectiveFocusNode.hasFocus);
    }
  }

  void _onFocusChange() {
    setState(() => _isFocused = _effectiveFocusNode.hasFocus);
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      validator: widget.validator,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      maxLines: widget.maxLines,
      focusNode: _effectiveFocusNode,
      autovalidateMode: widget.autovalidateMode ??
          (_isFocused
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: widget.errorText,
        errorMaxLines: 3,
        suffixIcon: widget.suffixIcon,
        prefixIcon: widget.prefixIcon,
        prefixText: widget.prefixText,
        counterText: widget.maxLength != null ? null : '',
      ),
    );
  }
}
