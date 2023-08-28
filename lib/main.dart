import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'notes.dart';



void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(NoteAdapter());
  notesBox = await Hive.openBox<Note>(notesBoxKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Notes"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            tooltip: "菜單",
            icon: const Icon(Icons.menu),
          ),
        ],
      ),
      body: NoteList(),
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
