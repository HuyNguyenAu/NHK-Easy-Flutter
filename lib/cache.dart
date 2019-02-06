import 'dart:convert';
import 'dart:io';

import 'package:nhk_easy/nhk_easy.dart';
import 'package:path_provider/path_provider.dart';

Future<String> get _localPath async {
  return (await getApplicationDocumentsDirectory()).path;
}

Future<void> cacheArticle(final Article _article) async {
  try {
    final _path = await _localPath,
        _cachedFile = File('$_path/${_article.id}.dat'),
        _data = jsonEncode({
      'id': _article.id,
      'title': _article.title,
      'image': _article.image,
      'date': _article.date,
      'content': _article.content
    });

    if (!await _cachedFile.exists()) {
      await _cachedFile.create();
    }

    await _cachedFile.writeAsString(_data);
  } catch (e) {
    throw Exception('Failed to cache article.');
  }
}

Future getCachedFiles() async {
  final _path = await _localPath,
      _cachedDir = await Directory('$_path').list().toList(),
      _cachedFiles = [];
  
  for (final _cachedFile in _cachedDir) {
    if (_cachedFile.toString().contains('.dat')) {
      _cachedFiles.add(_cachedFile.path);
    }
  }
  return _cachedFiles;
}

Future<void> cleanUpCachedFiles(List<Article> _items) async {
  final _path = await _localPath,
      _cachedFiles = await getCachedFiles();
  
  for (Article _item in _items) {
    if (_cachedFiles.singleWhere((x) => x.toString().contains(_item.id)).isEmpty) {
      final File _cachedFile = File('$_path/${_item.id}.dat');

      await _cachedFile.delete();
    }
  }
}

Future<Article> retrieveArticle(final String id) async {
  final _path = await _localPath, _cachedFile = File('$_path/$id.dat');

  if (await _cachedFile.exists()) {
    final _data = jsonDecode(await _cachedFile.readAsString());
    
    return Article.build(
        _data['id'], _data['title'], _data['image'], _data['date'], _data['content']);
  }

  return null;
}
