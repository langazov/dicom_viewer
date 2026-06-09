import 'package:dicom_viewer/dicom/domain/dicom_models.dart';
import 'package:dicom_viewer/dicom/import/dicom_import_source.dart';
import 'package:dicom_viewer/dicom/parsing/dicom_parser.dart';
import 'package:dicom_viewer/dicom/parsing/parsed_dicom_file.dart';

class DicomImportService {
  const DicomImportService({this.parser = const DicomParser()});

  final DicomParser parser;

  DicomImportResult importSources(Iterable<DicomImportSource> sources) {
    final parsedFiles = <ParsedDicomFile>[];
    final skippedFiles = <DicomImportFailure>[];

    for (final source in sources) {
      final result = parser.parseBytes(source.bytes, filePath: source.filePath);
      final file = result.file;
      if (file == null) {
        skippedFiles.add(
          DicomImportFailure(
            filePath: source.filePath,
            reason: result.error ?? 'Unknown DICOM import error.',
          ),
        );
      } else {
        parsedFiles.add(file);
      }
    }

    return DicomImportResult(
      patients: _groupPatients(parsedFiles),
      skippedFiles: skippedFiles,
    );
  }

  List<DicomPatient> _groupPatients(List<ParsedDicomFile> parsedFiles) {
    final byPatient = <String, List<ParsedDicomFile>>{};

    for (final file in parsedFiles) {
      byPatient.putIfAbsent(file.patientId, () => []).add(file);
    }

    return byPatient.entries
        .map((entry) {
          final patientFiles = entry.value;
          patientFiles.sort(_compareParsedFiles);

          return DicomPatient(
            id: entry.key,
            displayName: patientFiles.first.patientName,
            studies: _groupStudies(patientFiles),
          );
        })
        .toList(growable: false);
  }

  List<DicomStudy> _groupStudies(List<ParsedDicomFile> patientFiles) {
    final byStudy = <String, List<ParsedDicomFile>>{};

    for (final file in patientFiles) {
      byStudy.putIfAbsent(file.studyInstanceUid, () => []).add(file);
    }

    return byStudy.entries
        .map((entry) {
          final studyFiles = entry.value;
          studyFiles.sort(_compareParsedFiles);

          return DicomStudy(
            instanceUid: entry.key,
            description: studyFiles.first.studyDescription,
            studyDate: studyFiles.first.studyDate,
            series: _groupSeries(studyFiles),
          );
        })
        .toList(growable: false);
  }

  List<DicomSeries> _groupSeries(List<ParsedDicomFile> studyFiles) {
    final bySeries = <String, List<ParsedDicomFile>>{};

    for (final file in studyFiles) {
      bySeries.putIfAbsent(file.seriesInstanceUid, () => []).add(file);
    }

    return bySeries.entries
        .map((entry) {
          final seriesFiles = entry.value;
          seriesFiles.sort(_compareParsedFiles);

          return DicomSeries(
            instanceUid: entry.key,
            description: seriesFiles.first.seriesDescription,
            modality: seriesFiles.first.modality,
            instances: seriesFiles
                .map((file) => file.instance)
                .toList(growable: false),
          );
        })
        .toList(growable: false);
  }

  int _compareParsedFiles(ParsedDicomFile left, ParsedDicomFile right) {
    final leftNumber = left.instance.instanceNumber;
    final rightNumber = right.instance.instanceNumber;
    if (leftNumber != null && rightNumber != null) {
      final comparison = leftNumber.compareTo(rightNumber);
      if (comparison != 0) {
        return comparison;
      }
    }

    return left.filePath.compareTo(right.filePath);
  }
}
