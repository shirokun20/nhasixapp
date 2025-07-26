import 'package:flutter/material.dart';
import 'package:nhasixapp/core/constants/colors_const.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/presentation/widgets/app_main_drawer_widget.dart';
import 'package:nhasixapp/presentation/widgets/app_main_header_widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsConst.primaryColor,
      appBar: AppMainHeaderWidget(context: context),
      drawer: AppMainDrawerWidget(context: context),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Text(
              'Main Screen',
              style: TextStyle(
                color: ColorsConst.primaryTextColor,
                fontSize: 24,
              ),
            ),
          ),
        ),
        _buildContentFooter()
      ],
    );
  }

  Widget _buildContentFooter() {
    return Container(
      color: ColorsConst.thirdColor,
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Spacer(),
          IconButton(
            iconSize: 32,
            // highlightColor: ColorsConst.thirdColor,
            onPressed: null,
            icon: Icon(Icons.chevron_left),
            color: ColorsConst.primaryTextColor,
          ),
          Spacer(),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  'Page 1 of 100',
                  style: TextStyleConst.styleBold(
                    textColor: ColorsConst.primaryTextColor,
                    size: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: 8,
                ),
                Container(
                  height: 2,
                  color: ColorsConst.primaryTextColor,
                )
              ],
            ),
          ),
          Spacer(),
          IconButton(
            iconSize: 32,
            onPressed: () {},
            icon: Icon(Icons.chevron_right),
            color: ColorsConst.primaryTextColor,
          ),
          Spacer(),
        ],
      ),
    );
  }
}
