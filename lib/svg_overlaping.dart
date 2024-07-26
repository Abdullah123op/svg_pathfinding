import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:svg_pathfinding/utils/logger.dart';

import 'html_demo.dart';

const double svgWidth = 400; // Set width of the SVG for calculations
const double svgHeight = 400; // Set height of the SVG for calculations

class SvgOverlaping extends StatelessWidget {
  const SvgOverlaping({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SVG Overlaping',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SvgOverlapingScreen(),
    );
  }
}

class SvgOverlapingScreen extends StatefulWidget {
  const SvgOverlapingScreen({super.key});

  @override
  State<SvgOverlapingScreen> createState() => _SvgOverlapingScreenState();
}

class _SvgOverlapingScreenState extends State<SvgOverlapingScreen> {
  String svgAssetPath = 'assets/sample_svg.svg';
  String? _currentSvgContent;

  String svgString = '''
<svg width="$svgWidth" height="$svgHeight" xmlns="http://www.w3.org/2000/svg">
 <rect x="0" y="0" width="$svgWidth" height="$svgHeight" fill="none" stroke="black" stroke-width="2"/>
  <g id="gedge"></g>
  <g id="gvertex"></g>
</svg>
  ''';

  List<Vertex> vertices = [];
  List<Edge> edges = [];
  Vertex? startVertex;
  Vertex? selectedVertex;
  int edgeCost = 1;
  WorkMode? workMode = WorkMode.drawVertex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initialize();
  }

  Future<void> _initialize() async {
    final String svgString = await DefaultAssetBundle.of(context).loadString(svgAssetPath);
    setState(() {
      _currentSvgContent = svgString; // Initialize with the original SVG content
    });
  }

  @override
  Widget build(BuildContext context) {
    // Log.e(_currentSvgContent);
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTapDown: _onTapDown,
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          SvgPicture.string(
                            _currentSvgContent!,
                            width: svgWidth,
                            height: svgHeight,
                          ),
                          SvgPicture.string(
                            svgString,
                            width: svgWidth,
                            height: svgHeight,
                            fit: BoxFit.cover,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ButtonBar(
              alignment: MainAxisAlignment.center,
              children: <Widget>[
                Radio(
                  value: WorkMode.drawVertex,
                  groupValue: workMode,
                  onChanged: (WorkMode? value) {
                    setState(() {
                      workMode = value!;
                    });
                  },
                ),
                const Text('Draw vertex'),
                Radio(
                  value: WorkMode.drawEdge,
                  groupValue: workMode,
                  onChanged: (value) {
                    setState(() {
                      workMode = value;
                    });
                  },
                ),
                const Text('Draw edge'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onTapDown(TapDownDetails details) {
    final position = details.localPosition;
    // final gridPosition = Offset(position.dx / gridSize, position.dy / gridSize);
    final x = details.localPosition.dx;
    final y = details.localPosition.dy;

    // Log.e('Tap position: $position');
    // drawVertex(details.localPosition.dx, details.localPosition.dy);

    switch (workMode) {
      case WorkMode.drawVertex:
        drawVertex(x, y);
        break;
      case WorkMode.drawEdge:
        drawEdge(x, y);
        break;
      case WorkMode.setStart:
        // Handle setting start vertex
        break;
      case WorkMode.delVertexEdge:
        // Handle deleting vertex or edge
        break;
      case WorkMode.setCostLabel:
        // Handle setting cost or label
        break;
      case null:
    }
  }

  void drawVertex(double x, double y) {
    // Adjust coordinates based on the SVG coordinate system if necessary
    final adjustedX = x;
    final adjustedY = y;
    final vertex = Vertex(adjustedX, adjustedY, String.fromCharCode(65 + vertices.length));
    Log.e('Adding vertex at: ($adjustedX, $adjustedY)');
    setState(() {
      vertices.add(vertex);
      updateSvg();
    });
  }

  void drawEdge(double x, double y) {
    final vertex = getVertexAt(x, y);
    if (vertex != null) {
      if (selectedVertex == null) {
        selectedVertex = vertex;
      } else {
        final edge = Edge(selectedVertex!, vertex, edgeCost);
        Log.e('Adding edge: $edge');
        setState(() {
          edges.add(edge);
          selectedVertex = null;
          updateSvg();
        });
      }
    } else {
      setState(() {
        selectedVertex = null;
      });
    }
  }

  Vertex? getVertexAt(double x, double y) {
    const double tolerance = 20;
    try {
      return vertices.firstWhere(
        (vertex) => (vertex.x - x).abs() < tolerance && (vertex.y - y).abs() < tolerance,
      );
    } catch (e) {
      return null;
    }
  }

  void updateSvg() {
    final vertexElements = vertices.map((v) {
      return '''
<circle cx="${v.x}" cy="${v.y}" r="7" fill="red" stroke="black" stroke-width="1"/>
      ''';
    }).join();

    final edgeElements = edges.map((e) {
      return '''
<line x1="${e.from.x}" y1="${e.from.y}" x2="${e.to.x}" y2="${e.to.y}" stroke="skyblue" stroke-width="6" />
<text x="${(e.from.x + e.to.x) / 2}" y="${(e.from.y + e.to.y) / 2}" text-anchor="middle" alignment-baseline="central" font-size="0" fill="black">${e.cost}</text>
      ''';
    }).join();

    setState(() {
      svgString = '''
<svg width="$svgWidth" height="$svgHeight" xmlns="http://www.w3.org/2000/svg">
 <rect x="0" y="0" width="$svgWidth" height="$svgHeight" fill="none" stroke="black" stroke-width="2"/>
  <g id="gedge">$edgeElements</g>
  <g id="gvertex">$vertexElements</g>
</svg>
      ''';
    });
  }
}
