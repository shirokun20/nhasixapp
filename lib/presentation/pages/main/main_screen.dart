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
import 'package:nhasixapp/presentation/widgets/content_list_widget.dart';
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
        // Use pagination or infinite scroll based on user preference
        // For now, we'll use pagination with ContentListWidget
        return Column(
          children: [
            Expanded(
              child: ContentListWidget(
                onContentTap: _onContentTap,
                enablePullToRefresh: true, // Allow pull-to-refresh
                enableInfiniteScroll:
                    false, // Disable infinite scroll for pagination
              ),
            ),
            _buildContentFooter(state)
          ],
        );
      },
    );
  }

  /// Handle content tap to navigate to detail screen
  void _onContentTap(Content content) {
    // TODO: Navigate to detail screen with DetailCubit
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Tapped: ${content.title}',
          style: TextStyleConst.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: ColorsConst.accentBlue,
        duration: const Duration(seconds: 2),
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
