import 'dart:convert';
import 'dart:io' as io show Directory, File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_example/quill_delta_sample.dart';
import 'package:path/path.dart' as path;

void main() => runApp(const MainApp());

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: const HomePage(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final QuillController _controller = () {
    return QuillController.basic(
      config: QuillControllerConfig(
        clipboardConfig: QuillClipboardConfig(
          enableExternalRichPaste: true,
          onImagePaste: (imageBytes) async {
            if (kIsWeb) {
              // Dart IO is unsupported on the web.
              return null;
            }
            // Save the image somewhere and return the image URL that will be
            // stored in the Quill Delta JSON (the document).
            final newFileName = 'image-file-${DateTime.now().toIso8601String()}.png';
            final newPath = path.join(
              io.Directory.systemTemp.path,
              newFileName,
            );
            final file = await io.File(
              newPath,
            ).writeAsBytes(imageBytes, flush: true);
            return file.path;
          },
        ),
      ),
    );
  }();
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load document
    _controller.document = Document.fromJson(kQuillDefaultSample);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Quill Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.output),
            tooltip: 'Print Delta JSON to log',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'The JSON Delta has been printed to the console.',
                  ),
                ),
              );
              debugPrint(jsonEncode(_controller.document.toDelta().toJson()));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            QuillSimpleToolbar(
              controller: _controller,
              config: QuillSimpleToolbarConfig(
                showClipboardPaste: true,
                showDirection: true,
                customButtons: [
                  // TODO(Seb): Need to check what this is for! Nested emoji selectors for desktop views.
                  QuillToolbarCustomButtonOptions(
                    icon: const Icon(Icons.add_alarm_rounded),
                    onPressed: () {
                      _controller.document.insert(
                        _controller.selection.extentOffset,
                        TimeStampEmbed(DateTime.now().toString()),
                      );

                      _controller.updateSelection(
                        TextSelection.collapsed(
                          offset: _controller.selection.extentOffset + 1,
                        ),
                        ChangeSource.local,
                      );
                    },
                  ),
                ],
                buttonOptions: QuillSimpleToolbarButtonOptions(
                  base: QuillToolbarBaseButtonOptions(
                    afterButtonPressed: () {
                      final isDesktop = {
                        TargetPlatform.linux,
                        TargetPlatform.windows,
                        TargetPlatform.macOS,
                      }.contains(defaultTargetPlatform);
                      if (isDesktop) {
                        _editorFocusNode.requestFocus();
                      }
                    },
                  ),
                  linkStyle: QuillToolbarLinkStyleButtonOptions(
                    validateLink: (link) {
                      // Treats all links as valid. When launching the URL,
                      // `https://` is prefixed if the link is incomplete (e.g., `google.com` → `https://google.com`)
                      // however this happens only within the editor.
                      return true;
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              child: QuillEditor(
                focusNode: _editorFocusNode,
                scrollController: _editorScrollController,
                controller: _controller,
                config: QuillEditorConfig(
                  placeholder: 'Start writing your notes...',
                  padding: const EdgeInsets.all(16),
                  embedBuilders: [TimeStampEmbedBuilder()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _editorScrollController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }
}

class TimeStampEmbed extends Embeddable {
  const TimeStampEmbed(String value) : super(timeStampType, value);

  factory TimeStampEmbed.fromDocument(Document val) {
    try {
      final jsonData = val.toDelta().toJson();
      final encode = jsonEncode(jsonData);
      return TimeStampEmbed(encode);
    } catch (e) {
      debugPrint("TimeStampEmbed fromDocument error $e");
      return const TimeStampEmbed('');
    }
  }

  static const String timeStampType = 'timeStamp';

  Document? toDocument() {
    try {
      final decoded = jsonDecode(data as String);
      if (decoded is! List) return null;
      return Document.fromJson(decoded.cast<Map<String, dynamic>>());
    } catch (e) {
      debugPrint("TimeStampEmbed toDocument error $e");
      return null;
    }
  }
}

class TimeStampEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'timeStamp';

  @override
  String toPlainText(Embed node) {
    return node.value.stringVal.toString();
  }

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    return Row(
      children: [
        const Icon(Icons.access_time_rounded),
        Text(embedContext.node.value.data as String),
      ],
    );
  }
}
