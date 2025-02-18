import 'dart:convert';

import 'package:universal_io/io.dart';
import 'package:walletconnect_flutter_v2/apis/core/relay_client/relay_client_models.dart';
import 'package:walletconnect_flutter_v2/apis/models/basic_models.dart';
import 'package:walletconnect_flutter_v2/apis/models/uri_parse_result.dart';

class WalletConnectUtils {
  static bool isExpired(int expiry) {
    return DateTime.now().toUtc().compareTo(
              DateTime.fromMillisecondsSinceEpoch(
                toMilliseconds(expiry),
              ),
            ) >=
        0;
  }

  static int toMilliseconds(int seconds) {
    return seconds * 1000;
  }

  static int calculateExpiry(int offset) {
    return DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 + offset;
  }

  static String getOS() {
    return <String>[Platform.operatingSystem, Platform.operatingSystemVersion]
        .join('-');
  }

  static String getId() {
    return 'unknown'; // TODO: implement
  }

  static String formatUA(
    String protocol,
    int version,
    String sdkVersion,
  ) {
    String os = getOS();
    String id = getId();
    return <String>[
      [protocol, version].join('-'),
      <String>['Dart', sdkVersion].join('-'),
      os,
      id,
    ].join('/');
  }

  static String formatRelayRpcUrl({
    required String protocol,
    required int version,
    required String relayUrl,
    required String sdkVersion,
    required String auth,
    String? projectId,
  }) {
    final Uri uri = Uri.parse(relayUrl);
    final Map<String, String> queryParams = Uri.splitQueryString(uri.query);
    String ua = formatUA(
      protocol,
      version,
      sdkVersion,
    );

    final Map<String, String> relayParams = {
      'auth': auth,
      if (projectId != null && projectId.isNotEmpty) 'projectId': projectId,
      'ua': ua,
    };
    queryParams.addAll(relayParams);
    return uri.replace(queryParameters: queryParams).toString();
  }

  /// ---- URI HANDLING --- ///

  static URIParseResult parseUri(Uri uri) {
    String protocol = uri.scheme;
    String path = uri.path;
    final List<String> splitParams = path.split('@');
    if (splitParams.length == 1) {
      throw WalletConnectError(
        code: 0,
        message: 'Invalid URI: Missing @',
      );
    }
    List<String> methods = (uri.queryParameters['methods'] ?? '')
        // Replace all the square brackets with empty string, split by comma
        .replaceAll(
          RegExp(r'[\[\]"]+'),
          '',
        )
        .split(
          ',',
        );
    if (methods.length == 1 && methods[0].isEmpty) {
      methods = [];
    }
    final URIVersion? version;
    switch (splitParams[1]) {
      case '1':
        version = URIVersion.v1;
        break;
      case '2':
        version = URIVersion.v2;
        break;
      default:
        version = null;
    }
    final URIV1ParsedData? v1Data;
    final URIV2ParsedData? v2Data;
    if (version == URIVersion.v1) {
      v1Data = URIV1ParsedData(
        key: uri.queryParameters['key']!,
        bridge: uri.queryParameters['bridge']!,
      );
      v2Data = null;
    } else {
      v1Data = null;
      v2Data = URIV2ParsedData(
        symKey: uri.queryParameters['symKey']!,
        relay: Relay(
          uri.queryParameters['relay-protocol']!,
          data: uri.queryParameters.containsKey('relay-data')
              ? uri.queryParameters['relay-data']
              : null,
        ),
        methods: methods,
      );
    }

    URIParseResult ret = URIParseResult(
      protocol: protocol,
      version: version,
      topic: splitParams[0],
      v1Data: v1Data,
      v2Data: v2Data,
    );
    return ret;
  }

  static Map<String, String> formatRelayParams(
    Relay relay, {
    String delimiter = '-',
  }) {
    Map<String, String> params = {};
    params[['relay', 'protocol'].join(delimiter)] = relay.protocol;
    if (relay.data != null) {
      params[['relay', 'data'].join(delimiter)] = relay.data!;
    }
    return params;
  }

  static Uri formatUri({
    required String protocol,
    required String version,
    required String topic,
    required String symKey,
    required Relay relay,
    required List<List<String>>? methods,
  }) {
    Map<String, String> params = formatRelayParams(relay);
    params['symKey'] = symKey;
    if (methods != null) {
      params['methods'] = methods
          .map((e) => jsonEncode(e))
          .join(
            ',',
          )
          .replaceAll(
            '"',
            '',
          );
    } else {
      params['methods'] = '[]';
    }

    return Uri(
      scheme: protocol,
      path: '$topic@$version',
      queryParameters: params,
    );
  }

  static Map<String, T> convertMapTo<T>(Map<String, dynamic> inMap) {
    Map<String, T> m = {};
    for (var entry in inMap.entries) {
      m[entry.key] = entry.value as T;
    }
    return m;
  }
}
