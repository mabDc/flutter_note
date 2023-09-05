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
          toNotePage(context, defaultNewNote());
        },
        tooltip: '添加筆記',
        child: const Icon(Icons.add),
      ),
    );
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
      title: Text("记事本"),
      centerTitle: true,
      floating: true,
      snap: true,
      pinned: true,
      expandedHeight: 100.0,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          var top = constraints.biggest.height;
          // print("22334");
          // print(top);
          if (top < 62) return Container();
          return FlexibleSpaceBar(
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
}

void toNotePage(BuildContext context, Note note) {
  Navigator.push(
      context, MaterialPageRoute(builder: (context) => EditNotePage(note: note)));
}

Widget buildNotes(List<Note> v) {
  return SliverPadding(
    padding: EdgeInsets.all(16),
    sliver: SliverWaterfallFlow(
      gridDelegate: SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        // collectGarbage: (List<int> garbages) {
        //   print('collect garbage : $garbages');
        // },
        // viewportBuilder: (int firstIndex, int lastIndex) {
        //   print('viewport : [$firstIndex,$lastIndex]');
        // },
      ),
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          final note = v[index];
          final foreColor = Color(note.foreColor);
          final time = Text(
            dateFormat.format(DateTime.fromMicrosecondsSinceEpoch(note.create)),
            style: TextStyle(color: foreColor.withAlpha(140)),
          );

          return Container(
            decoration:
                buildDecoration(note).copyWith(borderRadius: BorderRadius.circular(12)),
            child: Card(
              color: Colors.transparent,
              child: Container(
                decoration: buildDecoration(note)
                    .copyWith(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.all(4),
                child: InkWell(
                  onTap: () => toNotePage(context, note),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (note.title.isNotEmpty)
                        Text(
                          note.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 22,
                            color: foreColor,
                            decoration: TextDecoration.underline,
                            decorationColor: foreColor,
                            decorationThickness: 0.8,
                          ),
                        ),
                      Text(
                        note.content,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: note.title.isEmpty ? 16 : null, color: foreColor),
                        maxLines: 6,
                      ),
                      Row(children: [Spacer(), time])
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        childCount: v.length,
      ),
    ),
  );
}

final isAndroid = Platform.isAndroid;
BoxDecoration buildDecoration(Note note) {
  return BoxDecoration(
    color: Color(note.backColor),
    // borderRadius: BorderRadius.circular(20),
    image: note.background.isEmpty
        ? null
        : DecorationImage(image: AssetImage(note.background), fit: BoxFit.cover),
  );
}

void buildShowMenu<T>(BuildContext context, List<PopupMenuEntry<T>> items) {
  final s = MediaQuery.of(context).size;
  showMenu<T>(
    context: context,
    constraints: BoxConstraints(minWidth: s.width - 100),
    position: RelativeRect.fromLTRB(50, s.height, 50, 10),
    items: items,
  );
}

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
  late final foreColor = Color(widget.note.foreColor);
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
    return WillPopScope(
      onWillPop: () async {
        if (focusNode.hasFocus) {
          focusNode.unfocus();
          save();
          return false;
        }
        return true;
      },
      child: Container(
        decoration: buildDecoration(widget.note),
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                if (focusNode.hasFocus) {
                  focusNode.unfocus();
                  save();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
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
                  final s = MediaQuery.of(context).size;
                  showMenu(
                    context: context,
                    shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    constraints: BoxConstraints(minWidth: s.width - 80),
                    position: RelativeRect.fromLTRB(40, s.height - 120, 40, 0),
                    items: [
                      PopupMenuItem(
                        child: Text("以文本形式分享"),
                        onTap: () {
                          if (_content.isNotEmpty) Share.share(_content);
                        },
                      ),
                      PopupMenuItem(
                        child: Text("以圖片形式分享"),
                      ),
                      PopupMenuItem(
                        child: Text("拷貝文本到剪貼板"),
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _content));
                        },
                      ),
                    ],
                  );
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
                      onPressed: () {
                        final s = MediaQuery.of(context).size;
                        var n = "";
                        showMenu(
                          context: context,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          constraints: BoxConstraints(minWidth: s.width - 80),
                          position: RelativeRect.fromLTRB(40, s.height - 120, 40, 20),
                          items: [
                            PopupMenuItem(
                              child: Text("未分类"),
                              onTap: () => widget.note.folder = "",
                            ),
                            PopupMenuItem(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      onChanged: (value) => n = value,
                                      onSubmitted: (value) {
                                        widget.note.folder = value;
                                        Navigator.of(context).pop();
                                      },
                                      decoration: InputDecoration(hintText: "添加新分类"),
                                    ),
                                  ),
                                  TextButton(
                                      onPressed: () {
                                        widget.note.folder = n;
                                        Navigator.of(context).pop();
                                      },
                                      child: Text("确定")),
                                ],
                              ),
                            ),
                          ],
                        ).then((value) {
                          setState(() {});
                        });
                      },
                      icon: Icon(Icons.folder_copy_outlined),
                      label:
                          Text(widget.note.folder.isEmpty ? '未分類' : widget.note.folder),
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
                    style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold, color: foreColor),
                    decoration: InputDecoration(
                        hintText: "標題",
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: foreColor.withAlpha(130))),
                    maxLines: null,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    "$dataString   |   $wordLength 字",
                    style: TextStyle(color: foreColor.withAlpha(150)),
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
                    style: TextStyle(color: foreColor),
                    autofocus: wordLength == 0,
                    decoration: InputDecoration(
                        hintText: "開始書寫",
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: foreColor.withAlpha(130))),
                    maxLines: null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
