import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Future<Database> _initializeDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'tasks_database.db');

    return openDatabase(
      path,
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE tasks(id INTEGER PRIMARY KEY, title TEXT, completed INTEGER)",
        );
      },
      version: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Database>(
      future: _initializeDatabase(),
      builder: (BuildContext context, AsyncSnapshot<Database> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final database = snapshot.data;
          return MaterialApp(
            title: 'To-Do App',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: MyHomePage(title: 'To-Do List', database: database),
          );
        } else {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  final Database? database;

  MyHomePage({Key? key, required this.title, required this.database})
      : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> _taskList = [];

  @override
  void initState() {
    super.initState();
    _refreshTaskList();
  }

  Future<void> _addTask(String title) async {
    final Database? db = widget.database;
    await db!.insert('tasks', {'title': title, 'completed': 0});
    _refreshTaskList();
  }

  Future<void> _refreshTaskList() async {
    final Database? db = widget.database;
    final List<Map<String, dynamic>> tasks = await db!.query('tasks');
    setState(() {
      _taskList = tasks;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: ListView.builder(
          itemCount: _taskList.length,
          itemBuilder: (BuildContext context, int index) {
            final task = _taskList[index];
            return ListTile(
              title: Text(task['title']),
              trailing: Checkbox(
                value: task['completed'] == 1,
                onChanged: (value) {
                  // TODO: Handle task completion status
                },
              ),
              onLongPress: () {
                // TODO: Handle task deletion
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              final TextEditingController _textEditingController =
              TextEditingController();
              return AlertDialog(
                title: Text('Add Task'),
                content: TextField(
                  controller: _textEditingController,
                  decoration: InputDecoration(hintText: 'Enter task title'),
                ),
                actions: [
                  TextButton(
                    child: Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text('Add'),
                    onPressed: () {
                      final title = _textEditingController.text.trim();
                      if (title.isNotEmpty) {
                        _addTask(title);
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      persistentFooterButtons: [
        ElevatedButton(
          child: Text('Show Tasks'),
          onPressed: () {
            _refreshTaskList();
          },
        ),
      ],
    );
  }
}
