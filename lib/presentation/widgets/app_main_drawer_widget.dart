import 'package:flutter/material.dart';
import 'package:nhasixapp/core/constants/colors_const.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';

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
              // Update the state of the app
              // ...
              // Then close the drawer
              Navigator.pop(context);
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
              // Update the state of the app
              // ...
              // Then close the drawer
              Navigator.pop(context);
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
              // Update the state of the app
              // ...
              // Then close the drawer
              Navigator.pop(context);
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
            },
          ),
        ],
      ),
    );
  }
}
