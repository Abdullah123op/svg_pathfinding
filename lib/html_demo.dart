import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:svg_pathfinding/utils/logger.dart';

var svgWidth = 400;
var svgHeight = 480;

class DijkstraApp extends StatelessWidget {
  const DijkstraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Dijkstra's Algorithm Solver",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DijkstraHomePage(),
    );
  }
}

class DijkstraHomePage extends StatefulWidget {
  const DijkstraHomePage({super.key});

  @override
  _DijkstraHomePageState createState() => _DijkstraHomePageState();
}

class _DijkstraHomePageState extends State<DijkstraHomePage> {
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
  WorkMode? workMode = WorkMode.drawVertex;
  Vertex? selectedVertex;
  int edgeCost = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dijkstra's Algorithm Solver")),
      body: Column(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              onTapDown: (details) {
                handleTap(details.localPosition.dx, details.localPosition.dy);
              },
              child: SvgPicture.string(
                svgString,
                width: svgWidth.toDouble(),
                height: svgHeight.toDouble(),
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
              Radio(
                value: WorkMode.setStart,
                groupValue: workMode,
                onChanged: (value) {
                  setState(() {
                    workMode = value;
                  });
                },
              ),
              const Text('Set Start'),
            ],
          ),
          ButtonBar(
            alignment: MainAxisAlignment.center,
            children: <Widget>[
              Radio(
                value: WorkMode.delVertexEdge,
                groupValue: workMode,
                onChanged: (value) {
                  setState(() {
                    workMode = value;
                  });
                },
              ),
              const Text('Delete vertex or edge'),
              Radio(
                value: WorkMode.setCostLabel,
                groupValue: workMode,
                onChanged: (value) {
                  setState(() {
                    workMode = value;
                  });
                },
              ),
              const Text('Set cost or label'),
            ],
          ),
          ElevatedButton(
            onPressed: saveGraphAsSvg,
            child: const Text('Save graph'),
          ),
          Table(
            children: const [
              TableRow(children: [Text('Round'), Text('Vertices')]),
              // Add more rows as needed
            ],
          ),
          // Implement modals for setting edge cost and vertex label as dialogs
        ],
      ),
    );
  }

  void handleTap(double x, double y) {
    Log.e('Tap at: ($x, $y)');
    switch (workMode) {
      case WorkMode.drawVertex:
        drawVertex(x, y + 50.00);
        break;
      case WorkMode.drawEdge:
        drawEdge(x, y + 50.00);
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
      case WorkMode.findRoute:
      // TODO: Handle this case.
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
    const double tolerance = 50;
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
<circle cx="${v.x}" cy="${v.y}" r="20" fill="white" stroke="black" />
<text x="${v.x}" y="${v.y}" text-anchor="middle" alignment-baseline="central" font-size="16" fill="black">${v.label}</text>
      ''';
    }).join();

    final edgeElements = edges.map((e) {
      return '''
<line x1="${e.from.x}" y1="${e.from.y}" x2="${e.to.x}" y2="${e.to.y}" stroke="darkgrey" stroke-width="6" />
<text x="${(e.from.x + e.to.x) / 2}" y="${(e.from.y + e.to.y) / 2}" text-anchor="middle" alignment-baseline="central" font-size="20" fill="black">${e.cost}</text>
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

  Future<void> saveGraphAsSvg() async {
    // Request storage permission
    if (await Permission.storage.request().isGranted) {
      try {
        // Get the path to the Downloads folder
        final downloadsDirectory = Directory('/storage/emulated/0/Download');
        if (!await downloadsDirectory.exists()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Downloads directory does not exist')),
          );
          return;
        }

        // Define the file path and write the SVG content
        var time = DateTime.now().minute;
        final path = '${downloadsDirectory.path}/graph$time.svg';
        final file = File(path);
        Log.e(svgString);
        await file.writeAsString(svgString);

        Log.e('Graph saved to $path');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Graph saved to $path')),
        );
      } catch (e) {
        Log.e('Error saving file: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving file: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission denied')),
      );
    }
  }
}

enum WorkMode { drawVertex, drawEdge, setStart, delVertexEdge, setCostLabel, findRoute }

class Vertex {
  final double x;
  final double y;
  final String label;

  Vertex(this.x, this.y, this.label);

  @override
  String toString() {
    return 'Vertex(x: $x, y: $y, label: $label)';
  }
}

class Edge {
  final Vertex from;
  final Vertex to;
  final int cost;

  Edge(this.from, this.to, this.cost);

  @override
  String toString() {
    return 'Edge(from: $from, to: $to, cost: $cost)';
  }
}
