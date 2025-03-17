import 'package:flutter/material.dart';
import 'package:input_history_text_field/input_history_text_field.dart';
import 'package:input_history_text_field/src/model/input_history_item.dart';
import 'package:input_history_text_field/src/model/input_history_items.dart';

class InputHistoryTextFieldState extends State<InputHistoryTextField> {
  late InputHistoryController _inputHistoryController;
  late String Function(String) _textToSingleLine;
  late FocusNode _focusNode;
  final GlobalKey _overlayHistoryListKey = GlobalKey();
  OverlayEntry? _overlayHistoryList;
  String? _lastSubmitValue;

  @override
  void initState() {
    super.initState();
    _initWidgetState();
    _initController();
  }

  @override
  void didUpdateWidget(covariant InputHistoryTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Re-initialize state if needed after hot reload
    if (widget.textEditingController == null) {
      widget.textEditingController =
          TextEditingController(text: _lastSubmitValue);
    }
    _initWidgetState();
    _initController();
  }

  void _initWidgetState() {
    if (!widget.enableHistory) return;
    _focusNode = widget.focusNode ??= FocusNode();
    _textToSingleLine = widget.textToSingleLine ?? _defaultTextToSingleLine;
    widget.textEditingController ??=
        TextEditingController(text: _lastSubmitValue);
    if (widget.enableFilterHistory)
      widget.textEditingController?.addListener(_onTextChange);
    _focusNode.addListener(_onFocusChange);
  }

  void _initController() {
    _inputHistoryController =
        widget.inputHistoryController ?? InputHistoryController();
    _inputHistoryController.setup(
      widget.historyKey,
      widget.limit,
      widget.textEditingController,
      widget.promoteRecentHistoryItems,
      lockItems: widget.lockedItems,
    );
  }

  void _onTextChange() {
    _inputHistoryController.filterHistory(widget.textEditingController!.text);
    if (_focusNode.hasFocus && !_inputHistoryController.isShown()) {
      _inputHistoryController.toggleExpand();
    }
  }

  void _onFocusChange() {
    if (widget.readOnly) {
      return;
    }
    if (_overlayHistoryList == null) {
      _initOverlay(); // Initialize the overlay right away
    }
    if (_focusNode.hasFocus && _overlayHistoryList == null) {
      _toggleOverlayHistoryList();
    }
    if (!_focusNode.hasFocus) {
      // If user clicked another field, hide history
      if (FocusManager.instance.primaryFocus != _focusNode) {
        _inputHistoryController.hide();
      }

      // Save history when focus is lost
      if (widget.textEditingController!.text != _lastSubmitValue) {
        _saveHistory();
        _lastSubmitValue = widget.textEditingController!.text;
      }
    }
  }

  void _saveHistory() {
    if (!widget.enableSave) return;
    final text = widget.textEditingController?.text;
    _inputHistoryController.add(text ?? '');
  }

  @override
  void dispose() {
    super.dispose();
    _inputHistoryController.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _overlayHistoryList?.remove();
  }

  @override
  Widget build(BuildContext context) {
    return _textField();
  }

  Future<void> _toggleOverlayHistoryList() async {
    if (!widget.showHistoryList) return;

    if (_focusNode.hasFocus) {
      if (!_inputHistoryController.isShown()) {
        _inputHistoryController.toggleExpand();
      }
    } else {
      _inputHistoryController.hide();
    }
  }

  void _initOverlay() {
    _overlayHistoryList = _historyListContainer();
    Overlay.of(context).insert(_overlayHistoryList!);
  }

  OverlayEntry _historyListContainer() {
    final renderBox = context.findRenderObject() as RenderBox;
    return OverlayEntry(
      builder: (context) {
        return StreamBuilder<bool>(
          stream: _inputHistoryController.listShow.stream,
          builder: (context, shown) {
            if (!shown.hasData ||
                shown.connectionState == ConnectionState.waiting)
              return SizedBox.shrink();
            return Stack(
              children: <Widget>[
                _historyList(context, renderBox, shown.data!),
              ],
            );
          },
        );
      },
    );
  }

