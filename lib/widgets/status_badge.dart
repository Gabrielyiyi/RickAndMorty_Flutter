import 'package:flutter/material.dart';

import '../models/character.dart';
import '../theme/app_theme.dart';

/// Indicador de estado (Vivo / Muerto / Desconocido) con punto de color.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key, this.compact = false});

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.status(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            Character.statusLabel(status),
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
