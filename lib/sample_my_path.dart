import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xml/xml.dart' as xml;

class MySvgPath extends StatelessWidget {
  const MySvgPath({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SVG Overlaping',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MySvgPathWidget(),
    );
  }
}

// class MySvgPathWidget extends StatefulWidget {
//   const MySvgPathWidget({super.key});
//
//   @override
//   _MySvgPathWidgetState createState() => _MySvgPathWidgetState();
// }
//
// class _MySvgPathWidgetState extends State<MySvgPathWidget> {
//   // Track clicked vertices
//   List<String> clickedVertices = [];
//
//   // SVG string
//   String svgString = '''
// <svg width="400.0" height="400.0" xmlns="http://www.w3.org/2000/svg">
//     <rect x="0" y="0" width="400.0" height="400.0" fill="none" stroke="black" stroke-width="2"/>
//     <g id="gedge"><line x1="218.74438339313542" y1="338.1165745765152" x2="216.77128932398864" y2="201.79371161728358" stroke="skyblue" stroke-width="3"/>
//         <text x="217.75783635856203" y="269.9551430968994" text-anchor="middle" alignment-baseline="central" font-size="12" fill="black">1</text>
//         <line x1="216.77128932398864" y1="201.79371161728358" x2="325.3811492211133" y2="192.28698564775823" stroke="skyblue" stroke-width="3"/>
//         <text x="271.07621927255093" y="197.0403486325209" text-anchor="middle" alignment-baseline="central" font-size="12" fill="black">1</text>
//         <line x1="216.77128932398864" y1="201.79371161728358" x2="56.950669723100035" y2="204.03586396858674" stroke="skyblue" stroke-width="3"/>
//         <text x="136.86097952354433" y="202.91478779293516" text-anchor="middle" alignment-baseline="central" font-size="12" fill="black">1</text>
//     </g>
//     <g id="gvertex"><circle cx="218.74438339313542" cy="338.1165745765152" r="10" fill="grey" stroke="black" stroke-width="1"/>
//         <text x="218.74438339313542" y="342.1165745765152" text-anchor="middle" alignment-baseline="central" font-size="12" fill="white">A</text>
//         <circle cx="216.77128932398864" cy="201.79371161728358" r="10" fill="grey" stroke="black" stroke-width="1"/>
//         <text x="216.77128932398864" y="205.79371161728358" text-anchor="middle" alignment-baseline="central" font-size="12" fill="white">B</text>
//         <circle cx="325.3811492211133" cy="192.28698564775823" r="10" fill="grey" stroke="black" stroke-width="1"/>
//         <text x="325.3811492211133" y="196.28698564775823" text-anchor="middle" alignment-baseline="central" font-size="12" fill="white">C</text>
//         <circle cx="56.950669723100035" cy="204.03586396858674" r="10" fill="grey" stroke="black" stroke-width="1"/>
//         <text x="56.950669723100035" y="208.03586396858674" text-anchor="middle" alignment-baseline="central" font-size="12" fill="white">D</text>
//     </g>
// </svg>
//   ''';
//
//   // Store the edges
//   final Map<String, List<String>> edges = {};
//
//   // Store vertex positions
//   final Map<String, Offset> vertexPositions = {};
//
//   @override
//   void initState() {
//     super.initState();
//     // Parse SVG to extract edges and vertex positions
//     parseSvg();
//   }
//
//   void parseSvg() {
//     final document = xml.XmlDocument.parse(svgString);
//
//     // Parse edges
//     final lines = document.findAllElements('line');
//     for (var line in lines) {
//       final x1 = double.parse(line.getAttribute('x1')!);
//       final y1 = double.parse(line.getAttribute('y1')!);
//       final x2 = double.parse(line.getAttribute('x2')!);
//       final y2 = double.parse(line.getAttribute('y2')!);
//
//       final startVertex = getVertexId(x1, y1);
//       final endVertex = getVertexId(x2, y2);
//
//       if (startVertex != null && endVertex != null) {
//         if (!edges.containsKey(startVertex)) {
//           edges[startVertex] = [];
//         }
//         if (!edges.containsKey(endVertex)) {
//           edges[endVertex] = [];
//         }
//         edges[startVertex]!.add(endVertex);
//         edges[endVertex]!.add(startVertex); // Assuming undirected graph
//       }
//     }
//
//     // Parse vertices
//     final circles = document.findAllElements('circle');
//     for (var circle in circles) {
//       final cx = double.parse(circle.getAttribute('cx')!);
//       final cy = double.parse(circle.getAttribute('cy')!);
//       final id = document
//           .findAllElements('text')
//           .firstWhere(
//             (text) => text.getAttribute('x') == cx.toString() && text.getAttribute('y') == cy.toString(),
//             orElse: () => xml.XmlElement(xml.XmlName('')),
//           )
//           .innerText;
//
//       vertexPositions[id] = Offset(cx, cy);
//     }
//   }
//
//   String? getVertexId(double x, double y) {
//     for (var entry in vertexPositions.entries) {
//       final pos = entry.value;
//       if ((pos.dx - x).abs() < 10 && (pos.dy - y).abs() < 10) {
//         return entry.key;
//       }
//     }
//     return null;
//   }
//
//   void onVertexClick(String vertex) {
//     setState(() {
//       clickedVertices.add(vertex);
//       if (clickedVertices.length > 1) {
//         String path = findPath(clickedVertices.first, clickedVertices.last);
//         Log.e(path);
//       } else {
//         Log.e('error');
//       }
//     });
//   }
//
//   String findPath(String start, String end) {
//     // Simple BFS for finding the path
//     final queue = <List<String>>[];
//     final visited = <String>{};
//
//     queue.add([start]);
//     visited.add(start);
//
//     while (queue.isNotEmpty) {
//       final path = queue.removeAt(0);
//       final vertex = path.last;
//
//       if (vertex == end) {
//         return path.join(' to ');
//       }
//
//       for (var neighbor in edges[vertex]!) {
//         if (!visited.contains(neighbor)) {
//           visited.add(neighbor);
//           queue.add(List<String>.from(path)..add(neighbor));
//         }
//       }
//     }
//     return 'No path found';
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           SvgPicture.string(
//             svgString,
//             fit: BoxFit.cover,
//           ),
//           ...vertexPositions.entries.map((entry) {
//             return Positioned(
//               left: entry.value.dx - 10, // Adjust for center alignment
//               top: entry.value.dy - 10, // Adjust for center alignment
//               child: Container(
//                 color: Colors.red,
//                 child: GestureDetector(
//                   onTap: () {
//                     Log.e('clcike');
//                     onVertexClick(entry.key);
//                   },
//                   child: Container(
//                     width: 20,
//                     height: 20,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Colors.transparent,
//                       border: Border.all(color: Colors.transparent),
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           }).toList(),
//         ],
//       ),
//     );
//   }
// }
//
//

