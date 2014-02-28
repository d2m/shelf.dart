// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.typedef;

import 'request.dart';

/// The signature of a function which handles a [ShelfRequest].
///
/// A [ShelfHandler] may receive a request directly from an HTTP server or it
/// may be composed as part of a larger application.
///
/// Should return [ShelfResponse] or [Future<ShelfResponse>].
//TODO(kevmoo): provide a more detailed explanation.
typedef ShelfHandler(ShelfRequest request);
