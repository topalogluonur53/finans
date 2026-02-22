import 'package:flutter/material.dart';

class NumPad extends StatelessWidget {
  final Function(int) onNumberSelected;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;

  const NumPad({
    super.key,
    required this.onNumberSelected,
    required this.onBackspace,
    this.onBiometric,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(context, [1, 2, 3]),
          const SizedBox(height: 16),
          _buildRow(context, [4, 5, 6]),
          const SizedBox(height: 16),
          _buildRow(context, [7, 8, 9]),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSpecialButton(
                context,
                icon: Icons.fingerprint,
                onPressed: onBiometric,
              ),
              _buildNumberButton(context, 0),
              _buildSpecialButton(
                context,
                icon: Icons.backspace_outlined,
                onPressed: onBackspace,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, List<int> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((n) => _buildNumberButton(context, n)).toList(),
    );
  }

  Widget _buildNumberButton(BuildContext context, int number) {
    return InkWell(
      onTap: () => onNumberSelected(number),
      customBorder: const CircleBorder(),
      splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          number.toString(),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialButton(BuildContext context,
      {required IconData icon, VoidCallback? onPressed}) {
    return InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 32,
          color: onPressed != null
              ? Theme.of(context).colorScheme.onSurface
              : Colors.transparent,
        ),
      ),
    );
  }
}
