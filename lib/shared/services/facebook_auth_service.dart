import 'dart:js' as js;
import 'package:js/js_util.dart' as js_util;

class FacebookAuthService {
  Future<bool> isFacebookSDKReady() async {
    await Future.delayed(const Duration(seconds: 3)); // Giả lập thời gian khởi tạo SDK
    bool? isSDKReady = js_util.getProperty(js_util.globalThis, 'facebookSDKReady');
    return isSDKReady ?? false;
  }

  void handleFacebookLogin(Function(String) onSuccess, Function(String) onError) {
    try {
      var fb = js.context['FB'];
      if (fb == null || fb.callMethod == null) {
        onError("Facebook SDK chưa sẵn sàng.");
        return;
      }

      fb.callMethod('getLoginStatus', [
        js.allowInterop((response) {
          if (response['status'] == 'connected' && response['authResponse'] != null) {
            String accessToken = response['authResponse']['accessToken'];
            if (accessToken.isNotEmpty) {
              onSuccess(accessToken);
            } else {
              _getAccessToken(onSuccess, onError);
            }
          } else {
            fb.callMethod('login', [
              js.allowInterop((loginResponse) {
                if (loginResponse['status'] == 'connected' && loginResponse['authResponse'] != null) {
                  String loginAccessToken = loginResponse['authResponse']['accessToken'];
                  if (loginAccessToken.isNotEmpty) {
                    onSuccess(loginAccessToken);
                  } else {
                    _getAccessToken(onSuccess, onError);
                  }
                } else {
                  onError("Facebook login failed.");
                }
              }),
              {'scope': 'email,public_profile'}
            ]);
          }
        })
      ]);
    } catch (e) {
      onError("Facebook Sign-In Error: $e");
    }
  }

  void _getAccessToken(Function(String) onSuccess, Function(String) onError) {
    var fb = js.context['FB'];
    fb.callMethod('getLoginStatus', [
      js.allowInterop((response) {
        if (response['status'] == 'connected' && response['authResponse'] != null) {
          String accessToken = response['authResponse']['accessToken'];
          if (accessToken.isNotEmpty) {
            onSuccess(accessToken);
          } else {
            Future.delayed(const Duration(seconds: 2), () => _getAccessToken(onSuccess, onError));
          }
        } else {
          onError("Không thể lấy access token.");
        }
      })
    ]);
  }
}
