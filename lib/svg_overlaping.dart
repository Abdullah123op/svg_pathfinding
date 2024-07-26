import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  @override
  Widget build(BuildContext context) {
    Log.e(svgString);
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
                // Radio(
                //   value: WorkMode.findRoute,
                //   groupValue: workMode,
                //   onChanged: (value) {
                //     setState(() {
                //       workMode = value;
                //     });
                //   },
                // ),
                // const Text('Find Route'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onTapDown(TapDownDetails details) {
    final position = details.localPosition;
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
        handleFindRoute(x, y);
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

  void handleFindRoute(double x, double y) {
    final vertex = getVertexAt(x, y);
    if (vertex != null) {
      if (startVertex == null) {
        startVertex = vertex;
        Log.e('Start vertex selected: ${vertex.label}');
      } else {
        final endVertex = vertex;
        final path = findShortestPath(startVertex!, endVertex);
        Log.e('Path: ${path.map((v) => v.label).join(' -> ')}');

        // Print the vertices in the path
        for (var i = 0; i < path.length - 1; i++) {
          Log.e('From ${path[i].label} to ${path[i + 1].label}');
        }

        setState(() {
          startVertex = null; // Reset the start vertex for the next route finding
        });
      }
    }
  }

  List<Vertex> findShortestPath(Vertex start, Vertex end) {
    final distances = <Vertex, double>{};
    final previousVertices = <Vertex, Vertex?>{};
    final unvisited = PriorityQueue<Vertex>((a, b) => distances[a]!.compareTo(distances[b]!));

    // Initialize distances and previous vertices
    for (var vertex in vertices) {
      distances[vertex] = double.infinity;
      previousVertices[vertex] = null;
      unvisited.add(vertex);
    }
    distances[start] = 0;

    while (unvisited.isNotEmpty) {
      final current = unvisited.removeFirst();
      if (current == end) break;

      // Consider all edges connected to the current vertex
      for (var edge in edges.where((e) => e.from == current || e.to == current)) {
        final neighbor = edge.from == current ? edge.to : edge.from;
        final newDist = distances[current]! + edge.cost;

        if (newDist < distances[neighbor]!) {
          distances[neighbor] = newDist;
          previousVertices[neighbor] = current;
          // Ensure the priority queue is updated with new distances
          unvisited.add(neighbor);
        }
      }
    }

    // Reconstruct the path
    final path = <Vertex>[];
    Vertex? current = end;
    while (current != null) {
      path.insert(0, current);
      current = previousVertices[current];
    }

    // Check if the path starts from the start vertex
    if (path.isNotEmpty && path.first == start) {
      Log.e('Path: ${path.map((v) => v.label).join(' -> ')}');
    } else {
      Log.e('No path found from ${start.label} to ${end.label}');
      Log.e('Path: ${path.map((v) => v.label).join(' -> ')}');
    }

    return path;
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
<text x="${(e.from.x + e.to.x) / 2}" y="${(e.from.y + e.to.y) / 2}" text-anchor="middle" alignment-baseline="central" font-size="12" fill="black">${e.cost}</text>
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
