import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:svg_pathfinding/fetures/pathfinding/model/edges_vertex_workmode.dart';
import 'package:svg_pathfinding/fetures/pathfinding/view_model/svg_path_finding_model.dart';

const double svgWidth = 400; // Set width of the SVG for calculations
const double svgHeight = 400; // Set height of the SVG for calculations

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
                child: GestureDetector(
                  onTapDown: provider.onTapDown,
                  child: Column(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            SvgPicture.asset(
                              'assets/sample_svg.svg',
                              width: svgWidth,
                              height: svgHeight,
                            ),
                            SvgPicture.string(
                              provider.svgString,
                              width: svgWidth,
                              height: svgHeight,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              left: provider.calculateX(provider.currentPosition!.longitude),
                              top: provider.calculateY(provider.currentPosition!.latitude),
                              child: const Icon(Icons.location_on_rounded, color: Color(0xFFFF0F00)),
                            ),
                            if (provider.workMode == WorkMode.findRoute)
                              ...provider.vertexPositions.entries.map((entry) {
                                return Positioned(
                                  left: entry.value.dx - 10, // Adjust for center alignment
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
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}
