import 'package:flutter/material.dart';

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

  Edge(this.from, this.to);

  @override
  String toString() {
    return 'Edge(from: $from, to: $to)';
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);
}

class EdgePosition {
  final Offset start;
  final Offset end;

  EdgePosition({required this.start, required this.end});
}
