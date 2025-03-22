// Investigate and resolve the issue where the popup does not correctly follow the cursor in a multiline TextFormField.
// Steps to reproduce the issue:

// 1.Type 'banana.' in the input field; suggestions will appear.
// 2.Select a suggestion after each '.' to trigger another suggestion.
// 3.Continue this process until the text spans at least 4+ lines.
// 4.Observe that the popup does not correctly follow the cursor.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MaterialApp(home: MyApp()));
}

const contentPadding = EdgeInsets.symmetric(vertical: 15, horizontal: 20);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _editableTextKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  TextPosition get _cursorPosition => _controller.selection.extent;
  final List<String> _suggestions = ['apple', 'tomato', 'watermelon'];
  final List<String> _newSuggestions = ['banana', 'orange', 'grape'];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_scheduleOverlayUpdate);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_scheduleOverlayUpdate);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _scheduleOverlayUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateOverlay();
      }
    });
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _updateOverlay();
    } else {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!_focusNode.hasFocus) {
          _overlayEntry?.remove();
          _overlayEntry = null;
        }
      });
    }
  }

  void _updateOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }

    if (_controller.text.isEmpty) return;

    final textParts = _controller.text.split('.');
    final lastPart = textParts.last;

    final caretOffset = _getCaretPosition();
    final filteredSuggestions = _controller.text.endsWith('.')
        ? _newSuggestions
        : _suggestions.where((s) => s.contains(lastPart)).toList();

    if (filteredSuggestions.isEmpty) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      return;
    }

    final overlay = Overlay.of(context);
    const overlayWidth = 200.0;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: caretOffset.dx,
        top: caretOffset.dy + 42,
        width: overlayWidth,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: filteredSuggestions
                  .map((suggestion) => ListTile(
                        title: Text(suggestion),
                        onTap: () {
                          _onSuggestionSelected(suggestion);
                        },
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _onSuggestionSelected(String suggestion) {
    final text = _controller.text;

    if (text.endsWith('.')) {
      _controller.text = '$text$suggestion';
    } else {
      final textParts = text.split('.');
      textParts.removeLast();
      _controller.text = '${textParts.join('.')}$suggestion';
    }

    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );

    _scheduleOverlayUpdate();
  }

  // getting the caret (cursor) position
  Offset _getCaretPosition() {
    final renderObject = _editableTextKey.currentContext?.findRenderObject();
    if (renderObject is RenderBox) {
      RenderEditable? renderEditable = _findRenderEditable(renderObject);
      if (renderEditable != null) {
        final textPainter = TextPainter(
          maxLines: null,
          textScaler: TextScaler.linear(1.25),
          text: TextSpan(
            text: _controller.text,
            style: GoogleFonts.spaceMono(
              fontSize: Theme.of(context).textTheme.bodyMedium!.fontSize,
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        final caretOficial =
            renderEditable.getLocalRectForCaret(_cursorPosition);

        textPainter.layout(maxWidth: 500 - contentPadding.left - contentPadding.right);
        final caretOffset =
            textPainter.getOffsetForCaret(_cursorPosition, caretOficial);
        final globalOffset = renderObject.localToGlobal(caretOffset);
 print(
            'Posição do cursor - X: ${globalOffset.dx}, Y: ${globalOffset.dy}');
        print('caretOffset - X: ${caretOffset.dx}, Y: ${caretOffset.dy}');
        // print('caretOficial - X: ${caretOficial.dx}, Y: ${caretOffset.dy}');
        print('diff - Y: ${globalOffset.dy - caretOffset.dy}');
       
        print('------------');
        return globalOffset;
      } else {
        print('RenderEditable não encontrado.');
      }
    } else {
      print('RenderBox não encontrado.');
    }
    return Offset.zero;
  }

  // Traverse the render tree to find the RenderEditable
  RenderEditable? _findRenderEditable(RenderObject renderObject) {
    if (renderObject is RenderEditable) {
      return renderObject;
    }

    RenderEditable? result;
    renderObject.visitChildren((child) {
      result ??= _findRenderEditable(child);
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Posição do Cursor'), leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back)),),
        body: Container(
          // alignment: Alignment.center,
          padding: const EdgeInsets.all(6),
          width: 500,
          child: TextFormField(
            key: _editableTextKey,
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            style: GoogleFonts.spaceMono(
              fontSize: Theme.of(context).textTheme.bodyMedium!.fontSize,
            ),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: contentPadding,
            ),
            onChanged: (value) {
              _scheduleOverlayUpdate();
            },
          ),
        ),
      ),
    );
  }
}
