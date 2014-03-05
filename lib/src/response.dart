// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.response;

import 'dart:async';
import 'dart:convert';

import 'package:collection/wrappers.dart';

import 'media_type.dart';

/// The response returned by a [ShelfHandler].
abstract class ShelfResponse {
  /// The HTTP status code of the response.
  final int statusCode;

  /// The HTTP headers of the response.
  ///
  /// The value is immutable.
  final Map<String, String> headers;

  /// The MIME type of the response.
  ///
  /// This is parsed from the Content-Type header in [headers]. It contains only
  /// the MIME type, without any Content-Type parameters.
  ///
  /// If [headers] doesn't have a Content-Type header, this will be `null`.
  String get mimeType {
    var contentType = _contentType;
    if (contentType == null) return null;
    return contentType.mimeType;
  }

  /// The encoding of the response.
  ///
  /// This is parsed from the "charset" paramater of the Content-Type header in
  /// [headers].
  ///
  /// If [headers] doesn't have a Content-Type header or it specifies an
  /// encoding that [dart:convert] doesn't support, this will be `null`.
  Encoding get encoding {
    var contentType = _contentType;
    if (contentType == null) return null;
    if (!contentType.parameters.containsKey('charset')) return null;
    return Encoding.getByName(contentType.parameters['charset']);
  }

  /// The parsed version of the Content-Type header in [headers].
  ///
  /// This is cached for efficient access.
  MediaType get _contentType {
    if (_contentTypeCache != null) return _contentTypeCache;
    if (!headers.containsKey('content-type')) return null;
    _contentTypeCache = new MediaType.parse(headers['content-type']);
    return _contentTypeCache;
  }
  MediaType _contentTypeCache;

  /// Creates a [ShelfResponse] with a [String] body.
  //TODO(kevmoo) Rework constructors to support many body types.
  factory ShelfResponse.string(int statusCode, Map<String, String> headers,
      String body) = _StringShelfResponse;

  ShelfResponse(this.statusCode, Map<String, String> headers) :
    // copy the source map to ensure headers are immutable
    this.headers = new UnmodifiableMapView(new Map.from(headers)) {
    assert(statusCode != null);
    assert(statusCode > 0);
  }

  /// Creates a [ShelfResponse] with a status code of `500`.
  ///
  /// The default value for [message] is "Internal Server Error".
  factory ShelfResponse.internalServerError([String message]) {
    if (message == null) message = 'Internal Server Error';
    return new _StringShelfResponse(500, {}, message);
  }

  /// Returns a [Stream] representing the body of the response.
  // TODO(kevmoo): expose the requsted encoding and instruct those who override
  //               `read` to ensure they send text correctly.
  Stream<List<int>> read();
}

class _StringShelfResponse extends ShelfResponse {
  final String body;

  _StringShelfResponse(int statusCode, Map<String, String> headers, this.body)
      : super(statusCode, headers);

  // TODO: no clue how to handle encoding correctly here..
  Stream<List<int>> read() => new Stream.fromIterable([UTF8.encode(body)]);
}
