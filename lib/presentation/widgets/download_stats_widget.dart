import 'package:flutter/material.dart';

import '../../core/constants/colors_const.dart';
import '../../core/constants/text_style_const.dart';
import '../blocs/download/download_bloc.dart';

/// Widget for displaying download statistics and overall progress
class DownloadStatsWidget extends StatelessWidget {
  const DownloadStatsWidget({
    super.key,
    required this.state,
  });

  final DownloadLoaded state;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsConst.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorsConst.onSurface.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Overall progress
          if (state.downloads.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Progress',
                        style: TextStyleConst.titleSmall.copyWith(
                          color: ColorsConst.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: state.totalProgress,
                        backgroundColor:
                            ColorsConst.onSurface.withValues(alpha: 0.1),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(ColorsConst.primary),
                        minHeight: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${(state.totalProgress * 100).toInt()}%',
                  style: TextStyleConst.titleMedium.copyWith(
                    color: ColorsConst.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Stats grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.download,
                  label: 'Total',
                  value: state.downloads.length.toString(),
                  color: ColorsConst.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.downloading,
                  label: 'Active',
                  value: state.activeDownloads.length.toString(),
                  color: ColorsConst.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.schedule,
                  label: 'Queued',
                  value: state.queuedDownloads.length.toString(),
                  color: ColorsConst.warning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.check_circle,
                  label: 'Done',
                  value: state.completedDownloads.length.toString(),
                  color: ColorsConst.success,
                ),
              ),
            ],
          ),

          // Speed and size info
          if (state.activeDownloads.isNotEmpty ||
              state.totalDownloadedSize > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (state.totalDownloadSpeed > 0) ...[
                  Expanded(
                    child: _buildInfoRow(
                      icon: Icons.speed,
                      label: 'Speed',
                      value: state.formattedTotalSpeed,
                    ),
                  ),
                ],
                if (state.totalDownloadedSize > 0) ...[
                  if (state.totalDownloadSpeed > 0) const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoRow(
                      icon: Icons.storage,
                      label: 'Downloaded',
                      value: state.formattedTotalSize,
                    ),
                  ),
                ],
              ],
            ),
          ],

          // Failed downloads warning
          if (state.failedDownloads.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorsConst.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ColorsConst.error.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: ColorsConst.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${state.failedDownloads.length} download${state.failedDownloads.length == 1 ? '' : 's'} failed',
                      style: TextStyleConst.bodySmall.copyWith(
                        color: ColorsConst.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Switch to failed tab
                      // This would need to be handled by the parent widget
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: ColorsConst.error,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                    ),
                    child: Text(
                      'View',
                      style: TextStyleConst.labelSmall.copyWith(
                        color: ColorsConst.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Processing indicator
          if (state.isProcessing) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(ColorsConst.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  state is DownloadProcessing
                      ? (state as DownloadProcessing).operation
                      : 'Processing...',
                  style: TextStyleConst.bodySmall.copyWith(
                    color: ColorsConst.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyleConst.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyleConst.bodySmall.copyWith(
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: ColorsConst.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyleConst.bodySmall.copyWith(
            color: ColorsConst.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: TextStyleConst.bodySmall.copyWith(
            color: ColorsConst.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
