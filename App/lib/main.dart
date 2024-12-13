import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Map weekDict = {
  1: '월', // Monday
  2: '화', // Tuesday
  3: '수', // Wednesday
  4: '목', // Thursday
  5: '금', // Friday
  6: '토', // Saturday
  7: '일', // Sunday
};

void main() { 
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return MaterialApp(
      title: 'Flutter Demo',
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
        
      ),
      
      darkTheme: ThemeData.dark(),
      home: const MyHomePage(),
    );
  }
}

class AppState extends ChangeNotifier {
  bool isDarkMode = false;
  bool alarmEnabled = false;

  String _selectedAlarmSound = '기본 알람음';
  double _volume = 0.5; 
  int _selectedAlarmStrength = 1;

  String get selectedAlarmSound => _selectedAlarmSound;
  int get selectedAlarmStrength => _selectedAlarmStrength;
  double get volume => _volume;

  int battery = 30;

  List<Alarm> alarms = [];
  
  String userName = "오수현입니다람쥐썬더"; 

  Map<String, dynamic>? nearestAlarm;

  Future<Map<String, dynamic>> fetchNearestAlarm() async {
    var url = Uri.http('172.30.1.36:5200', 'getNearestAlarm');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      if (response.body != "null") {
        return jsonDecode(response.body); // Map<String, dynamic> 형태로 반환
      } else {
        return {}; // null인 경우 빈 Map 반환
      }
    } else {
      throw Exception('알람 정보를 가져오는 데 실패했습니다.');
    }
  }

  void setAlarmSound(String sound) async{
    _selectedAlarmSound = sound;

    var url = Uri.http('172.30.1.36:5200', 'setAlarmSound');
    var response = await http.post(url, body : {'alarmSound' : sound});
    print('Response status: ${response.statusCode}');

    notifyListeners();
  }
  

  void setVolume(double value) async {
    _volume = value;

    var url = Uri.http('172.30.1.36:5200', 'setVolume');
    var response = await http.post(url, body : {'alarmVolume' : value.toString()});
    print('Response status: ${response.statusCode}');

    notifyListeners();
  }

  void setAlarmStrength(int Strength) async {
    _selectedAlarmStrength = Strength;

    var url = Uri.http('172.30.1.36:5200', 'setAlarmStrength');
    var response = await http.post(url, body : {'alarmStrength' : Strength.toString()});
    print('Response status: ${response.statusCode}');
    
    notifyListeners();
  }
  
  void toggleDarkMode() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }

  void toggleAlarm() {
    alarmEnabled = !alarmEnabled;
    notifyListeners();
  }

  void addAlarm(Alarm alarm) async {
    alarms.add(alarm);

    var url = Uri.http('172.30.1.36:5200', 'addAlarm');
    var response = await http.post(url, body: {
      'name': alarm.name,
      'time': alarm.time.toIso8601String(), // ISO8601 형식으로 변환
    });
    print('Add Alarm Response: ${response.statusCode}');

    await fetchNearestAlarm();

    notifyListeners();
  }

  void removeAlarm(int index) async {
    Alarm alarm = alarms[index];
    alarms.removeAt(index);

    var url = Uri.http('172.30.1.36:5200', 'removeAlarm');
    var response = await http.post(url, body: {
      'name': alarm.name,
      'time': alarm.time.toIso8601String(),
    });
    print('Remove Alarm Response: ${response.statusCode}');

    notifyListeners();
  }

}

class Alarm {
  final String name;
  final DateTime time;

  Alarm({required this.name, required this.time});
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    void initState() {
      // super.initState();
      final appState = Provider.of<AppState>(context, listen: false);
      appState.fetchNearestAlarm().then((alarm) {
        appState.nearestAlarm = alarm;
        appState.notifyListeners();
      });
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('TENTEN'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(appState.isDarkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: () => appState.toggleDarkMode(),
          ),
        ],
      ),
      drawer: const AppBarDrawer(),
      body: Column(
        children: const [
          SizedBox(height: 20),
          DeviceInfo(),
          AlarmList(), 
        ],
      ),
    );
  }
}

class DeviceInfo extends StatelessWidget {
  const DeviceInfo({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Container(
      width : MediaQuery.of(context).size.width,
      height : MediaQuery.of(context).size.height * 0.5,
      padding : EdgeInsets.all(20),
      
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          DeviceImage(),
          SizedBox(height: 10,),
          Text(
            "Speed WakeGon",
            style : TextStyle(fontSize: 25,fontWeight: FontWeight.bold),
            ),
            
          SizedBox(height: 5,),
          Text(
            "${appState.battery}%",
            style: TextStyle(fontSize : 15,),
          ),
        ],
      ),
    );
  }
}

