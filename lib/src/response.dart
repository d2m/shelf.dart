// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.response;

import 'dart:async';
import 'dart:convert';

import 'package:collection/wrappers.dart';
import 'package:stack_trace/stack_trace.dart';

import 'media_type.dart';
import 'util.dart';

/// The response returned by a [ShelfHandler].
class ShelfResponse {
  /// The HTTP status code of the response.
  final int statusCode;

  /// The HTTP headers of the response.
  ///
  /// The value is immutable.
  final Map<String, String> headers;

  /// The streaming body of the response.
  ///
  /// This can be read via [read] or [readAsString].
  final Stream<List<int>> _body;

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

  /// Constructs a 200 OK response.
  ///
  /// This indicates that the request has succeeded.
  ///
  /// [body] is the response body. It may be either a [String], a
  /// [Stream<List<int>>], or `null` to indicate no body. If it's a [String],
  /// [encoding] is used to encode it to a [Stream<List<int>>]. It defaults to
  /// UTF-8.
  ///
  /// If [encoding] is passed, the "encoding" field of the Content-Type header
  /// in [headers] will be set appropriately. If there is no existing
  /// Content-Type header, it will be set to "application/octet-stream".
  ShelfResponse.ok(body, {Map<String, String> headers, Encoding encoding})
      : this(200, body: body, headers: headers, encoding: encoding);

  /// Constructs a 301 Moved Permanently response.
  ///
  /// This indicates that the requested resource has moved permanently to a new
  /// URI. [location] is that URI; it can be either a [String] or a [Uri]. It's
  /// automatically set as the Location header in [headers].
  ///
  /// [body] is the response body. It may be either a [String], a
  /// [Stream<List<int>>], or `null` to indicate no body. If it's a [String],
  /// [encoding] is used to encode it to a [Stream<List<int>>]. It defaults to
  /// UTF-8.
  ///
  /// If [encoding] is passed, the "encoding" field of the Content-Type header
  /// in [headers] will be set appropriately. If there is no existing
  /// Content-Type header, it will be set to "application/octet-stream".
  ShelfResponse.movedPermanently(location, {body, Map<String, String> headers,
      Encoding encoding})
      : this._redirect(301, location, body, headers, encoding);

  /// Constructs a 302 Found response.
  ///
  /// This indicates that the requested resource has moved temporarily to a new
  /// URI. [location] is that URI; it can be either a [String] or a [Uri]. It's
  /// automatically set as the Location header in [headers].
  ///
  /// [body] is the response body. It may be either a [String], a
  /// [Stream<List<int>>], or `null` to indicate no body. If it's a [String],
  /// [encoding] is used to encode it to a [Stream<List<int>>]. It defaults to
  /// UTF-8.
  ///
  /// If [encoding] is passed, the "encoding" field of the Content-Type header
  /// in [headers] will be set appropriately. If there is no existing
  /// Content-Type header, it will be set to "application/octet-stream".
  ShelfResponse.found(location, {body, Map<String, String> headers,
      Encoding encoding})
      : this._redirect(302, location, body, headers, encoding);

  /// Constructs a 303 See Other response.
  ///
  /// This indicates that the response to the request should be retrieved using
  /// a GET request to a new URI. [location] is that URI; it can be either a
  /// [String] or a [Uri]. It's automatically set as the Location header in
  /// [headers].
  ///
  /// [body] is the response body. It may be either a [String], a
  /// [Stream<List<int>>], or `null` to indicate no body. If it's a [String],
  /// [encoding] is used to encode it to a [Stream<List<int>>]. It defaults to
  /// UTF-8.
  ///
  /// If [encoding] is passed, the "encoding" field of the Content-Type header
  /// in [headers] will be set appropriately. If there is no existing
  /// Content-Type header, it will be set to "application/octet-stream".
  ShelfResponse.seeOther(location, {body, Map<String, String> headers,
      Encoding encoding})
      : this._redirect(303, location, body, headers, encoding);

  /// Constructs a helper constructor for redirect responses.
  ShelfResponse._redirect(int statusCode, location, body,
      Map<String, String> headers, Encoding encoding)
      : this(statusCode,
            body: body,
            encoding: encoding,
            headers: _addHeader(
                headers, 'location', _locationToString(location)));

  /// Constructs a 304 Not Modified response.
  ///
  /// This is used to respond to a conditional GET request that provided
  /// information used to determine whether the requested resource has changed
  /// since the last request. It indicates that the resource has not changed and
  /// the old value should be used.
  ShelfResponse.notModified({Map<String, String> headers})
      : this(304, headers: _addHeader(
            headers, 'date', formatHttpDate(new DateTime.now())));

  /// Constructs a 403 Forbidden response.
  ///
  /// This indicates that the server is refusing to fulfill the request.
  ///
  /// [body] is the response body. It may be either a [String], a
  /// [Stream<List<int>>], or `null` to indicate no body. If it's a [String],
  /// [encoding] is used to encode it to a [Stream<List<int>>]. It defaults to
  /// UTF-8.
  ///
  /// If [encoding] is passed, the "encoding" field of the Content-Type header
  /// in [headers] will be set appropriately. If there is no existing
  /// Content-Type header, it will be set to "application/octet-stream".
  ShelfResponse.forbidden(body, {Map<String, String> headers,
      Encoding encoding})
      : this(403, body: body, headers: headers);

