import 'dart:math';

import 'package:collection/priority_queue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgPathfindingApp extends StatelessWidget {
  const SvgPathfindingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SVG Pathfinding',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SvgPathfindingScreen(svgAssetPath: 'assets/sample_svg.svg'),
    );
  }
}

class SvgPathfindingScreen extends StatefulWidget {
  final String svgAssetPath;

  const SvgPathfindingScreen({super.key, required this.svgAssetPath});

  @override
  _SvgPathfindingScreenState createState() => _SvgPathfindingScreenState();
}

class _SvgPathfindingScreenState extends State<SvgPathfindingScreen> {
  Offset? _start;
  Offset? _end;
  List<Node> path = [];
  List<List<int>> grid = [];
  List<Offset?> obstaclePoints = [];
  final int gridSize = 5; // Define the size of each grid cell
  bool isPlacingObstacles = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    grid = _generateGrid();
  }

  List<List<int>> _generateGrid() {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    int rows = (height / gridSize).floor();
    int cols = (width / gridSize).floor();

    return List.generate(rows, (i) => List.generate(cols, (j) => 0));
  }

  void _updateGridWithObstacles() {
    if (obstaclePoints.length < 2) return;

    // Clear existing obstacles
    grid = _generateGrid();

    for (int i = 0; i < obstaclePoints.length - 1; i++) {
      Offset start = obstaclePoints[i]!;
      Offset end = obstaclePoints[i + 1]!;

      // Ensure start and end positions are valid
      if (start.dx.isNaN || start.dy.isNaN || end.dx.isNaN || end.dy.isNaN) continue;

      final double dx = (end.dx - start.dx).abs();
      final double dy = (end.dy - start.dy).abs();
      final int steps = max(dx, dy).toInt();

      for (int step = 0; step <= steps; step++) {
        final double t = step / steps;
        final double x = start.dx + t * (end.dx - start.dx);
        final double y = start.dy + t * (end.dy - start.dy);

        // Ensure x and y are within bounds
        if (x < 0 || x >= grid[0].length || y < 0 || y >= grid.length) continue;

        grid[y.toInt()][x.toInt()] = 1; // Mark the grid cell as an obstacle
      }
    }
  }

  void _toggleObstacleMode() {
    setState(() {
      if (isPlacingObstacles) {
        _updateGridWithObstacles();
      }
      isPlacingObstacles = !isPlacingObstacles;
      if (!isPlacingObstacles) {
        obstaclePoints.clear();
      }
    });
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      if (isPlacingObstacles) {
        Offset position = _getGridPosition(details.localPosition);
        if (position.dx.isFinite && position.dy.isFinite) {
          obstaclePoints.add(position);
        }
      } else if (_start == null) {
        _start = _getGridPosition(details.localPosition);
      } else if (_end == null) {
        _end = _getGridPosition(details.localPosition);
        path = aStar(
          Node(_start!.dx.toInt(), _start!.dy.toInt()),
          Node(_end!.dx.toInt(), _end!.dy.toInt()),
          grid,
        );
      } else {
        _start = _getGridPosition(details.localPosition);
        _end = null;
        path = [];
      }
    });
  }

  Offset _getGridPosition(Offset position) {
    int x = (position.dx / gridSize).floor();
    int y = (position.dy / gridSize).floor();
    return Offset(x.toDouble(), y.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 30.0),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _toggleObstacleMode,
                    child: Text(isPlacingObstacles ? 'Placing Obstacles' : 'Add Obstacle'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTapDown: _onTapDown,
                child: Center(
                  child: Stack(
                    children: [
                      SvgPicture.asset(
                        widget.svgAssetPath,
                        width: double.infinity,
                      ),
                      CustomPaint(
                        painter: PathPainter(_start, _end, path, gridSize, grid, obstaclePoints),
                        child: const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Node {
  final int x;
  final int y;
  double g = double.infinity;
  double h = double.infinity;
  Node? parent;

  Node(this.x, this.y);

  double get f => g + h;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Node && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

List<Node> aStar(Node start, Node goal, List<List<int>> grid) {
  PriorityQueue<Node> openSet = PriorityQueue((a, b) => a.f.compareTo(b.f));
  Set<Node> closedSet = {};

  start.g = 0;
  start.h = _heuristic(start, goal);
  openSet.add(start);

  while (openSet.isNotEmpty) {
    Node current = openSet.removeFirst();
    if (current == goal) {
      return _reconstructPath(current);
    }

    closedSet.add(current);

    for (Node neighbor in _getNeighbors(current, grid)) {
      if (closedSet.contains(neighbor)) {
        continue;
      }

      double tentativeG = current.g + _distance(current, neighbor);

      if (tentativeG < neighbor.g) {
        neighbor.parent = current;
        neighbor.g = tentativeG;
        neighbor.h = _heuristic(neighbor, goal);

        if (!openSet.contains(neighbor)) {
          openSet.add(neighbor);
        }
      }
    }
  }

  // No path found, return an empty list
  return [];
}

double _heuristic(Node a, Node b) {
  return (a.x - b.x).abs() + (a.y - b.y).abs().toDouble();
}

double _distance(Node a, Node b) {
  return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
}

List<Node> _getNeighbors(Node node, List<List<int>> grid) {
  List<Node> neighbors = [];
  int rows = grid.length;
  if (rows == 0) return neighbors;

  int cols = grid[0].length;

  for (int dx = -1; dx <= 1; dx++) {
    for (int dy = -1; dy <= 1; dy++) {
      if (dx == 0 && dy == 0) continue;

      int newX = node.x + dx;
      int newY = node.y + dy;

      if (newX >= 0 && newX < cols && newY >= 0 && newY < rows && grid[newY][newX] == 0) {
        neighbors.add(Node(newX, newY));
      }
    }
  }

  return neighbors;
}

List<Node> _reconstructPath(Node? node) {
  List<Node> path = [];
  while (node != null) {
    path.add(node);
    node = node.parent;
  }
  return path.reversed.toList();
}

class PathPainter extends CustomPainter {
  final Offset? start;
  final Offset? end;
  final List<Node> path;
  final int gridSize;
  final List<List<int>> grid;
  final List<Offset?> obstaclePoints;

  PathPainter(this.start, this.end, this.path, this.gridSize, this.grid, this.obstaclePoints);

  @override
  void paint(Canvas canvas, Size size) {
    final pathPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pointPaintStart = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final pointPaintEnd = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    final obstaclePaint = Paint()
      ..color = Colors.red.withOpacity(0.5) // Make obstacle color semi-transparent
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    // Draw obstacles first
    if (obstaclePoints.isNotEmpty) {
      Path obstaclePath = Path();

      for (int i = 0; i < obstaclePoints.length - 1; i++) {
        Offset start = obstaclePoints[i]!;
        Offset end = obstaclePoints[i + 1]!;

        // Ensure start and end positions are valid
        if (start.dx.isNaN || start.dy.isNaN || end.dx.isNaN || end.dy.isNaN) continue;

        if (i == 0) {
          obstaclePath.moveTo(start.dx * gridSize, start.dy * gridSize);
        } else {
          final prev = obstaclePoints[i - 1]!;
          final curr = obstaclePoints[i]!;
          final next = obstaclePoints[i + 1]!;

          final prevVector = Offset(curr.dx - prev.dx, curr.dy - prev.dy);
          final nextVector = Offset(next.dx - curr.dx, next.dy - curr.dy);

          final angleDiff = prevVector.direction - nextVector.direction;
          if (angleDiff.abs() > pi / 6) {
            // Adjust angle threshold as needed
            final controlPoint1 = Offset(
              curr.dx * gridSize + (prev.dx - curr.dx) * gridSize * 0.5,
              curr.dy * gridSize + (prev.dy - curr.dy) * gridSize * 0.5,
            );

            final controlPoint2 = Offset(
              curr.dx * gridSize + (next.dx - curr.dx) * gridSize * 0.5,
              curr.dy * gridSize + (next.dy - curr.dy) * gridSize * 0.5,
            );

            obstaclePath.cubicTo(
              controlPoint1.dx,
              controlPoint1.dy,
              controlPoint2.dx,
              controlPoint2.dy,
              end.dx * gridSize,
              end.dy * gridSize,
            );
          } else {
            obstaclePath.lineTo(end.dx * gridSize, end.dy * gridSize);
          }
        }
      }

      canvas.drawPath(obstaclePath, obstaclePaint);
    }

    // Draw path after obstacles to ensure it's on top
    if (path.isNotEmpty) {
      Path pathToDraw = Path();
      pathToDraw.moveTo(path[0].x * gridSize.toDouble(), path[0].y * gridSize.toDouble());

      for (int i = 0; i < path.length - 2; i++) {
        var current = path[i];
        var next = path[i + 1];
        var afterNext = path[i + 2];

        if ((current.x - next.x != next.x - afterNext.x) || (current.y - next.y != next.y - afterNext.y)) {
          // Add a quadratic bezier curve if direction changes
          double midX = (next.x + afterNext.x) / 2 * gridSize.toDouble();
          double midY = (next.y + afterNext.y) / 2 * gridSize.toDouble();
          pathToDraw.quadraticBezierTo(
            next.x * gridSize.toDouble(),
            next.y * gridSize.toDouble(),
            midX,
            midY,
          );
        } else {
          pathToDraw.lineTo(next.x * gridSize.toDouble(), next.y * gridSize.toDouble());
        }
      }

      // Draw the final line
      pathToDraw.lineTo(path.last.x * gridSize.toDouble(), path.last.y * gridSize.toDouble());

      canvas.drawPath(pathToDraw, pathPaint);
    }

    if (start != null) {
      canvas.drawCircle(
        Offset(start!.dx * gridSize, start!.dy * gridSize),
        5,
        pointPaintStart,
      );
    }

    if (end != null) {
      canvas.drawCircle(
        Offset(end!.dx * gridSize, end!.dy * gridSize),
        5,
        pointPaintEnd,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
