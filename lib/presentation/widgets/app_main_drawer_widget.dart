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
      backgroundColor: ColorsConst.primaryColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              color: ColorsConst.primaryColor,
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
                  style: TextStyleConst.styleBold(
                    textColor: ColorsConst.primaryTextColor,
                    size: 30,
                  ),
                ),
                Text(
                  'Nhentai unofficial client',
                  style: TextStyleConst.styleRegular(
                    textColor: ColorsConst.primaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.download,
              color: ColorsConst.primaryTextColor,
            ),
            title: Text(
              'Downloaded galleries',
              style: TextStyleConst.styleRegular(
                textColor: ColorsConst.primaryTextColor,
              ),
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
              color: ColorsConst.primaryTextColor,
            ),
            title: Text(
              'Random gallery',
              style: TextStyleConst.styleRegular(
                textColor: ColorsConst.primaryTextColor,
              ),
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
              Icons.favorite,
              color: ColorsConst.primaryTextColor,
            ),
            title: Text(
              'Favorite galleries',
              style: TextStyleConst.styleRegular(
                textColor: ColorsConst.primaryTextColor,
              ),
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
              color: ColorsConst.primaryTextColor,
            ),
            title: Text(
              'View history',
              style: TextStyleConst.styleRegular(
                textColor: ColorsConst.primaryTextColor,
              ),
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
