import 'dart:async';
import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart';
import 'package:scholaris_api/new-tentant.handler.dart';
import 'package:scholaris_api/types.dart' as types;

Future<dynamic> main(final context) async {
  final req = types.Request(
      context.req.method,
      context.req.scheme,
      context.req.url,
      context.req.host,
      context.req.path,
      context.req.queryString,
      context.req.port,
      context.req.headers,
      body: context.req.body,
      bodyRaw: context.req.bodyRaw,
      query: context.req.query);

  final res = types.Response(context.res.empty, context.res.json,
      context.res.redirect, context.res.send);

  final client = Client()
      .setEndpoint("https://api.scholaris.space/v1")
      .setProject(Platform.environment["APPWRITE_FUNCTION_PROJECT_ID"])
      .setKey(Platform.environment['APPWRITE_API_KEY']);

  final ctx =
      types.RequestContext(client, req, res, context.log, context.error);

  try {
    final userId = req.headers['x-appwrite-user-id'];
    User? user;
    if (userId != null && userId.isNotEmpty) {
      final users = Users(client);
      user = await users.get(userId: userId);
      ctx.user = user;
    }
    final challenge = '${req.method}::${req.path}'.toLowerCase();
    dynamic ans;
    if (RegExp(r'^post::/new-tenant$', caseSensitive: true)
        .hasMatch(challenge)) {
      ans = await createTenant(ctx);
    } else {
      throw types.ExecutionException('Service unavailable', status: 503);
    }

    if (ans == null) return res.empty();
    return res.json(ans);
  } on types.ExecutionException catch (err) {
    context.error(err.message);
    return res.send('Internal Server Error', 500);
  }
}