class DeviceImage extends StatelessWidget {
  const DeviceImage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    String imgPath;
    imgPath = appState.battery < 30 ? 'assets/images/cat_hungry.png' : 'assets/images/cat.jpeg';
    return Container(
      width : MediaQuery.of(context).size.width * 0.6,
      height : MediaQuery.of(context).size.height * 0.25,  
      child:Image(image:AssetImage(imgPath)), 
      // child:Image(image: (appState.battery < 30 ? AssetImage('assets/images/cat_hungry.png') : AssetImage('assets/images/cat.jpeg')),)
    );
  }
}

class AlarmList extends StatelessWidget {
  const AlarmList({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // AppState에서 가장 가까운 알람 데이터를 가져옵니다.
    final nearestAlarm = appState.nearestAlarm;

    if (nearestAlarm == null || nearestAlarm.isEmpty) {
      return const Center(
        child: Text('알람이 없습니다.', style: TextStyle(fontSize: 18)),
      );
    }

    final alarmTime = DateTime.parse(nearestAlarm["time"]);
    final now = DateTime.now();
    final difference = alarmTime.difference(now);

    return ListTile(
      leading: const Icon(Icons.alarm),
      title: Text(
        "다음 알람: ${nearestAlarm["name"]}",
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        "남은 시간: ${difference.inHours}시간 ${difference.inMinutes % 60}분 ${difference.inSeconds % 60}초",
      ),
    );
  }
}
class AppBarDrawer extends StatelessWidget {
  const AppBarDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const UserAccountsDrawerHeader(
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 60),
            ),
            accountName: Text('   텐텐'),
            accountEmail: Text(""),
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('알람 설정'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AlarmSettingsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('사용자 설정'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserSettingsPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class AlarmSettingsPage extends StatefulWidget {
  const AlarmSettingsPage({super.key});

  @override
  _AlarmSettingsPageState createState() => _AlarmSettingsPageState();
}

class _AlarmSettingsPageState extends State<AlarmSettingsPage> {
  Future<void> _showAddAlarmDialog(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final TextEditingController alarmNameController = TextEditingController();
    DateTime selectedDateTime = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('알람 추가'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: alarmNameController,
                    decoration: const InputDecoration(
                      labelText: '알람 이름',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "날짜: ${selectedDateTime.year}-${selectedDateTime.month}-${selectedDateTime.day}",
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDateTime,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              selectedDateTime = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                selectedDateTime.hour,
                                selectedDateTime.minute,
                              );
                            });
                          }
                        },
                        child: const Text('날짜 변경'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "시간: ${TimeOfDay.fromDateTime(selectedDateTime).format(context)}",
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                          );
                          if (pickedTime != null) {
                            setState(() {
                              selectedDateTime = DateTime(
                                selectedDateTime.year,
                                selectedDateTime.month,
                                selectedDateTime.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        },
                        child: const Text('시간 변경'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                if (alarmNameController.text.isNotEmpty) {
                  appState.addAlarm(
                    Alarm(
                      name: alarmNameController.text,
                      time: selectedDateTime,
                    ),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('알람 이름을 입력하세요.')),
                  );
                }
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('알람 설정')),
      body: ListView.builder(
        padding: const EdgeInsets.all(10.0),
        itemCount: appState.alarms.length,
        itemBuilder: (context, index) {
          final alarm = appState.alarms[index];
          var weekday = weekDict[(alarm.time.weekday)] ?? ''; 
          return Column(
            children: [
              SizedBox(height : 20),
              Container(
                width : MediaQuery.of(context).size.width * 0.95,
                height : MediaQuery.of(context).size.height * 0.12,
                decoration: BoxDecoration(
                  color : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color : Colors.grey,
                    )
                  ]
                ),
                child:Row(
                  children: [
                    SizedBox(width : 30),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${alarm.name}",
                          style: TextStyle(fontSize: 25,),
                          ),
                        Text(
                          "${alarm.time.month}월 ${alarm.time.day}일 (${weekday})",
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    SizedBox(width : MediaQuery.of(context).size.width * 0.22),
                    Text(
                      "${DateFormat('HH : mm').format(alarm.time)}",
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.w300),
                    ),
                    SizedBox(width : 10),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => appState.removeAlarm(index),
                    ),
                    
                  ],
                  )
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAlarmDialog(context),
        child: const Icon(Icons.add),
        backgroundColor: Colors.white,
        
      ),
    );
  }
}


class UserSettingsPage extends StatelessWidget {
  const UserSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('사용자 설정')),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            const profileImage(),
            const SizedBox(height: 20),
            Text(
              "${appState.userName}",
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 30),
            AlarmSoundSettingWidget(),
            const SizedBox(height: 30),
            AlarmStrengthSettingWidget(),
          ],
        ),
      ),
    );
  }
}

