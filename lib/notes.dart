import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

const notesBoxKey = "notes";
const notesTypeId = 1;
late final Box<Note> notesBox;

class _StyleItem {
  final Color backColor;
  final Color foreColor;
  final String background;
  const _StyleItem(this.backColor, this.foreColor, this.background);
}

final styles = [
  const _StyleItem(Color(0xFFFFFFCC), Color(0xFF303133), ''), //page_turn
  const _StyleItem(Color(0xfff1f1f1), Color(0xff373534), ''), //白底
  const _StyleItem(Color(0xfff5ede2), Color(0xff373328), ''), //浅黄
  const _StyleItem(Color(0xFFF5DEB3), Color(0xff373328), ''), //黄
  const _StyleItem(Color(0xffe3f8e1), Color(0xff485249), ''), //绿
  const _StyleItem(Color(0xff999c99), Color(0xff353535), ''), //浅灰
  const _StyleItem(Color(0xff33383d), Color(0xffc5c4c9), ''), //黑
  const _StyleItem(Color(0xff010203), Color(0xFfffffff), ''), //纯黑
  ///
  const _StyleItem(Color(0xFF303133), Color(0xFFFFFFCC), ''), //page_turn
  const _StyleItem(Color(0xff373534), Color(0xfff1f1f1), ''), //白底
  const _StyleItem(Color(0xff373328), Color(0xfff5ede2), ''), //浅黄
  const _StyleItem(Color(0xff373328), Color(0xFFF5DEB3), ''), //黄
  const _StyleItem(Color(0xff485249), Color(0xffe3f8e1), ''), //绿
  const _StyleItem(Color(0xff353535), Color(0xff999c99), ''), //浅灰
  const _StyleItem(Color(0xffc5c4c9), Color(0xff33383d), ''), //黑
  const _StyleItem(Color(0xFfffffff), Color(0xff010203), ''), //纯黑
  ///
  const _StyleItem(Color(0xffffffff), Color(0xff101010), "assets/bg/001.jpg"),
  const _StyleItem(Color(0xffffffff), Color(0xff101010), "assets/bg/002.jpg"),
  const _StyleItem(Color(0xffffffff), Color(0xff000000), "assets/bg/003.png"),
  const _StyleItem(Color(0xffffffff), Color(0xff102030), "assets/bg/004.jpg"),
  const _StyleItem(Color(0xff101010), Color(0xffc5c4c9), "assets/bg/005.jpg"),
  const _StyleItem(Color(0xfffefefe), Color(0xff353535), "assets/bg/006.jpg"),
  const _StyleItem(Color(0xff101010), Color(0xffc5c4c9), "assets/bg/007.jpg"),
  const _StyleItem(Color(0xfffefefe), Color(0xff010203), "assets/bg/008.png"),
];

void deleteNote(int id) {
  notesBox.delete(id);
}

class Note {
  bool pin;
  final int create;
  int edit;
  int foreColor;
  int backColor;
  String background;
  String folder;
  String title;
  String content;

  Note(
    this.pin,
    this.create,
    this.edit,
    this.foreColor,
    this.backColor,
    this.background,
    this.folder,
    this.title,
    this.content,
  );

  static Note defaultNewNote({
    String title = "",
    String content = "",
  }) {
    return Note(
      false,
      DateTime.now().microsecondsSinceEpoch,
      DateTime.now().microsecondsSinceEpoch,
      Colors.black.value,
      Colors.white.value,
      "",
      "",
      title,
      content,
    );
  }
}

class NoteAdapter extends TypeAdapter<Note> {
  @override
  Note read(BinaryReader reader) {
    // T cast<T>(x, T v) => x is T ? x : v;
    // final create = cast(reader.readInt(), DateTime.now().millisecondsSinceEpoch),
    //     title = cast(reader.readString(), ""),
    //     content = cast(reader.readString(), "");
    final pin = reader.readBool(),
        create = reader.readInt(),
        edit = reader.readInt(),
        foreColor = reader.readInt(),
        backColor = reader.readInt(),
        background = reader.readString(),
        folder = reader.readString(),
        title = reader.readString(),
        content = reader.readString();
    return Note(
      pin,
      create,
      edit,
      foreColor,
      backColor,
      background,
      folder,
      title,
      content,
    );
  }

  @override
  int get typeId => notesTypeId;

  @override
  void write(BinaryWriter writer, Note obj) {
    writer.writeBool(obj.pin);
    writer.writeInt(obj.create);
    writer.writeInt(obj.edit);
    writer.writeInt(obj.foreColor);
    writer.writeInt(obj.backColor);
    writer.writeString(obj.background);
    writer.writeString(obj.folder);
    writer.writeString(obj.title);
    writer.writeString(obj.content);
  }
}
