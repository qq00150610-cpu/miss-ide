// lib/engine/decompile/format_converter.dart - 格式转换器
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'smali_generator.dart';

/// 转换类型枚举
enum ConversionType {
  dexToSmali,
  dexToJava,
  apkToSmali,
  apkToAnalysis,
  dexToHex,
  hexToDex,
}

/// 转换任务状态
enum ConversionStatus {
  pending,
  processing,
  completed,
  failed,
}

/// 转换结果
class ConversionResult {
  final bool success;
  final String outputPath;
  final String? error;
  final Map<String, dynamic> metadata;

  const ConversionResult({
    required this.success,
    this.outputPath = '',
    this.error,
    this.metadata = const {},
  });
}

/// 格式转换器
class FormatConverter {
  final SmaliGenerator _smaliGenerator = SmaliGenerator();

  /// 转换文件格式
  Future<ConversionResult> convert(
    String inputPath,
    ConversionType type, {
    String? outputPath,
    Map<String, dynamic>? options,
  }) async {
    try {
      final inputFile = File(inputPath);
      if (!await inputFile.exists()) {
        return ConversionResult(
          success: false,
          error: 'Input file not found: $inputPath',
        );
      }

      final outPath = outputPath ?? _generateOutputPath(inputPath, type);
      
      switch (type) {
        case ConversionType.dexToSmali:
          return await _dexToSmali(inputPath, outPath, options);
        case ConversionType.dexToJava:
          return await _dexToJava(inputPath, outPath);
        case ConversionType.apkToSmali:
          return await _apkToSmali(inputPath, outPath);
        case ConversionType.apkToAnalysis:
          return await _apkToAnalysis(inputPath, outPath);
        case ConversionType.dexToHex:
          return await _dexToHex(inputPath, outPath);
        case ConversionType.hexToDex:
          return await _hexToDex(inputPath, outPath);
      }
    } catch (e) {
      return ConversionResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// DEX 转 Smali
  Future<ConversionResult> _dexToSmali(
    String inputPath,
    String outputPath,
    Map<String, dynamic>? options,
  ) async {
    final classes = await _smaliGenerator.generateFromDex(inputPath);
    
    final outputDir = Directory(outputPath);
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    int count = 0;
    for (final cls in classes) {
      final classFileName = cls.className.replaceAll('.', '/') + '.smali';
      final file = File(p.join(outputPath, classFileName));
      await file.parent.create(recursive: true);
      await file.writeAsString(cls.toSmali());
      count++;
    }

    return ConversionResult(
      success: true,
      outputPath: outputPath,
      metadata: {
        'classCount': count,
        'inputFile': inputPath,
        'outputDir': outputPath,
      },
    );
  }

  /// DEX 转 Java（需要jadx）
  Future<ConversionResult> _dexToJava(String inputPath, String outputPath) async {
    // 使用 JadxWrapper 进行转换
    // 这里简化处理，实际会调用 jadx_wrapper.dart
    return ConversionResult(
      success: false,
      error: 'DEX to Java requires Jadx engine. Use JadxWrapper directly.',
    );
  }

  /// APK 转 Smali
  Future<ConversionResult> _apkToSmali(
    String inputPath,
    String outputPath,
  ) async {
    // 1. 解压 APK
    // 2. 找到所有 DEX 文件
    // 3. 转换为 Smali
    return ConversionResult(
      success: false,
      error: 'APK to Smali conversion requires apktool. Use external tools.',
    );
  }

  /// APK 转分析报告
  Future<ConversionResult> _apkToAnalysis(
    String inputPath,
    String outputPath,
  ) async {
    final report = StringBuffer();
    report.writeln('# APK Analysis Report');
    report.writeln('Generated at: ${DateTime.now()}');
    report.writeln();

    // 基本信息
    report.writeln('## Basic Information');
    report.writeln('- Input: $inputPath');
    final file = File(inputPath);
    report.writeln('- Size: ${await file.length()} bytes');
    report.writeln();

    // DEX 文件信息
    report.writeln('## DEX Files');
    
    // 生成报告文件
    final outputFile = File(outputPath);
    await outputFile.writeAsString(report.toString());

    return ConversionResult(
      success: true,
      outputPath: outputPath,
      metadata: {
        'fileSize': await file.length(),
      },
    );
  }

  /// DEX 转十六进制
  Future<ConversionResult> _dexToHex(String inputPath, String outputPath) async {
    final bytes = await File(inputPath).readAsBytes();
    final buffer = StringBuffer();
    
    for (var i = 0; i < bytes.length; i++) {
      if (i % 16 == 0) {
        if (i > 0) buffer.writeln();
        buffer.write('${i.toRadixString(16).padLeft(8, '0')}: ');
      }
      buffer.write(bytes[i].toRadixString(16).padLeft(2, '0'));
      buffer.write(' ');
    }

    final outputFile = File(outputPath);
    await outputFile.writeAsString(buffer.toString());

    return ConversionResult(
      success: true,
      outputPath: outputPath,
      metadata: {'byteCount': bytes.length},
    );
  }

  /// 十六进制转 DEX
  Future<ConversionResult> _hexToDex(String inputPath, String outputPath) async {
    final content = await File(inputPath).readAsString();
    final bytes = <int>[];

    // 解析十六进制内容
    final hexPattern = RegExp(r'([0-9a-fA-F]{2})');
    for (final match in hexPattern.allMatches(content)) {
      bytes.add(int.parse(match.group(1)!, radix: 16));
    }

    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(Uint8List.fromList(bytes));

    return ConversionResult(
      success: true,
      outputPath: outputPath,
      metadata: {'byteCount': bytes.length},
    );
  }

  String _generateOutputPath(String inputPath, ConversionType type) {
    final dir = Directory(inputPath).parent.path;
    final basename = p.basenameWithoutExtension(inputPath);
    
    switch (type) {
      case ConversionType.dexToSmali:
        return p.join(dir, '${basename}_smali');
      case ConversionType.dexToJava:
        return p.join(dir, '${basename}_java');
      case ConversionType.apkToSmali:
        return p.join(dir, '${basename}_smali');
      case ConversionType.apkToAnalysis:
        return p.join(dir, '${basename}_analysis.md');
      case ConversionType.dexToHex:
        return p.join(dir, '${basename}.hex');
      case ConversionType.hexToDex:
        return p.join(dir, '${basename}.dex');
    }
  }

  /// 批量转换
  Future<List<ConversionResult>> batchConvert(
    List<String> inputPaths,
    ConversionType type, {
    String? outputDirectory,
  }) async {
    final results = <ConversionResult>[];
    for (final path in inputPaths) {
      final output = outputDirectory != null
          ? p.join(outputDirectory, p.basename(path))
          : null;
      final result = await convert(path, type, outputPath: output);
      results.add(result);
    }
    return results;
  }
}
