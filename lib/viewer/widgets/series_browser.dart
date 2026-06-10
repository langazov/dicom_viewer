import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/viewer/state/viewer_state.dart';
import 'package:dicom_viewer/viewer/widgets/series_thumbnail_view.dart';
import 'package:flutter/material.dart';

class SeriesBrowser extends StatelessWidget {
  const SeriesBrowser({
    super.key,
    required this.state,
    required this.onSeriesSelected,
    required this.onSearchChanged,
    required this.onTogglePatientName,
  });

  final ViewerState state;
  final ValueChanged<String> onSeriesSelected;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onTogglePatientName;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF171D21),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Studies',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: state.hidePatientName
                      ? 'Show patient name'
                      : 'Hide patient name',
                  icon: Icon(
                    state.hidePatientName
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: onTogglePatientName,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SearchBar(
              hintText: 'Search patient, study, series',
              leading: const Icon(Icons.search),
              constraints: const BoxConstraints(minHeight: 44),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: onSearchChanged,
            ),
            const SizedBox(height: 12),
            if (state.recentSeriesIds.isNotEmpty) ...[
              _RecentSeriesStrip(
                state: state,
                onSeriesSelected: onSeriesSelected,
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: _StudyContent(
                state: state,
                onSeriesSelected: onSeriesSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudyContent extends StatelessWidget {
  const _StudyContent({required this.state, required this.onSeriesSelected});

  final ViewerState state;
  final ValueChanged<String> onSeriesSelected;

  @override
  Widget build(BuildContext context) {
    if (state.isImporting) {
      return const Center(child: CircularProgressIndicator());
    }

    final patients = state.filteredPatients;
    if (patients.isEmpty) {
      return _EmptyStudies(state: state);
    }

    return ListView.builder(
      itemCount: patients.length,
      itemBuilder: (context, patientIndex) {
        final patient = patients[patientIndex];
        return ExpansionTile(
          initiallyExpanded: true,
          tilePadding: EdgeInsets.zero,
          title: Text(
            state.hidePatientName
                ? 'Patient ${patient.id}'
                : patient.displayName,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text('${patient.studies.length} study(s)'),
          children: [
            for (final study in patient.studies)
              ExpansionTile(
                initiallyExpanded: true,
                tilePadding: const EdgeInsets.only(left: 8),
                title: Text(
                  study.description.isEmpty
                      ? 'Unnamed study'
                      : study.description,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${study.series.length} series'
                  '${study.studyDate != null ? ' | ${_formatDate(study.studyDate!)}' : ''}',
                ),
                children: [
                  for (final series in study.series)
                    _SeriesTile(
                      series: series,
                      selected: state.selectedSeriesId == series.instanceUid,
                      onTap: () => onSeriesSelected(series.instanceUid),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  static String _formatDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }
}

class _SeriesTile extends StatelessWidget {
  const _SeriesTile({
    required this.series,
    required this.selected,
    required this.onTap,
  });

  final DicomSeries series;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final geometrySummary = _geometrySummary(series);
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
      leading: SizedBox(
        width: 48,
        height: 48,
        child: SeriesThumbnailView(series: series, size: 48),
      ),
      selected: selected,
      selectedTileColor: const Color(0xFF153638),
      onTap: onTap,
      title: Text(
        series.description.isEmpty ? 'Unnamed series' : series.description,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${series.modality} | ${series.instances.length} instance(s)'
        '${geometrySummary.isNotEmpty ? ' | $geometrySummary' : ''}',
      ),
      dense: true,
    );
  }

  static String _geometrySummary(DicomSeries series) {
    if (series.instances.isEmpty) {
      return '';
    }
    final first = series.instances.first;
    final spacing = first.metadata.pixelSpacing;
    final pixelData = first.metadata.pixelData;
    final colorLabel = pixelData.isColor
        ? ' color'
        : pixelData.isPaletteColor
            ? ' palette'
            : '';
    final size = '${first.metadata.columns}x${first.metadata.rows}';
    if (spacing == null) {
      return '$size$colorLabel';
    }
    return '$size$colorLabel, ${spacing.columnMm.toStringAsFixed(2)}x${spacing.rowMm.toStringAsFixed(2)} mm';
  }
}

class _RecentSeriesStrip extends StatelessWidget {
  const _RecentSeriesStrip({
    required this.state,
    required this.onSeriesSelected,
  });

  final ViewerState state;
  final ValueChanged<String> onSeriesSelected;

  @override
  Widget build(BuildContext context) {
    final allSeries = <DicomSeries>[];
    for (final patient in state.patients) {
      for (final study in patient.studies) {
        for (final series in study.series) {
          allSeries.add(series);
        }
      }
    }
    final byId = {for (final s in allSeries) s.instanceUid: s};
    final recents = state.recentSeriesIds
        .map((id) => byId[id])
        .whereType<DicomSeries>()
        .take(8)
        .toList(growable: false);

    if (recents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recents.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final series = recents[index];
              final selected = state.selectedSeriesId == series.instanceUid;
              return InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => onSeriesSelected(series.instanceUid),
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF39A9A7)
                          : const Color(0xFF334047),
                    ),
                    borderRadius: BorderRadius.circular(6),
                    color: selected
                        ? const Color(0xFF153638)
                        : const Color(0xFF20272C),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        series.description.isEmpty
                            ? 'Unnamed series'
                            : series.description,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${series.modality} | ${series.instances.length}',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF9FB0B8),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyStudies extends StatelessWidget {
  const _EmptyStudies({required this.state});

  final ViewerState state;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_open, size: 36, color: Color(0xFF6E858E)),
            const SizedBox(height: 12),
            Text(
              state.searchQuery.isNotEmpty
                  ? 'No matching studies'
                  : 'No studies imported',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.searchQuery.isNotEmpty
                  ? 'Try a different patient name, study, or series description.'
                  : 'Import DICOM files to populate the local study index.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFFAAB8BE)),
            ),
            if (state.importMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                state.importMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: state.importStatus == ImportStatus.failed
                      ? const Color(0xFFE27B7B)
                      : const Color(0xFFE0B84D),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
