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
import 'package:nhasixapp/presentation/widgets/pagination_widget.dart';

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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: ColorsConst.primaryTextColor,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: const TextStyle(
                color: ColorsConst.primaryTextColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
                SizedBox(
                  height: 5,
                ),
                Row(
                  children: content.tags
                      .map((value) => Text(value.name,
                          style: const TextStyle(
                              color: ColorsConst.redCustomColor)) as Widget)
                      .toList(),
                ),
              ],
            ),
            subtitle: Text(
              'ID: ${content.id}',
              style: const TextStyle(color: ColorsConst.redCustomColor),
            ),
            leading: CachedNetworkImage(
              imageUrl: content.coverUrl,
              height: 100,
              width: 50,
              fit: BoxFit.cover,
            ),
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
    if (state is! ContentLoaded) {
      return const SizedBox.shrink();
    }

    return PaginationWidget(
      currentPage: state.currentPage,
      totalPages: state.totalPages,
      hasNext: state.hasNext,
      hasPrevious: state.hasPrevious,
      onNextPage: () {
        _contentBloc.add(const ContentNextPageEvent());
      },
      onPreviousPage: () {
        _contentBloc.add(const ContentPreviousPageEvent());
      },
      onGoToPage: (page) {
        _contentBloc.add(ContentGoToPageEvent(page));
      },
      showProgressBar: true,
      showPercentage: true,
      showPageInput: true, // Enable page input for large page counts
    );
  }
}
