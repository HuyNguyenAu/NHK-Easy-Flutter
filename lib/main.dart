import 'cache.dart';
import 'nhk_easy.dart';
import 'settings.dart';
import 'dart:async';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DynamicTheme(
      defaultBrightness: Brightness.light,
      data: (brightness) => ThemeData(
            primarySwatch: Colors.blue,
            brightness: brightness,
          ),
      themedWidgetBuilder: (context, theme) {
        return MaterialApp(
          title: 'NHK Easy',
          home: MyHomePage(title: 'NHK Easy'),
          theme: theme,
        );
      },
    );
  }
}

class DoubleHolder {
  double value = 0.01;
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;
  final DoubleHolder offset = new DoubleHolder();

  double getScrollOffset() {
    return offset.value;
  }

  void setScrollOffset(final double value) {
    offset.value = value;
  }

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class ArticlePage extends StatefulWidget {
  ArticlePage({Key key, this.article, this.fontSize}) : super(key: key);
  final Article article;
  final int fontSize;

  @override
  _ArticlePageState createState() => _ArticlePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isloading = false, scrollToTopVisible = false;
  int _fontSize = 0;
  ScrollController scrollController = ScrollController();
  GlobalKey<RefreshIndicatorState> globalKey =
      GlobalKey<RefreshIndicatorState>();
  double progress = 0.0;
  Stopwatch stopwatch = Stopwatch();
  List<Article> articles = [];

  Future load() async {
    if (isloading) {
      return;
    }
    final newsList = await getNewsList();
    double count = 0.0;

    setState(() {
      isloading = true;
    });

    for (final Map news in newsList) {
      final Article article = await buildArticle(news);

      setState(() {
        articles.add(article);
        progress = count++ / newsList.length;
      });
      cacheArticle(article);
    }
    setState(() {
      isloading = false;
    });
    progress = 0.0;
    await cleanUpCachedFiles(articles);
  }

  double changefontSize() {
    if (_fontSize == 0) {
      return 16.0;
    } else if (_fontSize == 1) {
      return 19.0;
    }
    return 22.0;
  }

  @override
  Widget build(BuildContext context) {
    scrollController =
        new ScrollController(initialScrollOffset: widget.getScrollOffset());
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          Opacity(
            opacity: isloading ? 1.0 : 0.0,
            child: CircularPercentIndicator(
              radius: 24.0,
              lineWidth: 5.0,
              percent: progress,
              progressColor: Colors.white,
            ),
          ),
          IconButton(
            icon: Icon(IconData(0xe264, fontFamily: 'MaterialIcons')),
            onPressed: () {
              setState(() {
                if (_fontSize >= 0 && _fontSize < 2) {
                  setState(() {
                    _fontSize++;
                  });
                } else {
                  _fontSize = 0;
                }
                saveFontSize(_fontSize);
              });
            },
          ),
          IconButton(
            icon: Icon(Theme.of(context).brightness == Brightness.light
                ? Icons.wb_sunny
                : IconData(0xe3a8, fontFamily: 'MaterialIcons')),
            onPressed: () {
              DynamicTheme.of(context).setBrightness(
                  Theme.of(context).brightness == Brightness.dark
                      ? Brightness.light
                      : Brightness.dark);
              Theme.of(context).brightness == Brightness.dark
                  ? saveBrightness(true)
                  : saveBrightness(false);
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: load,
          ),
        ],
      ),
      body: RefreshIndicator(
        key: globalKey,
        onRefresh: load,
        child: NotificationListener(
          child: ListView.builder(
            controller: scrollController,
            itemCount: articles.length,
            itemBuilder: (BuildContext buildContext, int index) {
              return ListTile(
                title: Text(
                  articles.elementAt(index).title,
                  style: TextStyle(fontSize: changefontSize()),
                ),
                subtitle: Text(articles.elementAt(index).date),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ArticlePage(
                            article: articles.elementAt(index),
                            fontSize: _fontSize,
                          )));
                },
              );
            },
          ),
          onNotification: (notification) {
            if (notification is ScrollNotification) {
              widget.setScrollOffset(notification.metrics.pixels);
            }
            setState(() {
              scrollToTopVisible = true;
            });
            Future.delayed(const Duration(milliseconds: 3000), () {
              setState(() {
                scrollToTopVisible = false;
              });
            });
          },
        ),
      ),
      floatingActionButton: Opacity(
        opacity: scrollToTopVisible ? 1.0 : 0.0,
        child: FloatingActionButton(
          child: Icon(Icons.arrow_upward),
          onPressed: () {
            scrollController.jumpTo(0.01);
          },
        ),
      ),
    );
  }

  void doStuff() async{
     setState(() {
       
    });
      await getFontSize().then((x) => _fontSize = x);
      await getBrightness().then((x) => DynamicTheme.of(context)
          .setBrightness(x ? Brightness.dark : Brightness.light));
  }

  @override
  void initState() {
    super.initState();

   
  }
}

class _ArticlePageState extends State<ArticlePage> {
  @override
  Widget build(BuildContext context) {
    String url = Uri.dataFromString(
        buildContent(
            widget.article, Theme.of(context).brightness, widget.fontSize),
        mimeType: 'text/html',
        parameters: {'charset': 'utf-8'}).toString();
    return Container(
      child: WebviewScaffold(
        initialChild: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Color.fromARGB(255, 46, 46, 46)
                : Color.fromARGB(255, 250, 250, 250),
          ),
        ),
        appBar: AppBar(),
        scrollBar: false,
        enableAppScheme: true,
        withZoom: true,
        url: url,
      ),
    );
  }
}
