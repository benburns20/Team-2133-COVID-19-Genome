import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genome_2133/cards/variant.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../home.dart';
import '../cards/skeleton.dart';

List selections = [];

class VariantView extends StatefulWidget {
  final Map country;
  final List<Map<String, dynamic>> variants;
  final Function updateParent;
  final GoogleMapController mapController;

  const VariantView({Key? key, required this.country, required this.variants, required this.updateParent, required this.mapController}) : super(key: key);

  @override
  State<VariantView> createState() => _VariantView();
}

class _VariantView extends State<VariantView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white, //change your color here
        ),
        title: Text(widget.country["country"] + " Variants",
            style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration:
              BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Row(children: [
              Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: IconButton(
                    icon: const Icon(Icons.content_copy),
                    tooltip: "Copy selected variants to clipboard",
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(
                              text: selections
                                  .toString()
                                  .replaceAll("[", '')
                                  .replaceAll("]", '')
                                  .replaceAll(", ", "\n")))
                          .then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Copied variants to clipboard')));
                      });
                    },
                  )),
              Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: ElevatedButton(
                      style: TextButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 18),
                          backgroundColor: Colors.white), //style
                      onPressed: () => launchUrl(Uri.parse(
                          'https://blast.ncbi.nlm.nih.gov/Blast.cgi?PROGRAM=blastn&PAGE_TYPE=BlastSearch&LINK_LOC=blasthome')),
                      child: const Text('Compare')))
            ]),
          ),
        ],
      ),
      body: SortablePage(
        items: widget.variants,
        updateParent: widget.updateParent,
        mapController: widget.mapController
      ),
    );
  }
}

class SortablePage extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Function updateParent;
  final GoogleMapController mapController;

  const SortablePage({Key? key, required this.items, required this.updateParent, required this.mapController}) : super(key: key);

  @override
  _SortablePageState createState() => _SortablePageState();
}

class _SortablePageState extends State<SortablePage> {
  late List<String> headerLabel;
  int? sortColumnIndex;
  bool isAscending = false;

  @override
  void initState() {
    headerLabel = List<String>.from(widget.items.first.keys);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          children: [
            Container(color: Theme.of(context).backgroundColor),
            Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.vertical,
                    child: buildDataTable(),
                  ),
                )),
          ],
        ),
      );

  Widget buildDataTable() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: DataTable(
        sortAscending: isAscending,
        sortColumnIndex: sortColumnIndex,
        columns: getColumns(headerLabel),
        rows: getRows(widget.items),
      ),
    );
    /*return FutureBuilder(
      future: rootBundle.loadString("assets/data.json"),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (!snapshot.hasData) return Container();
        users = json.decode(snapshot.data!)["Fake Data"];
        return DataTable(
          sortAscending: isAscending,
          sortColumnIndex: sortColumnIndex,
          columns: getColumns(['Accession', 'Geographical Location', 'Date Collected', 'Generated', 'Pinned']),
          rows: getRows(users),
        );
      }
    );*/
  }

  List<DataColumn> getColumns(List<String> columns) => columns
      .map((String column) => DataColumn(
            label: Expanded(
                child: Text(column.toTitle, textAlign: TextAlign.center)),
            onSort: onSort,
          ))
      .toList();

  List<DataRow> getRows(List items) => items.map((user) {
        List<DataCell> lister;

        List<dynamic> data = [];
        for (String key in headerLabel) {
          if (key != "accession" && key != "selected" && key != "pinned") {
            data.add(user[key]);
          }
        }
        lister = getCells(data.reversed.toList());

        lister.add(DataCell(
            Align(
                alignment: Alignment.centerRight,
                child: Text(user["accession"].toString())
            ),
            onTap: () {
              Navigator.pop(context);
              VariantCard selectedVariant = VariantCard(
                variant: user,
                mapController: widget.mapController,
                updateParent: widget.updateParent,
                controlKey: GlobalKey(),
              );
              addCard(SkeletonCard(
                controlKey: GlobalKey(),
                title: selectedVariant.toString(),
                body: selectedVariant,
                updateParent: widget.updateParent,
              ));
              widget.updateParent();
            }
        ));

        lister.add(DataCell(Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: user["selected"]
                ? const Icon(Icons.done_sharp)
                : const Icon(Icons.check_box_outline_blank),
            color: const Color(0xff445756),
            onPressed: () {
              setState(() {
                user["selected"] = !user["selected"];
                if (user["selected"]) {
                  selections.add(user["accession"]);
                } else {
                  selections.remove(user["accession"]);
                }
              });
            },
          ),
        )));

        lister.add(DataCell(Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: user["pinned"]
                ? const Icon(Icons.push_pin)
                : const Icon(Icons.push_pin_outlined),
            color: const Color(0xff445756),
            onPressed: () {
              setState(() {
                user["pinned"] = !user["pinned"];
              });
            },
          ),
        )));

        return DataRow(cells: lister);
      }).toList();

  List<DataCell> getCells(List<dynamic> cells) => cells
      .map((data) => DataCell(Align(
          alignment: Alignment.centerRight, child: Text(data.toString()))))
      .toList();

  void onSort(int columnIndex, bool ascending) {
    widget.items.sort((user1, user2) => compareString(
        ascending,
        user1[headerLabel[columnIndex]].toString(),
        user2[headerLabel[columnIndex]].toString()));

    setState(() {
      sortColumnIndex = columnIndex;
      isAscending = ascending;
    });
  }

  int compareString(bool ascending, String value1, String value2) =>
      ascending ? value1.compareTo(value2) : value2.compareTo(value1);
}

extension StringExtension on String {
  String capitalize() =>
      "${this[0].toUpperCase()}${substring(1).toLowerCase()}";

  String get toTitle => split(" ").map((str) => str.capitalize()).join(" ");
}
