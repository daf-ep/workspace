// Copyright (C) 2026 Fiber
//
// This software is licensed under the PolyForm Noncommercial License 1.0.0. A
// copy of it is available at
// https://polyformproject.org/licenses/noncommercial/1.0.0, and in the LICENSE
// file at the root of this repository.
//
// What you may do:
// - Use, study, and modify this software for any noncommercial purpose,
//   including personal use, research, education, and use by a charitable,
//   public research, public safety, health, environmental, or government
//   institution.
// - Distribute copies of it, with or without your changes, for those same
//   noncommercial purposes.
//
// What you may not do:
// - Use this software, or a modified or combined version of it, in a
//   commercial product or service, or for any other commercial purpose.
// - Sublicense it, or transfer your licence to someone else.
//
// What you must do in return:
// - Keep this notice on every file you received it on.
//
// Disclaimer:
// AS FAR AS THE LAW ALLOWS, THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY
// OR CONDITION OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR
// NON-INFRINGEMENT. IN NO EVENT SHALL FIBER BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING BUT NOT
// LIMITED TO LOSS OF USE, DATA, PROFITS, OR BUSINESS INTERRUPTION) ARISING OUT
// OF OR RELATED TO THESE TERMS OR THE USE OR NATURE OF THE SOFTWARE, UNDER ANY
// KIND OF LEGAL CLAIM.
//
// This header is a summary written for convenience. Where it differs from the
// LICENSE file, the LICENSE file governs.

import 'dart:async';

/// A generator that asked, directly or through another one, for the type it is building.
///
/// [cycle] lists the types in the order they were requested, the one that
/// closed the loop last.
class ContextDependencyCycleException implements Exception {
  /// Reports the loop [cycle] walked through.
  const ContextDependencyCycleException(this.cycle);

  /// The chain of types that led back to itself.
  final List<Type> cycle;

  @override
  String toString() => 'Dependency cycle detected: ${cycle.join(' -> ')}';
}

/// A function that builds the value a context serves for one type.
typedef Generator = Object? Function();

/// The dependency container the zone carries.
///
/// A generator runs at most once per context, and the value it returns lives as
/// long as that context does. A lookup that finds nothing here walks up to the
/// parent, so a child overrides only the types it names and inherits the rest.
class AppContext {
  AppContext._(this._parent, this._name, [this._overrides = const <Type, Generator>{}]);

  static const Object _key = Object();

  final AppContext? _parent;
  final String? _name;
  final Map<Type, Generator> _overrides;
  final Map<Type, Object?> _values = <Type, Object?>{};

  final List<Type> _reentrantChecks = <Type>[];

  /// The name this context was opened under, or `app` when it was given none.
  String get name => _name ?? 'app';

  /// The context the current zone carries, or the root one outside any [run].
  static AppContext get current => Zone.current[_key] as AppContext? ?? _root;

  static final AppContext _root = AppContext._(null, 'root');

  /// The value registered for [T] here or in an enclosing context, or null.
  T? get<T extends Object>() {
    final Object? value = _generateIfNecessary(T);
    if (value != null) return value as T;
    return _parent?.get<T>();
  }

  /// Runs [body] in a child context that adds [overrides], and returns its result.
  ///
  /// The child is carried by a zone, so everything [body] calls and everything
  /// it awaits sees the same overrides without being handed them.
  ///
  /// Throws a [ContextDependencyCycleException] when a generator ends up asking
  /// for the type it is building.
  Future<V> run<V>({required FutureOr<V> Function() body, String? name, Map<Type, Generator>? overrides}) async {
    final AppContext child = AppContext._(
      this,
      name,
      Map<Type, Generator>.unmodifiable(overrides ?? <Type, Generator>{}),
    );

    return runZoned<Future<V>>(() async => await body(), zoneValues: <Object, Object>{_key: child});
  }

  Object? _generateIfNecessary(Type type) {
    if (!_overrides.containsKey(type)) return null;
    if (_values.containsKey(type)) return _values[type];

    if (_reentrantChecks.contains(type)) {
      throw ContextDependencyCycleException(List<Type>.unmodifiable(<Type>[..._reentrantChecks, type]));
    }

    _reentrantChecks.add(type);
    try {
      return _values[type] = _overrides[type]!();
    } finally {
      _reentrantChecks.removeLast();
    }
  }

  @override
  String toString() => 'AppContext($name)';
}
