import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/presentation/blocs/content/content_bloc.dart';
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
  late final ContentBloc _contentBloc;

  @override
  void initState() {
    super.initState();
    _contentBloc = getIt<ContentBloc>()
      ..add(const ContentLoadEvent(sortBy: SortOption.newest));
  }

  @override
  void dispose() {
    _contentBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _contentBloc,
      child: Scaffold(
        backgroundColor: ColorsConst.primaryColor,
        appBar: AppMainHeaderWidget(context: context),
        drawer: AppMainDrawerWidget(context: context),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<ContentBloc, ContentState>(
      builder: (context, state) {
        return Column(
          children: [
            Expanded(
              child: _buildContent(state),
            ),
            _buildContentFooter(state)
          ],
        );
      },
    );
  }

  Widget _buildContent(ContentState state) {
    if (state is ContentLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: ColorsConst.primaryTextColor,
        ),
      );
    } else if (state is ContentError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: ${state.message}',
              style: const TextStyle(color: ColorsConst.primaryTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (state.canRetry)
              ElevatedButton(
                onPressed: () => _contentBloc.add(const ContentRetryEvent()),
                child: const Text('Retry'),
              ),
          ],
        ),
      );
    } else if (state is ContentEmpty) {
      return Center(
        child: Column(
          children: [
            Text(
              state.message,
              style: const TextStyle(color: ColorsConst.primaryTextColor),
            ),
            ElevatedButton(
              onPressed: () => _contentBloc.add(const ContentRetryEvent()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (state is ContentLoaded) {
      return ListView.builder(
        itemCount: state.contents.length,
        itemBuilder: (context, index) {
          final content = state.contents[index];
          return ListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: ColorsConst.primaryTextColor),
                ),
                SizedBox(height: 5,),
                Row(
                  children: content.tags.map((value) 
                     => Text(value.name, style: const TextStyle(color: ColorsConst.redCustomColor)) as Widget).toList(),
                  ),
              ],
            ),
            subtitle: Text(
              'ID: ${content.id}',
              style: const TextStyle(color: ColorsConst.redCustomColor),
            ),
            leading: CachedNetworkImage(imageUrl: content.coverUrl, height: 100, width: 50, fit: BoxFit.cover,),
          );
        },
      );
    }
    return const Center(
      child: Text(
        'Welcome!',
        style: TextStyle(color: ColorsConst.primaryTextColor, fontSize: 24),
      ),
    );
  }

  Widget _buildContentFooter(ContentState state) {
    int currentPage = 0;
    int totalPages = 0;

    if (state is ContentLoaded) {
      currentPage = state.currentPage;
      totalPages = state.totalPages;
    }

    return Container(
      color: ColorsConst.thirdColor,
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          IconButton(
            iconSize: 32,
            onPressed:
                (state is ContentLoaded && state.hasPrevious) ? () {} : null,
            icon: const Icon(Icons.chevron_left),
            color: ColorsConst.primaryTextColor,
          ),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  'Page $currentPage of $totalPages',
                  style: TextStyleConst.styleBold(
                    textColor: ColorsConst.primaryTextColor,
                    size: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 8,
                ),
                Container(
                  height: 2,
                  color: ColorsConst.primaryTextColor,
                )
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            iconSize: 32,
            onPressed: (state is ContentLoaded && state.hasNext) ? () {} : null,
            icon: const Icon(Icons.chevron_right),
            color: ColorsConst.primaryTextColor,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
