// lib/engine/decompile/smali_generator.dart - Smali 代码生成器
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;

/// Smali 指令类型
enum SmaliOpCode {
  // 数据操作
  move, moveWide, moveObject,
  moveResult, moveResultWide, moveResultObject,
  
  // 返回指令
  returnVoid, return_, returnWide, returnObject,
  
  // 方法调用
  invokeVirtual, invokeSuper, invokeDirect, invokeStatic, invokeInterface,
  invokeVirtualRange, invokeSuperRange, invokeDirectRange, invokeStaticRange, invokeInterfaceRange,
  
  // 字段操作
  iget, igetWide, igetObject, igetBoolean, igetByte, igetShort,
  iput, iputWide, iputObject, iputBoolean, iputByte, iputShort,
  sget, sgetWide, sgetObject, sgetBoolean, sgetByte, sgetShort,
  sput, sputWide, sputObject, sputBoolean, sputByte, sputShort,
  
  // 方法调用结果
  moveException,
  
  // 其他
  nop, goto, goto16, goto32,
  ifEq, ifNe, ifLt, ifGe, ifGt, ifLe,
  ifEqz, ifNez, ifLtz, ifGez, ifGtz, ifLez,
  arrayLength, newInstance, newArray,
  filledNewArray, filledNewArrayRange,
  
  // 数据
  const_, constWide, constWide16, constWide32, constWideHigh16,
  constHigh16, const4, const16, constString, constStringJumbo,
  constClass, monitorEnter, monitorExit,
  
  // 一元运算
  negInt, notInt, negLong, notLong, negFloat, negDouble,
  intToLong, intToFloat, intToDouble,
  longToInt, longToFloat, longToDouble,
  floatToInt, floatToLong, floatToDouble,
  doubleToInt, doubleToLong, doubleToFloat,
  
  // 二元运算
  addInt, subInt, mulInt, divInt, remInt, andInt, orInt, xorInt, shlInt, shrInt, ushrInt,
  addLong, subLong, mulLong, divLong, remLong, andLong, orLong, xorLong, shlLong, shrLong, ushrLong,
  addFloat, subFloat, mulFloat, divFloat, remFloat,
  addDouble, subDouble, mulDouble, divDouble, remDouble,
  
  // 类型转换
  addIntLit16, rsubInt, addIntLit8, rsubIntLit8,
  andIntLit16, orIntLit16, xorIntLit16,
  andIntLit8, orIntLit8, xorIntLit8,
  shlIntLit8, shrIntLit8, ushrIntLit8,
  
  // 未识别
  unknown,
}

/// Smali 寄存器类型
enum RegisterType {
  normal,
  wide,
  object,
}

/// DEX 指令信息
class DexInstruction {
  final int opcode;
  final int operands;
  final Uint8List data;

  const DexInstruction({
    required this.opcode,
    this.operands = 0,
    this.data = const [],
  });
}

/// Smali 方法信息
class SmaliMethod {
  final String name;
  final String descriptor;
  final String accessFlags;
  final List<String> registers;
  final List<String> instructions;
  final List<SmaliMethod> nestedMethods;
  final List<SmaliClass> nestedClasses;

  const SmaliMethod({
    required this.name,
    required this.descriptor,
    this.accessFlags = '',
    this.registers = const [],
    this.instructions = const [],
    this.nestedMethods = const [],
    this.nestedClasses = const [],
  });

  String toSmali() {
    final buffer = StringBuffer();
    buffer.writeln('.method $accessFlags $name$descriptor');
    
    if (registers.isNotEmpty) {
      buffer.writeln('.registers ${registers.length}');
    }
    
    for (final instruction in instructions) {
      buffer.writeln('    $instruction');
    }
    
    buffer.writeln('.end method');
    return buffer.toString();
  }
}

/// Smali 字段信息
class SmaliField {
  final String name;
  final String type;
  final String accessFlags;
  final String? value;

  const SmaliField({
    required this.name,
    required this.type,
    this.accessFlags = '',
    this.value,
  });

  String toSmali() {
    final buffer = StringBuffer('.field ');
    if (accessFlags.isNotEmpty) {
      buffer.write('$accessFlags ');
    }
    buffer.write('$name:$type');
    if (value != null) {
      buffer.write(' = $value');
    }
    return buffer.toString();
  }
}

/// Smali 类信息
class SmaliClass {
  final String className;
  final String superClass;
  final List<String> interfaces;
  final List<String> sourceFile;
  final List<SmaliField> fields;
  final List<SmaliMethod> methods;
  final List<SmaliAnnotation> annotations;
  final List<SmaliData> staticData;

