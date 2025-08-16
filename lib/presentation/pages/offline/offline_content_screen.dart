import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/colors_const.dart';
import '../../../core/constants/text_style_const.dart';
import '../../../core/di/service_locator.dart';
import '../../cubits/offline_search/offline_search_cubit.dart';
import '../../widgets/content_card_widget.dart';
import '../../widgets/progress_indicator_widget.dart';
import '../../widgets/error_widget.dart';

/// Screen for browsing offline/downloaded content
class OfflineContentScreen extends StatefulWidget {
  const OfflineContentScreen({super.key});

  @override
  State<OfflineContentScreen> createState() => _OfflineContentScreenState();
}

class _OfflineContentScreenState extends State<OfflineContentScreen> {
  late OfflineSearchCubit _offlineSearchCubit;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _offlineSearchCubit = getIt<OfflineSearchCubit>();

    // Load all offline content initially
    _offlineSearchCubit.getAllOfflineContent();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OfflineSearchCubit>(
      create: (context) => _offlineSearchCubit,
      child: Scaffold(
        backgroundColor: ColorsConst.darkBackground,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: BlocBuilder<OfflineSearchCubit, OfflineSearchState>(
                builder: (context, state) => _buildBody(state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: ColorsConst.darkSurface,
      elevation: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back, color: ColorsConst.darkTextPrimary),
      ),
      title: Row(
        children: [
          Icon(
            Icons.offline_bolt,
            color: ColorsConst.accentGreen,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            'Offline Content',
            style: TextStyleConst.headingMedium.copyWith(
              color: ColorsConst.darkTextPrimary,
            ),
          ),
        ],
      ),
      actions: [
        // Storage info
        BlocBuilder<OfflineSearchCubit, OfflineSearchState>(
          builder: (context, state) {
            return FutureBuilder<Map<String, dynamic>>(
              future: _offlineSearchCubit.getOfflineStats(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final stats = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${stats['totalContent']} items',
                            style: TextStyleConst.bodySmall.copyWith(
                              color: ColorsConst.darkTextSecondary,
                            ),
                          ),
                          Text(
                            stats['formattedSize'],
                            style: TextStyleConst.bodySmall.copyWith(
                              color: ColorsConst.accentBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsConst.darkSurface,
        border: Border(
          bottom: BorderSide(
            color: ColorsConst.borderMuted,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: TextStyleConst.bodyMedium.copyWith(
                color: ColorsConst.darkTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search offline content...',
                hintStyle: TextStyleConst.bodyMedium.copyWith(
                  color: ColorsConst.darkTextSecondary,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: ColorsConst.darkTextSecondary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _offlineSearchCubit.getAllOfflineContent();
                        },
                        icon: Icon(
                          Icons.clear,
                          color: ColorsConst.darkTextSecondary,
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: ColorsConst.borderDefault),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: ColorsConst.accentBlue),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {});
                if (value.trim().isEmpty) {
                  _offlineSearchCubit.getAllOfflineContent();
                }
              },
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _offlineSearchCubit.searchOfflineContent(value.trim());
                } else {
                  _offlineSearchCubit.getAllOfflineContent();
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              final query = _searchController.text.trim();
              if (query.isNotEmpty) {
                _offlineSearchCubit.searchOfflineContent(query);
              } else {
                _offlineSearchCubit.getAllOfflineContent();
              }
              _searchFocusNode.unfocus();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsConst.accentBlue,
              foregroundColor: ColorsConst.darkTextPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Search',
              style: TextStyleConst.buttonMedium.copyWith(
                color: ColorsConst.darkTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(OfflineSearchState state) {
    if (state is OfflineSearchLoading) {
      return const Center(
        child: AppProgressIndicator(
          message: 'Loading offline content...',
        ),
      );
    }

    if (state is OfflineSearchError) {
      return Center(
        child: AppErrorWidget(
          title: 'Offline Content Error',
          message: state.message,
          onRetry: () => _offlineSearchCubit.getAllOfflineContent(),
        ),
      );
    }

    if (state is OfflineSearchEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: ColorsConst.darkTextTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              state.emptyMessage,
              style: TextStyleConst.bodyLarge.copyWith(
                color: ColorsConst.darkTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/downloads'),
              icon: const Icon(Icons.download),
              label: const Text('Go to Downloads'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsConst.accentBlue,
                foregroundColor: ColorsConst.darkTextPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (state is OfflineSearchLoaded) {
      return Column(
        children: [
          // Results header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  state.displayTitle,
                  style: TextStyleConst.headingSmall.copyWith(
                    color: ColorsConst.darkTextPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  state.resultsSummary,
                  style: TextStyleConst.bodySmall.copyWith(
                    color: ColorsConst.darkTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Content grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: state.results.length,
              itemBuilder: (context, index) {
                final content = state.results[index];
                Logger().i(content);
                return ContentCard(
                  content: content,
                  onTap: () => context.push('/reader/${content.id}'),
                  showOfflineIndicator: true,
                );
              },
            ),
          ),
        ],
      );
    }

    // Initial state
    return const Center(
      child: AppProgressIndicator(
        message: 'Loading offline content...',
      ),
    );
  }
}
