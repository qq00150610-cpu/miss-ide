# Jadx 集成指南

## 概述

Miss IDE 内置 Jadx 反编译引擎，支持将 DEX、JAR、APK 文件反编译为 Java 源代码。本指南介绍 Jadx 集成的工作原理和使用方法。

## 架构设计

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter 应用程序层                          │
│  ┌─────────────────────────────────────────────────────┐     │
│  │              JadxWrapper (Dart)                     │     │
│  │  - decompileApk()                                   │     │
│  │  - decompileDex()                                  │     │
│  │  - decompileJar()                                  │     │
│  │  - getClassList()                                  │     │
│  └─────────────────────────┬───────────────────────────┘     │
│                            │ MethodChannel                      │
└────────────────────────────┼───────────────────────────────────┘
                             │
┌────────────────────────────┼───────────────────────────────────┐
│                    Android 原生层                              │
│  ┌─────────────────────────▼───────────────────────────┐     │
│  │           JadxEnginePlugin (Kotlin)                  │     │
│  │  - 处理 Flutter 端 MethodChannel 调用              │     │
│  │  - 管理协程作用域                                   │     │
│  │  - 发送进度事件                                     │     │
│  └─────────────────────────┬───────────────────────────┘     │
│                            │                                    │
│  ┌─────────────────────────▼───────────────────────────┐     │
│  │              反编译引擎 (Java/Kotlin)                 │     │
│  │  - DEX 解析器                                       │     │
│  │  - JAR 解析器 (JD-Core)                             │     │
│  │  - 资源解码器                                       │     │
│  └─────────────────────────────────────────────────────┘     │
└────────────────────────────────────────────────────────────────┘
```

## 核心组件

### 1. JadxWrapper (Flutter/Dart)

JadxWrapper 是 Dart 端的统一封装，提供以下功能：

```dart
// 获取 Jadx 版本
final version = await JadxWrapper.instance.getVersion();

// 反编译 APK
final result = await JadxWrapper.instance.decompileApk(
  '/path/to/app.apk',
  config: JadxConfig(
    deobfuscation: true,
    outputType: 'java',
  ),
  onProgress: (progress) {
    print('进度: ${progress.percent * 100}%');
  },
);

// 反编译 DEX
final result = await JadxWrapper.instance.decompileDex(
  '/path/to/classes.dex',
);

// 获取类列表
final classes = await JadxWrapper.instance.getClassList('/path/to/app.apk');
```

### 2. JadxEnginePlugin (Android/Kotlin)

Android 原生插件，处理实际的反编译操作：

```kotlin
// 主要方法
"getVersion"       -> 返回 Jadx 版本
"decompileApk"     -> 反编译 APK 文件
"decompileDex"     -> 反编译 DEX 文件
"decompileJar"    -> 反编译 JAR 文件
"decompileSingleClass" -> 反编译单个类
"getClassList"     -> 获取类列表
"decodeResources" -> 解码资源文件
"cancel"          -> 取消当前任务
```

## 配置选项

### JadxConfig

| 选项 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `deobfuscation` | bool | false | 启用反混淆 |
| `debugInfo` | bool | false | 显示调试信息 |
| `skipResources` | bool | false | 跳过资源解码 |
| `outputType` | String | 'java' | 输出类型 (java/smali) |
| `classLimit` | int? | null | 限制处理的类数量 |

## 进度回调

进度通过 EventChannel 实时推送：

```dart
 JadxWrapper.instance.decompileApk(
  apkPath,
  onProgress: (progress) {
    // progress.current    - 当前处理数
    // progress.total      - 总数
    // progress.currentClass - 当前类名
    // progress.percent    - 百分比 (0.0 - 1.0)
  },
);
```

## 使用示例

### 基本用法

```dart
import 'package:miss_ide/engine/jadx/jadx_wrapper.dart';

class DecompilePage extends StatefulWidget {
  @override
  State<DecompilePage> createState() => _DecompilePageState();
}

class _DecompilePageState extends State<DecompilePage> {
  DecompileProgress? _progress;
  DecompileResult? _result;
  
  Future<void> _decompile() async {
    final jadx = JadxWrapper.instance;
    
    setState(() => _progress = null);
    
    _result = await jadx.decompileApk(
      '/sdcard/apps/MyApp.apk',
      config: const JadxConfig(
        deobfuscation: true,
        outputType: 'java',
      ),
      onProgress: (progress) {
        setState(() => _progress = progress);
      },
    );
    
    if (_result!.success) {
      _openDecompiledProject(_result!.outputDir);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_progress != null)
          LinearProgressIndicator(value: _progress!.percent),
        if (_result?.success == true)
          Text('反编译成功: ${_result!.javaFiles.length} 个 Java 文件'),
      ],
    );
  }
}
```

### 使用调度中心

```dart
import 'package:miss_ide/engine/jadx/decompile_engine.dart';

// 创建任务
final taskId = DecompileEngineCenter.instance.createTask(
  inputPath: '/sdcard/apps/MyApp.apk',
);

// 开始反编译
final result = await DecompileEngineCenter.instance.startTask(
  taskId,
  config: const JadxConfig(deobfuscation: true),
);

// 监听任务状态
DecompileEngineCenter.instance.taskStream.listen((tasks) {
  final task = tasks[taskId];
  print('状态: ${task?.state}');
  print('进度: ${task?.progress?.percent}');
});
```

## 注意事项

### 1. 性能考虑

- 大型 APK 反编译可能需要较长时间
- 建议在后台 isolate 中执行
- 使用进度回调让用户了解进度

### 2. 存储空间

- 反编译结果会占用大量磁盘空间
- 建议清理不再需要的反编译结果
- 可以配置输出目录

### 3. 混淆代码

- 启用了 ProGuard/R8 混淆的 APK 反编译效果可能较差
- 可以启用 `deobfuscation` 选项尝试改善
- 某些混淆名称可能无法恢复

### 4. 法律合规

- 仅用于合法的安全研究和学习目的
- 不要使用反编译技术侵犯他人知识产权
- 遵守相关法律法规

## 故障排除

### 反编译失败

1. 检查 APK 文件是否损坏
2. 确认存储权限已授予
3. 检查是否有足够的存储空间
4. 查看错误日志

### 进度卡住

1. 点击取消按钮
2. 重启应用
3. 检查系统资源是否充足

### 输出为空

1. 确认 APK 中包含 DEX 文件
2. 尝试使用其他反编译器
3. 检查输出目录权限

## 高级用法

### 自定义反编译器

```dart
// 注册自定义反编译器
DecompileEngineCenter.instance.registerDecompiler(
  DecompilerType.jadx,
  CustomJadxWrapper(),
);
```

### 批量反编译

```dart
final apkFiles = ['/path/to/app1.apk', '/path/to/app2.apk'];
final results = await Future.wait(
  apkFiles.map((path) => JadxWrapper.instance.decompileApk(path)),
);
```

## 相关链接

- [Jadx 官方仓库](https://github.com/skylot/jadx)
- [JD-Core 官方仓库](https://github.com/java-decompiler/jd-core)
- [项目技术方案](./技术方案.md)
