import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:help_app/app_router.dart';

@RoutePage()
class RootPage extends StatelessWidget {
  const RootPage ({super.key});
  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: const [
        HomeRoute(),
        MapRoute(),
        ChatRoute(),
      ],
      builder: (context, child) {
        final tabsRouter = context.tabsRouter;
        return(
          Scaffold(
            body: child,
            bottomNavigationBar: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'ホーム',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.map),
                  label: 'マップ',
                )
              ],
              currentIndex: tabsRouter.activeIndex,
              onTap: tabsRouter.setActiveIndex,
            ),
          )
        );
      },
    );
  }
}
