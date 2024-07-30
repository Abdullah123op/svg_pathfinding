import 'dart:math';

import 'package:collection/priority_queue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:svg_pathfinding/utils/logger.dart';
import 'package:xml/xml.dart' as xml;

class SvgSvgPathfindingApp extends StatelessWidget {
  const SvgSvgPathfindingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SVG Pathfinding',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SvgSvgPathfindingScreen(svgAssetPath: 'assets/sample_svg.svg'),
    );
  }
}

class SvgSvgPathfindingScreen extends StatefulWidget {
  final String svgAssetPath;

  const SvgSvgPathfindingScreen({super.key, required this.svgAssetPath});

  @override
  _SvgSvgPathfindingScreenState createState() => _SvgSvgPathfindingScreenState();
}

class _SvgSvgPathfindingScreenState extends State<SvgSvgPathfindingScreen> {
  Offset? _start;
  Offset? _end;
  List<Node> path = [];
  List<List<int>> grid = [];
  String? _currentSvgContent; // Hold the current SVG content as a string
  final int gridSize = 10; // Define the size of each grid cell
  final double svgWidth = 300; // Set width of the SVG for calculations
  final double svgHeight = 300; // Set height of the SVG for calculations

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initialize();
  }

  Future<void> _initialize() async {
    final paths = await parseSvg(widget.svgAssetPath);
    final String svgString = await DefaultAssetBundle.of(context).loadString(widget.svgAssetPath);
    setState(() {
      grid = svgToGrid(paths, gridSize);
      _currentSvgContent = svgString; // Initialize with the original SVG content
    });
  }

  Future<List<xml.XmlElement>> parseSvg(String assetPath) async {
    final String svgString = await DefaultAssetBundle.of(context).loadString(assetPath);
    final xml.XmlDocument document = xml.XmlDocument.parse(svgString);
    final svgRoot = document.rootElement;
    return svgRoot.findAllElements('path').toList();
  }

  List<List<int>> svgToGrid(List<xml.XmlElement> paths, int gridSize) {
    final canvasWidth = svgWidth;
    final canvasHeight = svgHeight;
    final numCols = (canvasWidth / gridSize).ceil();
    final numRows = (canvasHeight / gridSize).ceil();
    final grid = List.generate(numRows, (_) => List.generate(numCols, (_) => 0));

    for (final pathElement in paths) {
      final pathData = pathElement.getAttribute('d');
      final points = parsePathData(pathData);

      for (final point in points) {
        final int x = (point.dx / gridSize).floor();
        final int y = (point.dy / gridSize).floor();

        if (x >= 0 && x < numCols && y >= 0 && y < numRows) {
          grid[y][x] = 1; // Mark as obstacle
        }
      }
    }

    return grid;
  }

  List<Offset> parsePathData(String? pathData) {
    if (pathData == null) return [];

    final points = <Offset>[];
    final commands = pathData.split(RegExp(r'[MmLlZz]')).where((c) => c.isNotEmpty);

    for (final command in commands) {
      final coords = command.trim().split(RegExp(r'\s+|,')).map((s) => double.tryParse(s) ?? 0).toList();
      if (coords.length == 2) {
        points.add(Offset(coords[0], coords[1]));
      }
    }

    return points;
  }

  Future<void> _updatePathfinding(Offset start, Offset end) async {
    final newPath = performPathfinding(grid, start, end);
    final newSvgPath = pathToSvg(newPath, gridSize);

    final originalSvg = await DefaultAssetBundle.of(context).loadString(widget.svgAssetPath);
    final updatedSvg = updateSvg(originalSvg, newSvgPath, newPath);

    setState(() {
      path = newPath;
      _currentSvgContent = updatedSvg;
    });
  }

  List<Node> performPathfinding(List<List<int>> grid, Offset start, Offset end) {
    final startNode = Node(start.dx.toInt(), start.dy.toInt());
    final endNode = Node(end.dx.toInt(), end.dy.toInt());
    return aStar(startNode, endNode, grid);
  }

  String pathToSvg(List<Node> path, int gridSize) {
    final pathCommands = StringBuffer('M');

    for (int i = 0; i < path.length; i++) {
      final node = path[i];
      final x = node.x * gridSize.toDouble();
      final y = node.y * gridSize.toDouble();

      if (i > 0) {
        pathCommands.write(' L');
      }
      pathCommands.write(' $x,$y');
    }

    // Ensure the path string ends with a valid command
    pathCommands.write(' Z'); // Close the path if needed

    return pathCommands.toString();
  }

  String updateSvg(String originalSvg, String newPath, List<Node> path) {
    final xml.XmlDocument document = xml.XmlDocument.parse(originalSvg);
    final svgRoot = document.rootElement;

    // Create new path element
    final newPathElement = xml.XmlElement(
      xml.XmlName('path'),
      [
        xml.XmlAttribute(xml.XmlName('d'), newPath),
        xml.XmlAttribute(xml.XmlName('stroke'), 'red'),
        xml.XmlAttribute(xml.XmlName('fill'), 'none'),
      ],
    );

    svgRoot.children.add(newPathElement);

    // Add circles for start and end points
    if (_start != null && _end != null) {
      svgRoot.children.add(_createCircleElement(_start!, 'blue'));
      svgRoot.children.add(_createCircleElement(_end!, 'green'));
    }

    // Add circles for path points
    for (final node in path) {
      svgRoot.children.add(_createCircleElement(Offset(node.x * gridSize.toDouble(), node.y * gridSize.toDouble()), 'orange'));
    }

    return document.toXmlString(pretty: true);
  }

  xml.XmlElement _createCircleElement(Offset point, String color) {
    final x = point.dx;
    final y = point.dy;

    return xml.XmlElement(
      xml.XmlName('circle'),
      [
        xml.XmlAttribute(xml.XmlName('cx'), x.toString()),
        xml.XmlAttribute(xml.XmlName('cy'), y.toString()),
        xml.XmlAttribute(xml.XmlName('r'), '3'), // Radius of the circle
        xml.XmlAttribute(xml.XmlName('fill'), color)
      ],
    );
  }

  void _onTapDown(TapDownDetails details) {
    final position = details.localPosition;
    final gridPosition = Offset(position.dx / gridSize, position.dy / gridSize);

    print('Tap position: $position');
    print('Grid position: $gridPosition');

    setState(() {
      if (_start == null) {
        _start = gridPosition;
        print('Start point set: $_start');
      } else if (_end == null) {
        _end = gridPosition;
        print('End point set: $_end');
        _updatePathfinding(_start!, _end!);
      } else {
        _start = gridPosition;
        _end = null;
        path = [];
        print('Reset start point: $_start');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Log.e(_currentSvgContent);
    return SafeArea(
      child: Scaffold(
        body: GestureDetector(
          onTapDown: _onTapDown,
          child: Center(
            child: _currentSvgContent == null
                ? const CircularProgressIndicator()
                : SvgPicture.string(
                    _currentSvgContent!,
                    width: svgWidth,
                    height: svgHeight,
                  ),
          ),
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

  return [];
}

double _heuristic(Node a, Node b) {
  return (a.x - b.x).abs() + (a.y - b.y).abs().toDouble();
}

double _distance(Node a, Node b) {
  return sqrt(pow((a.x - b.x).toDouble(), 2) + pow((a.y - b.y).toDouble(), 2));
}

List<Node> _getNeighbors(Node node, List<List<int>> grid) {
  List<Node> neighbors = [];
  List<List<int>> directions = [
    [0, 1],
    [1, 0],
    [0, -1],
    [-1, 0]
  ];

  for (List<int> dir in directions) {
    int nx = node.x + dir[0];
    int ny = node.y + dir[1];

    if (nx >= 0 && ny >= 0 && nx < grid[0].length && ny < grid.length && grid[ny][nx] == 0) {
      neighbors.add(Node(nx, ny));
    }
  }

  return neighbors;
}

List<Node> _reconstructPath(Node current) {
  List<Node> path = [current];
  while (current.parent != null) {
    current = current.parent!;
    path.add(current);
  }
  return path.reversed.toList();
}
