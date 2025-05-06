import 'package:flutter/material.dart';
import 'package:nhasixapp/core/constants/colors_const.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsConst.secondaryColor,
      appBar: appBar(context),
      drawer: customDrawer(),
    );
  }

  PreferredSizeWidget appBar(BuildContext context) {
    return AppBar(
      leading: Builder(builder: (context) {
        return IconButton(
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
          color: ColorsConst.primaryTextColor,
          icon: const Icon(
            Icons.menu,
          ),
        );
      }),
      actions: [
        IconButton(
          onPressed: () {},
          color: ColorsConst.primaryTextColor,
          icon: const Icon(
            Icons.search,
          ),
        ),
        PopupMenuButton<String>(
          color: ColorsConst.primaryColor,
          icon:
              const Icon(Icons.more_vert, color: ColorsConst.primaryTextColor),
          onSelected: (String item) {
            // Handle item selection
          },
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem<String>(
                value: 'opob',
                child: Text(
                  'Open in browser',
                  style: TextStyleConst.styleRegular(),
                ),
              ),
              PopupMenuItem<String>(
                value: 'download-all',
                child: Text(
                  'Download all galleries\nin this page',
                  style: TextStyleConst.styleRegular(),
                ),
              ),
            ];
          },
        ),
      ],
      title: Text(
        'Nhentai',
        style: TextStyleConst.styleBold(
          textColor: ColorsConst.primaryTextColor,
        ),
      ),
      backgroundColor: ColorsConst.primaryColor,
    );
  }

  Widget customDrawer() {
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
              // Update the state of the app
              // ...
              // Then close the drawer
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
