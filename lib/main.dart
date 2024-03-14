import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() => runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LineDrawingScreen(),
    );
  }
}

final lineStateProvider =
    StateNotifierProvider<LineStateNotifier, List<Offset>>(
  (ref) => LineStateNotifier(),
);

class LineStateNotifier extends StateNotifier<List<Offset>> {
  LineStateNotifier() : super([]);

  void addPoint(Offset point) {
    if (state.isNotEmpty && _doesNewLineIntersectAny(point)) {
      if (kDebugMode) {
        print('Действие отменено - новая линия пересечет ранее созданную');
      }
    } else {
      state = [...state, point];
    }
  }

  bool _doesNewLineIntersectAny(Offset newPoint) {
    if (state.length < 2) {
      return false; // нужно минимум 2 точки для сегмента
    }

    // новый сегмент от последней точки в списке - к новой точке
    LineSegment newSegment = LineSegment(
      state.last,
      newPoint,
    );

    // проверка на пересечение с каждым сегментом в списке
    for (int i = 0; i < state.length - 2; i++) {
      LineSegment existingSegment = LineSegment(state[i], state[i + 1]);
      if (newSegment.intersects(existingSegment)) {
        return true;
      }
    }

    return false;
  }
}

class LineSegment {
  Offset p1;
  Offset p2;

  LineSegment(this.p1, this.p2);

  bool intersects(LineSegment other) {
    double s1x, s1y, s2x, s2y;
    s1x = p2.dx - p1.dx;
    s1y = p2.dy - p1.dy;
    s2x = other.p2.dx - other.p1.dx;
    s2y = other.p2.dy - other.p1.dy;

    double s, t;
    s = (-s1y * (p1.dx - other.p1.dx) + s1x * (p1.dy - other.p1.dy)) /
        (-s2x * s1y + s1x * s2y);
    t = (s2x * (p1.dy - other.p1.dy) - s2y * (p1.dx - other.p1.dx)) /
        (-s2x * s1y + s1x * s2y);

    return s >= 0 && s <= 1 && t >= 0 && t <= 1;
  }
}

class LineDrawingScreen extends ConsumerWidget {
  const LineDrawingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linePoints = ref.watch(lineStateProvider);
    return Scaffold(
      body: GestureDetector(
        onTapUp: (details) {
          ref.read(lineStateProvider.notifier).addPoint(details.localPosition);
        },
        child: CustomPaint(
          painter: LinePainter(linePoints),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class LinePainter extends CustomPainter {
  final List<Offset> points;
  LinePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4;
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
