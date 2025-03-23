import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:wartiva_autocomplete/my_app.dart';

void main() {
  runApp(MaterialApp(home: CursorPositionExample()));
}

class CursorPositionExample extends StatefulWidget {
  const CursorPositionExample({super.key});

  @override
  State<CursorPositionExample> createState() => _CursorPositionExampleState();
}

class _CursorPositionExampleState extends State<CursorPositionExample> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _editableTextKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  TextPosition _cursorPosition = TextPosition(offset: 0);

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_updateSuggestionPosition);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.removeListener(_updateSuggestionPosition);
    _controller.dispose();
    _focusNode.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  // Atualiza a posição do cursor
  void _updateSuggestionPosition() {
    setState(() {
      _cursorPosition = _controller.selection.extent;
    });
    _getCaretPosition();
  }

  // Obtém a posição do cursor
  void _getCaretPosition() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }

    if (_controller.text.isEmpty) return;
    final renderObject = _editableTextKey.currentContext?.findRenderObject();
    if (renderObject is RenderBox) {
      RenderEditable? renderEditable = _findRenderEditable(renderObject);
      if (renderEditable != null) {
        final textPainter = TextPainter(
          maxLines: null,
          textScaler: TextScaler.linear(1.25),
          text: TextSpan(
            text: _controller.text,
            style: const TextStyle(color: Colors.black),
          ),
          textDirection: TextDirection.ltr,
        );
        final caretOficial =
            renderEditable.getLocalRectForCaret(_cursorPosition);

        textPainter.layout(maxWidth: 500);
        final caretOffset =
            textPainter.getOffsetForCaret(_cursorPosition, caretOficial);
        final globalOffset = renderObject.localToGlobal(caretOffset);
        final height = renderEditable.size.height;

        _showOverlay(globalOffset);
        print(
            'Posição do cursor - X: ${globalOffset.dx}, Y: ${globalOffset.dy}');
        print('caretOffset - X: ${caretOffset.dx}, Y: ${caretOffset.dy}');
        // print('caretOficial - X: ${caretOficial.dx}, Y: ${caretOffset.dy}');
        print('diff - Y: ${globalOffset.dy - caretOffset.dy}');
        print('height: $height');
        print('------------');
      } else {
        print('RenderEditable não encontrado.');
      }
    } else {
      print('RenderBox não encontrado.');
    }
  }

  final List<String> _suggestions = ['apple', 'tomato', 'watermelon'];
  final List<String> _newSuggestions = ['banana', 'orange', 'grape'];

  void _showOverlay(Offset offset) {
    _overlayEntry?.remove();
    final textParts = _controller.text.split('.');
    final lastPart = textParts.last;
    final filteredSuggestions = _controller.text.endsWith('.')
        ? _newSuggestions
        : _suggestions.where((s) => s.contains(lastPart)).toList();

    if (filteredSuggestions.isEmpty) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      return;
    }
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + 42,
        width: 200,
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
    Overlay.of(context).insert(_overlayEntry!);
  }

    void _onSuggestionSelected(String suggestion) {
    final text = _controller.text;

    if (text.endsWith('.')) {
      _controller.text = '$text$suggestion';
    } else {
      final textParts = text.split('.');
      textParts.removeLast();
      _controller.text = '${textParts.join('.')}.$suggestion';
    }

    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );

    _scheduleOverlayUpdate();
  }

    void _scheduleOverlayUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateSuggestionPosition();
      }
    });
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

  // Exibe o TextField e imprime a posição do cursor
  void _onFocusChange() {
    if (_focusNode.hasFocus) {
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Task with default fonte')),
    
      body: SizedBox(
        width: 500,
        child: Column(
          children: [
            TextFormField(
              key: _editableTextKey,
              controller: _controller,
              focusNode: _focusNode,
              style: const TextStyle(
                color: Colors.black,
              ),
              cursorColor: Colors.blue,
              maxLines: null,
              autofocus: true,
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) {
                  return MyApp();
                }));
              },
              child: const Text('Original task  >>'),
            ),
          ],
        ),
      ),
    );
  }
}
