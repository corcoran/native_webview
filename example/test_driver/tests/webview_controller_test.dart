import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_webview/native_webview.dart';

import '../utils.dart';

void main() {
  group("loadUrl", () {
    testWebView('loadUrl', (tester, context) async {
      await tester.pumpWidget(
        WebView(
          initialUrl: 'https://flutter.dev/',
          onWebViewCreated: context.onWebViewCreated,
        ),
      );
      final controller = await context.webviewController.future;
      await controller.loadUrl('https://www.google.com/');
      final currentUrl = await controller.currentUrl();
      expect(currentUrl, 'https://www.google.com/');

      context.complete();
    });

    testWebView('with headers', (tester, context) async {
      await tester.pumpWidget(
        WebView(
          initialUrl: 'https://flutter.dev/',
          onWebViewCreated: context.onWebViewCreated,
          onPageFinished: context.onPageFinished,
        ),
      );
      final controller = await context.webviewController.future;

      context.pageFinished.stream.listen(onData([
        (event) async {
          expect(event, "https://flutter.dev/");

          final headers = <String, String>{
            'test_header': 'flutter_test_header'
          };
          await controller.loadUrl(
            'https://flutter-header-echo.herokuapp.com/',
            headers: headers,
          );
        },
        (event) async {
          expect(event, "https://flutter-header-echo.herokuapp.com/");
          final content = await controller.evaluateJavascript(
            '(() => document.documentElement.innerText)()',
          );
          expect(content.contains('flutter_test_header'), isTrue);
          context.complete();
        },
      ]));
    });
  });

  group("JavascriptHandler", () {
    testWebView("messages received", (tester, context) async {
      final List<List<dynamic>> argumentsReceived = [];

      await tester.pumpWidget(
        WebView(
          initialUrl: 'https://flutter.dev/',
          onWebViewCreated: (controller) {
            controller.addJavascriptHandler("hoge", (arguments) async {
              argumentsReceived.add(arguments);
            });
            context.onWebViewCreated(controller);
          },
          onPageFinished: context.onPageFinished,
        ),
      );
      final controller = await context.webviewController.future;

      context.pageFinished.stream.listen(onData([
        (event) async {
          await controller.evaluateJavascript("""
          window.nativeWebView.callHandler("hoge", "value", 1, true);
          """);
          expect(argumentsReceived, [
            ["value", 1, true],
          ]);
          context.complete();
        },
      ]));
    });

    testWebView("nothing handler", (tester, context) async {
      final List<List<dynamic>> argumentsReceived = [];

      await tester.pumpWidget(
        WebView(
          initialUrl: 'https://flutter.dev/',
          onWebViewCreated: context.onWebViewCreated,
          onPageFinished: context.onPageFinished,
        ),
      );
      final controller = await context.webviewController.future;
      context.pageFinished.stream.listen(onData([
        (event) async {
          // no error
          await controller.evaluateJavascript("""
          window.nativeWebView.callHandler("hoge", "value", 1, true);
          """);
          expect(argumentsReceived, []);
          context.complete();
        },
      ]));
    });
  });

  group("evaluateJavascript", () {
    testWebView('success', (tester, context) async {
      await tester.pumpWidget(
        WebView(
          initialUrl: 'about:blank',
          onWebViewCreated: context.onWebViewCreated,
          onPageFinished: context.onPageFinished,
        ),
      );
      final controller = await context.webviewController.future;

      context.pageFinished.stream.listen(onData([
        (event) async {
          expect(
            await controller.evaluateJavascript('(() => "りんご")()'),
            "りんご",
          );
          expect(
            await controller.evaluateJavascript('(() => 1000)()'),
            1000,
          );
          expect(
            await controller.evaluateJavascript('(() => ["りんご"])()'),
            ["りんご"],
          );
          expect(
            await controller.evaluateJavascript(
                '(function() { return {"りんご": "Apple"} })()'),
            {"りんご": "Apple"},
          );

          expect(
            await controller.evaluateJavascript("""
class Rectangle {
  constructor(height, width) {
    this.height = height;
    this.width = width;
  }
}
(() => new Rectangle(100, 200))()
            """),
            {'height': 100, 'width': 200},
          );

          context.complete();
        },
      ]));
    });

    testWebView('invalid javascript', (tester, context) async {
      await tester.pumpWidget(
        WebView(
          initialUrl: 'about:blank',
          onWebViewCreated: context.onWebViewCreated,
          onPageFinished: context.onPageFinished,
        ),
      );
      final controller = await context.webviewController.future;

      context.pageFinished.stream.listen(onData([
        (event) async {
          try {
            await controller.evaluateJavascript('() => ');
            fail("syntax error did not occur.");
          } catch (error) {
            expect(error, isA<PlatformException>());
            expect(error.toString(),
                contains("SyntaxError: Unexpected end of script"));
          } finally {
            context.complete();
          }
        },
      ]));
    }, skip: Platform.isAndroid);

    testWebView('unsupported type', (tester, context) async {
      await tester.pumpWidget(
        WebView(
          initialUrl: 'about:blank',
          onWebViewCreated: context.onWebViewCreated,
          onPageFinished: context.onPageFinished,
        ),
      );
      final controller = await context.webviewController.future;

      context.pageFinished.stream.listen(onData([
        (event) async {
          try {
            await controller.evaluateJavascript('(() => function test() {})()');
          } catch (error) {
            expect(error, isA<PlatformException>());
            expect(
                error.toString(),
                contains(
                    "JavaScript execution returned a result of an unsupported type"));

            context.complete();
          }
        },
      ]));
    }, skip: Platform.isAndroid);
  });
}
