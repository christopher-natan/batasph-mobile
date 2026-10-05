import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:batasph_mobile/config/theme/my_theme.dart';
import 'package:batasph_mobile/data/local/my_shared_pref.dart';
import 'package:batasph_mobile/pages/home/home_controller.dart';
import 'package:batasph_mobile/pages/home/home_page.dart';
import 'package:batasph_mobile/pages/splash/splash_page.dart';
import 'package:batasph_mobile/pages/voice_chat/services/voice_call_audio_service.dart';
import 'package:batasph_mobile/pages/voice_chat/voice_chat_controller.dart';
import 'package:batasph_mobile/pages/voice_chat/voice_chat_page.dart';

const _previewKey = ValueKey('design-preview');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = FontLoader('Poppins')
      ..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Poppins-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Poppins-SemiBold.ttf'));
    await fonts.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    await MySharedPref.init();
  });
  tearDown(() async => Get.reset());

  Future<void> showPage(WidgetTester tester, Widget page, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) => RepaintBoundary(
          key: _previewKey,
          child: GetMaterialApp(
            debugShowCheckedModeBanner: false,
            theme: MyTheme.getThemeData(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(padding: const EdgeInsets.only(top: 24, bottom: 20)),
              child: child!,
            ),
            home: page,
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/logo.png'),
        tester.element(find.byType(Scaffold).first),
      );
      await precacheImage(
        const ResizeImage(
          AssetImage('assets/images/avatars/luna_face.jpg'),
          width: 768,
        ),
        tester.element(find.byType(Scaffold).first),
      );
    });
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }

  Future<void> savePreview(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('WRITE_DESIGN_PREVIEWS')) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_previewKey),
    );
    void repaint(RenderObject object) {
      object.markNeedsPaint();
      object.visitChildren(repaint);
    }

    debugDisableShadows = false;
    try {
      repaint(boundary);
      await tester.pump();
      await tester.runAsync(() async {
        await precacheImage(
          const AssetImage('assets/images/logo.png'),
          tester.element(find.byType(Scaffold).first),
        );
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('docs/design-previews/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    } finally {
      debugDisableShadows = true;
      repaint(boundary);
      await tester.pump();
    }
  }

  PreviewCallController registerCall() {
    Get.put(VoiceCallAudioService());
    final controller = PreviewCallController();
    Get.put<VoiceChatController>(controller);
    return controller;
  }

  testWidgets('splash displays the selected brand', (tester) async {
    await showPage(tester, const SplashPage(), const Size(390, 844));
    expect(find.bySemanticsLabel('BatasPH'), findsOneWidget);
    await savePreview(tester, '00-splash');
    expect(tester.takeException(), isNull);
  });

  testWidgets('dialer preserves call and settings actions', (tester) async {
    final controller = PreviewHomeController();
    Get.put<HomeController>(controller);
    await showPage(tester, const HomePage(), const Size(390, 844));
    await savePreview(tester, '01-home');
    await tester.tap(find.byIcon(Icons.call_rounded));
    await tester.tap(find.byTooltip('Settings'));
    expect(controller.calls, 1);
    expect(controller.settings, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('call controls, errors and summary keep their actions', (
    tester,
  ) async {
    final controller = registerCall();
    await showPage(tester, const VoiceChatPage(), const Size(390, 844));
    expect(controller.calls, 1);
    expect(find.text('End call').hitTestable(), findsOneWidget);
    await savePreview(tester, '02-active-call');
    await tester.tap(find.byIcon(Icons.mic_none_rounded));
    await tester.pump();
    expect(controller.isUserMuted.value, isTrue);
    // No transcript on screen; only Mute and End.
    expect(find.byIcon(Icons.closed_caption_rounded), findsNothing);
    controller.errorMessage.value = 'Connection interrupted';
    controller.state.value = VoiceChatState.error;
    await tester.pump();
    expect(find.text('Connection interrupted'), findsOneWidget);
    await tester.tap(find.text('Tap to try again'));
    await tester.pump();
    expect(controller.calls, 2);
    await tester.tap(find.byIcon(Icons.call_end_rounded));
    await tester.pump();
    expect(find.text('Until next time.'), findsOneWidget);
    expect(find.text('What are my rights as a tenant?'), findsNothing);
    expect(find.byType(EditableText), findsNothing);
    expect(find.text('Your last question'), findsNothing);
    await savePreview(tester, '03-call-ended');
    await tester.tap(find.text('Call again'));
    await tester.pump();
    expect(controller.calls, 3);
    expect(controller.callEnded.value, isFalse);
    await tester.tap(find.byIcon(Icons.call_end_rounded));
    await tester.pump();
    await tester.tap(find.text('Done'));
    expect(controller.leaves, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('long backend errors stay readable and retry stays reachable', (
    tester,
  ) async {
    final controller = registerCall();
    await showPage(tester, const VoiceChatPage(), const Size(320, 568));
    controller.errorMessage.value = List.filled(
      8,
      'The connection was interrupted while preparing the response.',
    ).join(' ');
    controller.state.value = VoiceChatState.error;
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Tap to try again'));
    await tester.tap(find.text('Tap to try again'));
    await tester.pump();
    expect(controller.calls, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('system back ends the call before leaving its summary', (
    tester,
  ) async {
    final controller = registerCall();
    Get.put<HomeController>(PreviewHomeController());
    await showPage(tester, const HomePage(), const Size(390, 844));
    Get.to<void>(() => const VoiceChatPage());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(controller.calls, 1);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(controller.callEnded.value, isTrue);
    expect(find.text('Until next time.'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(VoiceChatPage), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final size in [
    const Size(320, 568),
    const Size(375, 812),
    const Size(414, 896),
    const Size(768, 1024),
  ]) {
    testWidgets('call fits $size and long content remains scrollable', (
      tester,
    ) async {
      final controller = registerCall();
      await showPage(tester, const VoiceChatPage(), size);
      for (final state in VoiceChatState.values) {
        controller.state.value = state;
        controller.errorMessage.value = state == VoiceChatState.error
            ? 'Connection interrupted. Please try again.'
            : '';
        await tester.pump();
        expect(tester.takeException(), isNull, reason: state.name);
      }
      expect(find.byIcon(Icons.call_end_rounded).hitTestable(), findsOneWidget);
      final endPosition = tester.getBottomLeft(find.text('End call'));
      expect(size.height - endPosition.dy, greaterThanOrEqualTo(60));
      await tester.tap(find.byIcon(Icons.call_end_rounded));
      await tester.pump();
      controller.lastQuestion.value = List.filled(
        15,
        'Please explain my rights as a tenant.',
      ).join(' ');
      controller.lastLegalBasis.assignAll([
        'A long legal reference that must wrap without overflowing the summary',
        'Civil Code',
        'Additional legal basis',
      ]);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Call again'));
      expect(find.text('Call again').hitTestable(), findsOneWidget);
      controller.lastQuestion.value = '';
      controller.lastLegalBasis.clear();
      await tester.pump();
      expect(find.text('No question was asked in this call.'), findsNothing);
      expect(find.text('Your last question'), findsNothing);
      expect(find.byType(EditableText), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
    testWidgets('dialer fits $size and call remains reachable', (tester) async {
      final controller = PreviewHomeController();
      Get.put<HomeController>(controller);
      await showPage(tester, const HomePage(), size);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byIcon(Icons.call_rounded));
      await tester.tap(find.byIcon(Icons.call_rounded));
      expect(controller.calls, 1);
    });
  }
}

/// UI fixtures never open a microphone, play audio or contact the backend.
class PreviewHomeController extends HomeController {
  int calls = 0;
  int settings = 0;
  @override
  void startCall() => calls++;
  @override
  void openSettings() => settings++;
}

class PreviewCallController extends VoiceChatController {
  int calls = 0;
  int leaves = 0;
  @override
  // Skip the production onInit: it starts microphone and network warm-up.
  // ignore: must_call_super
  void onInit() {}
  @override
  void onClose() {}
  @override
  Future<void> startCall() async {
    calls++;
    callEnded.value = false;
    state.value = VoiceChatState.speaking;
    callElapsedSeconds.value = 154;
    lastQuestion.value = 'What are my rights as a tenant?';
    lastLegalBasis.assignAll(['Civil Code']);
  }

  @override
  void toggleMute() => isUserMuted.toggle();
  @override
  Future<void> endConversation() async {
    endedCallSeconds.value = 252;
    callEnded.value = true;
    state.value = VoiceChatState.idle;
  }

  @override
  void leaveCall() => leaves++;
}
