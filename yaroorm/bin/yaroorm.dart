// import 'dart:isolate';
// import 'dart:mirrors';

// import 'package:analyzer/file_system/physical_file_system.dart';

// import 'ast/model_visitor.dart';

// final _genFiles = RegExp(r'\.g.dart$');

// void main() async {
//   final resourceProvider = PhysicalResourceProvider.INSTANCE;
//   final pathContext = resourceProvider.pathContext;
//   final modelDir = resourceProvider.getFolder(pathContext.normalize('lib/src/models'));

//   final modelFiles = modelDir
//       .getChildren()
//       .where((e) => !_genFiles.hasMatch(e.path) && e.path.endsWith('.dart'));

//   /// model with properties
//   await Future.wait(modelFiles.map((e) => parseModelFile(e.path)));

//   final uri = resourceProvider.getFile('zomato.reflectable.dart').toUri();

//   // print(uri);

//   final resulst = currentMirrorSystem()
//       .libraries
//       .keys
//       // .where((e) => e.toString().contains('zomato'))
//       .join('\n');

//   print(resulst);

//   // print(result);

//   // print(result.libraries);
// }