class AlarmSoundSettingWidget extends StatelessWidget {
  const AlarmSoundSettingWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const AlarmSoundSettingsPage()),
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.grey,
              blurRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            '알람음 선택',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w200),
          ),
        ),
      ),
    );
  }
}

class AlarmStrengthSettingWidget extends StatelessWidget {
  const AlarmStrengthSettingWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const AlarmStrengthSettingsPage()),
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.grey,
              blurRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            '알람 강도 설정',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w200),
          ),
        ),
      ),
    );
  }
}

class AlarmSoundSettingsPage extends StatelessWidget {
  const AlarmSoundSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> alarmSounds = [
      '기본 알람음',
      '알람음 2',
      '알람음 3',
      '알람음 4',
      '알람음 5',
    ];

    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('알람음 선택')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: alarmSounds.length,
              itemBuilder: (context, index) {
                final isSelected = appState.selectedAlarmSound == alarmSounds[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[100] : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      alarmSounds[index],
                      style: TextStyle(
                        color: isSelected ? Colors.blue : Colors.black,
                      ),
                    ),
                    onTap: () {
                      appState.setAlarmSound(alarmSounds[index]);
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                Icon( appState.volume == 0? Icons.volume_off : appState.volume < 0.5 ? Icons.volume_down_alt : Icons.volume_up, size:30),
                // const Text('음량 설정', style: TextStyle(fontSize: 16)),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.blue, 
                    inactiveTrackColor: Colors.grey[300], 
                    trackHeight: 1.0, 
                    thumbColor: Colors.blue,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10.0, 
                    ),
                    overlayColor: Colors.blue.withOpacity(0.2), 
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 20.0, 
                    ),
                    tickMarkShape: SliderTickMarkShape.noTickMark, 
                    activeTickMarkColor: Colors.blue, 
                    inactiveTickMarkColor: Colors.grey, 
                  ),
                  child: Slider(
                    value: appState.volume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 100, // 틱 갯수
                    label: '${(appState.volume * 100).toInt()}%',
                    onChanged: (value) {
                      appState.setVolume(value);
                    },
                  ),
                ),
                SizedBox(height : 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AlarmStrengthSettingsPage extends StatelessWidget {
  const AlarmStrengthSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> alarmStrengths = ['약', '중', '강'];

    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('알람 강도 설정')),
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.05),
          Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.5,
            // alignment: Alignment.center,
            child: Column(
              children: [
                Text(
                  '현재 선택: ${alarmStrengths[appState.selectedAlarmStrength]}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.15,
              decoration: BoxDecoration(
                // color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  // BoxShadow(
                  //   
                  // ),
                ],
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "알람 강도 설정",
                    style: TextStyle(fontSize: 16),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.blue,
                      inactiveTrackColor: Colors.grey[300],
                      trackHeight: 2.0,
                      thumbColor: Colors.blue,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10.0,
                      ),
                      overlayColor: Colors.blue.withOpacity(0.2),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 20.0,
                      ),
                      tickMarkShape: SliderTickMarkShape.noTickMark,
                    ),
                    child: Slider(
                      value: appState.selectedAlarmStrength.toDouble(),
                      min: 0.0,
                      max: 2.0, 
                      divisions: 2, 
                      label: alarmStrengths[appState.selectedAlarmStrength],
                      onChanged: (value) {
                        appState.setAlarmStrength(value.toInt());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class profileImage extends StatelessWidget {
  const profileImage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width : MediaQuery.of(context).size.width * 0.6,
      height : MediaQuery.of(context).size.height * 0.2,
      child:CircleAvatar(
        backgroundColor: Colors.white,
        child:Icon(Icons.person, size : 120,)
        // backgroundImage:AssetImage('assets/images/JJang.png'),
      )
    );
  }
}
