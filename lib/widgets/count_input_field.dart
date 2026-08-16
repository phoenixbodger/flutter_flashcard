import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CountInputField extends StatefulWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String label;
  final String? helperText;

  const CountInputField({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.label,
    this.helperText,
  });

  @override
  State<CountInputField> createState() => _CountInputFieldState();
}

class _CountInputFieldState extends State<CountInputField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(CountInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !_focusNode.hasFocus) {
      _controller.text = '${widget.value}';
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _commitText();
    }
  }

  void _commitText() {
    final parsed = int.tryParse(_controller.text);
    final clamped = (parsed ?? widget.value).clamp(widget.min, widget.max);
    if (_controller.text != '$clamped') {
      _controller.text = '$clamped';
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    }
    if (clamped != widget.value) {
      widget.onChanged(clamped);
    }
  }

  void _onTextChanged(String text) {
    final parsed = int.tryParse(text);
    if (parsed == null) return;

    if (parsed > widget.max) {
      _controller.text = '${widget.max}';
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
      if (widget.max != widget.value) {
        widget.onChanged(widget.max);
      }
      return;
    }

    if (parsed >= widget.min && parsed != widget.value) {
      widget.onChanged(parsed);
    }
  }

  void _onSliderChanged(double value) {
    final newValue = value.round();
    _controller.text = '$newValue';
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    if (newValue != widget.value) {
      widget.onChanged(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveMax = widget.max < widget.min ? widget.min : widget.max;
    final effectiveMin = widget.min > effectiveMax ? effectiveMax : widget.min;
    final effectiveValue = widget.value.clamp(effectiveMin, effectiveMax);
    final sliderDivisions =
        effectiveMax > effectiveMin ? effectiveMax - effectiveMin : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: widget.label,
            helperText: widget.helperText,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: _onTextChanged,
          onSubmitted: (_) => _commitText(),
        ),
        Slider(
          value: effectiveValue.toDouble(),
          min: effectiveMin.toDouble(),
          max: effectiveMax.toDouble(),
          divisions: sliderDivisions,
          label: '$effectiveValue',
          onChanged: _onSliderChanged,
        ),
      ],
    );
  }
}
