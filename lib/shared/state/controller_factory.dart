import 'app_controller_contract.dart';
import 'controller_factory_io.dart'
    if (dart.library.html) 'controller_factory_web.dart';

/// 创建应用控制器。
///
/// 通过条件导入选择实现：原生平台（Android/iOS/桌面）使用基于 SQLite 的
/// `AppController`；Web 使用只读的 `DemoAppController`。`init()` 已在具体实现
/// 内启动，调用方无需再次调用。
AppControllerContract createAppController() => createAppControllerImpl();