  Decoration _listDecoration() {
    return BoxDecoration(
      color: Theme.of(context).canvasColor,
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(6),
        bottomRight: Radius.circular(6),
      ),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.shadow.withValues(alpha: .3),
          offset: Offset(0, 3), // Slightly stronger downward offset
          blurRadius: 8, // Higher blur for softer effect
          spreadRadius: 1, // Slight spread for more natural shadow
        ),
        BoxShadow(
          color: Theme.of(context).colorScheme.shadow.withValues(alpha: .15),
          offset: Offset(0, 1), // Light offset for top surface separation
          blurRadius: 3,
        ),
      ],
    );
  }

  Widget _historyList(BuildContext context, RenderBox render, bool isShow) {
    final offset = render.localToGlobal(Offset.zero);
    final listOffset = widget.listOffset ?? Offset(0, 0);

    return Positioned(
      key: _overlayHistoryListKey,
      top: offset.dy +
          render.size.height +
          (widget.listStyle == ListStyle.Badge
              ? listOffset.dy + 6
              : listOffset.dy),
      left: offset.dx + listOffset.dx,
      width: isShow
          ? widget.listStyle == ListStyle.List
              ? render.size.width
              : null
          : null,
      height: isShow ? null : 0,
      child: Material(
        child: widget.overlayHeight != null
            ? ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: widget.overlayHeight!,
                  maxWidth: render.size.width,
                ),
                child: _listContainer(render, isShow),
              )
            : ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: render.size.width,
                ),
                child: _listContainer(render, isShow),
              ),
      ),
    );
  }

  Widget _listContainer(RenderBox render, bool isShow) {
    return Container(
      decoration: widget.listStyle == ListStyle.Badge
          ? null
          : widget.listDecoration ?? _listDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(6),
          bottomRight: Radius.circular(6),
        ),
        child: StreamBuilder<InputHistoryItems>(
          stream: _inputHistoryController.list.stream,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.hasError || !isShow)
              return SizedBox.shrink();
            if (widget.listStyle == ListStyle.Badge) {
              return Wrap(
                spacing: 8,
                children: snapshot.data!.all.asMap().entries.map((entry) {
                  int index = entry.key;
                  var item = entry.value;
                  return widget.historyBadgeItemLayoutBuilder?.call(
                          _inputHistoryController,
                          snapshot.data!.all[index],
                          index) ??
                      _badgeHistoryItem(item);
                }).toList(),
              );
            } else {
              return ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: snapshot.data!.all.length,
                itemBuilder: (context, index) {
                  return widget.historyListItemLayoutBuilder?.call(
                          _inputHistoryController,
                          snapshot.data!.all[index],
                          index) ??
                      _listHistoryItem(
                        snapshot.data!.all[index],
                      );
                },
              );
            }
          },
        ),
      ),
    );
  }

  Widget _badgeHistoryItem(item) {
    return ElevatedButton(
      style: ButtonStyle(
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        ),
      ),
      onPressed: () async {
        _lastSubmitValue = item.text;
        await _inputHistoryController.select(item.text);
        widget.onHistoryItemSelected?.call(item.text);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// history icon
          if (widget.showHistoryIcon) _historyIcon(true),
          if (widget.showHistoryIcon) SizedBox(width: 4),

          /// text
          _historyItemText(item),

          /// delete icon
          if (widget.showDeleteIcon) SizedBox(width: 4),
          if (widget.showDeleteIcon) _deleteIcon(item, true)
        ],
      ),
    );
  }

  Widget _listHistoryItem(InputHistoryItem item) {
    return InkWell(
      onTap: () async {
        _lastSubmitValue = item.text;
        await _inputHistoryController.select(item.text);
        widget.onHistoryItemSelected?.call(item.text);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            if (widget.showHistoryIcon) _historyIcon(false),
            if (widget.showHistoryIcon) SizedBox(width: 12),
            Expanded(
              child: Tooltip(
                message: item.text,
                child: _historyItemText(item),
              ),
            ),
            if (widget.showDeleteIcon) SizedBox(width: 12),
            if (widget.showDeleteIcon) _deleteIcon(item, false)
          ],
        ),
      ),
    );
  }

  Widget _historyItemText(InputHistoryItem item) {
    return Text(_textToSingleLine.call(item.text),
        overflow: TextOverflow.ellipsis,
        style: item.isLock ? widget.lockedItemTextStyle : widget.itemTextStyle);
  }

  Widget _historyIcon(bool isBadge) {
    return widget.historyIcon ??
        Icon(
          Icons.history,
          size: isBadge ? 20 : null,
        );
  }

  Widget _deleteIcon(InputHistoryItem item, bool isBadge) {
    if (item.isLock) return SizedBox.shrink();
    if (isBadge) {
      return InkWell(
        onTap: () {
          _inputHistoryController.remove(item);
        },
        child: widget.deleteIcon ??
            Icon(
              Icons.close,
              size: 20,
            ),
      );
    } else {
      return SizedBox(
        height: 24,
        width: 24,
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
          visualDensity: VisualDensity.compact,
          icon: widget.deleteIcon ??
              Icon(
                Icons.close,
              ),
          onPressed: () {
            _inputHistoryController.remove(item);
          },
        ),
      );
    }
  }

  void _onTap() {
    if (widget.textEditingController!.text != _lastSubmitValue &&
        _lastSubmitValue != null) {
      widget.onTap?.call();
    }
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
      Future.delayed(Duration(milliseconds: 100), () {
        _toggleOverlayHistoryList();
      });
    } else {
      _toggleOverlayHistoryList();
    }
  }

  String _defaultTextToSingleLine(String text) {
    return text.replaceAll("\n", "").replaceAll(" ", "");
  }

  Widget _textField() {
    return TextFormField(
        onTapOutside: (event) async {
          RenderBox? overlayBox = _overlayHistoryListKey.currentContext
              ?.findRenderObject() as RenderBox?;
          RenderBox? renderBox = context.findRenderObject() as RenderBox?;

          if (overlayBox != null && renderBox != null) {
            // Convert the tap's local position to global position
            // Get the global position of the tap event
            Offset globalTapPosition = event.position;

            // Get the global position and size of the overlay entry
            Offset overlayPosition = overlayBox.localToGlobal(Offset.zero);
            Size overlaySize = overlayBox.size;

            // Check if the tap is within the overlay bounds
            bool tappedOutside = !(globalTapPosition.dx >= overlayPosition.dx &&
                globalTapPosition.dx <=
                    overlayPosition.dx + overlaySize.width &&
                globalTapPosition.dy >= overlayPosition.dy &&
                globalTapPosition.dy <=
                    overlayPosition.dy + overlaySize.height);

            // If tapped outside the overlay, close the overlay
            if (tappedOutside) {
              _focusNode.unfocus();
              _inputHistoryController.hide();
            }
          } else {
            _focusNode.unfocus();
            _inputHistoryController.hide();
          }
        },
        key: widget.key,
        controller: widget.textEditingController,
        focusNode: _focusNode,
        decoration: widget.decoration,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        style: widget.style,
        strutStyle: widget.strutStyle,
        textAlign: widget.textAlign,
        textAlignVertical: widget.textAlignVertical,
        textDirection: widget.textDirection,
        readOnly: widget.readOnly,
        contextMenuBuilder: widget.contextMenuBuilder,
        showCursor: widget.showCursor,
        autofocus: widget.autofocus,
        obscureText: widget.obscureText,
        autocorrect: widget.autocorrect,
        smartDashesType: widget.smartDashesType,
        smartQuotesType: widget.smartQuotesType,
        enableSuggestions: widget.enableSuggestions,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        expands: widget.expands,
        maxLength: widget.maxLength,
        // ignore: deprecated_member_use
        maxLengthEnforcement: widget.maxLengthEnforcement,
        onChanged: widget.onChanged,
        onEditingComplete: widget.onEditingComplete,
        inputFormatters: widget.inputFormatters,
        enabled: widget.enabled,
        cursorWidth: widget.cursorWidth,
        cursorRadius: widget.cursorRadius,
        cursorColor: widget.cursorColor,
        selectionHeightStyle: widget.selectionHeightStyle,
        selectionWidthStyle: widget.selectionWidthStyle,
        keyboardAppearance: widget.keyboardAppearance,
        scrollPadding: widget.scrollPadding,
        dragStartBehavior: widget.dragStartBehavior,
        enableInteractiveSelection: widget.enableInteractiveSelection,
        onTap: _onTap,
        buildCounter: widget.buildCounter,
        scrollController: widget.scrollController,
        scrollPhysics: widget.scrollPhysics);
  }
}
