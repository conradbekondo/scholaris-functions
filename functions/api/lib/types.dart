import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart';

const maintainerRole = 'maintainer';
const adminRole = 'admin';
const tenantMembershipRoles = [maintainerRole, adminRole];

class Request {
  final String method, scheme, url, host, path, queryString;
  final Map<String, String>? query;
  final int port;
  final String? bodyRaw;
  final dynamic body;
  final Map<String, dynamic> headers;

  Request(this.method, this.scheme, this.url, this.host, this.path,
      this.queryString, this.port, this.headers,
      {this.body, this.bodyRaw, this.query});
}

class Response {
  final void Function() empty;
  final dynamic Function(Map<String, dynamic>, [int, Map<String, dynamic>])
      json;
  final dynamic Function(String, int) redirect;
  final dynamic Function(String, [int, Map<String, dynamic>]) send;

  Response(this.empty, this.json, this.redirect, this.send);
}

class ExecutionException implements Exception {
  final String message;
  int? status;
  Exception? cause;
  ExecutionException(this.message, {this.cause, this.status = 500});
}

class RequestContext {
  final Client client;
  final Request req;
  final Response res;
  final void Function(String) log;
  final void Function(String) error;
  User? user;

  RequestContext(this.client, this.req, this.res, this.log, this.error,
      {this.user});
}

typedef RequestHandler = Future<dynamic> Function(RequestContext);

mixin PropertyGetter on Document {
  T? extractProperty<T>(String key) {
    return data[key];
  }
}

mixin PropertySetter on Document {
  void setValue(String key, dynamic value) {
    data[key] = value;
  }
}

mixin _TenantSubscription on PropertyGetter, PropertySetter {
  int? get cycleDuration {
    return extractProperty('cycleDuration');
  }

  set cycleDuration(int? value) {
    setValue('cycleDuration', value);
  }

  String? get subscriptionPlan {
    return extractProperty('subscriptionPlan');
  }

  set subscriptionPlan(String? value) {
    setValue('subscriptionPlan', value);
  }

  bool get paused {
    return extractProperty('paused');
  }

  set paused(bool value) {
    setValue('paused', value);
  }

  String? get tenant {
    return extractProperty('tenant');
  }

  set tenant(String? value) {
    setValue('paused', value);
  }
}

mixin _Tenant on PropertyGetter, PropertySetter {
  String get name {
    return extractProperty('name');
  }

  set name(String value) {
    setValue('name', value);
  }
}
typedef TenantSubscription = _TenantSubscription;
typedef Tenant = _Tenant;

const resourceDelimiter = '/';

enum ResourceType { resources, tenants, institutions }

// ignore: constant_identifier_names
enum PlatformAction { Update, Delete, Read }

const anyResource = '*';

class ResourceStringBuilder {
  List<String> _tokens = const [];

  ResourceStringBuilder._(String prefix) {
    _tokens = prefix.split(resourceDelimiter);
  }

  static ResourceStringBuilder create(String? resource) {
    return ResourceStringBuilder._(resource ??
        [ResourceType.resources.toString(), anyResource]
            .join(resourceDelimiter));
  }

  String build() {
    return _tokens.join(resourceDelimiter);
  }

  void _append(String token) {
    _tokens.add(token);
  }

  ResourceStringBuilder type(ResourceType resourceType) {
    _append(resourceType.toString());
    return this;
  }

  ResourceStringBuilder resource(String resource) {
    _append(resource);
    return this;
  }
}
