import 'package:file_picker/file_picker.dart';

Future<List<PlatformFile>?> selectPdf() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
    allowMultiple: false,
  );
  if (result == null) {
    return null;
  } else {
    return result.files;
  }
}