  /// Constructs a 404 Not Found response.
  ///
  /// This indicates that the server didn't find any resource matching the
  /// requested URI.
  ///
  /// [body] is the response body. It may be either a [String], a
  /// [Stream<List<int>>], or `null` to indicate no body. If it's a [String],
  /// [encoding] is used to encode it to a [Stream<List<int>>]. It defaults to
  /// UTF-8.
  ///
  /// If [encoding] is passed, the "encoding" field of the Content-Type header
  /// in [headers] will be set appropriately. If there is no existing
  /// Content-Type header, it will be set to "application/octet-stream".
  ShelfResponse.notFound(body, {Map<String, String> headers, Encoding encoding})
      : this(404, body: body, headers: headers);

  /// Constructs a 500 Internal Server Error response.
  ///
  /// This indicates that the server had an internal error that prevented it
  /// from fulfilling the request.
  ///
  /// [body] is the response body. It may be either a [String], a
  /// [Stream<List<int>>], or `null` to indicate no body. If it's `null` or not
  /// passed, a default error message is used. If it's a [String], [encoding] is
  /// used to encode it to a [Stream<List<int>>]. It defaults to UTF-8.
  ///
  /// If [encoding] is passed, the "encoding" field of the Content-Type header
  /// in [headers] will be set appropriately. If there is no existing
  /// Content-Type header, it will be set to "application/octet-stream".
  ShelfResponse.internalServerError({body, Map<String, String> headers,
      Encoding encoding})
      : this(500,
            headers: body == null ? _adjust500Headers(headers) : headers,
            body: body == null ? 'Internal Server Error' : body);

  /// Constructs an HTTP response with the given [statusCode].
  ///
  /// [statusCode] must be greater than or equal to 100.
  ///
  /// [body] is the response body. It may be either a [String], a
  /// [Stream<List<int>>], or `null` to indicate no body. If it's `null` or not
  /// passed, a default error message is used. If it's a [String], [encoding] is
  /// used to encode it to a [Stream<List<int>>]. It defaults to UTF-8.
  ///
  /// If [encoding] is passed, the "encoding" field of the Content-Type header
  /// in [headers] will be set appropriately. If there is no existing
  /// Content-Type header, it will be set to "application/octet-stream".
  ShelfResponse(this.statusCode, {body, Map<String, String> headers,
      Encoding encoding})
      : _body = _bodyToStream(body, encoding),
        headers = _adjustHeaders(headers, encoding) {
    if (statusCode < 100) {
      throw new ArgumentError("Invalid status code: $statusCode.");
    }
  }

  /// Returns a [Stream] representing the body of the response.
  ///
  /// This can only be called once per [ShelfRequest].
  Stream<List<int>> read() => _body;

  /// Returns a [Future] that returns the body of the response as a String.
  ///
  /// If [encoding] is passed, that's used to decode the response body.
  /// Otherwise the encoding is taken from the Content-Type header. If that
  /// doesn't exist or doesn't have a "charset" parameter, UTF-8 is used.
  ///
  /// This calls [read] internally, which can only be called once per
  /// [ShelfRequest].
  Future<String> readAsString([Encoding encoding]) {
    if (encoding == null) encoding = this.encoding;
    if (encoding == null) encoding = UTF8;
    return Chain.track(encoding.decodeStream(read()));
  }
}

/// Converts [body] to a byte stream.
///
/// [body] may be either a [String], a [Stream<List<int>>], or `null`. If it's a
/// [String], [encoding] will be used to convert it to a [Stream<List<int>>].
Stream<List<int>> _bodyToStream(body, Encoding encoding) {
  if (encoding == null) encoding = UTF8;
  if (body == null) return new Stream.fromIterable([]);
  if (body is String) return new Stream.fromIterable([encoding.encode(body)]);
  if (body is Stream) return body;

  throw new ArgumentError('Response body "$body" must be a String or a '
      'Stream.');
}

/// Adds information about [encoding] to [headers].
///
/// Returns a new map without modifying [headers].
UnmodifiableMapView<String, String> _adjustHeaders(
    Map<String, String> headers, Encoding encoding) {
  if (headers == null) headers = const {};
  if (encoding == null) return new UnmodifiableMapView(headers);
  if (headers['content-type'] == null) {
    return new UnmodifiableMapView(_addHeader(headers, 'content-type',
        'application/octet-stream; charset=${encoding.name}'));
  }

  var contentType = new MediaType.parse(headers['content-type'])
      .change(parameters: {'charset': encoding.name});
  return new UnmodifiableMapView(
      _addHeader(headers, 'content-type', contentType.toString()));
}

/// Adds a header with [name] and [value] to [headers], which may be null.
///
/// Returns a new map without modifying [headers].
Map<String, String> _addHeader(Map<String, String> headers, String name,
    String value) {
  headers = headers == null ? {} : new Map.from(headers);
  headers[name] = value;
  return headers;
}

/// Adds content-type information to [headers].
///
/// Returns a new map without modifying [headers]. This is used to add
/// content-type information when creating a 500 response with a default body.
Map<String, String> _adjust500Headers(Map<String, String> headers) {
  if (headers == null || headers['content-type'] == null) {
    return _addHeader(headers, 'content-type', 'text/plain');
  }

  var contentType = new MediaType.parse(headers['content-type'])
      .change(mimeType: 'text/plain');
  return _addHeader(headers, 'content-type', contentType.toString());
}

/// Converts [location], which may be a [String] or a [Uri], to a [String].
///
/// Throws an [ArgumentError] if [location] isn't a [String] or a [Uri].
String _locationToString(location) {
  if (location is String) return location;
  if (location is Uri) return location.toString();

  throw new ArgumentError('Response location must be a String or Uri, was '
      '"$location".');
}
