import 'package:image_picker/image_picker.dart';

Future<List<XFile>?> selectImages() async {
  final ImagePicker picker = ImagePicker();
  final List<XFile>? selectedImages = await picker.pickMultiImage();

  if (selectedImages == null || selectedImages.isEmpty) {
    return null;
  } else {
    return selectedImages;
  }
}

Future<XFile?> pickSingleImage() async {
  final ImagePicker picker = ImagePicker();
  final XFile? selectedImages =
      await picker.pickImage(source: ImageSource.gallery);

  if (selectedImages == null) {
    return null;
  } else {
    return selectedImages;
  }
}
