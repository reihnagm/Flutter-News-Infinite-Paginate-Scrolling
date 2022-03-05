import 'package:dio/dio.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pagination/models/news.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Pagination',
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key }) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GlobalKey<ScaffoldState> globalKey = GlobalKey<ScaffoldState>();

  final pagingController = PagingController<int, Article>(
    firstPageKey: 1,
  );

  @override 
  void initState() {
    super.initState();
    pagingController.addPageRequestListener((pageKey) {
      fetchPage(pageKey);
    });
  }

  Future<void> fetchPage(int pageKey) async {
    try { 
      Dio dio = Dio();
      Response res = await dio.get("https://newsapi.org/v2/top-headlines?country=us&apiKey=93173e715f5f414593ec9e4be79001c6&page=$pageKey");
      Map<String, dynamic> data = res.data;
      NewsModel newsModel = NewsModel.fromJson(data);
      List<Article> articles = newsModel.articles!;

      final previouslyFetchedItemsCount = pagingController.itemList?.length ?? 0;
      
      final isLastPage = articles.length < previouslyFetchedItemsCount;
      final newItems = articles;

      if (isLastPage) {
        pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + 1;
        pagingController.appendPage(newItems, nextPageKey);
      }
    } catch(e) {
      pagingController.error = e;
      debugPrint(e.toString());
    }
  }

  @override
  void dispose() {
    pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: globalKey,
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xffF8F8FF),
      body: RefreshIndicator(
        backgroundColor: Colors.white,
        color: Colors.black,
        onRefresh: () {
          return Future.sync(() {
            pagingController.refresh();
          });
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            const SliverAppBar(
              backgroundColor: Colors.white,
              title: Text("News App",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w400
                ),
              ),
              pinned: true,
              centerTitle: true,
              forceElevated: true,
              elevation: 0.0,
              automaticallyImplyLeading: false,
            ),
        
            SliverPadding(
              padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
              sliver: PagedSliverList.separated(
                pagingController: pagingController,
                separatorBuilder: (context, index) => const SizedBox(
                  height: 16.0,
                ),
                builderDelegate: PagedChildBuilderDelegate<Article>(
                  itemBuilder: (BuildContext context, Article article, int i) {
                    return Container(
                      margin: const EdgeInsets.only(
                        left: 16.0, 
                        right: 16.0
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(article.title!,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500
                            ),
                          )
                        ],
                      ),
                    );
                  },
                  animateTransitions: true,
                  firstPageProgressIndicatorBuilder: (context) {
                    return const SpinKitChasingDots(
                      size: 16.0,
                      color: Colors.black
                    );
                  },
                  firstPageErrorIndicatorBuilder: (context) => const Text("Error",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500
                    ),
                  ),
                  newPageProgressIndicatorBuilder: (context) {
                    return const SpinKitChasingDots(
                      size: 16.0,
                      color: Colors.black
                    );
                  },
                  noItemsFoundIndicatorBuilder: (context) =>  const Text("No items Found",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500
                    ),
                  ),
                )
              ),
            )
      
          ],
        ),
      )
    );
  }
}
