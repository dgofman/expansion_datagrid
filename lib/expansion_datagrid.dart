import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

typedef ExpandAction = void Function(BuildContext context, RowItem rowItem);

abstract class ExpansionDataGrid extends StatefulWidget {
  static const rowPadding = EdgeInsetsDirectional.only(start: 10.0, end: 10.0);

  final bool isAlwaysShown;
  final Duration expansionAnimationDuration;
  final ScrollController? scrollController;
  final int crossAxisWidth;
  final DataGridModel _model;

  ExpansionDataGrid(
      {Key? key,
      bool? isAlwaysShown,
      Duration? expansionAnimationDuration,
      int? insertIndex,
      int? crossAxisWidth,
      ScrollController? controller})
      : _model = DataGridModel(),
        isAlwaysShown = isAlwaysShown ?? kIsWeb,
        crossAxisWidth = crossAxisWidth ?? 300,
        expansionAnimationDuration =
            expansionAnimationDuration ?? const Duration(milliseconds: 1000),
        scrollController = controller,
        super(key: key);

  Future<void> lazyLoad(void Function(List<dynamic>) callback);
  ExpansionDataGrid setHeaders(List<Header> headers) {
    _model.headers = headers;
    return update();
  }

  ExpansionDataGrid setData(List<dynamic> data) {
    _model.data = data;
    return update();
  }

  ExpansionDataGrid update() {
    _model.state?.update();
    return this;
  }

  static BorderSide getBorderSide(ThemeData theme) {
    if (theme.dataTableTheme.decoration is BoxDecoration) {
      final decoration = theme.dataTableTheme.decoration as BoxDecoration;
      return decoration.border?.bottom ?? const BorderSide();
    }
    return const BorderSide();
  }

  static Color getHeadingRowColor(ThemeData theme) {
    return theme.dataTableTheme.headingRowColor?.resolve(<MaterialState>{}) ??
        theme.colorScheme.secondary;
  }

  List<Header> get headers => _model.headers;
  List<dynamic> get data => _model.data;
  void insertRow(RowItem rowItem, [int index = 0 /* -1 to last index */]) =>
      _model.state?.addRowItem(rowItem, index);
  void editRowItem(RowItem rowItem, dynamic data) =>
      _model.state?.editRowItem(rowItem, data);
  void deleteRowItem(RowItem rowItem) => _model.state?.deleteRowItem(rowItem);
  Alignment getRowAlignment(Header header) => Alignment.centerLeft;
  String getRowValue(dynamic val, RowItem rowItem, String? format) =>
      '${val ?? ''}';
  Widget getRowComponent(
          BuildContext context, dynamic val, RowItem rowItem, Header header) =>
      Text(getRowValue(val, rowItem, header.format),
          style: Theme.of(context).dataTableTheme.dataTextStyle);
  Widget getEditComponent(BuildContext context, dynamic data, RowItem rowItem,
          String? format) =>
      Text(getRowValue(data, rowItem, format),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          style: Theme.of(context).dataTableTheme.dataTextStyle);

  Widget getLastHeader(BuildContext context) => Container();

  Widget createRow(
      BuildContext context, dynamic val, RowItem rowItem, Header header) {
    return Container(
        key: ValueKey('dg_row_${header.dataField}_${rowItem.rowIndex}'),
        padding: ExpansionDataGrid.rowPadding,
        alignment: getRowAlignment(header),
        child: Tooltip(
          message: getRowValue(val, rowItem, header.format),
          child: getRowComponent(context, val, rowItem, header),
        ));
  }

  Widget expandRow(BuildContext context, RowItem rowItem) {
    return createExpandPanel(context, [], [], rowItem);
  }

  List<Widget> createControlButtons(BuildContext context, RowItem rowItem,
      ExpandAction? onEdit, ExpandAction? onDelete) {
    final buttons = <Widget>[];
    if (onEdit != null) {
      buttons.add(IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            onEdit(context, rowItem);
          }));
    }
    if (onDelete != null) {
      buttons.add(IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            onDelete(context, rowItem);
          }));
    }
    return buttons;
  }

  Widget createExpandPanel(BuildContext context, List<FieldInfo> fields,
      List<dynamic> data, RowItem rowItem,
      {ExpandAction? onEdit, ExpandAction? onDelete}) {
    Size screenSize = MediaQuery.of(context).size;
    final borderSide = ExpansionDataGrid.getBorderSide(Theme.of(context));
    return Container(
      padding: const EdgeInsets.all(8),
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: borderSide.color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: max(screenSize.width ~/ crossAxisWidth, 1),
                mainAxisExtent: 60,
              ),
              itemCount: fields.length,
              itemBuilder: (context, index) {
                return createExpandColumn(
                    context, index, fields, data, rowItem);
              }),
          Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children:
                  createControlButtons(context, rowItem, onEdit, onDelete)),
        ],
      ),
    );
  }

  Column createExpandColumn(BuildContext context, int index,
      List<FieldInfo> fields, List<dynamic> data, RowItem rowItem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(fields[index].title,
            style: Theme.of(context).dataTableTheme.headingTextStyle),
        const SizedBox(height: 4),
        Container(
            key: ValueKey(
                'dg_edit_${fields[index].dataField}_${rowItem.rowIndex}'),
            child: getEditComponent(
                context, data[index], rowItem, fields[index].format))
      ],
    );
  }

  @override
  State<ExpansionDataGrid> createState() => _ExpansionDataGridState();
}

