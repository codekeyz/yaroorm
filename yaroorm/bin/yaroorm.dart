import 'package:analyzer/file_system/physical_file_system.dart';

import 'ast/model_visitor.dart';

final _genFiles = RegExp(r'\.g.dart$');

void main() async {
  final resourceProvider = PhysicalResourceProvider.INSTANCE;
  final pathContext = resourceProvider.pathContext;
  final directory = resourceProvider.getFolder(pathContext.normalize('lib/src/models'));
  final dartFiles = directory
      .getChildren()
      .where((e) => !_genFiles.hasMatch(e.path) && e.path.endsWith('.dart'));

  /// model with properties
  await Future.wait(dartFiles.map((e) => parseModelFile(e.path)));
}
