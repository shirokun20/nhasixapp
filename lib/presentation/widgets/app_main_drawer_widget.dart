import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import '../../core/routing/app_route.dart';

class AppMainDrawerWidget extends StatelessWidget {
  const AppMainDrawerWidget({
    super.key,
    required this.context,
  });

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
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
                    color: theme.textTheme.headlineLarge?.color,
                  ),
                ),
                Text(
                  'Nhentai unofficial client',
                  style: TextStyleConst.caption.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.download,
              color: theme.iconTheme.color,
            ),
            title: Text(
              'Downloaded galleries',
              style: TextStyleConst.navigationLabel.copyWith(
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoute.downloads);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.offline_bolt,
              color: theme.iconTheme.color,
            ),
            title: Text(
              'Offline content',
              style: TextStyleConst.navigationLabel.copyWith(
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.push('/offline');
            },
          ),
          ListTile(
            leading: Icon(
              Icons.shuffle,
              color: theme.iconTheme.color,
            ),
            title: Text(
              'Random gallery',
              style: TextStyleConst.navigationLabel.copyWith(
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoute.random);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.favorite,
              color: theme.iconTheme.color,
            ),
            title: Text(
              'Favorite galleries',
              style: TextStyleConst.navigationLabel.copyWith(
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoute.favorites);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.history,
              color: theme.iconTheme.color,
            ),
            title: Text(
              'View history',
              style: TextStyleConst.navigationLabel.copyWith(
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoute.history);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.settings,
              color: theme.iconTheme.color,
            ),
            title: Text(
              'Settings',
              style: TextStyleConst.navigationLabel.copyWith(
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoute.settings);
            },
          ),
        ],
      ),
    );
  }
}