  const SmaliClass({
    required this.className,
    this.superClass = '',
    this.interfaces = const [],
    this.sourceFile = const [],
    this.fields = const [],
    this.methods = const [],
    this.annotations = const [],
    this.staticData = const [],
  });

  String toSmali() {
    final buffer = StringBuffer();
    
    // 类头部
    buffer.writeln('.class $className');
    if (superClass.isNotEmpty) {
      buffer.writeln('.super $superClass');
    }
    
    // 接口
    for (final iface in interfaces) {
      buffer.writeln('.implements $iface');
    }
    
    // 源文件
    if (sourceFile.isNotEmpty) {
      buffer.writeln('.source "${sourceFile.join(', ')}"');
    }
    
    buffer.writeln();
    
    // 注解
    for (final annotation in annotations) {
      buffer.writeln(annotation.toSmali());
    }
    
    buffer.writeln();
    
    // 静态数据
    if (staticData.isNotEmpty) {
      buffer.writeln('. Annotations and static data');
      for (final data in staticData) {
        buffer.writeln(data.toSmali());
      }
      buffer.writeln();
    }
    
    // 字段
    for (final field in fields) {
      buffer.writeln(field.toSmali());
    }
    buffer.writeln();
    
    // 方法
    for (final method in methods) {
      buffer.write(method.toSmali());
      buffer.writeln();
    }
    
    return buffer.toString();
  }
}

/// Smali 注解
class SmaliAnnotation {
  final String type;
  final List<SmaliAnnotationElement> elements;

  const SmaliAnnotation({
    required this.type,
    this.elements = const [],
  });

  String toSmali() {
    final buffer = StringBuffer('.annotation system $type\n');
    for (final element in elements) {
      buffer.writeln('    ${element.toSmali()}');
    }
    buffer.write('.end annotation');
    return buffer.toString();
  }
}

/// Smali 注解元素
class SmaliAnnotationElement {
  final String name;
  final String value;

  const SmaliAnnotationElement({
    required this.name,
    required this.value,
  });

  String toSmali() => '$name = $value';
}

/// Smali 数据
class SmaliData {
  final String name;
  final dynamic value;
  final String type;

  const SmaliData({
    required this.name,
    required this.value,
    required this.type,
  });

  String toSmali() {
    if (type == 'string') {
      return '.data item\n    .string "$value"';
    } else if (type == 'int') {
      return '.data item\n    .value = ${value}i  # int';
    }
    return '.data item\n    .value = $value';
  }
}

/// Smali 生成器
class SmaliGenerator {
  /// 从 DEX 文件生成 Smali 代码
  Future<List<SmaliClass>> generateFromDex(String dexPath) async {
    final file = File(dexPath);
    if (!await file.exists()) {
      throw Exception('DEX file not found: $dexPath');
    }

    final bytes = await file.readAsBytes();
    return _parseDex(bytes);
  }

  /// 解析 DEX 字节码
  List<SmaliClass> _parseDex(Uint8List bytes) {
    // DEX 文件头验证
    if (bytes.length < 0x70) {
      throw Exception('Invalid DEX file: too short');
    }

    // 检查 magic
    final magic = String.fromCharCodes(bytes.sublist(0, 8));
    if (!magic.startsWith('dex\n')) {
      throw Exception('Invalid DEX magic: $magic');
    }

    // 读取头部信息
    final header = _DexHeader.fromBytes(bytes);
    
    // 解析字符串表
    final strings = _parseStringIds(bytes, header);
    
    // 解析类型表
    final types = _parseTypeIds(bytes, header, strings);
    
    // 解析方法原型
    final prototypes = _parseProtoIds(bytes, header, strings, types);
    
    // 解析字段
    final fields = _parseFieldIds(bytes, header, strings, types);
    
    // 解析方法
    final methods = _parseMethodIds(bytes, header, strings, types, prototypes);
    
    // 解析类
    return _parseClasses(bytes, header, strings, types, prototypes, fields, methods);
  }

  List<String> _parseStringIds(Uint8List bytes, _DexHeader header) {
    final strings = <String>[];
    final stringIdsOff = header.stringIdsOff;
    final stringIdsSize = header.stringIdsSize;

    for (var i = 0; i < stringIdsSize; i++) {
      final off = stringIdsOff + i * 4;
      final stringDataOff = _readUint32(bytes, off);
      strings.add(_readString(bytes, stringDataOff));
    }

    return strings;
  }

