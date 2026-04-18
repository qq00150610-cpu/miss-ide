// lib/engine/resources/dex_analyzer.dart - DEX 结构分析器
import 'dart:io';
import 'dart:typed_data';

/// DEX 文件节信息
class DexSection {
  final String name;
  final int offset;
  final int size;
  final int count;
  final Map<String, dynamic> details;

  const DexSection({
    required this.name,
    required this.offset,
    required this.size,
    required this.count,
    this.details = const {},
  });
}

/// DEX 分析结果
class DexAnalysisResult {
  final bool success;
  final String filePath;
  final int fileSize;
  final String magic;
  final int checksum;
  final Map<String, DexSection> sections;
  final List<String> classes;
  final List<String> methods;
  final List<String> fields;
  final List<String> strings;
  final List<String> types;
  final Map<String, dynamic> metadata;
  final String? error;

  const DexAnalysisResult({
    this.success = false,
    this.filePath = '',
    this.fileSize = 0,
    this.magic = '',
    this.checksum = 0,
    this.sections = const {},
    this.classes = const [],
    this.methods = const [],
    this.fields = const [],
    this.strings = const [],
    this.types = const [],
    this.metadata = const {},
    this.error,
  });

  /// 生成分析报告
  String toReport() {
    final buffer = StringBuffer();
    buffer.writeln('# DEX Analysis Report');
    buffer.writeln();
    buffer.writeln('## Basic Information');
    buffer.writeln('- File: $filePath');
    buffer.writeln('- Size: $fileSize bytes');
    buffer.writeln('- Magic: $magic');
    buffer.writeln('- Checksum: ${checksum.toRadixString(16)}');
    buffer.writeln();
    
    buffer.writeln('## Sections');
    for (final section in sections.values) {
      buffer.writeln('- ${section.name}: offset=0x${section.offset.toRadixString(16)}, '
          'size=${section.size}, count=${section.count}');
    }
    buffer.writeln();
    
    buffer.writeln('## Statistics');
    buffer.writeln('- Classes: ${classes.length}');
    buffer.writeln('- Methods: ${methods.length}');
    buffer.writeln('- Fields: ${fields.length}');
    buffer.writeln('- Strings: ${strings.length}');
    buffer.writeln('- Types: ${types.length}');
    buffer.writeln();
    
    if (classes.isNotEmpty) {
      buffer.writeln('## Classes (first 50)');
      for (final cls in classes.take(50)) {
        buffer.writeln('- $cls');
      }
      if (classes.length > 50) {
        buffer.writeln('- ... and ${classes.length - 50} more');
      }
      buffer.writeln();
    }
    
    return buffer.toString();
  }
}

