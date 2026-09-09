# Comments and Documentation in Dart

## The Three Forms

| Form | For what |
| --- | --- |
| `///` | the only comment you write, placed on a declaration |
| `//` | an analyzer directive, like `// ignore: ...`, and the license header. Never prose |
| `/* */` | **never** for documentation, only to neutralize code for the length of a trial |

The choice isn't a matter of taste: a comment describes a declaration, so it's written `///` and placed above it. A function body carries nothing but the directives the analyzer reads.

## A Comment Is Written as a Sentence

Capital letter at the start, unless the first word is a case-sensitive identifier, and a trailing period. True for every form, fragments and `TODO`s included.

```dart
/// Whether this chunk opens the line it belongs to.
bool get opensLine => ...;
```

---

## Nothing in a Function Body

`../common/comments.md` sets the rule: a function body carries no comment, and what you would have written there moves up to the declaration, where the caller will see it.

```dart
// No: only whoever opens the implementation will read this sentence.
Future<Response> send(Request request) async {
  // The pool refuses a second call while the first is in flight.
  await _lock.acquire();
  ...
}
```

```dart
// Yes: whoever calls [send] sees the constraint on hover.
/// Sends [request] and waits for the answer.
///
/// The pool refuses a second call while the first is in flight, so a caller that
/// fans out needs a connection of its own.
Future<Response> send(Request request) async {
  await _lock.acquire();
  ...
}
```

When the text runs past a few sentences, it goes down into the internal documentation, and the declaration keeps only the line that signals a constraint exists.

## The Documentation Comment

### A One-Sentence Summary, Alone in Its Paragraph

The first sentence stands on its own and ends with a period. Tools only show it in lists: what runs past isn't read. A blank line separates it from the rest.

```dart
/// Deletes the file at [path].
///
/// Throws an [IOError] if the file could not be found. Throws a
/// [PermissionError] if the file is present but could not be deleted.
void delete(String path) { ... }
```

### The Grammatical Form Announces the Member's Nature

This is the most mechanical rule, and the one most often missed.

| What you're documenting | Starts with | Example |
| --- | --- | --- |
| a function whose side effect is the point | a third-person verb | `/// Connects to the server and fetches the query results.` |
| an accessor whose return value is the point | a noun phrase | `/// The [index]th element of this iterable in iteration order.` |
| a method that does real work to produce its return value | a third-person verb | `/// Creates a copy of this object but with the given fields replaced.` |
| a constructor | `Creates a/an ...` | `/// Creates insets from offsets from the left, top, right, and bottom.` |
| a non-boolean variable | a noun phrase | `/// The current day of the week.` |
| a boolean | `Whether` plus a noun or gerund | `/// Whether the modal is currently displayed to the user.` |
| a class, a type, a library | a noun phrase describing **an instance** | `/// A chunk of non-breaking output text terminated by a hard or soft newline.` |

An accessor and a method look alike in this table, but the test is what the return value costs to produce. `checkedCount` above just reads a count that already exists, a noun phrase. A method named `copyWith` builds a new object each time it's called, real work, so it starts with a verb even though a value is all a caller sees.

For a variable, you describe what the value **is**, never the work done to get it:

```dart
/// The number of checked buttons on the page.
int get checkedCount => ...
```

### It Doesn't Repeat the Signature

The name, the types, and the enclosing class are right in front of the reader. You only explain what doesn't read on its own.

```dart
class RadioButtonWidget extends Widget {
  /// Sets the tooltip to [lines].
  ///
  /// The lines should be word wrapped using the current font.
  void tooltip(List<String> lines) { ... }
}
```

A default value is the one exception worth a line even when it's already sitting in the signature: `Defaults to 3.` earns its place next to a named parameter, because a reader scanning the comment shouldn't have to jump to the constructor to learn it. It earns that place even more when the signature can't show it at all, a default resolved elsewhere at runtime:

```dart
class Icon extends StatelessWidget {
  /// The size of the icon in logical pixels.
  ///
  /// Defaults to the nearest [IconTheme]'s [IconThemeData.size].
  final double? size;
}
```

### A Repeated Idea Isn't Retyped

When a constructor says the same thing as the class it builds, or two declarations need the same paragraph, the text lives once, on a `{@template <name>}...{@endtemplate}` block, and every other spot that needs it carries `{@macro <name>}` instead of retyping the paragraph.

