import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

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

MaterialColor getMaterialColor(Color color) {
  final Map<int, Color> shades = {
    50: const Color.fromRGBO(136, 14, 79, .1),
    100: const Color.fromRGBO(136, 14, 79, .2),
    200: const Color.fromRGBO(136, 14, 79, .3),
    300: const Color.fromRGBO(136, 14, 79, .4),
    400: const Color.fromRGBO(136, 14, 79, .5),
    500: const Color.fromRGBO(136, 14, 79, .6),
    600: const Color.fromRGBO(136, 14, 79, .7),
    700: const Color.fromRGBO(136, 14, 79, .8),
    800: const Color.fromRGBO(136, 14, 79, .9),
    900: const Color.fromRGBO(136, 14, 79, 1),
  };
  return MaterialColor(color.value, shades);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final colorSeed = getMaterialColor(Color(4294198070));
    final colorSeed2 = getMaterialColor(Colors.deepOrange);
    final defaultLightColor =
        ColorScheme.fromSeed(seedColor: colorSeed, brightness: Brightness.light);
    final defaultDarkColor =
        ColorScheme.fromSeed(seedColor: colorSeed2, brightness: Brightness.dark);
    return MaterialApp(
      title: 'Notes',
      scrollBehavior: MyCustomScrollBehavior(),
      theme: ThemeData(colorScheme: defaultLightColor, useMaterial3: true),
      darkTheme: ThemeData(colorScheme: defaultDarkColor, useMaterial3: true),
      home: const HomePage(),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: Locale('zh', 'CH'),
      supportedLocales: [Locale('zh', 'CH')],
    );
  }
}

const physics =
    const AlwaysScrollableScrollPhysics(parent: const BouncingScrollPhysics());
final dateFormat = DateFormat("yy年MM月dd日 HH:mm");

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<Box<Note>>(
          valueListenable: notesBox.listenable(),
          builder: (BuildContext context, Box<Note> value, Widget? child) {
            final v = value.values.toList();
            return CustomScrollView(
              physics: physics,
              slivers: [
                buildTopBar(),
                topFolderBar(v),
                buildNotes(v),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          toNotePage(defaultNewNote());
        },
        tooltip: '添加筆記',
        child: const Icon(Icons.add),
      ),
    );
  }

  void toNotePage(Note note) {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => EditNotePage(note: note)));
  }

  SliverAppBar buildTopBar() {
    return SliverAppBar(
      actions: [
        IconButton(
          onPressed: () {},
          tooltip: "设置",
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
      floating: true,
      snap: true,
      pinned: true,
      expandedHeight: 100.0,
      centerTitle: true,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          var top = constraints.biggest.height;
          // print("22334");
          // print(top);
          if (top < 62)
            return FlexibleSpaceBar(
              title: Text("记事本"),
              centerTitle: true,
            );
          return FlexibleSpaceBar(
            background: Container(
              margin: EdgeInsets.only(top: 20, left: 30),
              child: Text(
                "记事本",
                style: TextStyle(fontSize: 24),
              ),
            ),
            title: Container(
              height: top - 62,
              child: TextButton.icon(
                style: ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll(Colors.black12)),
                onPressed: () {},
                icon: Icon(Icons.search),
                label: Text(
                  '搜索笔记' + ' ' * 1000,
                  style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
                ),
              ),
            ),
            expandedTitleScale: 1,
            titlePadding: EdgeInsetsDirectional.only(start: 16, end: 16, bottom: 6),
          );
        },
      ),
    );
  }

  SliverAppBar topFolderBar(List<Note> v) {
    return SliverAppBar(
      forceMaterialTransparency: true,
      pinned: true,
      title: TextButton.icon(
        style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(Colors.black12)),
        onPressed: () {},
        icon: Icon(Icons.folder_copy_outlined),
        label: Text(
          '全部',
          style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
        ),
      ),
    );
  }

  buildNotes(List<Note> v) {
    return WaterfallFlow.builder(
        itemCount: v.length,
        itemBuilder: (context, index) {
          final note = v[index];
          return Card(
            child: ListTile(
              title: Text(
                note.title.isNotEmpty ? "${note.title}\n\n${note.content}" : note.content,
                maxLines: 5,
              ),
              subtitle: Text(
                  dateFormat.format(DateTime.fromMicrosecondsSinceEpoch(note.create))),
              onTap: () => toNotePage(note),
            ),
          );
        },
        //cacheExtent: 0.0,
        padding: EdgeInsets.all(5.0),
        gridDelegate: SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 5.0,
          mainAxisSpacing: 5.0,

          /// follow max child trailing layout offset and layout with full cross axis extend
          /// last child as loadmore item/no more item in [GridView] and [WaterfallFlow]
          /// with full cross axis extend
          //  LastChildLayoutType.fullCrossAxisExtend,

          /// as foot at trailing and layout with full cross axis extend
          /// show no more item at trailing when children are not full of viewport
          /// if children is full of viewport, it's the same as fullCrossAxisExtend
          //  LastChildLayoutType.foot,
          // lastChildLayoutTypeBuilder: (index) =>
          // index == _list.length ? LastChildLayoutType.foot : LastChildLayoutType.none,
        ));
    // return SliverGrid.builder(
    //   itemCount: v.length,
    //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
    //   itemBuilder: (context, index) {
    //     final note = v[index];
    //     return Card(
    //       child: ListTile(
    //         title: Text(
    //           note.title.isNotEmpty ? "${note.title}\n\n${note.content}" : note.content,
    //           maxLines: 5,
    //         ),
    //         subtitle:
    //             Text(dateFormat.format(DateTime.fromMicrosecondsSinceEpoch(note.create))),
    //         onTap: () => toNotePage(note),
    //       ),
    //     );
    //   },
    // );
  }
}

