import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:svg_pathfinding/fetures/pathfinding/model/edges_vertex_workmode.dart';
import 'package:svg_pathfinding/fetures/pathfinding/view/svg_path_finding_screen.dart';
import 'package:svg_pathfinding/utils/logger.dart';
import 'package:xml/xml.dart' as xml;

class SvgPathFindingModel with ChangeNotifier {
  String svgAssetPath = 'assets/sample_svg.svg';

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

  // Store the edges
  Map<String, List<Edge>> findEdges = {};

  // Store vertex positions
  Map<String, Offset> vertexPositions = {};

  List<String> clickedVertices = [];

  String path = '';

  Position? currentPosition;

  // Define the geographic boundaries of your office
  final double minLatitude = 22.991990;
  final double maxLatitude = 22.992444;
  final double minLongitude = 72.496957;
  final double maxLongitude = 72.497742;

  // This function will call in the initState of stateful widget
  void initModel(BuildContext context) {
    initialize(context);
    _getCurrentLocation();
  }

  // This function will call in the build of stateful widget
  void buildModel(BuildContext context) {}

  // This function will call in the onDispose of stateful widget
  void resetModel() {
    svgString = '''
<svg width="$svgWidth" height="$svgHeight" xmlns="http://www.w3.org/2000/svg">
 <rect x="0" y="0" width="$svgWidth" height="$svgHeight" fill="none" stroke="black" stroke-width="2"/>
  <g id="gedge"></g>
  <g id="gvertex"></g>
</svg>
  ''';

    vertices = [];
    edges = [];
    startVertex = null;
    selectedVertex = null;
    edgeCost = 1;
    workMode = WorkMode.drawVertex;
    findEdges = {};
    vertexPositions = {};
    clickedVertices = [];
    path = '';
    notifyListeners();
  }

  Future<void> initialize(BuildContext context) async {
    // final String svgString = await DefaultAssetBundle.of(context).loadString(svgAssetPath);
    // currentSvgContent = svgString; // Initialize with the original SVG content
    updateSvg();
    notifyListeners();
  }