  List<String> _parseTypeIds(Uint8List bytes, _DexHeader header, List<String> strings) {
    final types = <String>[];
    final typeIdsOff = header.typeIdsOff;
    final typeIdsSize = header.typeIdsSize;

    for (var i = 0; i < typeIdsSize; i++) {
      final off = typeIdsOff + i * 4;
      final stringIdx = _readUint32(bytes, off);
      types.add(strings[stringIdx]);
    }

    return types;
  }

  List<SmaliMethod> _parseProtoIds(
    Uint8List bytes,
    _DexHeader header,
    List<String> strings,
    List<String> types,
  ) {
    final prototypes = <SmaliMethod>[];
    final protoIdsOff = header.protoIdsOff;
    final protoIdsSize = header.protoIdsSize;

    for (var i = 0; i < protoIdsSize; i++) {
      final off = protoIdsOff + i * 8;
      // 简化处理
      prototypes.add(SmaliMethod(
        name: 'proto_$i',
        descriptor: '()V',
      ));
    }

    return prototypes;
  }

  List<SmaliField> _parseFieldIds(
    Uint8List bytes,
    _DexHeader header,
    List<String> strings,
    List<String> types,
  ) {
    final fields = <SmaliField>[];
    final fieldIdsOff = header.fieldIdsOff;
    final fieldIdsSize = header.fieldIdsSize;

    for (var i = 0; i < fieldIdsSize; i++) {
      final off = fieldIdsOff + i * 8;
      final classIdx = _readUint16(bytes, off);
      final typeIdx = _readUint16(bytes, off + 2);
      final nameIdx = _readUint32(bytes, off + 4);
      
      fields.add(SmaliField(
        name: strings[nameIdx],
        type: types[typeIdx],
        accessFlags: _accessFlagsToString(0),
      ));
    }

    return fields;
  }

  List<SmaliMethod> _parseMethodIds(
    Uint8List bytes,
    _DexHeader header,
    List<String> strings,
    List<String> types,
    List<SmaliMethod> prototypes,
  ) {
    final methods = <SmaliMethod>[];
    final methodIdsOff = header.methodIdsOff;
    final methodIdsSize = header.methodIdsSize;

    for (var i = 0; i < methodIdsSize; i++) {
      final off = methodIdsOff + i * 8;
      final classIdx = _readUint16(bytes, off);
      final protoIdx = _readUint16(bytes, off + 2);
      final nameIdx = _readUint32(bytes, off + 4);
      
      methods.add(SmaliMethod(
        name: strings[nameIdx],
        descriptor: prototypes[protoIdx].descriptor,
      ));
    }

    return methods;
  }

  List<SmaliClass> _parseClasses(
    Uint8List bytes,
    _DexHeader header,
    List<String> strings,
    List<String> types,
    List<SmaliMethod> prototypes,
    List<SmaliField> fields,
    List<SmaliMethod> methods,
  ) {
    final classes = <SmaliClass>[];
    final classDefsOff = header.classDefsOff;
    final classDefsSize = header.classDefsSize;

    for (var i = 0; i < classDefsSize; i++) {
      final off = classDefsOff + i * 0x20;
      final classIdx = _readUint32(bytes, off);
      final accessFlags = _readUint32(bytes, off + 4);
      final superclassIdx = _readUint32(bytes, off + 8);
      final interfacesOff = _readUint32(bytes, off + 12);
      final sourceFileIdx = _readUint32(bytes, off + 16);
      final annotationsOff = _readUint32(bytes, off + 20);
      final classDataOff = _readUint32(bytes, off + 24);
      final staticValuesOff = _readUint32(bytes, off + 28);

      final className = types[classIdx];
      final superClass = superclassIdx != 0xFFFFFFFF ? types[superclassIdx] : '';
      final sourceFile = sourceFileIdx != 0xFFFFFFFF ? strings[sourceFileIdx] : '';

      // 解析接口
      final interfaces = <String>[];
      if (interfacesOff != 0) {
        final typeListOff = interfacesOff;
        final size = _readUint32(bytes, typeListOff);
        for (var j = 0; j < size; j++) {
          final idx = _readUint16(bytes, typeListOff + 4 + j * 2);
          interfaces.add(types[idx]);
        }
      }

      // 简化处理：生成基础结构
      classes.add(SmaliClass(
        className: className,
        superClass: superClass,
        interfaces: interfaces,
        sourceFile: [sourceFile],
        accessFlags: _accessFlagsToString(accessFlags),
      ));
    }

    return classes;
  }

