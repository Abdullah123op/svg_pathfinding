import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:svg_pathfinding/fetures/pathfinding/model/edges_vertex_workmode.dart';
import 'package:svg_pathfinding/fetures/pathfinding/view_model/svg_path_finding_model.dart';

const double svgWidth = 370; // Set width of the SVG for calculations
const double svgHeight = 600; // Set height of the SVG for calculations

class SvgPathFindingScreen extends StatefulWidget {
  const SvgPathFindingScreen({super.key});

  @override
  State<SvgPathFindingScreen> createState() => _SvgPathFindingScreenState();
}

class _SvgPathFindingScreenState extends State<SvgPathFindingScreen> {
  late SvgPathFindingModel _svgPathFindingModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // _initialize();
  }

  @override
  void initState() {
    super.initState();
    _svgPathFindingModel = Provider.of<SvgPathFindingModel>(context, listen: false);
    _svgPathFindingModel.initModel(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Consumer<SvgPathFindingModel>(builder: (context, provider, child) {
          return Column(
            children: [
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTapDown: provider.onTapDown,
                    child: Column(
                      children: [
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/solitaire_floor_plan.svg',
                                width: svgWidth,
                                height: svgHeight,
                                fit: BoxFit.cover,
                              ),
                              SvgPicture.string(
                                provider.svgString,
                                width: svgWidth,
                                height: svgHeight,
                                fit: BoxFit.contain,
                              ),
                              Align(
                                alignment: Alignment.topLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(left: 15, top: 5),
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.all(Radius.circular(8)),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_circle_up_outlined,
                                    color: Colors.white,
                                    size: 35,
                                  ),
                                ),
                              ),
                              Positioned(left: provider.offset.dx, top: provider.offset.dy, child: buildBlueDot()),
                              if (provider.workMode == WorkMode.findRoute)
                                ...provider.vertexPositions.entries.map((entry) {
                                  return Positioned(
                                    left: entry.value.dx - 1, // Adjust for center alignment
                                    top: entry.value.dy - 10, // Adjust for center alignment
                                    child: GestureDetector(
                                      onTap: () => provider.onVertexClick(entry.key),
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Text(
                'Your Location :- ${provider.yourLocation?.label}',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              Text(
                provider.path,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                // alignment: MainAxisAlignment.center,
                children: <Widget>[
                  Radio(
                    value: WorkMode.drawVertex,
                    groupValue: provider.workMode,
                    onChanged: (WorkMode? value) {
                      provider.setWorkMode(value!);
                    },
                  ),
                  const Text('Draw vertex'),
                  Radio(
                    value: WorkMode.drawEdge,
                    groupValue: provider.workMode,
                    onChanged: (value) {
                      provider.setWorkMode(value!);
                    },
                  ),
                  const Text('Draw edge'),
                  Radio(
                    value: WorkMode.findRoute,
                    groupValue: provider.workMode,
                    onChanged: (value) {
                      provider.setWorkMode(value!);
                    },
                  ),
                  const Text('Find Route'),
                  TextButton(
                      onPressed: () {
                        provider.resetModel();
                      },
                      child: const Text('Clear')),
                  TextButton(
                      onPressed: () {
                        provider.getYourLocation();
                      },
                      child: const Text('Get Your Location')),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget buildBlueDot() {
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error reading heading: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        double direction = snapshot.data!.heading!;
        double adjustedAngle = direction;

        adjustedAngle = (direction - 130) * (math.pi / 180);
        // if (direction >= 0 && direction < 130) {
        //   adjustedAngle = (direction - 130) * (math.pi / 180);
        // } else if (direction >= 130 && direction < 215) {
        //   adjustedAngle = (direction - 215) * (math.pi / 180);
        // } else if (direction >= 215 && direction < 315) {
        //   adjustedAngle = (direction - 315) * (math.pi / 180);
        // } else {
        //   adjustedAngle = (direction - 35) * (math.pi / 180);
        // }

        // if direction is null, then device does not support this sensor
        // show error message
        if (direction == null) {
          return const Center(
            child: Text("Device does not have sensors !"),
          );
        }

        return Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 4.0,
          child: Container(
            width: 25.0,
            height: 25.0,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2.0,
              ),
            ),
            child: Transform.rotate(
              angle: adjustedAngle,
              child: const Icon(
                Icons.navigation, // Use navigation icon to represent direction
                color: Colors.white,
                size: 13.0, // Adjust icon size as needed
              ),
            ),
          ),
        );
      },
    );
  }
}