final isAndroid = Platform.isAndroid;

class EditNotePage extends StatefulWidget {
  final Note note;
  const EditNotePage({Key? key, required this.note}) : super(key: key);

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  final history = <String>[];
  late final editTitle = TextEditingController(text: widget.note.title);
  late final editContent = TextEditingController(text: widget.note.content);
  final editContentHistory = UndoHistoryController();
  final focusNode = FocusNode();
  late final dataString;
  bool hasSave = true;
  @override
  void initState() {
    final date = DateTime.fromMicrosecondsSinceEpoch(widget.note.create);
    dataString = dateFormat.format(date);
    addListenable(editTitle);
    addListenable(editContent);
    addListenable(editContentHistory);
    focusNode.addListener(save); //切換焦點自動保存 //win会丢失焦点
    super.initState();
  }

  void save() {
    if (hasSave || _wordLength == 0) return;
    final now = DateTime.now().microsecondsSinceEpoch;
    print("正在保存筆記$now");
    widget.note.title = editTitle.text;
    widget.note.content = editContent.text;
    widget.note.edit = now;
    notesBox.put(widget.note.create.toString(), widget.note);
    print("已經保存了$now");
    if (mounted) {
      hasSave = true;
      Future.delayed(Duration(milliseconds: 100), () => setState(() {}));
    }
  }

  void addListenable(Listenable listenable) {
    listenable.addListener(() {
      if (mounted) {
        hasSave = false;
        setState(() {});
      }
    });
  }

  String get _content => editTitle.text.isEmpty
      ? editContent.text
      : "${editTitle.text}\n\n${editContent.text}";

  int get _wordLength => editTitle.text.length + editContent.text.length;

  @override
  void dispose() {
    history.clear();
    editTitle.dispose();
    editContent.dispose();
    editContentHistory.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wordLength = _wordLength;
    return Container(
      decoration: BoxDecoration(
          color: Color(widget.note.backColor),
          image: widget.note.background.isEmpty
              ? null
              : DecorationImage(
                  image: AssetImage(widget.note.background), fit: BoxFit.cover)),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          toolbarOpacity: 1.0,
          actions: [
            if (!isAndroid || focusNode.hasFocus)
              IconButton(
                icon: Icon(Icons.undo_rounded),
                tooltip: "撤销",
                onPressed:
                    editContentHistory.value.canUndo ? editContentHistory.undo : null,
              ),
            if (!isAndroid || focusNode.hasFocus)
              IconButton(
                icon: Icon(Icons.redo_rounded),
                tooltip: "重做",
                onPressed:
                    editContentHistory.value.canRedo ? editContentHistory.redo : null,
              ),
            IconButton(
              icon: Icon(Icons.save),
              tooltip: hasSave
                  ? "已保存"
                  : wordLength == 0
                      ? "無内容"
                      : "保存",
              onPressed: hasSave
                  ? null
                  : wordLength == 0
                      ? null
                      : save,
            ),
            IconButton(
              icon: Icon(Icons.widgets_outlined),
              tooltip: "皮肤",
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.share_rounded),
              tooltip: "分享",
              onPressed: () {
                showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (context) {
                      final w = MediaQuery.of(context).size.width;
                      return Stack(
                        children: <Widget>[
                          Positioned(
                            bottom: 10,
                            left: w * 0.05,
                            child: Container(
                              width: w * 0.9,
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      InkWell(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text("以文本形式分享" + ' ' * 1000),
                                        ),
                                        onTap: () {
                                          Share.share(_content);
                                        },
                                      ),
                                      InkWell(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text("以圖片形式分享" + ' ' * 1000),
                                        ),
                                        onTap: () {},
                                      ),
                                      InkWell(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text("拷貝文本到剪貼板" + ' ' * 1000),
                                        ),
                                        onTap: () async {
                                          await Clipboard.setData(
                                              ClipboardData(text: _content));
                                          // Utils.toast("已复制图片地址");
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: TextButton(
                                            onPressed: () {},
                                            style: ButtonStyle(
                                                backgroundColor: MaterialStatePropertyAll(
                                                    Colors.black12)),
                                            child: Center(child: Text("取消"))),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    });
              },
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          physics: physics,
          slivers: <Widget>[
            SliverAppBar(
              forceMaterialTransparency: true,
              pinned: true,
              leading: Container(),
              leadingWidth: 0,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: TextButton.icon(
                    style: ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll(Colors.black12)),
                    onPressed: () {},
                    icon: Icon(Icons.folder_copy_outlined),
                    label: Text('未分類'),
                  ),
                )
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: editTitle,
                  textAlign: TextAlign.justify,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(hintText: "標題", border: InputBorder.none),
                  maxLines: null,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  "$dataString   |   $wordLength 字",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: editContent,
                  undoController: editContentHistory,
                  focusNode: focusNode,
                  // focusNode: FocusNode,
                  textAlign: TextAlign.justify,
                  autofocus: wordLength == 0,
                  decoration: InputDecoration(hintText: "開始書寫", border: InputBorder.none),
                  maxLines: null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
