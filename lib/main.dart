import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'boxes.dart';
import 'task.dart';

const Color kBackground = Color.fromARGB(255, 7, 7, 7);
const Color kCard = Color.fromARGB(255, 42, 46, 53);
const Color kAccent = Color(0xFF4FC3F7);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  taskBox = await Hive.openBox<Task>('taskBox');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finals Lab 2',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 18, 18, 19),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: kBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: kCard
        ),
      ),
      home: const HomePage(),
    );
  }
}

String formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _addTask(BuildContext context) async {
    final result = await showDialog<Task>(
      context: context,
      builder: (_) => const TaskDialog(),
    );
    if (result != null) {
      await taskBox.add(result);
    }
  }

  Future<void> _editTask(BuildContext context, dynamic key, Task task) async {
    final result = await showDialog<Task>(
      context: context,
      builder: (_) => TaskDialog(existing: task),
    );
    if (result != null) {
      await taskBox.put(key, result);
    }
  }

  Future<void> _deleteTask(BuildContext context, dynamic key, Task task) async {
    await taskBox.delete(key);  
  }

  @override 
    Widget build(BuildContext context) {
      return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
        
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addTask(context),
        icon: const Icon(Icons.add),  
        label: const Text('Add Task'),
      ),
      body: ValueListenableBuilder<Box<Task>>(
        valueListenable: taskBox.listenable(),
        builder: (context, box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Text(  
                'No tasks yet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            );
          }

          final keys = box.keys.toList()
            ..sort((a, b) => box.get(a)!.date.compareTo(box.get(b)!.date));

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final key = keys[index];
              final task = box.get(key)!;

              return Dismissible(
                key: ValueKey(key),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.only(right: 20),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _deleteTask(context, key, task),
                child: Card(
                  color: kCard,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                   title: Text(
                      task.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(formatDate(task.date)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit, color: Colors.white70),
                          onPressed: () => _editTask(context, key, task),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deleteTask(context, key, task),
                        ),
                      ],
                    ),
                    onTap: () => _editTask(context, key, task),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class TaskDialog extends StatefulWidget {
  const TaskDialog({super.key, this.existing});

  final Task? existing;

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late DateTime _selectedDate;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _selectedDate = widget.existing?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(
        context,
        Task(title: _titleController.text.trim(), date: _selectedDate),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kCard,
      title: Text(_isEditing ? 'Edit Task' : 'New Task'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Title',
                hintText: 'Task Title',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Task title cannot be empty';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(formatDate(_selectedDate)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(_isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