```dart
/// {@template drag_details.global_position}
/// The global position at which the pointer contacted the screen.
/// {@endtemplate}
class DragUpdateDetails {
  /// {@macro drag_details.global_position}
  final Offset globalPosition;
}
```

A comment that only macros a template needs nothing else above it: the macro is the whole comment.

### Identifiers in Scope Go in Brackets

Cited in brackets, they become links. Written in plain text, they're links lost.

```dart
/// Throws a [StateError] if the queue is closed.
///
/// Similar to [Duration.inDays], but handles fractional days.
///
/// To create a point, call [Point.new] or use [Point.polar].
```

### Parameters, Return Value, and Exceptions, in Prose

No `@param`, `@returns`, or `@throws` tag. Parameters get cited in brackets within the text, and you open a sentence with `Returns` or `Throws` when needed.

```dart
/// Defines a flag with the given [name] and [abbreviation].
///
/// The [name] and [abbreviation] strings must not be empty.
///
/// Returns a new flag.
///
/// Throws a [DuplicateFlagException] if there is already an option named
/// [name] or there is already an option using the [abbreviation].
Flag addFlag(String name, String abbreviation) => ...
```

### A Getter and Its Setter Get Documented Only Once

Both are presented as a single field: documenting both loses one of the two texts.

```dart
/// The pH level of the water in the pool.
///
/// Ranges from 0-14, representing acidic to basic, with 7 being neutral.
int get phLevel => ...
set phLevel(int level) => ...
```

### The Comment Comes Before the Annotations

```dart
/// A button that can be flipped on and off.
@Component(selector: 'toggle')
class ToggleComponent {}
```

### An Example Is Often Worth More Than a Paragraph

````dart
/// The lesser of two numbers.
///
/// ```dart
/// min(5, 3) == 3
/// ```
num min(num a, num b) => ...
````

### Every Field of a Model

An exported class documents **every one** of its fields and accessors. Three fields documented out of five suggest the other two have neither origin nor invariant, when in fact they simply weren't reread, and the doubt falls back on the first three too.

```dart
/// A message as its handler sees it.
class QueueMessage<T> {
  /// The identifier the queue assigned when this message was enqueued.
  final String id;

  /// The payload the producer sent, decoded into the handler's own type.
  final T data;

  /// How many times this message has been delivered, starting at one.
  ///
  /// It is the server's count, not the payload's, so it cannot drift from what
  /// happened.
  final int attempts;
}
```

The first two lines teach almost nothing, and that's the point: they cost one line each and make the third one readable, because a field with nothing special says so instead of staying silent.

### Exported but Not for Use

Dart has no access level between public and private, so a declaration exported only so another package can call it, generate code from it, or infer a type from it, never meant for a caller to use directly, needs a way to say so instead of carrying full documentation it doesn't deserve. `@internal` on the declaration, or a bare `/// @nodoc` when a tool reads that convention, replaces the complete treatment with a short note: `/// An implementation detail of the generated subclass. Do not use.` Its members don't need documenting field by field either, since the exported-but-not-for-use status already answers why they're bare.

### What Deserves Documentation

**What's exported**, libraries, types, members, and top-level variables meant to be imported. That's the only case expected by default.

**A library**, above its directive: a summary, the vocabulary it introduces, a full example, the entry points to look at first.

**What's private**, when the member is used elsewhere in the library and its reason for existing doesn't read on its own.

**Never a test file.** The test's name and the assertion message carry the intent, and they show up when the suite is red.

---

## Formatting

**Little markup**: it lights up the text, it doesn't replace it. **No HTML**, if formatting calls for it, it's the content that needs revisiting. **Code blocks open with backticks**, never with indentation: the language can be announced, and indentation breaks the moment you're inside a list.

````dart
/// You can use [CodeBlockExample] like this:
///
/// ```dart
/// var example = CodeBlockExample();
/// print(example.isItGreat); // "Yes."
/// ```
````

## The Writing

The tone and the level of concreteness are in `../common/comments.md`. Here's what's specific to the language.

**Brief**, clear and precise first, short after, but short. **No abbreviations or acronyms** unless they're obvious to any reader. **`this` rather than `the`** to refer to the instance a member belongs to: `the` leaves it unclear which instance is meant.

```dart
class Box {
  /// The value this box wraps.
  Object? _value;

  /// Whether this box contains a value.
  bool get hasValue => _value != null;
}
```
