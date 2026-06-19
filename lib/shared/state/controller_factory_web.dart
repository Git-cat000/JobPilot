import 'app_controller_contract.dart';
import 'demo_app_controller.dart';

/// Web 控制器工厂：构造只读演示控制器并启动初始化（播种示例数据）。
AppControllerContract createAppControllerImpl() => DemoAppController()..init();