class MySvgPathWidget extends StatefulWidget {
  @override
  _MySvgPathWidgetState createState() => _MySvgPathWidgetState();
}

class _MySvgPathWidgetState extends State<MySvgPathWidget> {
  // Track clicked vertices
  List<String> clickedVertices = [];

  // SVG string
  String svgString = '''
<svg width="400.0" height="400.0" xmlns="http://www.w3.org/2000/svg">
    <rect x="0" y="0" width="400.0" height="400.0" fill="none" stroke="black" stroke-width="2"/>
    <g id="gedge"><line x1="218.74438339313542" y1="338.1165745765152" x2="216.77128932398864" y2="201.79371161728358" stroke="skyblue" stroke-width="3"/>
        <text x="217.75783635856203" y="269.9551430968994" text-anchor="middle" alignment-baseline="central" font-size="12" fill="black">1</text>
        <line x1="216.77128932398864" y1="201.79371161728358" x2="325.3811492211133" y2="192.28698564775823" stroke="skyblue" stroke-width="3"/>
        <text x="271.07621927255093" y="197.0403486325209" text-anchor="middle" alignment-baseline="central" font-size="12" fill="black">1</text>
        <line x1="216.77128932398864" y1="201.79371161728358" x2="56.950669723100035" y2="204.03586396858674" stroke="skyblue" stroke-width="3"/>
        <text x="136.86097952354433" y="202.91478779293516" text-anchor="middle" alignment-baseline="central" font-size="12" fill="black">1</text>
    </g>
    <g id="gvertex"><circle cx="218.74438339313542" cy="338.1165745765152" r="10" fill="grey" stroke="black" stroke-width="1"/>
        <text x="218.74438339313542" y="342.1165745765152" text-anchor="middle" alignment-baseline="central" font-size="12" fill="white">A</text>
        <circle cx="216.77128932398864" cy="201.79371161728358" r="10" fill="grey" stroke="black" stroke-width="1"/>
        <text x="216.77128932398864" y="205.79371161728358" text-anchor="middle" alignment-baseline="central" font-size="12" fill="white">B</text>
        <circle cx="325.3811492211133" cy="192.28698564775823" r="10" fill="grey" stroke="black" stroke-width="1"/>
        <text x="325.3811492211133" y="196.28698564775823" text-anchor="middle" alignment-baseline="central" font-size="12" fill="white">C</text>
        <circle cx="56.950669723100035" cy="204.03586396858674" r="10" fill="grey" stroke="black" stroke-width="1"/>
        <text x="56.950669723100035" y="208.03586396858674" text-anchor="middle" alignment-baseline="central" font-size="12" fill="white">D</text>
    </g>
</svg>
  ''';