  String _readString(Uint8List bytes, int offset) {
    final buffer = StringBuffer();
    var i = offset;
    
    // 读取 UTF-16LE 可变长编码
    while (i < bytes.length) {
      var byte = bytes[i++];
      var length = byte & 0x7F;
      
      if ((byte & 0x80) != 0) {
        byte = bytes[i++];
        length = ((byte & 0x7F) << 7) | (length & 0x7F);
      }
      
      if (length == 0) break;
      
      // 读取字符
      var ch = 0;
      if (i < bytes.length) {
        ch = bytes[i++];
        ch |= (bytes[i++] << 8);
      }
      buffer.writeCharCode(ch);
    }
    
    return buffer.toString();
  }

  int _readUint32(Uint8List bytes, int offset) {
    return bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
  }

  int _readUint16(Uint8List bytes, int offset) {
    return bytes[offset] | (bytes[offset + 1] << 8);
  }

  String _accessFlagsToString(int flags) {
    final parts = <String>[];
    if (flags & 0x01 != 0) parts.add('public');
    if (flags & 0x02 != 0) parts.add('private');
    if (flags & 0x04 != 0) parts.add('protected');
    if (flags & 0x08 != 0) parts.add('static');
    if (flags & 0x10 != 0) parts.add('final');
    if (flags & 0x20 != 0) parts.add('synchronized');
    if (flags & 0x40 != 0) parts.add('bridge');
    if (flags & 0x80 != 0) parts.add('varargs');
    if (flags & 0x100 != 0) parts.add('native');
    if (flags & 0x200 != 0) parts.add('interface');
    if (flags & 0x400 != 0) parts.add('abstract');
    if (flags & 0x800 != 0) parts.add('strictfp');
    if (flags & 0x1000 != 0) parts.add('synthetic');
    if (flags & 0x4000 != 0) parts.add('enum');
    if (flags & 0x8000 != 0) parts.add('mandatory');
    if (flags & 0x10000 != 0) parts.add('constructor');
    if (flags & 0x20000 != 0) parts.add('declared_synchronized');
    return parts.join(' ');
  }
}

/// DEX 文件头部结构
class _DexHeader {
  final Uint8List magic;
  final int checksum;
  final Uint8List signature;
  final int fileSize;
  final int headerSize;
  final int endianTag;
  final int linkSize;
  final int linkOff;
  final int mapOff;
  final int stringIdsSize;
  final int stringIdsOff;
  final int typeIdsSize;
  final int typeIdsOff;
  final int protoIdsSize;
  final int protoIdsOff;
  final int fieldIdsSize;
  final int fieldIdsOff;
  final int methodIdsSize;
  final int methodIdsOff;
  final int classDefsSize;
  final int classDefsOff;
  final int dataSize;
  final int dataOff;

  _DexHeader({
    required this.magic,
    required this.checksum,
    required this.signature,
    required this.fileSize,
    required this.headerSize,
    required this.endianTag,
    required this.linkSize,
    required this.linkOff,
    required this.mapOff,
    required this.stringIdsSize,
    required this.stringIdsOff,
    required this.typeIdsSize,
    required this.typeIdsOff,
    required this.protoIdsSize,
    required this.protoIdsOff,
    required this.fieldIdsSize,
    required this.fieldIdsOff,
    required this.methodIdsSize,
    required this.methodIdsOff,
    required this.classDefsSize,
    required this.classDefsOff,
    required this.dataSize,
    required this.dataOff,
  });

  factory _DexHeader.fromBytes(Uint8List bytes) {
    return _DexHeader(
      magic: bytes.sublist(0, 8),
      checksum: bytes[8] | (bytes[9] << 8) | (bytes[10] << 16) | (bytes[11] << 24),
      signature: bytes.sublist(12, 32),
      fileSize: _getInt32(bytes, 32),
      headerSize: _getInt32(bytes, 36),
      endianTag: _getInt32(bytes, 40),
      linkSize: _getInt32(bytes, 44),
      linkOff: _getInt32(bytes, 48),
      mapOff: _getInt32(bytes, 52),
      stringIdsSize: _getInt32(bytes, 56),
      stringIdsOff: _getInt32(bytes, 60),
      typeIdsSize: _getInt32(bytes, 64),
      typeIdsOff: _getInt32(bytes, 68),
      protoIdsSize: _getInt32(bytes, 72),
      protoIdsOff: _getInt32(bytes, 76),
      fieldIdsSize: _getInt32(bytes, 80),
      fieldIdsOff: _getInt32(bytes, 84),
      methodIdsSize: _getInt32(bytes, 88),
      methodIdsOff: _getInt32(bytes, 92),
      classDefsSize: _getInt32(bytes, 96),
      classDefsOff: _getInt32(bytes, 100),
      dataSize: _getInt32(bytes, 104),
      dataOff: _getInt32(bytes, 108),
    );
  }

  static int _getInt32(Uint8List bytes, int offset) {
    return bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
  }
}
