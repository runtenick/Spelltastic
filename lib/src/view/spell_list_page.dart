import 'package:code/src/model/spell_set.dart';

import '../model/account_manager.dart';
import '../model/character_class.dart';
import '../model/spell.dart';
import './spell__search_delegate_page.dart';
import './spell_detail_page.dart';
import '../data/sqlite_data_strategy.dart';
import 'package:flutter/material.dart';
import '../data/dbhelper.dart';
import 'dart:io' show Platform;

import '../model/character.dart';

List<Spell> spells_list = [];

//* Option de tri
enum OrderOption {
  asc,
  desc,
  Lvlasc,
  Lvldesc,
}

OrderOption currentOrder = OrderOption.asc;

class SpellListPage extends StatefulWidget {
  const SpellListPage({super.key, required this.character});
  final Character character;

  @override
  State<SpellListPage> createState() => _SpellListPage(character: character);
}

class _SpellListPage extends State<SpellListPage> {
  _SpellListPage({required this.character});
  Character character;

  @override
  void initState() {
    character = widget.character;
    super.initState();
    getData();
  }

  //* Chargement des données
  void getData() async {
    List<Spell> spells;
    if (Platform.isAndroid) {
      var dbHelper = DbHelper();
      spells = await dbHelper.loadSpells();
    } else {
      var data = SQLiteDataStrategy();
      spells = await data.loadSpells();
    }

    setState(() {
      spells_list = spells
          .where((spell) =>
              spell.GetLevelByClass(character.characterClass) != null)
          .toList();
      /* TO REMOVE */
      AccountManager()
          .characters[0]
          .sets
          .add(SpellSet("mySet", spells: spells_list.sublist(0, 20)));
    });
  }

  void useless() {
    print("useless");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste de sorts'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              //* Appel de la fonction de recherche
              showSearch(
                  context: context,
                  delegate: SpellSearchDelegate(spells_list, useless));
            },
          ),
          PopupMenuButton<OrderOption>(
            //* Menu d'option de tri
            onSelected: (value) {
              setState(() {
                switch (value) {
                  case OrderOption.asc:
                    {
                      //* tri ascendant
                      spells_list.sort((spell1, spell2) =>
                          spell1.name.compareTo(spell2.name));
                    }
                    break;

                  case OrderOption.desc:
                    {
                      //* tri descendant
                      spells_list.sort((spell1, spell2) =>
                          spell2.name.compareTo(spell1.name));
                    }
                    break;

                  case OrderOption.Lvlasc:
                    {
                      //* tri par niveaux ascendant
                      spells_list.sort((spell1, spell2) =>
                          (spell1.GetLevelByClass(character.characterClass) ??
                                  0)
                              .compareTo(spell2.GetLevelByClass(
                                      character.characterClass) ??
                                  0));
                    }
                    break;

                  case OrderOption.Lvldesc:
                    {
                      //* tri par niveaux descendant
                      spells_list.sort((spell1, spell2) =>
                          (spell2.GetLevelByClass(character.characterClass) ??
                                  0)
                              .compareTo(spell1.GetLevelByClass(
                                      character.characterClass) ??
                                  0));
                    }
                    break;
                }
              });
            },
            icon: const Icon(Icons.filter_alt),
            itemBuilder: (context) => [
              //* Option du menu de tri
              const PopupMenuItem(
                value: OrderOption.asc,
                child: Text('Croissant'),
              ),
              const PopupMenuItem(
                value: OrderOption.desc,
                child: Text('Décroissant'),
              ),
              const PopupMenuItem(
                value: OrderOption.Lvlasc,
                child: Text('Level Croissant'),
              ),
              const PopupMenuItem(
                value: OrderOption.Lvldesc,
                child: Text('Level Décroissant'),
              ),
            ],
          ),
        ],
      ),
      body: ListView.builder(
        itemExtent: 50,
        cacheExtent: 2,
        itemCount: spells_list.length,
        itemBuilder: (context, index) {
          //Coloration des lignes de la liste
          Color backgroundColor = Colors.white;
          if (spells_list[index]
                  .GetLevelByClass(character.characterClass)
                  ?.isEven ??
              false) {
            if (currentOrder == OrderOption.Lvlasc ||
                currentOrder == OrderOption.Lvldesc) {
              backgroundColor = const Color.fromARGB(255, 209, 214, 216);
            }
          }
          return ListTile(
            //Structure de chaque ligne (=> ListTile)
            tileColor: backgroundColor,
            title: RichText(
              //? Version avec le maximum description puis ...
              maxLines: 1,
              overflow: TextOverflow.ellipsis,

              text: TextSpan(
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: Theme.of(context).textTheme.titleLarge!.fontSize,
                    fontFamily:
                        Theme.of(context).textTheme.titleLarge!.fontFamily,
                  ),
                  children: <TextSpan>[
                    //? Version avec le maximum description puis ...
                    TextSpan(
                      text:
                          "${spells_list[index].name} ${spells_list[index].GetLevelByClass(character.characterClass)}",
                    ),
                    TextSpan(
                        text: '     ${spells_list[index].description}',
                        style: Theme.of(context).textTheme.titleSmall)

                    //? Option avec les 7 premiers mots
                    //TextSpan(text:'     ${spells_list[index].description.split(' ').take(7).join(' ')}...', style: Theme.of(context).textTheme.titleSmall)

                    //? Option avec les 35 premiers caractères ?
                    //TextSpan(text:'${spells_list[index].description.substring(0,35)}...', style: Theme.of(context).textTheme.titleSmall)
                  ]),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SpellDetailsPage(spell: spells_list[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
