import 'package:dicom_viewer/viewer/state/viewer_state.dart';
import 'package:flutter/material.dart';

class MetadataPanel extends StatelessWidget {
  const MetadataPanel({super.key, required this.state});

  final ViewerState state;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF171D21),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Metadata', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            const _MetadataRow(label: 'Patient', value: 'Hidden'),
            _MetadataRow(label: 'Studies', value: '${state.patients.length}'),
            _MetadataRow(
              label: 'Instances',
              value: '${state.importedInstanceCount}',
            ),
            _MetadataRow(
              label: 'Skipped',
              value: '${state.skippedFiles.length}',
            ),
            _MetadataRow(label: 'Import', value: state.importMessage ?? '--'),
            if (state.accessIssues.isNotEmpty)
              _MetadataRow(label: 'Access', value: state.accessIssues.first),
            if (state.skippedFiles.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Skipped files',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: state.skippedFiles.length,
                  itemBuilder: (context, index) {
                    final skipped = state.skippedFiles[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${skipped.filePath}: ${skipped.reason}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFE0B84D),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF91A3AA)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
