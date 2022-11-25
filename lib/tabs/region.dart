import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genome_2133/views/variant-view.dart';
import 'package:genome_2133/views/variant-card.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import '../home.dart';

class Window extends StatefulWidget {
  final Function updateParent;
  final String title;
  final Widget body;

  const Window({Key? key, required this.updateParent, required this.title, required this.body}) : super(key: key);

  @override
  State<Window> createState() => _Window();

  Offset getPosition() => const Offset(0, 0);

  void updatePosition(Offset newPosition) {}
}

class _Window extends State<Window> {
  bool isClosed = false;

  // turned off random placement so that it sits to right
  Offset position = Offset(
      ((window.physicalSize / window.devicePixelRatio).width -
          (window.physicalSize / window.devicePixelRatio).width / 3),
      ((window.physicalSize / window.devicePixelRatio).height -
          (window.physicalSize / window.devicePixelRatio).height / 2 - 225));

  getPosition() => position;

  void updatePosition(Offset newPosition) =>
      setState(() => position = newPosition);

  @override
  Widget build(BuildContext context) {
    if (isClosed) return Container();

    void riseStack() {
      // Change stack function
      if (widget == windows.last) return;

      // TODO: fix position swap bug
      /*windows.remove(widget);
      windows.add(widget);

      widget.updateParent();*/
    }

    Widget content = SizedBox(
      height: MediaQuery.of(context).size.height / 2,
      width: MediaQuery.of(context).size.height / 3,
      child: GestureDetector(
        onTap: () {
          riseStack();
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              Container(
                height: 40,
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                          onTap: () {
                            // TODO: add cleanup to home array
                            setState(() {
                              // need to handle cases where multiple cards?
                              if (widget.body is RegionCard) {
                                (widget.body as RegionCard).centerMap();
                              }
                              isClosed = true;
                            });
                          },
                        )
                      )
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: widget.body,
                ),
              )
            ],
          ),
        ),
      ),
    );

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Draggable(
          maxSimultaneousDrags: 1,
          feedback: Material(type: MaterialType.transparency, child: content),
          childWhenDragging: Container(),
          onDragEnd: (details) {
            updatePosition(details.offset);
            riseStack();
          },
          child: content),
    );
  }
}

class Region extends StatefulWidget {
  final Function updateParent;
  // is this necessary?
  final GoogleMapController mapController;

  const Region({Key? key, required this.updateParent, required this.mapController}) : super(key: key);

  @override
  State<Region> createState() => _Region();
}

class _Region extends State<Region> {
  TextEditingController search = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: const Center(child: Text("Select Region")),
        content: SizedBox(
          height: MediaQuery.of(context).size.height / 2,
          width: MediaQuery.of(context).size.width / 4,
          child: FutureBuilder(
              future: rootBundle.loadString("assets/data.json"),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (!snapshot.hasData) return Container();
                List countries = json.decode(snapshot.data!)["Countries"];
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                      child: TextField(
                          controller: search,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.search),
                            labelText: 'Search',
                          ),
                          onChanged: (text) {
                            setState(() {});
                          }),
                    ),
                    Flexible(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          for (int index = 0; index < countries.length; index++)
                            if (isValid(countries[index]["country"], search.text))
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: ElevatedButton(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              countries[index]["country"],
                                              style: TextStyle(
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width /
                                                          80,
                                                  color: Colors.black),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right)
                                    ],
                                  ),
                                  onPressed: () {
                                    RegionCard selectedCountry = RegionCard(
                                      country: countries[index],
                                      mapController: widget.mapController,
                                      updateParent: widget.updateParent,
                                    );
                                    Navigator.pop(context, [
                                      Window(
                                        updateParent: widget.updateParent,
                                        title: selectedCountry.toString(),
                                        body: selectedCountry,
                                      )
                                    ]);
                                  },
                                ),
                              )
                        ],
                      ),
                    ),
                  ],
                );
              }),
        ));
  }

  bool isValid(String name, String search) {
    // Search algo
    search = search.toLowerCase();
    name = name.toLowerCase();
    for (var element in search.runes) {
      if (!name.contains(String.fromCharCode(element))) return false;
      if (String.fromCharCode(element).allMatches(search).length >
          String.fromCharCode(element).allMatches(name).length) return false;
    }
    return true;
  }
}

class RegionCard extends StatefulWidget {
  final Map country;
  final GoogleMapController mapController;
  final LatLng _initMapCenter = const LatLng(20, 0);
  final Function updateParent;

  const RegionCard(
      {Key? key, required this.country, required this.mapController, required this.updateParent})
      : super(key: key);

