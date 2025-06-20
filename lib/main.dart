import 'package:flutter/material.dart';
import 'modules/password/password_book_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'modules/password/password_item.dart';
import 'modules/checkin/checkin_page.dart';
import 'modules/checkin/checkin_item.dart';
import 'modules/item/item_page.dart';
import 'modules/item/item.dart';
import 'modules/log/log_page.dart';
import 'modules/log/log_service.dart';
import 'dart:async';

void main() async {
  // 初始化Flutter绑定，确保所有插件可用
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    LogService.addError('FlutterError: ${details.exceptionAsString()}\\n${details.stack}');
    FlutterError.presentError(details);
  };
  runZonedGuarded(() async {
    // 初始化Hive本地数据库
    await Hive.initFlutter();
    // 注册各模块的数据模型适配器
    Hive.registerAdapter(PasswordItemAdapter());
    Hive.registerAdapter(CheckinItemAdapter());
    Hive.registerAdapter(ItemAdapter());
    // 打开各模块的数据盒子（本地持久化）
    await Hive.openBox<PasswordItem>('passwords');
    await Hive.openBox<CheckinItem>('checkins');
    await Hive.openBox<Item>('items');
    await Hive.openBox('main_sort');
    // 启动应用
    runApp(const MyApp());
  }, (error, stack) {
    LogService.addError('ZoneError: $error\\n$stack');
  });
}

