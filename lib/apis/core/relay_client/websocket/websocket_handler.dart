import 'dart:async';

import 'package:stream_channel/stream_channel.dart';
import 'package:walletconnect_flutter_v2/apis/core/relay_client/websocket/i_http_client.dart';
import 'package:walletconnect_flutter_v2/apis/core/relay_client/websocket/i_websocket_handler.dart';
import 'package:walletconnect_flutter_v2/apis/models/basic_models.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketHandler implements IWebSocketHandler {
  // static final _random = Random.secure();

  final String url;
  final Duration heartbeatInterval;
  final IHttpClient httpClient;
  final String origin;

  WebSocketChannel? _socket;

  StreamChannel<String>? _channel;
  StreamChannel<String>? get channel => _channel;

  Future<void> get ready => _socket!.ready;

  WebSocketHandler({
    required this.url,
    required this.httpClient,
    required this.origin,
    this.heartbeatInterval = const Duration(seconds: 30),
  });

  Future<void> init() async {
    await _connect();
  }

  Future<void> close() async {
    await _socket?.sink.close();
    // await _streamController?.close();
  }

  Future<void> _connect() async {
    // Perform the HTTP GET request
    // print(httpClient);
    // late Response response;

    // if (kIsWeb) {
    //   // Can't make a get request on web due to CORS, so we just assume we are good.
    //   response = Response('', 200);
    // } else {
    //   final httpsUrl = url.replaceFirst('wss', 'https');
    //   response = await httpClient.get(
    //     Uri.parse(
    //       httpsUrl,
    //     ),
    //   );
    // }

    // Check if the request was successful (status code 200)
    try {
      // print('connecting');
      _socket = WebSocketChannel.connect(
        Uri.parse(
          url,
        ),
      );

      await _socket!.ready;
      // print('websocket ready');

      _channel = _socket!.cast<String>();
    } catch (e) {
      // If the request failed, handle the error
      // debugPrint(
      //   'HTTP GET request failed with status code: ${response.statusCode}',
      // );
      // print(response.headers);
      // print(response.statusCode);

      // switch (response.statusCode) {
      //   case WebSocketErrors.PROJECT_ID_NOT_FOUND:
      //     throw HttpException(WebSocketErrors.PROJECT_ID_NOT_FOUND_MESSAGE);
      //   case WebSocketErrors.INVALID_PROJECT_ID:
      //     throw HttpException(WebSocketErrors.INVALID_PROJECT_ID_MESSAGE);
      //   case WebSocketErrors.TOO_MANY_REQUESTS:
      //     throw HttpException(WebSocketErrors.TOO_MANY_REQUESTS_MESSAGE);
      //   default:
      //     throw HttpException(response.body);
      // }

      throw WalletConnectError(
        code: 400,
        message:
            'WebSocket connection failed, this could be: 1. Missing project id, 2. Invalid project id, 3. Too many requests',
      );
    }
  }

  // Future<Response> testWebSocketHandshake(String url) async {
  //   final uri = Uri.parse(url);
  //   final websocketKey = base64.encode(
  //     List<int>.generate(
  //       16,
  //       (index) => _random.nextInt(256),
  //     ),
  //   );

  //   final response = await httpClient.get(
  //     uri,
  //     headers: {
  //       'Connection': 'Upgrade',
  //       'Upgrade': 'websocket',
  //       'Origin': origin,
  //       'Sec-WebSocket-Key': websocketKey,
  //       'Sec-WebSocket-Version': '13',
  //     },
  //   );

  //   return response;
  // }
}
