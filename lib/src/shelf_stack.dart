// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.stack;

import 'typedef.dart';
import 'middleware.dart';

/// A helper that makes it easy to compose a set of [ShelfMiddleware] and a
/// [ShelfHandler].
///
///     ShelfHandler handler = new ShelfStack()
///         .addMiddleware(loggingMiddleware)
///         .addMiddleware(cachingMiddleware)
///         .addHandler(application);
class ShelfStack {
  final ShelfStack _parent;
  final ShelfMiddleware _middleware;

  const ShelfStack()
      : _middleware = null,
        _parent = null;

  ShelfStack._(this._middleware, this._parent);

  /// Returns a new [ShelfStack] with [middleware] added to the existing set of
  /// [ShelfMiddleware].
  ///
  /// [middleware] will be the last [ShelfMiddleware] to process a request and
  /// the first to process a response.
  ShelfStack addMiddleware(ShelfMiddleware middleware) =>
      new ShelfStack._(middleware, this);

  /// Returns a new [ShelfHandler] with [handler] as the final processor of a
  /// [ShelfRequest] if all of the middleware in the stack have passed the
  /// request through.
  ShelfHandler addHandler(ShelfHandler handler) {
    if (_middleware == null) return handler;
    return _parent.addHandler(_middleware(handler));
  }

  /// Exposes this stack of [ShelfMiddleware] as a single middleware instance.
  ShelfMiddleware get middleware => addHandler;
}
