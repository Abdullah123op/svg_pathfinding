import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';
import 'package:svg_pathfinding/fetures/pathfinding/view/svg_path_finding_screen.dart';
import 'package:svg_pathfinding/fetures/pathfinding/view_model/svg_path_finding_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure widgets are initialized
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SvgPathFindingModel()),
        ],
        child: GlobalLoaderOverlay(
          useDefaultLoading: false,
          overlayColor: Colors.black.withOpacity(0.5),
          overlayWidgetBuilder: (_) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(100),
                child: CircularProgressIndicator(),
              ),
            );
          },
          child: const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SvgPathFindingScreen(),
          ),
        ));
  }
}
