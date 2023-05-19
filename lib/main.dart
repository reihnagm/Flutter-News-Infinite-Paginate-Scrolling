import 'package:intl/intl.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'package:flutter_news/utils/constant.dart';
import 'package:flutter_news/models/news.dart';

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

  PagingController<int, Article> pagingC = PagingController<int, Article>(
    firstPageKey: 1,
  );

  @override 
  void initState() {
    super.initState();
    pagingC.addPageRequestListener((pageKey) {
      getNews(pageKey);
    });
  }

  Future<void> getNews(int pageKey) async {
    try { 
      Dio dio = Dio();
      Response res = await dio.get("${AppConstants.baseUrl}?country=id&apiKey=${AppConstants.newsKey}&page=$pageKey");
      Map<String, dynamic> data = res.data;
      NewsModel newsModel = NewsModel.fromJson(data);
      List<Article> articles = newsModel.articles!;

      int previouslyFetchedItemsCount = pagingC.itemList?.length ?? 0;
      
      bool isLastPage = articles.length < previouslyFetchedItemsCount;

      List<Article> newItems = articles;

      if (isLastPage) {
        pagingC.appendLastPage(newItems);
      } else {
        pagingC.appendPage(newItems, pageKey + 1);
      }
      
    } catch(e, stacktrace) {
      debugPrint(stacktrace.toString());
      pagingC.error = e;
    }
  }

  @override
  void dispose() {
    pagingC.dispose();
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
            pagingC.refresh();
          });
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [

            const SliverAppBar(
              backgroundColor: Colors.white,
              title: Text("News",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600
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
                pagingController: pagingC,
                separatorBuilder: (BuildContext context, int i) => const Divider(
                  thickness: 1.5,
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
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [

                              Expanded(
                                flex: 1,
                                child: CachedNetworkImage(
                                  imageUrl: article.urlToImage!,
                                  imageBuilder: (BuildContext context, ImageProvider image) {
                                    return CircleAvatar(
                                      backgroundImage: image,
                                      maxRadius: 30.0,
                                    );
                                  },
                                ),
                              ),
                              
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(article.title!,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w500
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(DateFormat.yMEd().format(article.publishedAt!),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10.0,
                                        fontWeight: FontWeight.w500
                                      ),
                                    ),
                                  ],
                                ) 
                              ),

                            ],
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
                  firstPageErrorIndicatorBuilder: (context) => const Center(
                    child: Text("Oops! there was problem",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500
                      ),
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
                      fontSize: 16.0,
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