  @override
  State<RegionCard> createState() => _RegionCard();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return country["country"];
  }

  void centerMap () {
    mapController.animateCamera(CameraUpdate.newLatLngZoom(
        _initMapCenter, 3));
  }
}

class _RegionCard extends State<RegionCard> {
  _updateMap() async {
    widget.mapController.animateCamera(CameraUpdate.newLatLngZoom(
      LatLng(widget.country["latitude"],
          widget.country["longitude"] + (-10.0 * widget.country["zoom"] + 60)), widget.country["zoom"]));
  }

  @override
  void initState() {
    super.initState();
    // is this the safest way to call async method like this?
    _updateMap();
  }

  Future<Map<String, dynamic>> getVariantsRegion ({String region = "", String country = "", String state = "", int count = 10}) async {
    var headers = {
      'Content-Type': 'text/plain'
    };
    var request = http.Request('POST', Uri.parse('https://genome2133functions.azurewebsites.net/api/GetAccessionsByRegion?code=e58u_e3ljQhe8gX3lElCZ79Ep3DOGcoiA54YzkamEEeDAzFuEobmzQ=='));
    request.body = '''{''' +
      (region.isNotEmpty ? '''\n    "region": "''' + region + '''",''' : "") +
      (country.isNotEmpty ? '''\n    "country": "''' + country + '''",''' : "") +
      (state.isNotEmpty ? '''\n    "state": "''' + state + '''",''' : "") + '''
      \n    "count": ''' + (count < 0 ? '''"all"''' : count.toString()) + '''
      \n}''';
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      Map<String, dynamic> map = Map<String, dynamic>.from(jsonDecode(await response.stream.bytesToString()));
      return map;
    }
    return {"error" : response.reasonPhrase};
  }

  Future<Map<String, dynamic>> getCountryInfo (String country) async {
    var request = http.Request('GET', Uri.parse('https://restcountries.com/v3.1/name/' + country));

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      String responseDecoded = await response.stream.bytesToString();
      Map<String, dynamic> map = Map<String, dynamic>.from(jsonDecode(responseDecoded).first);
      return map;
    }
    return {"error" : response.reasonPhrase};
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      child: CustomScrollView(
        shrinkWrap: true,
        slivers: [
          SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Variants:",
                        style: TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                  FutureBuilder<Map<String, dynamic>>(
                      future: getVariantsRegion(country: widget.country["country"]),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Column(
                            children: [
                              SizedBox(
                                height: 150,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 18),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    style: TextButton.styleFrom(
                                      textStyle: const TextStyle(fontSize: 20),
                                    ),
                                    onPressed: () {  },
                                    child: const Text(
                                      "Further Info",
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                        if (snapshot.data!.containsKey("error")) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(child: Text(snapshot.data!["error"])),
                          );
                        }

                        return Column(
                          children: [
                            SizedBox(
                              height: 150,
                              child: Padding(
                                  padding: const EdgeInsets.only(left: 16, right: 16),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Wrap(
                                      children: [
                                        for (Map variant in snapshot.data!["accessions"])
                                          Padding(
                                            padding: const EdgeInsets.all(1.0),
                                            child: TextButton(
                                              style: TextButton.styleFrom(
                                                  textStyle:
                                                  const TextStyle(fontSize: 13)),
                                              onPressed: () {
                                                VariantCard selectedVariant = VariantCard(
                                                  variant: variant,
                                                );
                                                windows.add(Window(
                                                  title: selectedVariant.toString(),
                                                  body: selectedVariant,
                                                  updateParent: widget.updateParent,
                                                ));
                                                widget.updateParent();
                                              },
                                              child: Text(
                                                variant["accession"]!,
                                                style: TextStyle(
                                                  color: Theme.of(context).scaffoldBackgroundColor,
                                                  decoration:
                                                  TextDecoration.underline,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  )),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 18),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  style: TextButton.styleFrom(
                                    textStyle: const TextStyle(fontSize: 20),
                                  ),
                                  onPressed: () async {
                                    List<Map<String, dynamic>> regionView = List<Map<String, dynamic>>.from((await getVariantsRegion(country: widget.country["country"], count: -1))["accessions"]);
                                    for (Map<String, dynamic> variant in regionView) {
                                      variant["selected"] = false;
                                      variant["pinned"] = false;
                                    }

                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => VariantView(
                                              country: widget.country,
                                              variants: regionView,
                                              updateParent: widget.updateParent,
                                            )));
                                  },
                                  child: const Text(
                                    "Further Info",
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Country Info:",
                        style: TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                  FutureBuilder<Map<String, dynamic>>(
                      future: getCountryInfo(widget.country["country"]),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Container();
                        }

                        return Column(
                          children: [ // unMember
                            Align(
                              alignment: Alignment.centerLeft,
                              child: RichText(
                                text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: <TextSpan>[
                                    TextSpan(text: snapshot.data!["continents"].length == 1 ? "Continent: " : "Continents: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    for (String language in snapshot.data!["continents"])
                                      TextSpan(text:
                                      (language == snapshot.data!["continents"].last && snapshot.data!["continents"].length > 1 ? "and " : "") +
                                          language +
                                          (language == snapshot.data!["continents"].last ? "" : snapshot.data!["continents"].length != 2 ? ", " : " ")),
                                  ],
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: RichText(
                                text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: <TextSpan>[
                                    TextSpan(text: snapshot.data!.containsKey("borders") && snapshot.data!["borders"].length == 1 ? "Neighbor: " : "Neighbors: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    if (!snapshot.data!.containsKey("borders"))
                                      const TextSpan(text: "None"),
                                    if (snapshot.data!.containsKey("borders"))
                                      for (String language in snapshot.data!["borders"])
                                        TextSpan(text:
                                        (language == snapshot.data!["borders"].last && snapshot.data!["borders"].length > 1 ? "and " : "") +
                                            language +
                                            (language == snapshot.data!["borders"].last ? "" : snapshot.data!["borders"].length != 2 ? ", " : " ")),
                                  ],
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: RichText(
                                text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: <TextSpan>[
                                    TextSpan(text: snapshot.data!["capital"].length == 1 ? "Capital: " : "Capitals: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    for (String capital in snapshot.data!["capital"])
                                      TextSpan(text:
                                      (capital == snapshot.data!["capital"].last && snapshot.data!["capital"].length > 1 ? "and " : "") +
                                          capital +
                                          (capital == snapshot.data!["capital"].last ? "" : snapshot.data!["capital"].length != 2 ? ", " : " ")),
                                  ],
                                ),
                              ),
                            ),
                            for (String key in {"area", "population"})
                              Align(
                                alignment: Alignment.centerLeft,
                                child: RichText(
                                  text: TextSpan(
                                    style: DefaultTextStyle.of(context).style,
                                    children: <TextSpan>[
                                      TextSpan(text: key.toTitleCase() + ": ", style: const TextStyle(fontWeight: FontWeight.bold)),
                                      TextSpan(text: snapshot.data![key].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')),
                                    ],
                                  ),
                                ),
                              ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: RichText(
                                text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: <TextSpan>[
                                    const TextSpan(text: "Population Density: ", style: TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: (snapshot.data!["population"] / snapshot.data!["area"])
                                        .toStringAsFixed(2)
                                        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')),
                                  ],
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: RichText(
                                text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: <TextSpan>[
                                    const TextSpan(text: "United Nations: ", style: TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: snapshot.data!["unMember"] ? "Member" : "Non-Member"),
                                  ],
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: RichText(
                                text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: <TextSpan>[
                                    TextSpan(text: snapshot.data!["languages"].values.length == 1 ? "Language: " : "Languages: ", style: TextStyle(fontWeight: FontWeight.bold)),
                                    for (String language in snapshot.data!["languages"].values)
                                      TextSpan(text:
                                      (language == snapshot.data!["languages"].values.last && snapshot.data!["languages"].values.length > 1 ? "and " : "") +
                                          language +
                                          (language == snapshot.data!["languages"].values.last ? "" : snapshot.data!["languages"].values.length != 2 ? ", " : " ")),
                                  ],
                                ),
                              ),
                            ),
                            for (String key in {"landlocked", "independent", "flag"})
                              Align(
                                alignment: Alignment.centerLeft,
                                child: RichText(
                                  text: TextSpan(
                                    style: DefaultTextStyle.of(context).style,
                                    children: <TextSpan>[
                                      TextSpan(text: key.toTitleCase() + ": ", style: const TextStyle(fontWeight: FontWeight.bold)),
                                      TextSpan(text: snapshot.data![key].toString().toTitleCase()),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      }
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 18),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Future Variants",
                        style: TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: 18),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                          onPressed: () {},
                          child: const Text(
                              "Predict",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black)
                          )
                      ),
                    ),
                  ),
                  const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                            "     This button is \n currently disabled",
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)
                        ),
                      )
                  )
                ],
              ),
          )
        ],
      )
    );
  }
}

extension StringCasingExtension on String {
  String toCapitalized() => length > 0 ?'${this[0].toUpperCase()}${substring(1).toLowerCase()}':'';
  String toTitleCase() => replaceAll(RegExp(' +'), ' ').split(' ').map((str) => str.toCapitalized()).join(' ');
}