  // Store the edges
  final Map<String, List<String>> edges = {};

  // Store vertex positions
  final Map<String, Offset> vertexPositions = {
    'A': Offset(218.74438339313542, 338.1165745765152),
    'B': Offset(216.77128932398864, 201.79371161728358),
    'C': Offset(325.3811492211133, 192.28698564775823),
    'D': Offset(56.950669723100035, 204.03586396858674),
  };

  @override
  void initState() {
    super.initState();
    // Parse SVG to extract edges
    parseSvgEdges();
  }

  void parseSvgEdges() {
    final document = xml.XmlDocument.parse(svgString);
    final lines = document.findAllElements('line');

    for (var line in lines) {
      final x1 = double.parse(line.getAttribute('x1')!);
      final y1 = double.parse(line.getAttribute('y1')!);
      final x2 = double.parse(line.getAttribute('x2')!);
      final y2 = double.parse(line.getAttribute('y2')!);

      final startVertex = getVertexId(x1, y1);
      final endVertex = getVertexId(x2, y2);

      if (startVertex != null && endVertex != null) {
        if (!edges.containsKey(startVertex)) {
          edges[startVertex] = [];
        }
        if (!edges.containsKey(endVertex)) {
          edges[endVertex] = [];
        }
        edges[startVertex]!.add(endVertex);
        edges[endVertex]!.add(startVertex); // Assuming undirected graph
      }
    }
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
    setState(() {
      clickedVertices.add(vertex);
      if (clickedVertices.length > 1) {
        String path = findPath(clickedVertices.first, clickedVertices.last);
        print(path);
      } else {
        print('error');
      }
    });
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

      for (var neighbor in edges[vertex]!) {
        if (!visited.contains(neighbor)) {
          visited.add(neighbor);
          queue.add(List<String>.from(path)..add(neighbor));
        }
      }
    }
    return 'No path found';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SvgPicture.string(
            svgString,
            fit: BoxFit.cover,
            // Add your SVG path as a string
          ),
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
                    color: Colors.transparent,
                    border: Border.all(color: Colors.transparent),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
