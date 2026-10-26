import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Saves the downloaded invoice PDF to app storage
/// and opens it with the device's PDF viewer.
///
/// Requires path_provider and open_filex in pubspec.yaml.
Future<void> saveAndOpenInvoicePdf({
required List<int> bytes,
required String fileName,
}) async {
// Sanitize the file name.
final safeName = fileName.replaceAll(
RegExp(r'[^A-Za-z0-9._-]'),
'_',
);

if (safeName.isEmpty || safeName == '.' || safeName == '..') {
throw const FileSystemException('Tên file PDF không hợp lệ.');
}

// Ensure the file has a .pdf extension.
final pdfName = safeName.toLowerCase().endsWith('.pdf')
? safeName
    : '$safeName.pdf';

// Get app documents directory.
final directory = await getApplicationDocumentsDirectory();
final folder = Directory('${directory.path}/invoices');

// Create invoices directory if it does not exist.
if (!await folder.exists()) {
await folder.create(recursive: true);
}

// Save PDF.
final file = File('${folder.path}/$pdfName');
await file.writeAsBytes(bytes, flush: true);

// Open PDF using an installed PDF viewer.
final result = await OpenFilex.open(
file.path,
type: 'application/pdf',
);

  if (result.type != ResultType.done) {
    throw FileSystemException(
      'Không thể mở tệp PDF: ${result.message}',
      file.path,
    );
  }
}
