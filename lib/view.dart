import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';
import 'model.dart';
import 'view_model.dart';

final names = ['聴きたい', '聴いた', '好き'];
final labels = ['聴きたい', '聴いた', '好き'];
final colors = [
  Colors.blue.shade50,
  Colors.orange.shade50,
  Colors.green.shade50,
];

class KanbanView extends StatefulWidget {
  final KanbanViewModel vm;
  KanbanView(this.vm, {super.key});

  @override
  State<KanbanView> createState() => _KanbanViewState();
}

class _KanbanViewState extends State<KanbanView> {
  final input = TextEditingController();
  final urlInput = TextEditingController();

  void add() {
    widget.vm.add(input.text, urlInput.text.trim());
    input.clear();
    urlInput.clear();
  }

  Uri? parseLink(String url) {
    var s = url.trim();
    if (s.isEmpty) return null;
    if (!s.contains('://')) s = 'https://$s';
    final uri = Uri.tryParse(s);
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return uri;
  }

  Future<void> edit(Task t) async {
    var text = t.title;
    var url = t.url;
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('リストを編集'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: text,
              autofocus: true,
              decoration: InputDecoration(labelText: '曲名'),
              onChanged: (v) => text = v,
            ),
            TextFormField(
              initialValue: url,
              decoration: InputDecoration(labelText: 'URL'),
              onChanged: (v) => url = v,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text('キャンセル')),
          FilledButton(
            onPressed: () => Navigator.pop(c, (text, url)),
            child: Text('保存'),
          ),
        ],
      ),
    );
    if (result != null) widget.vm.rename(t, result.$1, result.$2);
  }

  Widget taskCard(Task t) {
    final s = t.status;
    final buttons = Wrap(
      spacing: 4,
      children: [
        if (s > 0)
          TextButton(
            onPressed: () => widget.vm.move(t, s - 1),
            child: Text('← ${labels[s - 1]}へ'),
          ),
        if (s < 2)
          FilledButton(
            onPressed: () => widget.vm.move(t, s + 1),
            child: Text('${labels[s + 1]}へ →'),
          ),
      ],
    );
    return Card(
      child: ListTile(
        title: Text(t.title),
        subtitle: buttons,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: Icon(Icons.edit), onPressed: () => edit(t)),
            openButton(t),
            IconButton(
              icon: Icon(Icons.delete_outline),
              onPressed: () => widget.vm.remove(t),
            ),
          ],
        ),
      ),
    );
  }

  Widget openButton(Task t) {
    final uri = parseLink(t.url);
    if (uri == null) {
      return IconButton(icon: Icon(Icons.open_in_new), onPressed: null);
    }
    return Link(
      uri: uri,
      target: LinkTarget.blank,
      builder: (context, followLink) => IconButton(
        icon: Icon(Icons.open_in_new),
        onPressed: followLink,
      ),
    );
  }

  Widget lane(int s) {
    final cards = [
      for (final t in widget.vm.tasks)
        if (t.status == s) taskCard(t),
    ];
    return SizedBox(
      width: 300,
      child: Card(
        color: colors[s],
        child: Column(
          children: [
            ListTile(title: Text(names[s]), trailing: Text('${cards.length}件')),
            Expanded(child: ListView(children: cards)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    input.dispose();
    urlInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: input,
      decoration: InputDecoration(
        labelText: '新しい曲',
        hintText: '例：丸の内サディスティック',
        border: OutlineInputBorder(),
      ),
    );
    final urlField = TextField(
      controller: urlInput,
      decoration: InputDecoration(
        labelText: 'URL',
        hintText: '例：https://www.youtube.com/watch?v=...',
        border: OutlineInputBorder(),
      ),
    );
    final button = ValueListenableBuilder(
      valueListenable: input,
      builder: (context, value, child) => FilledButton.icon(
        onPressed: value.text.isEmpty ? null : add,
        icon: Icon(Icons.add),
        label: Text('聴きたいに追加'),
      ),
    );
    final entry = Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            field,
            SizedBox(height: 8),
            urlField,
            Align(alignment: Alignment.centerRight, child: button),
          ],
        ),
      ),
    );
    final board = ListenableBuilder(
      listenable: widget.vm,
      builder: (context, child) => ListView(
        scrollDirection: Axis.horizontal,
        children: [for (int s = 0; s < 3; s++) lane(s)],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text('📋 Kanban')),
      body: Column(
        children: [
          entry,
          Expanded(child: board),
        ],
      ),
    );
  }
}
