import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'notes.dart';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        // etc.
      };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(NoteAdapter());
  notesBox = await Hive.openBox<Note>(notesBoxKey);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top]);
  const systemUiOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, systemNavigationBarColor: Colors.transparent);
  if (Platform.isAndroid || Platform.isIOS) {
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes',
      scrollBehavior: MyCustomScrollBehavior(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      //   title: const Text("Notes"),
      //   centerTitle: true,
      //   actions: [
      //     IconButton(
      //       onPressed: () {},
      //       tooltip: "菜單",
      //       icon: const Icon(Icons.menu),
      //     ),
      //   ],
      // ),
      // body: NoteList(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            actions: [
              IconButton(
                onPressed: () {},
                tooltip: "切换显示",
                icon: const Icon(Icons.menu),
              ),
              IconButton(
                onPressed: () {},
                tooltip: "设置",
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
            expandedHeight: 57,
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                var top = constraints.biggest.height;
                print("11123");
                print(top);
                if (top > 56) return Container();
                return FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    "记事本",
                    style:
                        TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
                  ),
                  titlePadding: EdgeInsets.only(left: 16, bottom: 16),
                );
              },
            ),
          ),

          // Add the app bar to the CustomScrollView.
          SliverAppBar(
            expandedHeight: 88,
            toolbarHeight: 30,
            collapsedHeight: 30,
            floating: true,
            title: Text("记事本"),
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                var top = constraints.biggest.height;
                print("22334");
                print(top);
                if (top < 56) return Container();
                return FlexibleSpaceBar(
                  title: Container(
                    height: top - 56,
                    child: TextButton.icon(
                      style: ButtonStyle(
                          backgroundColor: MaterialStatePropertyAll(Colors.black12)),
                      onPressed: () {},
                      icon: Icon(Icons.search),
                      label: Text(
                        '搜索笔记' + ' ' * 1000,
                        style: TextStyle(
                            color: Theme.of(context).textTheme.titleLarge?.color),
                      ),
                    ),
                  ),
                  expandedTitleScale: 1,
                  titlePadding: EdgeInsetsDirectional.only(start: 16, end: 16),
                );
              },
            ),
            // Display a placeholder widget to visualize the shrinking size.
            // flexibleSpace: Placeholder(),
            // Make the initial height of the SliverAppBar larger than normal.
          ),
          SliverAppBar(
            pinned: true,
            title: TextButton.icon(
              style:
                  ButtonStyle(backgroundColor: MaterialStatePropertyAll(Colors.black12)),
              onPressed: () {},
              icon: Icon(Icons.folder_copy_outlined),
              label: Text(
                '全部',
                style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
              ),
            ),
          ),
          // Next, create a SliverList
          SliverList(
            // Use a delegate to build items as they're scrolled on screen.
            delegate: SliverChildBuilderDelegate(
              // The builder function returns a ListTile with a title that
              // displays the index of the current item.
              (context, index) => ListTile(title: Text('Item #$index')),
              // Builds 1000 ListTiles
              childCount: 1000,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: '添加筆記',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class NoteList extends StatefulWidget {
  NoteList({Key? key}) : super(key: key);

  @override
  State<NoteList> createState() => _NoteListState();
}

class _NoteListState extends State<NoteList> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ValueListenableBuilder<Box<Note>>(
            valueListenable: notesBox.listenable(),
            builder: (BuildContext context, Box<Note> value, Widget? child) {
              final v = value.values.toList();
              return ListView.builder(
                itemCount: v.length,
                itemBuilder: (BuildContext context, int index) {
                  final note = v[index];
                  return ListTile(
                    title: Text(note.title.isEmpty ? note.title : note.content),
                    subtitle: Text(DateTime.fromMicrosecondsSinceEpoch(note.create)
                        .toIso8601String()
                        .substring(0, "1969-07-20T20:18:04".length)),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
