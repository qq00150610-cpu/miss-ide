// lib/engine/resources/xml_decoder.dart - 二进制 XML 解码器
import 'dart:io';
import 'dart:typed_data';

/// XML 节点类型
enum XmlNodeType {
  element,
  attribute,
  text,
  cdata,
  comment,
  declaration,
  unknown,
}

/// XML 属性
class XmlAttribute {
  final String namespace;
  final String name;
  final String? value;
  final int rawValueIndex;

  const XmlAttribute({
    this.namespace = '',
    required this.name,
    this.value,
    this.rawValueIndex = -1,
  });
}

/// XML 节点
class XmlNode {
  final String name;
  final XmlNodeType type;
  final List<XmlAttribute> attributes;
  final List<XmlNode> children;
  final String? textContent;
  final int lineNumber;

  const XmlNode({
    required this.name,
    this.type = XmlNodeType.element,
    this.attributes = const [],
    this.children = const [],
    this.textContent,
    this.lineNumber = 0,
  });

  String toFormattedXml({int indent = 0}) {
    final prefix = '  ' * indent;
    final buffer = StringBuffer();

    if (type == XmlNodeType.text || type == XmlNodeType.cdata) {
      buffer.write(textContent ?? '');
      return buffer.toString();
    }

    buffer.write('$prefix<$name');
    
    for (final attr in attributes) {
      final ns = attr.namespace.isNotEmpty ? '${attr.namespace}:' : '';
      if (attr.value != null) {
        buffer.write(' $ns${attr.name}="${_escapeXml(attr.value!)}"');
      } else {
        buffer.write(' $ns${attr.name}');
      }
    }

    if (children.isEmpty && (textContent == null || textContent!.isEmpty)) {
      buffer.write(' />');
    } else {
      buffer.write('>');
      if (textContent != null && textContent!.isNotEmpty) {
        buffer.write(_escapeXml(textContent!));
      }
      for (final child in children) {
        buffer.writeln();
        buffer.write(child.toFormattedXml(indent: indent + 1));
      }
      buffer.write('$prefix</$name>');
    }

    return buffer.toString();
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

/// XML 解析结果
class XmlDecodeResult {
  final bool success;
  final XmlNode? root;
  final Map<int, String> stringPool;
  final List<String> namespaces;
  final String? error;

  const XmlDecodeResult({
    this.success = false,
    this.root,
    this.stringPool = const {},
    this.namespaces = const [],
    this.error,
  });
}

/// 二进制 XML 解码器
class XmlDecoder {
  static const int _magicNumber = 0x000C3C3D;
  static const int _chunkHeaderSize = 8;

  /// 解码二进制 XML 文件
  XmlDecodeResult decode(Uint8List bytes) {
    if (bytes.length < 8) {
      return const XmlDecodeResult(
        success: false,
        error: 'Invalid XML: file too short',
      );
    }

    // 检查 magic: 0x0003 0x001C
    final magic = bytes[0] | (bytes[1] << 8);
    if (magic != 0x0003) {
      return const XmlDecodeResult(
        success: false,
        error: 'Invalid XML: not a binary XML file',
      );
    }

    // 解析字符串池
    final stringPool = <int, String>{};
    final namespaces = <String>[];

    int offset = _readUint16(bytes, 4) * 4 + 8;
    while (offset < bytes.length - 8) {
      final chunkType = _readUint16(bytes, offset);
      final chunkSize = _readUint32(bytes, offset + 4);

      if (chunkType == 0x001C) {
        // 字符串池
        final poolResult = _parseStringPool(bytes, offset);
        stringPool.addAll(poolResult.strings);
        offset += chunkSize;
      } else if (chunkType == 0x0010) {
        // XML 节点树
        final treeResult = _parseXmlTree(bytes, offset + 8, stringPool);
        return XmlDecodeResult(
          success: true,
          root: treeResult.root,
          stringPool: stringPool,
          namespaces: namespaces,
        );
      } else {
        offset += chunkSize;
      }
    }

    return const XmlDecodeResult(
      success: false,
      error: 'Failed to parse XML structure',
    );
  }

  /// 从文件解码
  XmlDecodeResult decodeFile(String filePath) {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      return decode(bytes);
    } catch (e) {
      return XmlDecodeResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  _StringPoolResult _parseStringPool(Uint8List bytes, int offset) {
    final strings = <int, String>{};
    
    // 字符串池头部
    final stringCount = _readUint32(bytes, offset + 12);
    final styleCount = _readUint32(bytes, offset + 16);
    final flags = _readUint32(bytes, offset + 20);
    final stringsStart = _readUint32(bytes, offset + 28);
    final stylesStart = _readUint32(bytes, offset + 32);

    final isUtf8 = (flags & (1 << 8)) != 0;
    
    int strOffset = offset + stringsStart;
    for (var i = 0; i < stringCount && strOffset < bytes.length; i++) {
      final stringResult = _readString(bytes, strOffset, isUtf8);
      strings[i] = stringResult.value;
      strOffset = stringResult.nextOffset;
    }

    return _StringPoolResult(strings: strings);
  }

  _StringReadResult _readString(Uint8List bytes, int offset, bool isUtf8) {
    int ch;
    int len;
    
    if (isUtf8) {
      ch = bytes[offset];
      len = ch & 0x7F;
      if ((ch & 0x80) != 0) {
        ch = bytes[offset + 1];
        len = ((ch & 0x3F) << 7) | (len & 0x7F);
      }
    } else {
      ch = bytes[offset] | (bytes[offset + 1] << 8);
      len = ch & 0x7FFF;
    }

    final buffer = StringBuffer();
    int pos = offset + (isUtf8 ? (len < 0x80 ? 1 : 2) : (len < 0x8000 ? 2 : 4));
    
    for (var i = 0; i < len && pos < bytes.length; i++) {
      ch = bytes[pos++];
      if (isUtf8) {
        if ((ch & 0x80) != 0) {
          if ((ch & 0xE0) == 0xC0) {
            ch = ((ch & 0x1F) << 6) | (bytes[pos++] & 0x3F);
          } else if ((ch & 0xF0) == 0xE0) {
            ch = ((ch & 0x0F) << 12) |
                ((bytes[pos++] & 0x3F) << 6) |
                (bytes[pos++] & 0x3F);
          }
        }
      }
      buffer.writeCharCode(ch);
    }

    return _StringReadResult(
      value: buffer.toString(),
      nextOffset: pos + (isUtf8 ? 1 : 2),
    );
  }

  _XmlTreeResult _parseXmlTree(
    Uint8List bytes,
    int offset,
    Map<int, String> stringPool,
  ) {
    // 简化实现
    return _XmlTreeResult(root: const XmlNode(name: 'root'));
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

  /// 将解码后的 XML 转换为格式化字符串
  String toFormattedString(XmlDecodeResult result) {
    if (!result.success || result.root == null) {
      return '<!-- Error: ${result.error ?? "Parse failed"} -->';
    }
    return result.root!.toFormattedXml();
  }
}

class _StringPoolResult {
  final Map<int, String> strings;
  const _StringPoolResult({required this.strings});
}

class _XmlTreeResult {
  final XmlNode? root;
  const _XmlTreeResult({this.root});
}

class _StringReadResult {
  final String value;
  final int nextOffset;
  const _StringReadResult({required this.value, required this.nextOffset});
}
