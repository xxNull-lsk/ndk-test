import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef Hello = Pointer<Utf8> Function(Pointer<Utf8> str);

class HelloNative {
  final DynamicLibrary dylib = Platform.isAndroid
      ? DynamicLibrary.open("libhello.so")
      : DynamicLibrary.process();
  late Hello fnHello;
  HelloNative() {
    fnHello = dylib.lookupFunction<Hello, Hello>('hello');
  }

  String hello(String msg) {
    final msgUtf8 = msg.toNativeUtf8();
    final ret = fnHello(msgUtf8).toDartString();

    calloc.free(msgUtf8);

    return ret;
  }
}