/// DEX 结构分析器
class DexAnalyzer {
  /// 分析 DEX 文件
  DexAnalysisResult analyze(Uint8List bytes, String filePath) {
    if (bytes.length < 0x70) {
      return DexAnalysisResult(
        success: false,
        filePath: filePath,
        fileSize: bytes.length,
        error: 'Invalid DEX: file too short',
      );
    }

    // 验证 magic
    final magic = String.fromCharCodes(bytes.sublist(0, 7));
    if (!magic.startsWith('dex\n')) {
      return DexAnalysisResult(
        success: false,
        filePath: filePath,
        fileSize: bytes.length,
        error: 'Invalid DEX magic: $magic',
      );
    }

    final fileSize = bytes.length;
    final checksum = _readUint32(bytes, 8);
    final sections = <String, DexSection>{};
    final strings = <String>[];
    final types = <String>[];
    final classes = <String>[];
    final methods = <String>[];
    final fields = <String>[];

    // 读取各个表的信息
    final stringIdsSize = _readUint32(bytes, 56);
    final stringIdsOff = _readUint32(bytes, 60);
    final typeIdsSize = _readUint32(bytes, 64);
    final typeIdsOff = _readUint32(bytes, 68);
    final protoIdsSize = _readUint32(bytes, 72);
    final protoIdsOff = _readUint32(bytes, 76);
    final fieldIdsSize = _readUint32(bytes, 80);
    final fieldIdsOff = _readUint32(bytes, 84);
    final methodIdsSize = _readUint32(bytes, 88);
    final methodIdsOff = _readUint32(bytes, 92);
    final classDefsSize = _readUint32(bytes, 96);
    final classDefsOff = _readUint32(bytes, 100);
    final dataSize = _readUint32(bytes, 104);
    final dataOff = _readUint32(bytes, 108);

    // 解析字符串表
    for (var i = 0; i < stringIdsSize; i++) {
      final off = stringIdsOff + i * 4;
      final stringDataOff = _readUint32(bytes, off);
      strings.add(_readDexString(bytes, stringDataOff));
    }

    // 解析类型表
    for (var i = 0; i < typeIdsSize; i++) {
      final off = typeIdsOff + i * 4;
      final stringIdx = _readUint32(bytes, off);
      if (stringIdx < strings.length) {
        types.add(strings[stringIdx]);
      }
    }

    // 解析字段表
    for (var i = 0; i < fieldIdsSize; i++) {
      final off = fieldIdsOff + i * 8;
      final typeIdx = _readUint16(bytes, off + 2);
      final nameIdx = _readUint32(bytes, off + 4);
      final typeName = typeIdx < types.length ? types[typeIdx] : 'unknown';
      final name = nameIdx < strings.length ? strings[nameIdx] : 'unknown';
      fields.add('$typeName $name');
    }

    // 解析方法表
    for (var i = 0; i < methodIdsSize; i++) {
      final off = methodIdsOff + i * 8;
      final classIdx = _readUint16(bytes, off);
      final protoIdx = _readUint16(bytes, off + 2);
      final nameIdx = _readUint32(bytes, off + 4);
      final className = classIdx < types.length ? types[classIdx] : 'unknown';
      final name = nameIdx < strings.length ? strings[nameIdx] : 'unknown';
      methods.add('$className.$name()');
    }

    // 解析类定义
    for (var i = 0; i < classDefsSize; i++) {
      final off = classDefsOff + i * 0x20;
      final classIdx = _readUint32(bytes, off);
      final className = classIdx < types.length ? types[classIdx] : 'unknown';
      classes.add(className);
    }

    // 构建节信息
    sections['header'] = DexSection(
      name: 'header',
      offset: 0,
      size: 0x70,
      count: 1,
      details: {
        'magic': magic,
        'checksum': checksum,
        'fileSize': fileSize,
      },
    );

    sections['string_ids'] = DexSection(
      name: 'string_ids',
      offset: stringIdsOff,
      size: stringIdsSize * 4,
      count: stringIdsSize,
    );

    sections['type_ids'] = DexSection(
      name: 'type_ids',
      offset: typeIdsOff,
      size: typeIdsSize * 4,
      count: typeIdsSize,
    );

    sections['proto_ids'] = DexSection(
      name: 'proto_ids',
      offset: protoIdsOff,
      size: protoIdsSize * 12,
      count: protoIdsSize,
    );

    sections['field_ids'] = DexSection(
      name: 'field_ids',
      offset: fieldIdsOff,
      size: fieldIdsSize * 8,
      count: fieldIdsSize,
    );

    sections['method_ids'] = DexSection(
      name: 'method_ids',
      offset: methodIdsOff,
      size: methodIdsSize * 8,
      count: methodIdsSize,
    );

    sections['class_defs'] = DexSection(
      name: 'class_defs',
      offset: classDefsOff,
      size: classDefsSize * 0x20,
      count: classDefsSize,
    );

    sections['data'] = DexSection(
      name: 'data',
      offset: dataOff,
      size: dataSize,
      count: 1,
    );

    return DexAnalysisResult(
      success: true,
      filePath: filePath,
      fileSize: fileSize,
      magic: magic,
      checksum: checksum,
      sections: sections,
      classes: classes,
      methods: methods,
      fields: fields,
      strings: strings,
      types: types,
      metadata: {
        'version': _getDexVersion(magic),
        'endianTag': _readUint32(bytes, 40),
      },
    );
  }

  /// 从文件分析
  DexAnalysisResult analyzeFile(String filePath) {
    try {
      final file = File(filePath);
      final bytes = file.readAsBytesSync();
      return analyze(Uint8List.fromList(bytes), filePath);
    } catch (e) {
      return DexAnalysisResult(
        success: false,
        filePath: filePath,
        error: e.toString(),
      );
    }
  }

  String _readDexString(Uint8List bytes, int offset) {
    final buffer = StringBuffer();
    var i = offset;
    
    while (i < bytes.length) {
      var byte = bytes[i++];
      var length = byte & 0x7F;
      
      if ((byte & 0x80) != 0) {
        byte = bytes[i++];
        length = ((byte & 0x7F) << 7) | (length & 0x7F);
      }
      
      if (length == 0) break;
      
      var ch = 0;
      if (i < bytes.length) {
        ch = bytes[i++];
        ch |= (bytes[i++] << 8);
      }
      buffer.writeCharCode(ch);
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

  String _getDexVersion(String magic) {
    if (magic.contains('035')) return '1.0';
    if (magic.contains('037')) return '1.5';
    if (magic.contains('038')) return '2.0';
    if (magic.contains('039')) return '3.0';
    if (magic.contains('035')) return '3.1';
    if (magic.contains('036')) return '3.2';
    return 'unknown';
  }
}
