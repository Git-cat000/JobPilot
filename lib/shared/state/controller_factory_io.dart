import 'app_controller.dart';
import 'app_controller_contract.dart';

/// 原生平台控制器工厂：构造 SQLite 控制器并启动初始化。
AppControllerContract createAppControllerImpl() => AppController()..init();
