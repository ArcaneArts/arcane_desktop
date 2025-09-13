import 'package:arcane/arcane.dart';
import 'package:arcane_desktop/arcane_desktop.dart';
import 'package:serviced/serviced.dart';

void main() async {
  await services().waitForStartup();
  runApp('demo', ArcaneWindow(child: const MyApp(), barTitle: (context) => Text("Arcane VFS")));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => ArcaneApp(home: const HomeScreen());
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => SliverScreen(header: Bar(title: Text("Derp")), sliver: SListView.builder(childCount: 1000, builder: (context, i) => Card(child: Text("Item $i", style: TextStyle(color: Color(0xFF00FF00), fontSize: 40)))));
}