  void onTapDown(TapDownDetails details) {
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

  void setWorkMode(WorkMode value) {
    workMode = value;
    if (workMode == WorkMode.findRoute) {
      parseSvgVerticesAndEdges();
    }
    notifyListeners();
  }

  void drawVertex(double x, double y) {
    final adjustedX = x;
    final adjustedY = y;
    final vertex = Vertex(adjustedX, adjustedY, String.fromCharCode(65 + vertices.length));
    Log.e('Adding vertex at: ($adjustedX, $adjustedY)');
    vertices.add(vertex);
    updateSvg();
  }

  void drawEdge(double x, double y) {
    final vertex = getVertexAt(x, y);
    if (vertex != null) {
      if (selectedVertex == null) {
        selectedVertex = vertex;
      } else {
        final edge = Edge(selectedVertex!, vertex, edgeCost);
        Log.e('Adding edge: $edge');

        edges.add(edge);
        if (!findEdges.containsKey(selectedVertex!.label)) {
          findEdges[selectedVertex!.label] = [];
        }
        if (!findEdges.containsKey(vertex.label)) {
          findEdges[vertex.label] = [];
        }
        findEdges[selectedVertex!.label]!.add(edge);
        findEdges[vertex.label]!.add(edge);

        selectedVertex = null;
        updateSvg();
      }
    } else {
      selectedVertex = null;
    }
    notifyListeners();
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
        final edge = Edge(
          vertices.firstWhere((v) => v.label == startVertex),
          vertices.firstWhere((v) => v.label == endVertex),
          edgeCost,
        );
        if (!findEdges.containsKey(startVertex)) {
          findEdges[startVertex] = [];
        }
        if (!findEdges.containsKey(endVertex)) {
          findEdges[endVertex] = [];
        }
        findEdges[startVertex]!.add(edge);
        findEdges[endVertex]!.add(edge); // Assuming undirected graph
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
    path = vertex;
    notifyListeners();

    clickedVertices.add(vertex);
    if (clickedVertices.length > 1) {
      String path = findShortestPath(clickedVertices.first, clickedVertices.last);

      this.path = path;
      clickedVertices.clear(); // Reset the list after finding a path
      notifyListeners();

      Log.e(path);
    }
  }

  String findShortestPath(String start, String end) {
    final distances = <String, double>{}; // Shortest distances from start
    final previous = <String, String?>{}; // Previous node in the shortest path
    final queue = PriorityQueue<MapEntry<String, double>>((a, b) => a.value.compareTo(b.value)); // Priority queue for the algorithm

    distances[start] = 0; // Initialize start node
    queue.add(MapEntry(start, 0)); // Add start node to the queue

    while (queue.isNotEmpty) {
      final current = queue.removeFirst().key; // Get the node with the smallest distance

      if (current == end) {
        final path = reconstructPath(previous, start, end); // Reconstruct the path from start to end
        Log.e('Path found: $path');
        Log.e('Path length: ${distances[end]}');
        return path;
      }

      if (findEdges[current] != null) {
        for (var edge in findEdges[current]!) {
          final neighbor = edge.from.label == current ? edge.to.label : edge.from.label; // Find the neighboring vertex
          final newDist = distances[current]! + euclideanDistance(current, neighbor); // Calculate new distance

          if (newDist < (distances[neighbor] ?? double.infinity)) {
            distances[neighbor] = newDist; // Update shortest distance
            previous[neighbor] = current; // Update previous node
            final heuristicDist = newDist + euclideanDistance(neighbor, end); // Calculate heuristic distance
            queue.add(MapEntry(neighbor, heuristicDist)); // Add neighbor to the queue with heuristic distance
          }
        }
      }
    }
    return 'No path found'; // Return if no path is found
  }

  double euclideanDistance(String vertexLabel1, String vertexLabel2) {
    final pos1 = vertexPositions[vertexLabel1]!; // Position of the first vertex
    final pos2 = vertexPositions[vertexLabel2]!; // Position of the second vertex
    return sqrt(pow(pos1.dx - pos2.dx, 2) + pow(pos1.dy - pos2.dy, 2)); // Calculate Euclidean distance
  }

  String reconstructPath(Map<String, String?> previous, String start, String end) {
    final path = <String>[]; // List to store the path
    String? current = end;

    while (current != null && current != start) {
      path.add(current); // Add current node to the path
      current = previous[current]; // Move to the previous node
    }

    if (current == start) {
      path.add(start); // Add start node to the path
      return path.reversed.join(' to '); // Return the path as a string
    } else {
      return 'No path found'; // Return if no path is found
    }
  }

// GPS Related code

  void _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, don't continue
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, don't continue
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, don't continue
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can get the location
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1, // Set to 1 meter to get more frequent updates
      ),
    ).listen((Position position) {
      Log.e("Current position: ${position.latitude}, ${position.longitude}");
      currentPosition = position;
      notifyListeners();
    });
  }

  double calculateX(double longitude) {
    // Office dimensions in pixels
    double officeWidth = svgWidth; // Width of your SVG in pixels

    // Clamp the longitude to the defined boundaries
    double clampedLongitude = longitude.clamp(minLongitude, maxLongitude);
    Log.e("Clamped Longitude: $clampedLongitude");

    // Calculate the x-coordinate in the SVG based on the longitude
    double x = ((clampedLongitude - minLongitude) / (maxLongitude - minLongitude)) * officeWidth;
    Log.e("Longitude: $longitude, Calculated X: $x");
    return x;
  }

  double calculateY(double latitude) {
    // Office dimensions in pixels
    double officeHeight = svgHeight; // Height of your SVG in pixels

    // Clamp the latitude to the defined boundaries
    double clampedLatitude = latitude.clamp(minLatitude, maxLatitude);
    Log.e("Clamped Latitude: $clampedLatitude");

    // Calculate the y-coordinate in the SVG based on the latitude
    double y = officeHeight - ((clampedLatitude - minLatitude) / (maxLatitude - minLatitude)) * officeHeight;
    Log.e("Latitude: $latitude, Calculated Y: $y");
    return y;
  }

  void updateSvg() {
    final svgBuffer = StringBuffer();
    svgBuffer.write('<svg width="$svgWidth" height="$svgHeight" xmlns="http://www.w3.org/2000/svg">');
    svgBuffer.write('<rect x="0" y="0" width="$svgWidth" height="$svgHeight" fill="none" stroke="black" stroke-width="2"/>');
    svgBuffer.write('<g id="gedge">');

    for (var edge in edges) {
      svgBuffer.write(
        '<line x1="${edge.from.x}" y1="${edge.from.y}" x2="${edge.to.x}" y2="${edge.to.y}" stroke="blue" stroke-width="2"/>',
      );
    }

    svgBuffer.write('</g>');
    svgBuffer.write('<g id="gvertex">');

    for (var vertex in vertices) {
      svgBuffer.write(
        '<circle cx="${vertex.x}" cy="${vertex.y}" r="10" fill="grey"/><text x="${vertex.x}" y="${vertex.y}" font-size="10" text-anchor="middle" fill="white">${vertex.label}</text>',
      );
    }

    svgBuffer.write('</g>');
    svgBuffer.write('</svg>');

    svgString = svgBuffer.toString();
    notifyListeners();
  }
}
