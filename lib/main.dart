import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(ToDoApp());

class ToDoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.blueGrey[50],
      ),
      home: ToDoHomePage(),
    );
  }
}

class Task {
  final String title;
  final String description;
  bool isDone;

  Task({required this.title, this.description = '', this.isDone = false});

  // Convert Task to Map (for JSON)
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'isDone': isDone,
  };

  // Convert Map to Task
  factory Task.fromJson(Map<String, dynamic> json) => Task(
    title: json['title'],
    description: json['description'],
    isDone: json['isDone'],
  );
}

class ToDoHomePage extends StatefulWidget {
  @override
  _ToDoHomePageState createState() => _ToDoHomePageState();
}

class _ToDoHomePageState extends State<ToDoHomePage> {
  List<Task> _tasks = [];
  Task? _recentlyDeletedTask;
  int? _recentlyDeletedIndex;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> taskList = _tasks.map((task) => jsonEncode(task.toJson())).toList();
    await prefs.setStringList('tasks', taskList);
  }

  void _loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? taskList = prefs.getStringList('tasks');
    if (taskList != null) {
      setState(() {
        _tasks = taskList.map((item) => Task.fromJson(jsonDecode(item))).toList();
      });
    }
  }

  void _addTask(Task task) {
    setState(() {
      _tasks.add(task);
    });
    _saveTasks();
  }

  void _toggleTask(int index) {
    setState(() {
      _tasks[index].isDone = !_tasks[index].isDone;
    });
    _saveTasks();
  }

  void _deleteTask(int index) {
    setState(() {
      _recentlyDeletedTask = _tasks[index];
      _recentlyDeletedIndex = index;
      _tasks.removeAt(index);
    });
    _saveTasks();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            if (_recentlyDeletedTask != null && _recentlyDeletedIndex != null) {
              setState(() {
                _tasks.insert(_recentlyDeletedIndex!, _recentlyDeletedTask!);
              });
              _saveTasks();
            }
          },
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(onSubmit: _addTask),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My To-Do List'),
        centerTitle: true,
      ),
      body: _tasks.isEmpty
          ? Center(
        child: Text(
          'No tasks yet. Tap + to add.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      )
          : ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) => Dismissible(
          key: Key(_tasks[index].title + index.toString()),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _deleteTask(index),
          background: Container(
            color: Colors.redAccent,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Icon(Icons.delete, color: Colors.white),
          ),
          child: TaskTile(
            task: _tasks[index],
            onToggle: () => _toggleTask(index),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showTaskDialog,
        tooltip: 'Add Task',
        child: Icon(Icons.add),
      ),
    );
  }
}

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;

  TaskTile({required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: ListTile(
        leading: Checkbox(
          value: task.isDone,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isDone ? TextDecoration.lineThrough : null,
            color: task.isDone ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: task.description.isNotEmpty ? Text(task.description) : null,
      ),
    );
  }
}

class AddTaskDialog extends StatefulWidget {
  final Function(Task) onSubmit;

  AddTaskDialog({required this.onSubmit});

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  void _submit() {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    if (title.isNotEmpty) {
      widget.onSubmit(Task(title: title, description: description));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('New Task'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            decoration: InputDecoration(labelText: 'Task Title'),
            autofocus: true,
          ),
          SizedBox(height: 8),
          TextField(
            controller: descriptionController,
            decoration: InputDecoration(labelText: 'Details (optional)'),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text('Add'),
        ),
      ],
    );
  }
}
