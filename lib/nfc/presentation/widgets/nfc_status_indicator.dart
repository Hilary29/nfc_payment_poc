import 'package:flutter/material.dart';

enum NfcStatus {
  idle,
  scanning,
  emitting,
  success,
  error,
}

class NfcStatusIndicator extends StatefulWidget {
  final NfcStatus status;
  final String message;

  const NfcStatusIndicator({
    super.key,
    required this.status,
    required this.message,
  });

  @override
  State<NfcStatusIndicator> createState() => _NfcStatusIndicatorState();
}

class _NfcStatusIndicatorState extends State<NfcStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.status == NfcStatus.scanning ||
        widget.status == NfcStatus.emitting) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(NfcStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == NfcStatus.scanning ||
        widget.status == NfcStatus.emitting) {
      _animationController.repeat();
    } else {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getColor() {
    switch (widget.status) {
      case NfcStatus.idle:
        return Colors.grey;
      case NfcStatus.scanning:
      case NfcStatus.emitting:
        return Colors.blue;
      case NfcStatus.success:
        return Colors.green;
      case NfcStatus.error:
        return Colors.red;
    }
  }

  IconData _getIcon() {
    switch (widget.status) {
      case NfcStatus.idle:
        return Icons.nfc;
      case NfcStatus.scanning:
      case NfcStatus.emitting:
        return Icons.wifi_tethering;
      case NfcStatus.success:
        return Icons.check_circle;
      case NfcStatus.error:
        return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final isAnimating = widget.status == NfcStatus.scanning ||
        widget.status == NfcStatus.emitting;

    return Card(
      elevation: 2,
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAnimating)
              RotationTransition(
                turns: _animationController,
                child: Icon(
                  _getIcon(),
                  size: 64,
                  color: color,
                ),
              )
            else
              Icon(
                _getIcon(),
                size: 64,
                color: color,
              ),
            const SizedBox(height: 16),
            Text(
              widget.message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
