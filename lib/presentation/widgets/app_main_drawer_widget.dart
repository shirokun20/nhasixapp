import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nhasixapp/core/constants/colors_const.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/core/routing/app_route.dart';

class AppMainDrawerWidget extends StatelessWidget {
  const AppMainDrawerWidget({
    super.key,
    required this.context,
  });

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: ColorsConst.darkSurface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              color: ColorsConst.darkCard,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const SizedBox(
                  height: 16,
                ),
                const Image(
                  height: 80,
                  width: 80,
                  image: AssetImage('assets/icons/ic_launcher-web.png'),
                ),
                const SizedBox(
                  height: 16,
                ),
                Text(
                  'Nhentai',
                  style: TextStyleConst.headingLarge.copyWith(
                    fontSize: 30,
                  ),
                ),
                Text(
                  'Nhentai unofficial client',
                  style: TextStyleConst.caption.copyWith(
                    color: ColorsConst.darkTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.download,
              color: ColorsConst.darkTextSecondary,
            ),
            title: Text(
              'Downloaded galleries',
              style: TextStyleConst.navigationLabel,
            ),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoute.downloads);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.offline_bolt,
              color: ColorsConst.accentGreen,
            ),
            title: Text(
              'Offline content',
              style: TextStyleConst.navigationLabel,
            ),
            onTap: () {
              Navigator.pop(context);
              context.push('/offline');
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.shuffle,
              color: ColorsConst.darkTextSecondary,
            ),
            title: Text(
              'Random gallery',
              style: TextStyleConst.navigationLabel,
            ),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoute.random);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.favorite,
              color: ColorsConst.accentPink,
            ),
            title: Text(
              'Favorite galleries',
              style: TextStyleConst.navigationLabel,
            ),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoute.favorites);
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.history,
              color: ColorsConst.darkTextSecondary,
            ),
            title: Text(
              'View history',
              style: TextStyleConst.navigationLabel,
            ),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoute.history);
            },
          ),
        ],
      ),
    );
  }
}
