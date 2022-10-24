import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static const baseUrl = 'chatflutter-36298-default-rtdb.firebaseio.com';
  final toDoController = TextEditingController();

  List _toDoList = [];
  final LocalStorage storage = new LocalStorage('todo_app');

  Map<String, dynamic> _lastRemoved = Map();
  int _lastRemovedPos = 0;

  @override
  void initState() {
    super.initState();
    _readData();
  }

  void _addToDo() {
    setState(()  {
      Map<String, dynamic> newToDo = {};
      newToDo["title"] = toDoController.text;
      toDoController.text = "";
      newToDo["ok"] = false;
      var id = _toDoList.length+1;
      newToDo["id"] = id;
      _toDoList.add(newToDo);
      saveFirebase(newToDo);
      _saveData();
    });
  }

  Future<Null> _refresh() async{
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a,b){
        if(a["ok"] && a["ok"]) return 1;
        else if (!a["ok"]&&b["ok"])  return -1;
        else return 0;
      });
      _saveData();
    });
    return null;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Task List"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: toDoController,
                    decoration: InputDecoration(
                      labelText: "Nova Tarefa",
                      labelStyle: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addToDo,
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10),
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem),
              onRefresh: _refresh ,
            )
          ),
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      background: Container(
        color: Colors.red,
        child: const Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (value) {
          setState(() {
            _toDoList[index]["ok"] = value;
            updateFirebase(_toDoList[index]);
            _saveData();
            dynamic data = storage.getItem('todos');
            if (data != null){
              List<dynamic> retorno = jsonDecode(data);
              _toDoList = [];
              print(retorno);
              retorno.forEach((data) {
                _toDoList.add({'title': data['title'], 'ok': data['ok']});
              });
            }
            saveFirebase(_toDoList);
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          var url = Uri.https(baseUrl,'/task.json');
          _lastRemoved = Map.from(_toDoList[index]);
          http.delete(url,body:json.encode(_toDoList));
          _lastRemovedPos = index;
          _toDoList.removeAt(index);
          _saveData();
          http.post(url,body: json.encode(_toDoList));

          final snack = SnackBar(
            content: Text("Tarefa ${_lastRemoved["title"]} removida !"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _toDoList.insert(_lastRemovedPos, _lastRemoved);
                    _saveData();
                  });
                }),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

   saveFirebase(newToDo) {
    var url = Uri.https(baseUrl,'/task.json');
    final response = http.post(url,
        body: json.encode(newToDo));
//    final id = json.decode(response.body)['name'];
    print('s;');
  }

  void updateFirebase(newToDo)  {
    var url = Uri.https(baseUrl,'/task/.json');
    http.delete(url);
  }


  Future _getFile() async {
    _toDoList = storage.getItem('todos');
  }

  Future _saveData() async {
    String data = json.encode(_toDoList);
    return storage.setItem('todos', data);
  }

  Future _readData() async {
    dynamic data = storage.getItem('todos');
    if (data == null) return [];
    List<dynamic> retorno = jsonDecode(data);
    _toDoList = [];
    retorno.forEach((data) {
      _toDoList.add({'title': data['title'], 'ok': data['ok']});
    });
    return _toDoList;
  }
}
