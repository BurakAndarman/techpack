import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:techpack/authentication/auth.dart';
import 'package:gradient_borders/gradient_borders.dart';
import 'package:html/dom.dart' as dom;
import 'package:techpack/pages/categories.dart';
import 'package:http/http.dart' as http;
import 'package:techpack/pages/pastBaskets.dart';
import '../models/product_model.dart';
import 'dart:math';

class Mainpage extends StatefulWidget {
  final User? user = Auth().currentUser;

  Future<void> signOut() async {
    await Auth().signOut();
  }

  @override
  _MainpageState createState() => _MainpageState();
}

class _MainpageState extends State<Mainpage> {
  bool isSearching = false;

  String queryBuilder(String query, String vendor) {
    String url;

    if (vendor == "teknosa") {
      url = "https://www.teknosa.com/arama/?s=$query";
    } else if (vendor == "itopya") {
      url = "https://www.itopya.com/AramaSonuclari?text=$query";
    } /*else if (vendor == "media markt") {
      url = "https://www.akakce.com/magaza/mediamarkt.html?pq=$query";
    } */
    else {
      url = "https://www.vatanbilgisayar.com/arama/$query/";
    }

    return url;
  }

  List<ProductModel> scraper(String vendor, http.Response response) {
    List<String> titles = [];
    List<String> prices = [];
    List<String> images = [];
    Random rnd = Random();
    List<ProductModel> searchedProducts = [];
    dom.Document html = dom.Document.html(response.body);

    if (vendor == "teknosa" &&
        html.querySelectorAll('#product-item > a.prd-link').isNotEmpty) {
      titles = html
          .querySelectorAll('#product-item > a.prd-link')
          .take(4)
          .map((e) => e.attributes['title']!)
          .toList();

      prices = html
          .querySelectorAll('#product-item')
          .take(4)
          .map((e) => e.attributes['data-product-price']!)
          .toList();

      images = html
          .querySelectorAll(
              '#product-item > div > div.prd-media > figure > img')
          .take(4)
          .map((e) => e.attributes['data-srcset']!)
          .toList();
    } else if (vendor == "vatan bilgisayar" &&
        html
            .querySelectorAll(
                "div.product-list__content > a > div.product-list__product-name > h3")
            .isNotEmpty) {
      titles = html
          .querySelectorAll(
              "div.product-list__content > a > div.product-list__product-name > h3")
          .take(4)
          .map((e) => e.innerHtml.trim())
          .toList();

      prices = html
          .querySelectorAll(
              "div.product-list__content > div.product-list__cost > span.product-list__price")
          .take(4)
          .map((e) {
        String price = e.innerHtml.trim();
        String formattedPrice = price.replaceAll(".", "");
        return formattedPrice;
      }).toList();

      images = html
          .querySelectorAll(
              "div.product-list__image-safe > a > div:nth-child(1) > img")
          .take(4)
          .map((e) => e.attributes["data-src"]!)
          .toList();
    } else if (vendor == "itopya" &&
        html
            .querySelectorAll(
                "#productList > div.product > div.product-body > a")
            .isNotEmpty) {
      titles = html
          .querySelectorAll("#productList > div.product > div.product-body > a")
          .take(4)
          .map((e) => e.innerHtml.trim())
          .toList();

      prices = html
          .querySelectorAll(
              "#productList > div.product > div.product-footer > div.price > strong")
          .take(4)
          .map((e) {
        String price = e.innerHtml.trim();
        String formattedPrice = price.substring(0, price.indexOf(","));
        String formattedPrice2 = formattedPrice.replaceAll(".", "");
        return formattedPrice2;
      }).toList();

      images = html
          .querySelectorAll(
              "#productList > div.product > div.product-header > a.image > img")
          .take(4)
          .map((e) => e.attributes["data-src"]!)
          .toList();
    } /*
    else if (vendor == "media markt" && html.querySelectorAll("#MSL > li > a > span > h3.pn_v8").isNotEmpty) {
      titles = html
          .querySelectorAll(
              "#MSL > li > a > span > h3.pn_v8")
          .take(4)
          .map((e) => e.innerHtml.trim())
          .toList();

      prices = html
          .querySelectorAll(
              "#MSL > li > a > span.w_v8 > span.pb_v8 > span.pt_v8")
          .take(4)
          .map((e) {
            String price = e.text.trim();
            String formattedPrice = price.substring(0, price.indexOf(",")).replaceAll(".", "");
            return formattedPrice;
          }).toList();

      images = html
          .querySelectorAll(
              "#MSL > li > a > img")
          .take(4)
          .map((e) => e.attributes["src"]!)
          .toList();
    }
    */

    for (int i = 0; i < titles.length; i++) {
      searchedProducts.add(ProductModel(
          title: titles[i],
          category: "search",
          price: double.parse(prices[i]),
          vendor: vendor,
          id: rnd.nextInt(10000),
          image: images[i]));
    }

    return searchedProducts;
  }

