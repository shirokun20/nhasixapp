import 'package:flutter/material.dart';

import '../../core/constants/colors_const.dart';
import '../../core/constants/text_style_const.dart';

class AppMainHeaderWidget extends StatelessWidget
    implements PreferredSizeWidget {
  const AppMainHeaderWidget({
    super.key,
    required this.context,
  });

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
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
                  'Download all galleries in this page',
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

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
