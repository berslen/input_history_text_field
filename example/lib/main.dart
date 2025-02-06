import 'package:flutter/material.dart';
import 'package:input_history_text_field/input_history_text_field.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sample',
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: Text("Sample"),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(50),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.light_mode, color: Colors.yellow),
                  Switch(
                    value: isDarkMode,
                    onChanged: (value) {
                      setState(() {
                        isDarkMode = value;
                      });
                    },
                  ),
                  Icon(Icons.dark_mode, color: Colors.black),
                ],
              ),

              /// sample 1
              /// - list
              InputHistoryTextField(
                historyKey: "01",
                listStyle: ListStyle.List,
                lockedItems: [
                  'Flutter',
                ],
                decoration: InputDecoration(hintText: 'List'),
              ),

              /// sample 2
              /// - list with updateHistoryItemDateTime
              InputHistoryTextField(
                historyKey: "02",
                listStyle: ListStyle.List,
                onHistoryItemSelected: (value) => print(value),
                lockedItems: [
                  'Flutter',
                ],
                promoteRecentHistoryItems: true,
                decoration: InputDecoration(
                    hintText: 'List with promoteRecentHistoryItem'),
              ),

              /// sample 3
              /// - badge
              InputHistoryTextField(
                historyKey: "03",
                listStyle: ListStyle.Badge,
                showHistoryIcon: false,
                decoration: InputDecoration(hintText: 'Badge'),
              ),

              /// sample 4
              /// - lock item
              InputHistoryTextField(
                historyKey: "04",
                listStyle: ListStyle.Badge,
                lockedItems: ['Flutter', 'Rails', 'React', 'Vue'],
                showHistoryIcon: false,
                decoration:
                    InputDecoration(hintText: 'Badge with Locked Items'),
              ),

              /// sample 5
              /// - customize
              InputHistoryTextField(
                historyKey: "05",
                limit: 3,
                enableHistory: true,
                showHistoryIcon: true,
                showDeleteIcon: true,
                decoration: InputDecoration(hintText: 'Customize list'),
                listDecoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.blueGrey
                      : Colors.grey,
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(2),
                      bottomRight: Radius.circular(2)),
                ),
                lockedItems: ['Flutter'],
                historyListItemLayoutBuilder: (controller, value, index) {
                  return InkWell(
                    onTap: () => controller.select(value.text),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    width: 5.0,
                                    color: index % 2 == 0
                                        ? Colors.red
                                        : Colors.blue,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    value.textToSingleLine,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    value.createdTimeLabel,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(context).disabledColor),
                                  ),
                                ],
                              )),
                        ),
                        if (!value.isLock)
                          IconButton(
                            color: Colors.black,
                            icon: Icon(
                              Icons.close,
                              size: 18,
                            ),
                            onPressed: () {
                              controller.remove(value);
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
