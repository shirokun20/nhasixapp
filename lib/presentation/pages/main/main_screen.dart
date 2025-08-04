import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/presentation/blocs/content/content_bloc.dart';
import 'package:nhasixapp/presentation/blocs/home/home_bloc.dart';
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
  late final HomeBloc _homeBloc;
  late final ContentBloc _contentBloc;

  @override
  void initState() {
    super.initState();
    // Initialize HomeBloc for screen-level state management
    _homeBloc = getIt<HomeBloc>()..add(HomeStartedEvent());

    // Initialize ContentBloc for content data management
    _contentBloc = getIt<ContentBloc>()
      ..add(const ContentLoadEvent(sortBy: SortOption.newest));
  }

  @override
  void dispose() {
    _homeBloc.close();
    _contentBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _homeBloc),
        BlocProvider.value(value: _contentBloc),
      ],
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, homeState) {
          // Show full screen loading during home initialization
          if (homeState is HomeLoading) {
            return Scaffold(
              backgroundColor: ColorsConst.darkBackground,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: ColorsConst.accentBlue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Initializing...',
                      style: TextStyleConst.styleMedium(
                        textColor: ColorsConst.darkTextPrimary,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Main screen UI when home is loaded
          return Scaffold(
            backgroundColor: ColorsConst.darkBackground,
            appBar: AppMainHeaderWidget(context: context),
            drawer: AppMainDrawerWidget(context: context),
            body: _buildBody(),
          );
        },
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
              color: ColorsConst.accentBlue,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: TextStyleConst.styleMedium(
                textColor: ColorsConst.darkTextPrimary,
                size: 16,
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
              style: TextStyleConst.styleMedium(
                textColor: ColorsConst.accentRed,
                size: 16,
              ),
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
              style: TextStyleConst.styleMedium(
                textColor: ColorsConst.darkTextSecondary,
                size: 16,
              ),
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
                  style: TextStyleConst.styleSemiBold(
                    textColor: ColorsConst.darkTextPrimary,
                    size: 16,
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    children: content.tags
                        .map((value) => Container(
                              margin: const EdgeInsets.only(right: 5),
                              child: Text(
                                value.name,
                                style: TextStyleConst.styleRegular(
                                  textColor:
                                      ColorsConst.getTagColor(value.type),
                                  size: 12,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              'ID: ${content.id}',
              style: TextStyleConst.styleLight(
                textColor: ColorsConst.darkTextSecondary,
                size: 12,
              ),
            ),
            leading: CachedNetworkImage(
              imageUrl: content.coverUrl,
              height: 130,
              width: 50,
              fit: BoxFit.cover,
            ),
          );
        },
      );
    }
    return Center(
      child: Text(
        'Welcome!',
        style: TextStyleConst.styleBold(
          textColor: ColorsConst.darkTextPrimary,
          size: 24,
        ),
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
