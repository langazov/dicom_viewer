import 'package:dicom_viewer/viewer/state/viewer_state.dart';
import 'package:flutter/material.dart';

class SeriesBrowser extends StatelessWidget {
  const SeriesBrowser({
    super.key,
    required this.state,
    required this.onSeriesSelected,
  });

  final ViewerState state;
  final ValueChanged<String> onSeriesSelected;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF171D21),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Studies', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SearchBar(
              hintText: 'Search patient, study, series',
              leading: const Icon(Icons.search),
              constraints: const BoxConstraints(minHeight: 44),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
            const SizedBox(height: 16),
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

    if (state.patients.isEmpty) {
      return _EmptyStudies(state: state);
    }

    return ListView.builder(
      itemCount: state.patients.length,
      itemBuilder: (context, patientIndex) {
        final patient = state.patients[patientIndex];
        return ExpansionTile(
          initiallyExpanded: true,
          tilePadding: EdgeInsets.zero,
          title: Text(patient.displayName, overflow: TextOverflow.ellipsis),
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
                subtitle: Text('${study.series.length} series'),
                children: [
                  for (final series in study.series)
                    ListTile(
                      contentPadding: const EdgeInsets.only(left: 16, right: 4),
                      leading: const Icon(Icons.view_in_ar),
                      selected: state.selectedSeriesId == series.instanceUid,
                      selectedTileColor: const Color(0xFF153638),
                      onTap: () => onSeriesSelected(series.instanceUid),
                      title: Text(
                        series.description.isEmpty
                            ? 'Unnamed series'
                            : series.description,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${series.modality} | ${series.instances.length} instance(s)',
                      ),
                      dense: true,
                    ),
                ],
              ),
          ],
        );
      },
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
        constraints: const BoxConstraints(maxWidth: 220),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_open, size: 36, color: Color(0xFF6E858E)),
            const SizedBox(height: 12),
            Text(
              'No studies imported',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Import DICOM files to populate the local study index.',
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