class _ExpansionDataGridState extends State<ExpansionDataGrid> {
  late List<RowItem> _items;
  late bool _isLoading = false;
  late ScrollController _scrollController;
  late bool _isExternal = false;
  late double _lastMaxScrollExtent = 0;

  List<Header> get headers => widget.headers;
  List<dynamic> get data => widget.data;

  Future<void> lazyLoading() async {
    if (!_isLoading &&
        _lastMaxScrollExtent != _scrollController.position.maxScrollExtent &&
        _scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent) {
      _lastMaxScrollExtent = _scrollController.position.maxScrollExtent;
      setState(() {
        _isLoading = true;
      });
      widget.lazyLoad((List<dynamic> data) {
        this.data.addAll(List<Map<String, Object>>.from(data));
        _items
            .addAll(data.map((item) => RowItem(item, _items.length)).toList());
        setState(() {
          _isLoading = false;
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _isExternal = widget.scrollController != null;
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.removeListener(lazyLoading);
    _scrollController.addListener(lazyLoading);
    update();
  }

  @override
  void dispose() {
    _scrollController.removeListener(lazyLoading);
    if (!_isExternal) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget._model.state = this;
    return Scrollbar(
      thumbVisibility: widget.isAlwaysShown,
      controller: _isExternal ? null : _scrollController,
      child: SingleChildScrollView(
        controller: _isExternal ? null : _scrollController,
        child: Column(
          children: <Widget>[
            headerBuilder(context),
            rowBuilder(context),
            if (_isLoading) const CircularProgressIndicator()
          ],
        ),
      ),
    );
  }

  void update() {
    setState(() {
      data;
      headers;
      _lastMaxScrollExtent = 0;
      _items = data.mapIndexed((index, item) => RowItem(item, index)).toList();
    });
  }

  void addRowItem(RowItem rowItem, int index) {
    for (var item in _items) {
      item.isExpanded = false;
    }
    //rowItem.isExpanded = true; //material/mergeable_material.dart:459:18 (_children[j] is MaterialGap is not true
    if (index == -1) {
      index = data.length;
    }
    setState(() {
      data.insert(index, rowItem.data);
      _items.insert(index, rowItem);
      reassign();
    });
  }

  void editRowItem(RowItem rowItem, dynamic data) {
    setState(() {
      this.data[rowItem.rowIndex] = data;
      rowItem.data = data;
    });
  }

  void deleteRowItem(RowItem rowItem) {
    setState(() {
      data.removeAt(rowItem.rowIndex);
      _items.removeAt(rowItem.rowIndex);
      reassign();
    });
  }

  void reassign() {
    int rowIndex = 0;
    for (var rowItem in _items) {
      rowItem.rowIndex = rowIndex++;
    }
  }

  Widget headerBuilder(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    BorderSide borderSide = ExpansionDataGrid.getBorderSide(theme);
    AlignmentGeometry? headingAlignment;
    if (theme.dataTableTheme is DataGridThemeData) {
      headingAlignment =
          (theme.dataTableTheme as DataGridThemeData).headingAlignment;
    }
    return Container(
        decoration: BoxDecoration(
            color: Colors.white, border: Border.all(color: borderSide.color)),
        height: theme.dataTableTheme.headingRowHeight,
        child: Row(
          children: headers
              .mapIndexed((index, item) => Expanded(
                    flex: (screenSize.width < item.minWidth) ? 0 : item.flex,
                    child: LayoutBuilder(
                      builder: (context, constraints) => (screenSize.width <
                              item.minWidth)
                          ? Container()
                          : Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                  color: ExpansionDataGrid.getHeadingRowColor(
                                      theme),
                                  border: index == 0 ||
                                          theme.dataTableTheme
                                                  .dividerThickness ==
                                              0
                                      ? null
                                      : Border(
                                          left: borderSide.copyWith(
                                              color: borderSide.color,
                                              width: theme.dataTableTheme
                                                  .dividerThickness),
                                        )),
                              alignment: headingAlignment,
                              child: Text(item.text,
                                  key: ValueKey<String>(
                                      'dg_header_${index += 1}'),
                                  textAlign: TextAlign.left,
                                  style: theme.dataTableTheme.headingTextStyle),
                            ),
                    ),
                  ))
              .toList()
            ..add(
              Expanded(flex: 0, child: widget.getLastHeader(context)),
            ),
        ));
  }

  Widget rowBuilder(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final borderSide = ExpansionDataGrid.getBorderSide(theme);
    return ExpansionPanelList(
      dividerColor: borderSide.color,
      animationDuration: widget.expansionAnimationDuration,
      expansionCallback: (int index, bool isExpanded) {
        for (var rowItem in _items) {
          rowItem.isExpanded = false;
        }
        setState(() {
          _items[index].isExpanded = !isExpanded;
        });
      },
      children: _items.map<ExpansionPanel>((RowItem rowItem) {
        return ExpansionPanel(
          backgroundColor: rowItem.rowIndex % 2 == 0
              ? theme.dataTableTheme.dataRowColor?.resolve(<MaterialState>{})
              : Colors.white,
          headerBuilder: (BuildContext context, bool isExpanded) {
            return Row(
                children: headers
                    .map((Header header) => Expanded(
                          flex: (screenSize.width < header.minWidth)
                              ? 0
                              : header.flex,
                          child: LayoutBuilder(
                              builder: (context, constraints) =>
                                  (screenSize.width < header.minWidth)
                                      ? Column()
                                      : widget.createRow(
                                          context,
                                          rowItem.data[header.dataField],
                                          rowItem,
                                          header)),
                        ))
                    .toList());
          },
          body: rowItem.isExpanded
              ? widget.expandRow(context, rowItem)
              : Container(),
          isExpanded: rowItem.isExpanded,
        );
      }).toList(),
    );
  }
}

class DataGridModel {
  late List<Header> headers;
  late List<dynamic> data;
  // ignore: library_private_types_in_public_api
  late _ExpansionDataGridState? state;
  DataGridModel()
      : state = null,
        data = [];
}

class Header {
  String text;
  String dataField;
  String format;
  int flex;
  double minWidth;
  Header(this.text, this.dataField, this.flex,
      {double width = 0, this.format = 'string'})
      : minWidth = width;
}

class RowItem {
  int rowIndex;
  dynamic data;
  late bool isExpanded;
  RowItem(this.data, [this.rowIndex = -1, this.isExpanded = false]);
}

class FieldInfo {
  late String title;
  final String dataField;
  final String? format;
  final GlobalKey<FormFieldState> key;
  final bool required;
  FieldInfo(this.dataField,
      {this.format, this.required = false, this.title = ''})
      : key = GlobalKey<FormFieldState>(debugLabel: dataField);
}

class DataGridThemeData extends DataTableThemeData {
  final Alignment? headingAlignment;

  const DataGridThemeData({
    Decoration? decoration,
    MaterialStateProperty<Color?>? dataRowColor,
    double? dataRowHeight,
    TextStyle? dataTextStyle,
    MaterialStateProperty<Color?>? headingRowColor,
    double? headingRowHeight,
    TextStyle? headingTextStyle,
    double? dividerThickness,
    this.headingAlignment,
  }) : super(
            decoration: decoration,
            dataRowColor: dataRowColor,
            dataRowHeight: dataRowHeight,
            dataTextStyle: dataTextStyle,
            headingRowColor: headingRowColor,
            headingRowHeight: headingRowHeight,
            headingTextStyle: headingTextStyle,
            dividerThickness: dividerThickness);

  @override
  DataTableThemeData copyWith({
    Decoration? decoration,
    MaterialStateProperty<Color?>? dataRowColor,
    double? dataRowHeight,
    TextStyle? dataTextStyle,
    MaterialStateProperty<Color?>? headingRowColor,
    double? headingRowHeight,
    TextStyle? headingTextStyle,
    double? horizontalMargin,
    double? columnSpacing,
    double? dividerThickness,
    double? checkboxHorizontalMargin,
    Alignment? headingAlignment,
  }) {
    return DataGridThemeData(
      decoration: decoration ?? this.decoration,
      dataRowColor: dataRowColor ?? this.dataRowColor,
      dataRowHeight: dataRowHeight ?? this.dataRowHeight,
      dataTextStyle: dataTextStyle ?? this.dataTextStyle,
      headingRowColor: headingRowColor ?? this.headingRowColor,
      headingRowHeight: headingRowHeight ?? this.headingRowHeight,
      headingTextStyle: headingTextStyle ?? this.headingTextStyle,
      dividerThickness: dividerThickness ?? this.dividerThickness,
      headingAlignment: headingAlignment ?? this.headingAlignment,
    );
  }
}

abstract class IExpandDataGrid {
  Widget createRow(
      BuildContext context, dynamic val, RowItem rowItem, Header header);
  Widget expandRow(BuildContext context, RowItem rowItem);
  String? getDisplayValue(dynamic val, Map? data, String? format);
  Future<void> lazyLoad(void Function(List<dynamic>) callback);
}
