import 'package:flutter/material.dart';

class MobileKeyboardToolbar extends StatelessWidget {
  final void Function(String key) onKey;

  const MobileKeyboardToolbar({super.key, required this.onKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        children: [
          _ToolbarButton('Ctrl', () => onKey('\x01'), isModifier: true),
          _ToolbarButton('Alt', () => onKey('\x1b'), isModifier: true),
          _ToolbarButton('Esc', () => onKey('\x1b')),
          _ToolbarButton('Tab', () => onKey('\t')),
          _ToolbarButton('|', () => onKey('|')),
          _ToolbarButton('~', () => onKey('~')),
          _ToolbarButton('/', () => onKey('/')),
          _ToolbarButton('-', () => onKey('-')),
          _ToolbarButton('\u2191', () => onKey('\x1b[A')), // Up
          _ToolbarButton('\u2193', () => onKey('\x1b[B')), // Down
          _ToolbarButton('\u2190', () => onKey('\x1b[D')), // Left
          _ToolbarButton('\u2192', () => onKey('\x1b[C')), // Right
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isModifier;

  const _ToolbarButton(this.label, this.onTap, {this.isModifier = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: isModifier
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            constraints: const BoxConstraints(minWidth: 40),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isModifier ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
