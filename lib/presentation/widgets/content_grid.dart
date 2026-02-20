import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/core/utils/responsive_grid_delegate.dart';
import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/presentation/cubits/settings/settings_cubit.dart';
import 'package:nhasixapp/presentation/widgets/content_card_widget.dart';
import 'package:nhasixapp/presentation/widgets/progress_indicator_widget.dart';

class ContentGrid extends StatelessWidget {
  final List<Content> contents;
  final bool hasNextPage;
  final VoidCallback? onLoadMore;
  final void Function(Content)? onContentTap;

  const ContentGrid({
    super.key,
    required this.contents,
    this.hasNextPage = false,
    this.onLoadMore,
    this.onContentTap,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (!hasNextPage) return false;
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent - 200) {
          onLoadMore?.call();
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverGrid(
              gridDelegate: ResponsiveGridDelegate.createGridDelegate(
                context,
                context.read<SettingsCubit>(),
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final content = contents[index];
                  return ContentCard(
                    content: content,
                    onTap: () => onContentTap?.call(content),
                    showLanguageFlag: false,
                    showPageCount: false,
                  );
                },
                childCount: contents.length,
              ),
            ),
          ),
          if (hasNextPage)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: AppProgressIndicator(size: 24)),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}