  Future<List<ProductModel>> extractData(String query, String vendor) async {
    List<ProductModel> products = [];
    final response = await http.get(Uri.parse(queryBuilder(query, vendor)));

    if (response.statusCode == 200) {
      products = scraper(vendor, response);
      return products;
    }

    print('Error: ${response.statusCode}.');
    return products;
  }

  Future<List<ProductModel>> search(String value) async {
    List<ProductModel> allResults = [];

    setState(() {
      isSearching = true;
    });

    final teknosaResults = await extractData(value, "teknosa");
    final itopyaResults = await extractData(value, "itopya");
    final vatanResults = await extractData(value, "vatan bilgisayar");
    final mmResults = await extractData(value, "media markt");

    allResults.addAll(teknosaResults);
    allResults.addAll(itopyaResults);
    allResults.addAll(vatanResults);
    allResults.addAll(mmResults);

    setState(() {
      isSearching = false;
    });

    return allResults;
  }

  @override
  Widget build(BuildContext context) {
    return isSearching
        ? Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 15),
                  Text("We Are Searching",
                      style: TextStyle(color: Colors.purple, fontSize: 18))
                ],
              ),
            ))
        : Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 70),
                    Text("Logged in as ${widget.user?.email ?? 'User email'}"),
                    const SizedBox(height: 30,),
                    Image.asset('assets/logo.jpg'),
                    Container(
                      width: 300.0,
                      child: TextField(
                        onSubmitted: (value) async {
                          List<ProductModel> results = await search(value);

                          if (results.isEmpty) {
                            final error = SnackBar(
                              content: const Text('We couldn\'t find any results 🙁'),
                              action: SnackBarAction(
                                label: 'Kapat',
                                onPressed: () {},
                              ),
                            );

                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(error);
                          } else {
                            // ignore: use_build_context_synchronously
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Categories(
                                      content: "searched products",
                                      searchedProducts: results)),
                            );
                          }
                        },
                        decoration: const InputDecoration(
                          suffixIcon: Icon(Icons.search),
                          labelStyle:
                              TextStyle(color: Colors.grey, fontSize: 16.0),
                          border: GradientOutlineInputBorder(
                              width: 3.0,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(30)),
                              gradient: LinearGradient(colors: [
                                Colors.deepPurpleAccent,
                                Colors.purple
                              ])),
                        ),
                      ),
                    ),
                    Center(
                        child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        TextButton.icon(
                            onPressed: widget.signOut,
                            icon: const Icon(Icons.logout_outlined,
                                color: Colors.purple),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              textStyle: const TextStyle(
                                  fontSize: 12, fontStyle: FontStyle.normal),
                              shadowColor: Colors.purple,
                            ),
                            label: const Text("Logout",
                                style: TextStyle(color: Colors.purple))),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const pastBaskets()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            textStyle: const TextStyle(
                                fontSize: 12, fontStyle: FontStyle.normal),
                            shadowColor: Colors.purple,
                          ),
                          label: const Text('Past Baskets',
                              style: TextStyle(color: Colors.purple)),
                          icon: const Icon(
                            Icons.shopping_basket_outlined,
                            color: Colors.purple,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Categories(
                                        content: "categories",
                                        searchedProducts: [],
                                      )),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            textStyle: const TextStyle(
                                fontSize: 12, fontStyle: FontStyle.normal),
                            shadowColor: Colors.purple,
                          ),
                          label: const Text('Categories',
                              style: TextStyle(color: Colors.purple)),
                          icon: const Icon(
                            Icons.dehaze,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    )),
                  ],
                ),
              ),
            ),
          );
  }
}
