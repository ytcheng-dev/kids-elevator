import 'dart:io';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';


class MockAudioPlayersPlatform {
  MockAudioPlayersPlatform();

  static const globalChannel = MethodChannel('xyz.luan/audioplayers.global'),
              perChannel = MethodChannel('xyz.luan/audioplayers'),
              pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  EventChannel? eventChannel;

  List<MethodCall> globalMethodList = [],
                   perMethodList = [];

  late String playerId;
  MockStreamHandlerEventSink? eventPipeline;

  late Directory tempDir;

  final _resumeCompleter = Completer<void>(),
        _setAudioContextCompleter = Completer<void>();

  Future<void> init() async {
    tempDir = await Directory.systemTemp.createTemp('flutter-elevator-tester');

    TestWidgetsFlutterBinding.ensureInitialized();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(globalChannel, (MethodCall call) async {
      globalMethodList.add(call);

      if (call.method == 'init') {
        return null;
      }

      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(perChannel, (MethodCall call) async {
      perMethodList.add(call);

      if (call.method == 'create') {
        playerId = call.arguments['playerId'];
        eventChannel = EventChannel('xyz.luan/audioplayers/events/$playerId');

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler(eventChannel!, MockStreamHandler.inline(
          onListen:(arguments, events) {
            eventPipeline = events;
          },
        ));

        return null;
      }
      else if (call.method == 'setAudioContext') {
        _setAudioContextCompleter.complete();
        return null;
      }
      else if (call.method == 'setSourceUrl') {
        pushPrepared();
        return null;
      }
      else if (call.method == 'resume') {
        if (!_resumeCompleter.isCompleted) {
          _resumeCompleter.complete();
        }
        return null;
      }

      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(pathProviderChannel, (MethodCall call) async {
      if (call.method == 'getTemporaryDirectory') {
        return tempDir.path;
      }
    });
  }

  Future<void> dispose() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(globalChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(perChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(pathProviderChannel, null);

    if (eventChannel != null) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler(eventChannel!, null);
    }

    await tempDir.delete(recursive: true);
  }

  void pushPrepared() {
    eventPipeline!.success({'event': 'audio.onPrepared', 'value': true});
  }

  void pushComplete() {
    eventPipeline!.success({'event': 'audio.onComplete'});
  }

  Future<void> waitForSetAudioContext() {
    return _setAudioContextCompleter.future.timeout(const Duration(seconds: 3));
  }

  Future<void> waitForResume() {
    return _resumeCompleter.future.timeout(const Duration(seconds: 3));
  }
}