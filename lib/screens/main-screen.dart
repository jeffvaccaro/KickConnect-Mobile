import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:mobile/config.dart';
import 'attendance-screen.dart'; // Import the AttendanceScreen

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

class MainScreen extends StatefulWidget {
  final Map<String, dynamic> apiResponse;

  MainScreen({required this.apiResponse});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late String name;
  late String role;
  late int accountId;
  late String token;
  List<dynamic> locations = [];
  List<dynamic> schedule = [];
  dynamic selectedLocation;
  final List<GlobalKey> _cardKeys = [];
  double _totalCardWidth = 0;

  @override
  void initState() {
    super.initState();
    name = widget.apiResponse['name'] ?? 'No Name';
    role = widget.apiResponse['role'] ?? 'No Role';
    accountId = widget.apiResponse['accountId'] ?? 0;
    token = widget.apiResponse['token'] ?? '';
    print(
      'Debug: Name - $name, Role - $role, AccountId - $accountId, Token - $token',
    );
    fetchLocations();
  }

  Future<void> fetchLocations() async {
    print(
      'Debug: Fetching locations for accountId $accountId with token $token',
    );
    final response = await http.get(
      Uri.parse(
        '${Config.baseUrl}/location/get-locations-by-acct-id/$accountId',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        locations = json.decode(response.body);
      });
      print('Debug: Fetched locations - $locations');
    } else {
      print(
        'Debug: Failed to load locations, status code: ${response.statusCode}',
      );
      throw Exception('Failed to load locations');
    }
  }

  Future<void> fetchSchedule(int locationId) async {
    print(
      'Debug: Fetching schedule for locationId $locationId with accountId $accountId',
    );
    final response = await http.get(
      Uri.parse(
        '${Config.baseUrl}/schedule/get-location-class-schedule/$locationId/$accountId',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        schedule = json.decode(response.body);
        _cardKeys.clear();
        _cardKeys.addAll(
          List.generate(schedule.length, (index) => GlobalKey()),
        );
        _totalCardWidth = 0;
      });
      print('Debug: Fetched schedule - $schedule');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        double calculatedTotalWidth = 0;
        for (int i = 0; i < _cardKeys.length; i++) {
          final key = _cardKeys[i];
          final RenderBox? box =
              key.currentContext?.findRenderObject() as RenderBox?;
          if (box != null) {
            final width = box.size.width;
            print('Width of card $i: $width');
            calculatedTotalWidth += width;
          }
        }
        setState(() {
          _totalCardWidth = calculatedTotalWidth;
        });
        print('Total Card Width: $_totalCardWidth');

        double screenWidth = MediaQuery.of(context).size.width;
        print('Screen Width: $screenWidth');
        if (_totalCardWidth > screenWidth) {
          print('Scrolling SHOULD be enabled.');
        } else {
          print('Scrolling is NOT needed.');
        }
      });
    } else {
      print(
        'Debug: Failed to load schedule, status code: ${response.statusCode}',
      );
      throw Exception('Failed to load schedule');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Debug: Building MainScreen');
    return Scaffold(
      appBar: AppBar(title: Text('Main Screen')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name: $name',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Role: $role',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            DropdownButton<dynamic>(
              hint: Text('Select Location'),
              value: selectedLocation,
              onChanged: (newValue) {
                print('Debug: Selected Location - $newValue');
                setState(() {
                  selectedLocation = newValue;
                  fetchSchedule(selectedLocation['locationId']);
                });
              },
              items:
                  locations.map((location) {
                    print('Debug: Location - ${location['locationName']}');
                    return DropdownMenuItem<dynamic>(
                      value: location,
                      child: Text(
                        location['locationName'] ?? 'No Location Name',
                      ),
                    );
                  }).toList(),
            ),
            SizedBox(height: 20),
            schedule.isNotEmpty
                ? SizedBox(
                  height: 250,
                  child: ScrollConfiguration(
                    behavior: MyCustomScrollBehavior(),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      physics: BouncingScrollPhysics(),
                      itemCount: schedule.length,
                      itemBuilder: (context, index) {
                        final item = schedule[index];
                        return Container(
                          key: _cardKeys[index],
                          margin: EdgeInsets.only(right: 10),
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Class Name: ${item['eventName'] ?? 'No Class Name'}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Class Description: ${item['eventDescription'] ?? 'No Description'}',
                                  ),
                                  SizedBox(height: 10),
                                  Text('Day: ${item['dayValue'] ?? ''}'),
                                  SizedBox(height: 10),
                                  Text('Time: ${item['startTime'] ?? ''}'),
                                  SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
                : Text('No classes available.'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AttendanceScreen()),
                );
              },
              child: Text('Scan QR Code'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(
    MaterialApp(
      scrollBehavior: MyCustomScrollBehavior(),
      home: MainScreen(apiResponse: {/* your apiResponse */}),
    ),
  );
}
