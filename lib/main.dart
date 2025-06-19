import 'package:flutter/material.dart';
import 'modules/password/password_book_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'modules/password/password_item.dart';
import 'modules/checkin/checkin_page.dart';
import 'modules/checkin/checkin_item.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(PasswordItemAdapter());
  Hive.registerAdapter(CheckinItemAdapter());
  await Hive.openBox<PasswordItem>('passwords');
  await Hive.openBox<CheckinItem>('checkins');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '习惯记忆合集',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MainScaffold(),
    );
  }
}

// 主Scaffold，包含侧边导航栏和页面切换
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0; // 0:首页 1:密码本 ...

  // 页面列表
  final List<Widget> _pages = [
    const HomePage(),
    const PasswordBookPage(),
    const CheckinPage(),
    // 其他模块页可继续添加
  ];

  // 侧边导航栏
  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.deepPurple,
            ),
            child: Text('习惯记忆合集', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('首页'),
            selected: _selectedIndex == 0,
            onTap: () {
              setState(() {
                _selectedIndex = 0;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('密码本'),
            selected: _selectedIndex == 1,
            onTap: () {
              setState(() {
                _selectedIndex = 1;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.check_circle),
            title: const Text('打卡'),
            selected: _selectedIndex == 2,
            onTap: () {
              setState(() {
                _selectedIndex = 2;
              });
              Navigator.pop(context);
            },
          ),
          // 其他模块入口可继续添加
        ],
      ),
    );
  }

  // 返回键逻辑
  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return false; // 不退出App
    }
    return true; // 退出App
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_selectedIndex == 0 ? '首页' : _selectedIndex == 1 ? '密码本' : _selectedIndex == 2 ? '打卡' : ''),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        drawer: _buildDrawer(),
        body: _pages[_selectedIndex],
      ),
    );
  }
}

// 首页：卡片式功能入口
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildModuleCard(context, Icons.lock, '密码本', 1),
          _buildModuleCard(context, Icons.check_circle, '打卡', 2),
          // 其他功能卡片可继续添加
        ],
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, IconData icon, String title, int pageIndex) {
    return GestureDetector(
      onTap: () {
        // 切换到对应模块页
        final state = context.findAncestorStateOfType<_MainScaffoldState>();
        state?.setState(() {
          state._selectedIndex = pageIndex;
        });
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: Colors.deepPurple),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
