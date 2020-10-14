import 'dart:convert';

import 'package:devinci/extra/classes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:devinci/extra/globals.dart' as globals;
import 'package:flutter_statusbarcolor/flutter_statusbarcolor.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_core/theme.dart';

class SallesPage extends StatefulWidget {
  SallesPage({Key key}) : super(key: key);

  @override
  _SallesPageState createState() => _SallesPageState();
}

final SalleDataSource salleDataSource = SalleDataSource();

class _SallesPageState extends State<SallesPage> {
  bool show = false;

  void runBeforeBuild() async {
    await globals.user.getSallesLibres();
    if (mounted)
      setState(() {
        show = true;
      });
  }

  void initState() {
    super.initState();
    //populateData();
    SchedulerBinding.instance.addPostFrameCallback((_) => runBeforeBuild());
  }

  Widget getCellWidget(BuildContext context, GridColumn column, int rowIndex) {
    print("get");

    if (globals.user.sallesStr.indexOf(column.mappingName) > -1) {
      try {
        final bool state = globals.user.salles[rowIndex]
            .occupation[globals.user.sallesStr.indexOf(column.mappingName)];
        return Container(
          color: state
              ? Theme.of(context).primaryColor
              : Theme.of(context).scaffoldBackgroundColor,
        );
      } catch (e) {
        return null;
      }
    } else {
      return null;
    }
  }

  List<GridColumn> genColumns() {
    List<GridColumn> res = new List<GridColumn>();
    res.add(GridTextColumn(mappingName: 'salles', headerText: 'Salles')
      ..cellStyle = DataGridCellStyle(textStyle: TextStyle(fontSize: 12))
      ..padding = EdgeInsets.only(left: 6));
    for (String elem in globals.user.sallesStr) {
      res.add(
        GridWidgetColumn(mappingName: elem)
          ..padding = EdgeInsets.only(left: 4, right: 4)
          ..width = 50.0,
      );
    }
    return res;
  }

  @override
  Widget build(BuildContext context) {
    globals.currentContext = context;
    FlutterStatusbarcolor.setStatusBarColor(Colors.transparent);
    FlutterStatusbarcolor.setStatusBarWhiteForeground(
        globals.currentTheme.isDark());
    FlutterStatusbarcolor.setNavigationBarColor(
        Theme.of(context).scaffoldBackgroundColor);
    FlutterStatusbarcolor.setNavigationBarWhiteForeground(
        globals.currentTheme.isDark());
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        brightness: MediaQuery.of(context).platformBrightness,
        centerTitle: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        automaticallyImplyLeading: false,
        title: Text(
          'Salles libres',
          style: Theme.of(context).textTheme.headline1,
        ),
        actions: <Widget>[
          IconButton(
            icon: IconTheme(
              data: Theme.of(context).accentIconTheme,
              child: Icon(Icons.close),
            ),
            onPressed: () async {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: show
          ? SfDataGrid(
              source: salleDataSource,
              cellBuilder: getCellWidget,
              columns: genColumns(),
              frozenColumnsCount: 1,
              gridLinesVisibility: GridLinesVisibility.both,
            )
          : Center(
              child: CupertinoActivityIndicator(
              animating: true,
            )),
    );
  }
}

class SalleDataSource extends DataGridSource<Salle> {
  @override
  List<Salle> get dataSource => globals.user.salles;

  @override
  Object getValue(Salle salle, String columnName) {
    if (columnName == "salles") {
      return salle.name;
    } else {
      return ' ';
    }
    // switch (columnName) {
    //   case 'salles':
    //     return salle.name;
    //     break;
    //   default:
    //     return ' ';
    //     break;
    // }
  }
}
