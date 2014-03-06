// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.request;

import 'dart:collection';

import 'package:collection/wrappers.dart';
import 'package:path/path.dart' as p;

/// Represents an HTTP request to be processed by a Shelf application.
class Request {
  /// The contents of any Content-Length fields in the HTTP request. May be
  /// `null`.
  final int contentLength;

  /// The remainder of the [requestedUri] path designating the virtual
  /// "location" of the request's target within the handler.
  ///
  /// [pathInfo] may be an empty string, if [requestedUri ]targets the handler
  /// root and does not have a trailing slash.
  ///
  /// [pathInfo] is never null. If it is not empty, it will start with `/`.
  ///
  /// [scriptName] and [pathInfo] combine to create a valid path that should
  /// correspond to the [requestedUri] path.
  final String pathInfo;

  /// The portion of the request URL that follows the "?", if any.
  final String queryString;

  /// The HTTP request method, such as "GET" or "POST".
  final String method;

  /// The initial portion of the [requestedUri] path that corresponds to the
  /// handler.
  ///
  /// [scriptName] allows a handler to know its virtual "location".
  ///
  /// If the handler corresponds to the "root" of a server, it will be an
  /// empty string, otherwise it will start with a `/`
  ///
  /// [scriptName] and [pathInfo] combine to create a valid path that should
  /// correspond to the [requestedUri] path.
  final String scriptName;

  /// The HTTP protocol version used in the request, either "1.0" or "1.1".
  final String protocolVersion;

  /// The original [Uri] for the request.
  final Uri requestedUri;

  /// The HTTP headers.
  ///
  /// The value is immutable.
  final Map<String, String> headers;

  Request(this.pathInfo, String queryString, this.method,
      this.scriptName, this.protocolVersion, this.contentLength,
      this.requestedUri, Map<String, String> headers)
      : this.queryString = queryString == null ? '' : queryString,
        this.headers = new UnmodifiableMapView(new HashMap.from(headers)) {
    if (method.isEmpty) throw new ArgumentError('method cannot be empty.');

    if (scriptName.isNotEmpty && !scriptName.startsWith('/')) {
      throw new ArgumentError('scriptName must be empty or start with "/".');
    }

    if (scriptName == '/') {
      throw new ArgumentError(
          'scriptName can never be "/". It should be empty instead.');
    }

    if (scriptName.endsWith('/')) {
      throw new ArgumentError('scriptName must not end with "/".');
    }

    if (pathInfo.isNotEmpty && !pathInfo.startsWith('/')) {
      throw new ArgumentError('pathInfo must be empty or start with "/".');
    }

    if (scriptName.isEmpty && pathInfo.isEmpty) {
      throw new ArgumentError('scriptName and pathInfo cannot both be empty.');
    }

    if (contentLength != null && contentLength < 0) {
      throw new ArgumentError('contentLength must be null or non-negative.');
    }
  }

  /// Convenience property to access [pathInfo] data as a [List].
  List<String> get pathSegments {
    var segs = p.url.split(pathInfo);
    if (segs.length > 0) {
      assert(segs.first == p.url.separator);
      segs.removeAt(0);
    }
    return segs;
  }
}
