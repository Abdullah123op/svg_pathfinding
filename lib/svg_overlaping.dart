import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:svg_pathfinding/utils/logger.dart';
import 'package:xml/xml.dart' as xml;

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

  // List<Vertex> vertices = [
  //   Vertex(218.74438339313542, 338.1165745765152, 'A'),
  //   Vertex(216.77128932398864, 201.79371161728358, 'B'),
  //   Vertex(325.3811492211133, 192.28698564775823, 'C'),
  //   Vertex(56.950669723100035, 204.03586396858674, 'D')
  // ];

  List<Edge> edges = [];

  // List<Edge> edges = [
  //   Edge(Vertex(218.74438339313542, 338.1165745765152, 'A'), Vertex(216.77128932398864, 201.79371161728358, 'B'), 1),
  //   Edge(Vertex(216.77128932398864, 201.79371161728358, 'B'), Vertex(325.3811492211133, 192.28698564775823, 'C'), 1),
  //   Edge(Vertex(216.77128932398864, 201.79371161728358, 'B'), Vertex(56.950669723100035, 204.03586396858674, 'D'), 1)
  // ];

  Vertex? startVertex;
  Vertex? selectedVertex;
  int edgeCost = 1;
  WorkMode? workMode = WorkMode.drawVertex;

  // Store the edges
  Map<String, List<String>> findEdges = {};

  // Store vertex positions
  Map<String, Offset> vertexPositions = {};

  List<String> clickedVertices = [];

  String path = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initialize();
  }

  Future<void> _initialize() async {
    final String svgString = await DefaultAssetBundle.of(context).loadString(svgAssetPath);
    setState(() {
      _currentSvgContent = svgString; // Initialize with the original SVG content
      updateSvg();
    });
  }

  void _onTapDown(TapDownDetails details) {
    final x = details.localPosition.dx;
    final y = details.localPosition.dy;

    switch (workMode) {
      case WorkMode.drawVertex:
        drawVertex(x, y);
        break;
      case WorkMode.drawEdge:
        drawEdge(x, y);
        break;
      case WorkMode.findRoute:
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

  @override
  Widget build(BuildContext context) {
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
                          if (workMode == WorkMode.findRoute)
                            ...vertexPositions.entries.map((entry) {
                              return Positioned(
                                left: entry.value.dx - 10, // Adjust for center alignment
                                top: entry.value.dy - 10, // Adjust for center alignment
                                child: GestureDetector(
                                  onTap: () => onVertexClick(entry.key),
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red.withOpacity(0.5),
                                      border: Border.all(color: Colors.transparent),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              path,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              // alignment: MainAxisAlignment.center,
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
                Radio(
                  value: WorkMode.findRoute,
                  groupValue: workMode,
                  onChanged: (value) {
                    setState(() {
                      parseSvgVerticesAndEdges();
                      workMode = value!;
                    });
                  },
                ),
                const Text('Find Route'),
                TextButton(
                    onPressed: () {
                      clearData();
                    },
                    child: const Text('Clear')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void clearData() {
    svgString = '''
<svg width="$svgWidth" height="$svgHeight" xmlns="http://www.w3.org/2000/svg">
 <rect x="0" y="0" width="$svgWidth" height="$svgHeight" fill="none" stroke="black" stroke-width="2"/>
  <g id="gedge"></g>
  <g id="gvertex"></g>
</svg>
  ''';

    vertices = [];
    edges = [];
    startVertex;
    selectedVertex;
    edgeCost = 1;
    workMode = WorkMode.drawVertex;
    findEdges = {};
    vertexPositions = {};
    clickedVertices = [];
    path = '';
    setState(() {});
  }

  void drawVertex(double x, double y) {
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

  void parseSvgVerticesAndEdges() {
    final document = xml.XmlDocument.parse(svgString);
    final circles = document.findAllElements('circle');

    for (var circle in circles) {
      final cx = double.parse(circle.getAttribute('cx')!);
      final cy = double.parse(circle.getAttribute('cy')!);
      final textElement = circle.nextElementSibling;
      final vertexId = textElement?.text;

      if (vertexId != null) {
        vertexPositions[vertexId] = Offset(cx, cy);
      }
    }

    final lines = document.findAllElements('line');

    for (var line in lines) {
      final x1 = double.parse(line.getAttribute('x1')!);
      final y1 = double.parse(line.getAttribute('y1')!);
      final x2 = double.parse(line.getAttribute('x2')!);
      final y2 = double.parse(line.getAttribute('y2')!);

      final startVertex = getVertexId(x1, y1);
      final endVertex = getVertexId(x2, y2);

      if (startVertex != null && endVertex != null) {
        if (!findEdges.containsKey(startVertex)) {
          findEdges[startVertex] = [];
        }
        if (!findEdges.containsKey(endVertex)) {
          findEdges[endVertex] = [];
        }
        findEdges[startVertex]!.add(endVertex);
        findEdges[endVertex]!.add(startVertex); // Assuming undirected graph
      }
    }
    Log.e('Edges: $findEdges');
  }

  String? getVertexId(double x, double y) {
    // Find the vertex id based on coordinates
    for (var entry in vertexPositions.entries) {
      final pos = entry.value;
      if ((pos.dx - x).abs() < 10 && (pos.dy - y).abs() < 10) {
        return entry.key;
      }
    }
    return null;
  }

  void onVertexClick(String vertex) {
    Log.e(vertex);
    setState(() {
      path = vertex;
    });

    clickedVertices.add(vertex);
    if (clickedVertices.length > 1) {
      String path = findPath(clickedVertices.first, clickedVertices.last);
      setState(() {
        this.path = path;
        clickedVertices.clear(); // Reset the list after finding a path
      });
      Log.e(path);
    } else {
      Log.e('error');
    }
  }

  String findPath(String start, String end) {
    // Simple BFS for finding the path
    final queue = <List<String>>[];
    final visited = <String>{};

    queue.add([start]);
    visited.add(start);

    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final vertex = path.last;

      if (vertex == end) {
        return path.join(' to ');
      }

      if (findEdges[vertex] != null) {
        for (var neighbor in findEdges[vertex]!) {
          if (!visited.contains(neighbor)) {
            visited.add(neighbor);
            queue.add(List<String>.from(path)..add(neighbor));
          }
        }
      }
    }
    return 'No path found';
  }

  void updateSvg() {
    final vertexElements = vertices.map((v) {
      return '''
<circle cx="${v.x}" cy="${v.y}" r="10" fill="grey" stroke="black" stroke-width="1"/>
<text x="${v.x}" y="${v.y + 4}" text-anchor="middle" alignment-baseline="central" font-size="12" fill="white">${v.label}</text>
      ''';
    }).join();

    final edgeElements = edges.map((e) {
      return '''
<line x1="${e.from.x}" y1="${e.from.y}" x2="${e.to.x}" y2="${e.to.y}" stroke="skyblue" stroke-width="3"/>
<!-- <text x="${(e.from.x + e.to.x) / 2}" y="${(e.from.y + e.to.y) / 2}" text-anchor="middle" alignment-baseline="central" font-size="12" fill="black">${e.cost}</text> -->
      ''';
    }).join();

    svgString = '''
<svg width="$svgWidth" height="$svgHeight" xmlns="http://www.w3.org/2000/svg">
 <rect x="0" y="0" width="$svgWidth" height="$svgHeight" fill="none" stroke="black" stroke-width="2"/>
  <g id="gedge">$edgeElements</g>
  <g id="gvertex">$vertexElements</g>
</svg>
    ''';

    setState(() {});
  }
}
