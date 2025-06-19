import 'package:flutter/material.dart';
import 'modules/password/password_book_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'modules/password/password_item.dart';
import 'modules/checkin/checkin_page.dart';
import 'modules/checkin/checkin_item.dart';
import 'modules/item/item_page.dart';
import 'modules/item/item.dart';
import 'modules/log/log_page.dart';
import 'package:hive/hive.dart';
import 'package:reorderables/reorderables.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(PasswordItemAdapter());
  Hive.registerAdapter(CheckinItemAdapter());
  Hive.registerAdapter(ItemAdapter());
  await Hive.openBox<PasswordItem>('passwords');
  await Hive.openBox<CheckinItem>('checkins');
  await Hive.openBox<Item>('items');
  await Hive.openBox('main_sort');
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
  late List<_ModuleCardInfo> _moduleCards;
  late Box box;

  @override
  void initState() {
    super.initState();
    box = Hive.box('main_sort');
    _moduleCards = _loadModuleCards();
  }

  List<_ModuleCardInfo> _loadModuleCards() {
    final defaultCards = [
      _ModuleCardInfo(icon: Icons.lock, title: '密码本', pageIndex: 1),
      _ModuleCardInfo(icon: Icons.check_circle, title: '打卡', pageIndex: 2),
      _ModuleCardInfo(icon: Icons.inventory, title: '物品管理', pageIndex: 3),
      _ModuleCardInfo(icon: Icons.bug_report, title: '日志', pageIndex: 4),
    ];
    final saved = box.get('cards');
    if (saved is List) {
      try {
        // 保证所有模块都在首页，且顺序为用户自定义
        final loaded = saved.map((e) => _ModuleCardInfo.fromMap(Map<String, dynamic>.from(e))).toList();
        final existPages = loaded.map((e) => e.pageIndex).toSet();
        for (final def in defaultCards) {
          if (!existPages.contains(def.pageIndex)) {
            loaded.add(def);
          }
        }
        return loaded;
      } catch (_) {}
    }
    return defaultCards;
  }

  void _saveModuleCards() {
    box.put('cards', _moduleCards.map((e) => e.toMap()).toList());
  }

  List<Widget> get _pages => [
    HomePage(
      moduleCards: _moduleCards,
      onSort: (cards) {
        setState(() {
          _moduleCards = List.from(cards);
        });
        _saveModuleCards();
      },
    ),
    const PasswordBookPage(),
    const CheckinPage(),
    const ItemPage(),
    const LogPage(),
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
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('物品管理'),
            selected: _selectedIndex == 3,
            onTap: () {
              setState(() {
                _selectedIndex = 3;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('日志'),
            selected: _selectedIndex == 4,
            onTap: () {
              setState(() {
                _selectedIndex = 4;
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
          title: Text(_selectedIndex == 0 ? '首页' : _selectedIndex == 1 ? '密码本' : _selectedIndex == 2 ? '打卡' : _selectedIndex == 3 ? '物品管理' : _selectedIndex == 4 ? '日志' : ''),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        drawer: _buildDrawer(),
        body: _pages[_selectedIndex],
      ),
    );
  }
}

// 首页：卡片式功能入口
class HomePage extends StatefulWidget {
  final List<_ModuleCardInfo> moduleCards;
  final void Function(List<_ModuleCardInfo>) onSort;
  const HomePage({super.key, required this.moduleCards, required this.onSort});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<_ModuleCardInfo> _cards;

  @override
  void initState() {
    super.initState();
    _cards = List.from(widget.moduleCards);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ReorderableWrap(
            direction: Axis.horizontal,
            alignment: WrapAlignment.start,
            runAlignment: WrapAlignment.start,
            spacing: 16,
            runSpacing: 16,
            maxMainAxisCount: 2,
            children: [
              for (final card in _cards)
                _buildModuleCard(context, card.icon, card.title, card.pageIndex, key: ValueKey(card.title)),
            ],
            onReorder: (oldIndex, newIndex) {
              setState(() {
                final item = _cards.removeAt(oldIndex);
                _cards.insert(newIndex, item);
              });
              widget.onSort(_cards);
            },
          ),
        );
      },
    );
  }

  Widget _buildModuleCard(BuildContext context, IconData icon, String title, int pageIndex, {Key? key}) {
    final double cardWidth = (MediaQuery.of(context).size.width - 16 * 3) / 2; // 16*3: 两边padding+中间间距
    return GestureDetector(
      key: key,
      onTap: () {
        final state = context.findAncestorStateOfType<_MainScaffoldState>();
        state?.setState(() {
          state._selectedIndex = pageIndex;
        });
      },
      child: SizedBox(
        width: cardWidth,
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
      ),
    );
  }
}

class _ModuleCardInfo {
  final IconData icon;
  final String title;
  final int pageIndex;
  _ModuleCardInfo({required this.icon, required this.title, required this.pageIndex});
  Map<String, dynamic> toMap() => {'icon': icon.codePoint, 'title': title, 'pageIndex': pageIndex};
  static _ModuleCardInfo fromMap(Map<String, dynamic> map) => _ModuleCardInfo(
    icon: IconData(map['icon'], fontFamily: 'MaterialIcons'),
    title: map['title'],
    pageIndex: map['pageIndex'],
  );
}
