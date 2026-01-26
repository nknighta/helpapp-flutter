import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:help_app/app_router.dart';

@RoutePage()
class RootPage extends StatelessWidget {
  const RootPage({super.key});
  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: const [
        MapRoute(), //マップ
        HomeRoute(), //ホーム
        ProfileRoute(), //プロフィール
      ],
      builder: (context, child) {
        final tabsRouter = context.tabsRouter;
        return (Scaffold(
          appBar: AppBar(
            title: const Text("helpapp"),
          ),
          body: child,
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.map), // ホーム遷移
                label: 'マップ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.home), // マップ遷移
                label: 'ホーム',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.face), // チャット遷移
                label: 'プロフィール',
              )
            ],
            currentIndex: tabsRouter.activeIndex,
            onTap: tabsRouter.setActiveIndex,
          ),
        ));
      },
    );
  }
}