/// 应用根组件，配置主题与首页
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
  int _selectedIndex = 0; // 当前选中的页面索引，0为首页
  late List<_ModuleCardInfo> _moduleCards; // 首页卡片信息
  late Box box; // Hive盒子用于保存首页卡片顺序

  @override
  void initState() {
    super.initState();
    box = Hive.box('main_sort');
    _moduleCards = _loadModuleCards();
  }

  /// 加载首页卡片顺序，若无则用默认顺序
  List<_ModuleCardInfo> _loadModuleCards() {
    final defaultCards = [
      _ModuleCardInfo(iconKey: 'lock', title: '密码本', pageIndex: 1),
      _ModuleCardInfo(iconKey: 'check_circle', title: '打卡', pageIndex: 2),
      _ModuleCardInfo(iconKey: 'inventory', title: '物品管理', pageIndex: 3),
      _ModuleCardInfo(iconKey: 'bug_report', title: '日志', pageIndex: 4),
    ];
    final saved = box.get('cards');
    if (saved is List) {
      try {
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

  /// 保存首页卡片顺序到本地
  void _saveModuleCards() {
    box.put('cards', _moduleCards.map((e) => e.toMap()).toList());
  }

  /// 各功能页面列表，按索引切换
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
    const SettingsPage(),
  ];

  /// 构建侧边导航栏
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
          // 首页入口
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
          // 密码本入口
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
          // 打卡入口
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
          // 物品管理入口
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
          // 日志入口
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
          // 设置入口
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('设置'),
            selected: _selectedIndex == 5,
            onTap: () {
              setState(() {
                _selectedIndex = 5;
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  /// 返回键逻辑：模块页返回首页，首页返回退出APP
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
          // 动态标题
          title: Text(_selectedIndex == 0 ? '首页' : _selectedIndex == 1 ? '密码本' : _selectedIndex == 2 ? '打卡' : _selectedIndex == 3 ? '物品管理' : _selectedIndex == 4 ? '日志' : _selectedIndex == 5 ? '设置' : ''),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        drawer: _buildDrawer(),
        body: _pages[_selectedIndex],
      ),
    );
  }
}

/// 首页：卡片式功能入口，支持拖拽排序
class HomePage extends StatefulWidget {
  final List<_ModuleCardInfo> moduleCards;
  final void Function(List<_ModuleCardInfo>) onSort;
  const HomePage({super.key, required this.moduleCards, required this.onSort});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<_ModuleCardInfo> _cards;
  late int col;
  late double ratio, hgap, vgap, pad;
  StreamSubscription? _hiveSub;

  @override
  void initState() {
    super.initState();
    _cards = List.from(widget.moduleCards);
    final box = Hive.box('main_sort');
    col = box.get('home_col') as int? ?? 2;
    ratio = box.get('home_ratio') as double? ?? 1.2;
    hgap = box.get('home_hgap') as double? ?? 28;
    vgap = box.get('home_vgap') as double? ?? 32;
    pad = box.get('home_pad') as double? ?? 20;
    _hiveSub = box.watch().listen((_) {
      if (!mounted) return;
      setState(() {
        col = box.get('home_col') as int? ?? 2;
        ratio = box.get('home_ratio') as double? ?? 1.2;
        hgap = box.get('home_hgap') as double? ?? 28;
        vgap = box.get('home_vgap') as double? ?? 32;
        pad = box.get('home_pad') as double? ?? 20;
      });
    });
  }

  @override
  void dispose() {
    _hiveSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 获取各模块数量
    int passwordCount = 0, checkinCount = 0, itemCount = 0, logCount = 0;
    try {
      passwordCount = Hive.box<PasswordItem>('passwords').length;
    } catch (_) {}
    try {
      checkinCount = Hive.box<CheckinItem>('checkins').length;
    } catch (_) {}
    try {
      itemCount = Hive.box<Item>('items').length;
    } catch (_) {}
    try {
      logCount = LogService.errors.length;
    } catch (_) {}
    final Map<int, int> moduleCounts = {
      1: passwordCount,
      2: checkinCount,
      3: itemCount,
      4: logCount,
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(pad),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: col,
            crossAxisSpacing: hgap,
            mainAxisSpacing: vgap,
            childAspectRatio: ratio,
          ),
          itemCount: _cards.length,
          itemBuilder: (context, idx) {
            final card = _cards[idx];
            return _buildModuleCard(context, card.iconKey, card.title, card.pageIndex, key: ValueKey(card.title));
          },
        );
      },
    );
  }

  Widget _buildInfoStat({required IconData icon, required String label, required int count, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 4),
          Text('$label: ', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Text('$count', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// 构建首页功能卡片
  Widget _buildModuleCard(BuildContext context, String iconKey, String title, int pageIndex, {Key? key}) {
    // 不同模块主色
    final List<Color> mainColors = [
      Color(0xFFF5F6FA), // 默认
      Color(0xFFA5D6F9), // 密码本 浅蓝
      Color(0xFFFFD580), // 打卡 浅橙
      Color(0xFFB2E5C8), // 物品管理 浅绿
      Color(0xFFFFB6B9), // 日志 浅粉
    ];
    final Color cardColor =
        pageIndex == 1 ? mainColors[1] : pageIndex == 2 ? mainColors[2] : pageIndex == 3 ? mainColors[3] : pageIndex == 4 ? mainColors[4] : mainColors[0];
    // 获取各模块数量
    int count = 0;
    if (pageIndex == 1) {
      try { count = Hive.box<PasswordItem>('passwords').length; } catch (_) {}
    } else if (pageIndex == 2) {
      try { count = Hive.box<CheckinItem>('checkins').length; } catch (_) {}
    } else if (pageIndex == 3) {
      try { count = Hive.box<Item>('items').length; } catch (_) {}
    } else if (pageIndex == 4) {
      try { count = LogService.errors.length; } catch (_) {}
    }
    String countLabel = pageIndex == 1 ? '密码' : pageIndex == 2 ? '打卡' : pageIndex == 3 ? '物品' : pageIndex == 4 ? '日志' : '';
    return GestureDetector(
      key: key,
      onTap: () {
        final state = context.findAncestorStateOfType<_MainScaffoldState>();
        state?.setState(() {
          state._selectedIndex = pageIndex;
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cardColor.withOpacity(0.85), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: cardColor.withOpacity(0.10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: cardColor.withOpacity(0.18), width: 1.2),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: cardColor.withOpacity(0.18),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(_iconFromKey(iconKey), size: 18, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3d246c),
                        letterSpacing: 1.1,
                        overflow: TextOverflow.ellipsis,
                        shadows: [
                          Shadow(
                            color: Colors.white70,
                            blurRadius: 1,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      maxLines: 2,
                    ),
                    if (countLabel.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: cardColor.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$countLabel：$count',
                            style: TextStyle(
                              color: cardColor.darken(0.18),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 首页卡片信息结构体
class _ModuleCardInfo {
  final String iconKey;
  final String title;
  final int pageIndex;
  _ModuleCardInfo({required this.iconKey, required this.title, required this.pageIndex});
  Map<String, dynamic> toMap() => {'iconKey': iconKey, 'title': title, 'pageIndex': pageIndex};
  static _ModuleCardInfo fromMap(Map<String, dynamic> map) => _ModuleCardInfo(
    iconKey: map['iconKey'],
    title: map['title'],
    pageIndex: map['pageIndex'],
  );
}

// 在用到的地方
IconData _iconFromKey(String key) {
  switch (key) {
    case 'lock': return Icons.lock;
    case 'check_circle': return Icons.check_circle;
    case 'inventory': return Icons.inventory;
    case 'bug_report': return Icons.bug_report;
    default: return Icons.extension;
  }
}

// 工具方法：颜色加深
extension ColorDarken on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

// 新增：设置页面
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Box box;
  final List<String> modules = ['首页卡片', '密码本', '打卡', '物品管理', '日志'];
  final List<String> keys = ['home', 'password', 'checkin', 'item', 'log'];
  Map<String, int> colMap = {};
  Map<String, double> ratioMap = {};
  Map<String, double> hgapMap = {};
  Map<String, double> vgapMap = {};
  Map<String, double> padMap = {};

  @override
  void initState() {
    super.initState();
    box = Hive.box('main_sort');
    for (var k in keys) {
      colMap[k] = (box.get('${k}_col') as int?) ?? 2;
      ratioMap[k] = (box.get('${k}_ratio') as double?) ?? 1.2;
      hgapMap[k] = (box.get('${k}_hgap') as double?) ?? 16;
      vgapMap[k] = (box.get('${k}_vgap') as double?) ?? 16;
      padMap[k] = (box.get('${k}_pad') as double?) ?? 16;
    }
  }

  void save() {
    for (var k in keys) {
      box.put('${k}_col', colMap[k]);
      box.put('${k}_ratio', ratioMap[k]);
      box.put('${k}_hgap', hgapMap[k]);
      box.put('${k}_vgap', vgapMap[k]);
      box.put('${k}_pad', padMap[k]);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')), 
      body: ListView(
        children: [
          const ListTile(title: Text('首页卡片尺寸', style: TextStyle(fontWeight: FontWeight.bold))),
          ExpansionTile(
            title: const Text('首页卡片'),
            children: [
              _buildSliderTile('首页卡片', 'home'),
            ],
          ),
          const Divider(),
          const ListTile(title: Text('功能模块卡片尺寸', style: TextStyle(fontWeight: FontWeight.bold))),
          ExpansionTile(
            title: const Text('密码本'),
            children: [
              _buildSliderTile('密码本', 'password'),
            ],
          ),
          ExpansionTile(
            title: const Text('打卡'),
            children: [
              _buildSliderTile('打卡', 'checkin'),
            ],
          ),
          ExpansionTile(
            title: const Text('物品管理'),
            children: [
              _buildSliderTile('物品管理', 'item'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile(String label, String k) {
    return ListTile(
      title: Text(label),
      subtitle: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          const Text('列数'),
          SizedBox(
            width: 60,
            child: Slider(
              value: colMap[k]!.toDouble(),
              min: 1,
              max: 3,
              divisions: 2,
              label: colMap[k]!.toString(),
              onChanged: (v) => setState(() => colMap[k] = v.round()),
              onChangeEnd: (_) => save(),
            ),
          ),
          Text(colMap[k]!.toString()),
          const SizedBox(width: 8),
          const Text('宽高比'),
          SizedBox(
            width: 100,
            child: Slider(
              value: ratioMap[k]!,
              min: 0.6,
              max: 2.0,
              divisions: 14,
              label: ratioMap[k]!.toStringAsFixed(2),
              onChanged: (v) => setState(() => ratioMap[k] = v),
              onChangeEnd: (_) => save(),
            ),
          ),
          Text(ratioMap[k]!.toStringAsFixed(2)),
          const SizedBox(width: 8),
          const Text('横间距'),
          SizedBox(
            width: 80,
            child: Slider(
              value: hgapMap[k]!,
              min: 4,
              max: 40,
              divisions: 9,
              label: hgapMap[k]!.toStringAsFixed(0),
              onChanged: (v) => setState(() => hgapMap[k] = v),
              onChangeEnd: (_) => save(),
            ),
          ),
          Text(hgapMap[k]!.toStringAsFixed(0)),
          const SizedBox(width: 8),
          const Text('纵间距'),
          SizedBox(
            width: 80,
            child: Slider(
              value: vgapMap[k]!,
              min: 4,
              max: 40,
              divisions: 9,
              label: vgapMap[k]!.toStringAsFixed(0),
              onChanged: (v) => setState(() => vgapMap[k] = v),
              onChangeEnd: (_) => save(),
            ),
          ),
          Text(vgapMap[k]!.toStringAsFixed(0)),
          const SizedBox(width: 8),
          const Text('外边距'),
          SizedBox(
            width: 80,
            child: Slider(
              value: padMap[k]!,
              min: 0,
              max: 40,
              divisions: 8,
              label: padMap[k]!.toStringAsFixed(0),
              onChanged: (v) => setState(() => padMap[k] = v),
              onChangeEnd: (_) => save(),
            ),
          ),
          Text(padMap[k]!.toStringAsFixed(0)),
        ],
      ),
    );
  }
}
