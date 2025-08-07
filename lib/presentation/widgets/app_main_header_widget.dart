import 'package:flutter/material.dart';

import '../../core/constants/colors_const.dart';
import '../../core/constants/text_style_const.dart';
import '../../core/routing/app_router.dart';

class AppMainHeaderWidget extends StatelessWidget
    implements PreferredSizeWidget {
  const AppMainHeaderWidget({
    super.key,
    required this.context,
    this.onSearchPressed,
  });

  final BuildContext context;
  final VoidCallback? onSearchPressed;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: Builder(builder: (context) {
        return IconButton(
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
          color: ColorsConst.darkTextPrimary,
          icon: const Icon(
            Icons.menu,
          ),
        );
      }),
      actions: [
        IconButton(
          onPressed: onSearchPressed ??
              () {
                // Navigate to dedicated SearchScreen
                AppRouter.goToSearch(context);
              },
          color: ColorsConst.darkTextPrimary,
          icon: const Icon(
            Icons.search,
          ),
          tooltip: 'Search',
        ),
        PopupMenuButton<String>(
          color: ColorsConst.darkCard,
          icon: const Icon(Icons.more_vert, color: ColorsConst.darkTextPrimary),
          onSelected: (String item) {
            // Handle item selection
          },
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem<String>(
                value: 'opob',
                child: Text(
                  'Open in browser',
                  style: TextStyleConst.bodyMedium,
                ),
              ),
              PopupMenuItem<String>(
                value: 'download-all',
                child: Text(
                  'Download all galleries in this page',
                  style: TextStyleConst.bodyMedium,
                ),
              ),
            ];
          },
        ),
      ],
      title: Text(
        'Nhentai',
        style: TextStyleConst.headingMedium,
      ),
      backgroundColor: ColorsConst.darkSurface,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
