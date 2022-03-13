# Expansion Datagrid

- Like most grids, Expansion Datagrid gives users the ability to sort, filter their data,
  group data and display additional data in the expanded panel. The grid can hide
  and display column based on the device resolution and size.
  Infinite scroll is used to load large amounts of data in the lazy loading mode;
  the data is loaded only when the scrollbar reaches the end of the scroller.
  Supports theme and customization of any widgets such as headers, rows, etc.

## Example
```dart
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter DataGrid',
      theme: ThemeData(
          primarySwatch: Colors.blue,
          dataTableTheme: DataGridThemeData(
              headingAlignment: Alignment.centerLeft,
              headingRowColor: MaterialStateProperty.all(Colors.grey),
              headingTextStyle: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
              dataRowColor: MaterialStateProperty.all(const Color(0xFFFBFBFD)),
              dataTextStyle: const TextStyle(color: Colors.black54, fontSize: 14),
              dividerThickness: 1,
              headingRowHeight: 50,
              decoration: const BoxDecoration(
                  color: Color(0xff3f5767),
                  border: Border(
                    bottom: BorderSide(color: Colors.black12),
                  )))),
      home: Scaffold(
        body: SafeArea(
          child: TestDataGrid().setHeaders(getHeaders()).setData(testData),
        ),
      ),
    );
  }

  List<Header> getHeaders() => [
        Header('Name', 'name', 4),
        Header('Since', 'since_date', 2, width: 450, format: 'date'),
        Header('Start Date', 'start_date', 2, width: 800, format: 'date'),
        Header('End Date', 'end_date', 2, width: 800, format: 'date'),
        Header('Status', 'is_active', 2, width: 300, format: 'status'),
      ];
}

class TestDataGrid extends ExpansionDataGrid {
  final editFields = [
    FieldInfo('name', title: 'Name', required: true),
    FieldInfo('since_date', title: 'Since', format: 'date'),
    FieldInfo('start_date', title: 'Start Date', format: 'date'),
    FieldInfo('end_date', title: 'End Date', format: 'date'),
    FieldInfo('is_active', title: 'Status', format: 'status')
  ];

  TestDataGrid({Key? key}) : super(key: key);

  @override
  Alignment getRowAlignment(Header header) => (header.format == 'status') ? Alignment.center : Alignment.centerLeft;

  @override
  String getRowValue(dynamic val, RowItem rowItem, String? format) {
    switch (format) {
      case 'status':
        return val == true ? 'Active' : 'Inactive';
      default:
        return super.getRowValue(val, rowItem, format);
    }
  }

  @override
  Widget getRowComponent(BuildContext context, dynamic val, RowItem rowItem, Header header) {
    if (header.dataField != 'name') {
      return super.getRowComponent(context, val, rowItem, header);
    }
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: Text(getRowValue(val, rowItem, header.format),
            style: const TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            )),
      ),
    );
  }

  @override
  Widget expandRow(BuildContext context, RowItem rowItem) {
    final data = [];
    for (var field in editFields) {
      data.add(rowItem.data[field.dataField]);
    }
    return createExpandPanel(context, editFields, data, rowItem,
        onDelete: (BuildContext context, RowItem rowItem) => deleteRowItem(rowItem));
  }

  @override
  Future<void> lazyLoad(void Function(List<dynamic>) callback) async {
    final items = [];
    final max = data.length + 10;
    await Future.delayed(const Duration(seconds: 2));
    for (int i = data.length + 1; i <= max; i++) {
      items.add({
        'name': 'ORG$i',
        'since_date': '2021-08-02',
        'start_date': '2021-08-03',
        'end_date': '2021-08-04',
        'is_active': true
      });
    }
    callback(items);
  }

  @override
  Widget getLastHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 56,
      height: theme.dataTableTheme.headingRowHeight ?? 32,
      color: ExpansionDataGrid.getHeadingRowColor(theme),
      child: IconButton(
          key: const ValueKey<String>('dt_header_add'),
          iconSize: 24,
          padding: const EdgeInsets.only(left: 16.0, right: 16.0),
          color: Theme.of(context).dataTableTheme.dataTextStyle?.color,
          onPressed: () {
            insertRow(RowItem({
              'name': 'Hello',
              'since_date': '01/01/2021',
              'start_date': '02/02/2021',
              'end_date': '03/03/2022',
              'is_active': true
            }));
          },
          icon: const Icon(Icons.add)),
    );
  }
}

void main() {
  runApp(const MyApp());
}
```

## See Also

- https://pub.dev/packages/framework
- https://pub.dev/packages/l10n_flutter
- https://pub.dev/packages/form_components
- https://pub.dev/packages/expansion_datagrid