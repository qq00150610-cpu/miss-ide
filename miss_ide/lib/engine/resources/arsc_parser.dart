// lib/engine/resources/arsc_parser.dart - resources.arsc 资源表解析器
import 'dart:io';
import 'dart:typed_data';

/// 资源表类型
enum ResourceType {
  string,
  int_,
  color,
  bool_,
  dimen,
  float_,
  style,
  array,
  plurals,
  layout,
  drawable,
  menu,
  xml,
  unknown,
}

/// 资源配置
class ResourceConfig {
  final int size;
  final int mcc;
  final int mnc;
  final String language;
  final String country;
  final int orientation;
  final int touchscreen;
  final int density;
  final int keyboard;
  final int navigation;
  final int screenWidth;
  final int screenHeight;
  final int sdkVersion;
  final int minorVersion;

  const ResourceConfig({
    this.size = 0,
    this.mcc = 0,
    this.mnc = 0,
    this.language = '',
    this.country = '',
    this.orientation = 0,
    this.touchscreen = 0,
    this.density = 0,
    this.keyboard = 0,
    this.navigation = 0,
    this.screenWidth = 0,
    this.screenHeight = 0,
    this.sdkVersion = 0,
    this.minorVersion = 0,
  });
}

/// 资源条目
class ResourceEntry {
  final int offset;
  final int size;
  final dynamic value;
  final ResourceConfig config;

  const ResourceEntry({
    required this.offset,
    this.size = 0,
    this.value,
    this.config = const ResourceConfig(),
  });
}

/// 资源池条目
class ResourcePoolEntry {
  final int index;
  final String key;
  final ResourceType type;
  final Map<ResourceConfig, ResourceEntry> entries;

  const ResourcePoolEntry({
    required this.index,
    required this.key,
    required this.type,
    this.entries = const {},
  });
}

/// ARSC 解析结果
class ArscParseResult {
  final bool success;
  final List<String> packageNames;
  final Map<String, List<ResourcePoolEntry>> resources;
  final Map<int, String> stringPool;
  final Map<int, String> typeNames;
  final String? error;

  const ArscParseResult({
    this.success = false,
    this.packageNames = const [],
    this.resources = const {},
    this.stringPool = const {},
    this.typeNames = const {},
    this.error,
  });
}

/// ARSC 资源表解析器
class ArscParser {
  /// 解析 resources.arsc 文件
  Future<ArscParseResult> parse(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return const ArscParseResult(
          success: false,
          error: 'File not found',
        );
      }

      final bytes = await file.readAsBytes();
      return _parseBytes(bytes);
    } catch (e) {
      return ArscParseResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// 从字节数据解析
  ArscParseResult _parseBytes(Uint8List bytes) {
    if (bytes.length < 12) {
      return const ArscParseResult(
        success: false,
        error: 'Invalid ARSC: file too short',
      );
    }

    // 验证 magic: "RES\xAD"
    if (bytes[0] != 0x52 || bytes[1] != 0x45 || bytes[2] != 0x53 || bytes[3] != 0x41) {
      return const ArscParseResult(
        success: false,
        error: 'Invalid ARSC magic',
      );
    }

    final result = ArscParseResult(success: true);

    // 解析资源表头部
    final resourceTableCount = _readUint16(bytes, 10);

    // 解析每个资源表
    int offset = 12;
    final packages = <String>[];
    final resources = <String, List<ResourcePoolEntry>>{};

    for (var i = 0; i < resourceTableCount && offset < bytes.length; i++) {
      final packageResult = _parsePackage(bytes, offset);
      if (packageResult != null) {
        packages.add(packageResult.name);
        resources[packageResult.name] = packageResult.entries;
        offset = packageResult.nextOffset;
      }
    }

    return ArscParseResult(
      success: true,
      packageNames: packages,
      resources: resources,
    );
  }

  _PackageResult? _parsePackage(Uint8List bytes, int offset) {
    if (offset + 12 > bytes.length) return null;

    final typeCount = _readUint16(bytes, offset + 10);
    final lastPublicType = _readUint16(bytes, offset + 12);
    final lastPublicKey = _readUint16(bytes, offset + 14);

    // 解析包名
    final packageName = _readString16(bytes, offset + 4, 256);
    final entries = <ResourcePoolEntry>[];

    offset += 16 + 256; // 跳过包头和类型字符串偏移表

    // 跳过键字符串池
    final keyStringsOffset = _readUint32(bytes, offset);
    offset = keyStringsOffset;

    // 简化：返回基本结构
    return _PackageResult(
      name: packageName,
      entries: entries,
      nextOffset: offset + 1000,
    );
  }

  String _readString16(Uint8List bytes, int offset, int maxLen) {
    final buffer = StringBuffer();
    for (var i = 0; i < maxLen && offset + i * 2 + 1 < bytes.length; i++) {
      final char = _readUint16(bytes, offset + i * 2);
      if (char == 0) break;
      buffer.writeCharCode(char);
    }
    return buffer.toString();
  }

  int _readUint16(Uint8List bytes, int offset) {
    return bytes[offset] | (bytes[offset + 1] << 8);
  }

  int _readUint32(Uint8List bytes, int offset) {
    return bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
  }

  /// 导出资源为可读格式
  Future<String> exportToReadable(String arscPath, String outputPath) async {
    final result = await parse(arscPath);
    if (!result.success) {
      throw Exception(result.error ?? 'Parse failed');
    }

    final buffer = StringBuffer();
    buffer.writeln('# ARSC Resource Export');
    buffer.writeln('# Generated: ${DateTime.now()}');
    buffer.writeln();

    for (final packageName in result.packageNames) {
      buffer.writeln('## Package: $packageName');
      
      final entries = result.resources[packageName];
      if (entries != null) {
        for (final entry in entries) {
          buffer.writeln('  ${entry.key}: ${entry.type}');
        }
      }
      buffer.writeln();
    }

    final outputFile = File(outputPath);
    await outputFile.writeAsString(buffer.toString());
    
    return outputPath;
  }

  /// 获取特定资源值
  Future<String?> getResourceValue(
    String arscPath,
    String resourceType,
    String resourceName,
  ) async {
    final result = await parse(arscPath);
    if (!result.success) return null;

    for (final entries in result.resources.values) {
      for (final entry in entries) {
        if (entry.key == resourceName && entry.type.name == resourceType) {
          return entry.entries.values.first.value?.toString();
        }
      }
    }
    return null;
  }
}

class _PackageResult {
  final String name;
  final List<ResourcePoolEntry> entries;
  final int nextOffset;

  const _PackageResult({
    required this.name,
    required this.entries,
    required this.nextOffset,
  });
}
