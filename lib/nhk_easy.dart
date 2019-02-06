import 'cache.dart';
import 'dart:convert' show jsonDecode, utf8, base64;
import 'package:html/dom.dart' show Document, Element;
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' show Response, get;
import 'package:flutter/material.dart' show Brightness;

Future<Response> _getResponse(
    final _url, final Map<String, String> _headers) async {
  final Response _response = await get(_url, headers: _headers);

  if (_response.statusCode == 200) {
    return _response;
  } else {
    throw Exception('Failed to get response.');
  }
}

Future getNewsList() async {
  final Response _response = await _getResponse(
      'http://www3.nhk.or.jp/news/easy/news-list.json',
      {'Content-Type': 'application/json; charset=utf-8'});

  if (_response.body.isNotEmpty) {
    return (jsonDecode(utf8.decode(_response.bodyBytes)).first as Map)
        .values
        .expand((map) => map);
  } else {
    throw Exception('Failed to get news list.');
  }
}

Future<String> _getImageData(final String url) async {
  String _data = '';
  try {
    final Response _response = await _getResponse(url,
        {'Content-Type': 'image/jpeg', 'Content-Transfer-Encoding': 'base64'});

    if (_response.bodyBytes.isNotEmpty) {
      _data = base64.encode(_response.bodyBytes);
    }
  } catch (e) {
    return _data;
  }
  return _data;
}

Future<String> buildImage(final List<String> _urls) async {
  String _image = '';

  for (String _url in _urls) {
    final String _base64Data = await _getImageData(_url);

    if (_base64Data.isNotEmpty) {
      _image =
          '<img style=" max-width: 100%; max-height: 100vh; margin: auto;" src="data:image/jpeg;base64,' +
              _base64Data +
              '">';
    }
  }
  return _image;
}

Future<Article> buildArticle(final Map _data) async {
  Article _article = Article();

  try {
    final String _id = _data['news_id'], _title = _data['title'];

    final _cache = await retrieveArticle(_id);
    if (_cache != null) {
      return _cache;
    }

    final List<String> _images = [
      'http://www3.nhk.or.jp/news/easy/$_id/$_id.jpg',
      _data['news_web_image_uri']
    ];

    final Response _response = await _getResponse(
        'http://www3.nhk.or.jp/news/easy/$_id/$_id.html',
        {'Content-Type': 'text/html; charset=utf-8'});

    if (_response.body.isNotEmpty) {
      final Document _document = parse(utf8.decode(_response.bodyBytes));
      _document.querySelectorAll('img').forEach((x) => x.remove());
      _document.querySelectorAll('.playerWrapper').forEach((x) => x.remove());
      _document.querySelectorAll('.dicWin').forEach((x) => x.remove());
      _document
          .querySelectorAll('rt')
          .forEach((x) => x.innerHtml = '(${x.innerHtml})');

      final Element _dateContent = _document.querySelector('#js-article-date'),
          _titleContent = _document.querySelector('.article-main__title'),
          _articleContent = _document.querySelector('#js-article-body');

      _article = Article.build(
          _id,
          _title,
          await buildImage(_images),
          _dateContent.innerHtml,
          _titleContent.outerHtml +
              _dateContent.outerHtml +
              _articleContent.outerHtml);
      await cacheArticle(_article);
    }
  } catch (e) {
    throw Exception('Failed to build article.');
  }
  return _article;
}

List<String> _getTheme(final Brightness _brightness) {
  if (_brightness == Brightness.dark) {
    return ['#eeeeee', '#2c2c2c'];
  }
  return ['#000000', '#fafafa'];
}

List<String> _getFontSize(final int _fontSize) {
  if (_fontSize == 0) {
    return ['medium', 'large'];
  } else if (_fontSize == 1) {
    return ['large', 'x-large'];
  }
  return ['x-large', 'xx-large'];
}

String buildContent(
    final Article _article, final Brightness _brightness, final int _fontSize) {
  final List<String> _theme = _getTheme(_brightness),
      _fontSizes = _getFontSize(_fontSize);

  return '\n<?xml version="1.0" encoding="UTF-8" ?>' +
      '\n<!>' +
      '\n<html lang=\'ja\'>' +
      '\n<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes">' +
      '\n<head><meta http-equiv="content-type" content="application/xhtml+xml; charset=UTF-8">' +
      '\n<style type="text/css"> body { margin-left: 0.5em; margin-right: 0.5em;' +
      '\nmargin-top: 0.5em; margin-bottom: 0.5em;' +
      '\nline-break: normal; -epub-line-break: normal; -webkit-line-break: normal;' +
      '\ncolor: ${_theme.first}; font-size: larger; background: ${_theme.last}; line-height: 200%;' +
      '\nfont-family: "Hiragino Sans", sans-serif; } p { text-indent: 1em;' +
      '\nfont-size: ${_fontSizes.first} } h1 { font-weight: 500; font-size: ${_fontSizes.last}; } </style>' +
      '\n</head><body>${_article.image}${_article.content}\n</body></html>';
}

class Article {
  final String id, title, image, date, content;

  Article({this.id, this.title, this.image, this.date, this.content});

  factory Article.build(
      String id, String title, String image, String date, String content) {
    return Article(
        id: id, title: title, image: image, date: date, content: content);
  }
}
