import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../providers/assistant_provider.dart';

class AiOrbWidget extends StatefulWidget {
  final AssistantState state;
  final VoidCallback onTap;

  const AiOrbWidget({
    Key? key,
    required this.state,
    required this.onTap,
  }) : super(key: key);

  @override
  State<AiOrbWidget> createState() => _AiOrbWidgetState();
}

class _AiOrbWidgetState extends State<AiOrbWidget> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    // Spinning rotation for thinking state
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Pulse/breathing for speaking and idle states
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // High speed waves for listening state
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    
    _applyStateSpeeds();
  }

  @override
  void didUpdateWidget(covariant AiOrbWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _applyStateSpeeds();
  }

  // Adjust animation speeds dynamically on state transitions
  void _applyStateSpeeds() {
    if (widget.state == AssistantState.thinking) {
      _rotationController.duration = const Duration(seconds: 1);
      _rotationController.repeat();
    } else if (widget.state == AssistantState.executing) {
      _rotationController.duration = const Duration(milliseconds: 400); // Super fast rotation
      _rotationController.repeat();
    } else {
      _rotationController.duration = const Duration(seconds: 4);
      _rotationController.repeat();
    }

    if (widget.state == AssistantState.listening) {
      _pulseController.duration = const Duration(milliseconds: 800);
      _pulseController.repeat(reverse: true);
    } else if (widget.state == AssistantState.speaking) {
      _pulseController.duration = const Duration(milliseconds: 450);
      _pulseController.repeat(reverse: true);
    } else if (widget.state == AssistantState.executing) {
      _pulseController.duration = const Duration(milliseconds: 200); // Fast overload pulsing
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.duration = const Duration(milliseconds: 2000);
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _getOrbColor().withOpacity(0.08),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _rotationController,
            _pulseController,
            _waveController,
          ]),
          builder: (context, child) {
            return CustomPaint(
              painter: OrbPainter(
                state: widget.state,
                rotationVal: _rotationController.value,
                pulseVal: _pulseController.value,
                waveVal: _waveController.value,
                baseColor: _getOrbColor(),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getOrbColor() {
    switch (widget.state) {
      case AssistantState.listening:
        return const Color(0xFF00FF9D); // Neon Green (Listening)
      case AssistantState.thinking:
        return const Color(0xFFFF9F0A); // Neon Amber (Thinking)
      case AssistantState.speaking:
        return const Color(0xFFBF5AF2); // Purple Bloom (Speaking)
      case AssistantState.executing:
        return const Color(0xFFFF375F); // Cyber Red/Pink (Action Launching)
      case AssistantState.idle:
      default:
        return const Color(0xFF00FFF0); // Cyber Cyan (Idle)
    }
  }
}

class OrbPainter extends CustomPainter {
  final AssistantState state;
  final double rotationVal;
  final double pulseVal;
  final double waveVal;
  final Color baseColor;

  OrbPainter({
    required this.state,
    required this.rotationVal,
    required this.pulseVal,
    required this.waveVal,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;

    // Draw central glowing background blobs
    final bgGlowPaint = Paint()
      ..color = baseColor.withOpacity(0.1 + (pulseVal * 0.1))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
    canvas.drawCircle(center, maxRadius * 0.65, bgGlowPaint);

    // 1. Draw outer dashboard cyber-ring
    final ringPaint = Paint()
      ..color = baseColor.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, maxRadius * 0.9, ringPaint);

    // 2. Draw rotating orbital segments (thinking/scanning style)
    final orbitalPaint = Paint()
      ..color = baseColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final double sweepAngle = math.pi * 0.35;
    final double startAngle1 = rotationVal * 2 * math.pi;
    final double startAngle2 = startAngle1 + math.pi;
    final double startAngle3 = -startAngle1 + (math.pi / 2);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: maxRadius * 0.82),
      startAngle1,
      sweepAngle,
      false,
      orbitalPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: maxRadius * 0.82),
      startAngle2,
      sweepAngle,
      false,
      orbitalPaint,
    );
    // Draw counter-rotating ring
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: maxRadius * 0.74),
      startAngle3,
      sweepAngle * 1.3,
      false,
      orbitalPaint..color = baseColor.withOpacity(0.35),
    );

    // 3. Draw active state effects
    if (state == AssistantState.listening) {
      // Draw dynamic microphone frequency wave lines
      final wavePaint = Paint()
        ..color = baseColor.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final path = Path();
      const int pointsCount = 60;
      final double waveAmplitude = 12.0 * pulseVal;
      final double innerRadius = maxRadius * 0.45;

      for (int i = 0; i <= pointsCount; i++) {
        final double theta = (i / pointsCount) * 2 * math.pi;
        final double waveOffset = math.sin(theta * 8 + (waveVal * 2 * math.pi)) * waveAmplitude;
        final double r = innerRadius + waveOffset;
        final double x = center.dx + r * math.cos(theta);
        final double y = center.dy + r * math.sin(theta);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, wavePaint);
    } 
    else if (state == AssistantState.speaking) {
      // Draw concentric expanding voice ripple pulses
      final ripplePaint = Paint()
        ..color = baseColor.withOpacity(1.0 - pulseVal)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      final double rippleRadius = maxRadius * 0.45 + (pulseVal * maxRadius * 0.35);
      canvas.drawCircle(center, rippleRadius, ripplePaint);
      
      // Secondary speaking pulse
      final double rippleRadius2 = maxRadius * 0.45 + (((pulseVal + 0.5) % 1.0) * maxRadius * 0.35);
      canvas.drawCircle(center, rippleRadius2, ripplePaint..color = baseColor.withOpacity(1.0 - ((pulseVal + 0.5) % 1.0)));
    }
    else if (state == AssistantState.executing) {
      // Draw intense reactor scan crosshairs and fast ripples for action execution
      final ripplePaint = Paint()
        ..color = baseColor.withOpacity(1.0 - pulseVal)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      final double rippleRadius = maxRadius * 0.35 + (pulseVal * maxRadius * 0.55);
      canvas.drawCircle(center, rippleRadius, ripplePaint);

      // Draw crosshair laser lines spinning
      final laserPaint = Paint()
        ..color = baseColor.withOpacity(0.3)
        ..strokeWidth = 1.0;
      
      for (int i = 0; i < 8; i++) {
        final double angle = i * math.pi / 4 + rotationVal * 2 * math.pi;
        final start = Offset(center.dx + maxRadius * 0.38 * math.cos(angle), center.dy + maxRadius * 0.38 * math.sin(angle));
        final end = Offset(center.dx + maxRadius * 0.95 * math.cos(angle), center.dy + maxRadius * 0.95 * math.sin(angle));
        canvas.drawLine(start, end, laserPaint);
      }
    }

    // 4. Draw Core circular engine
    final coreGlowPaint = Paint()
      ..color = baseColor.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, maxRadius * 0.38 + (pulseVal * 4.0), coreGlowPaint);

    final solidCorePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius * 0.35, solidCorePaint);

    // Inner bright center core
    final whiteCorePaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius * 0.2, whiteCorePaint);
  }

  @override
  bool shouldRepaint(covariant OrbPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.rotationVal != rotationVal ||
        oldDelegate.pulseVal != pulseVal ||
        oldDelegate.waveVal != waveVal ||
        oldDelegate.baseColor != baseColor;
  }
}
