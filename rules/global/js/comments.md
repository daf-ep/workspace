# Comments and Documentation in TypeScript and JavaScript

## The Three Forms

| Form | For what |
| --- | --- |
| `/** */` | the only comment you write: it describes the declaration that follows, and the editor shows it on hover |
| `//` | a tooling directive, and the license header. Never prose |
| `/* */` | **never** for documentation, only to neutralize code for the length of a trial |

A single star documents nothing. `/* ... */` placed above a function isn't attached to it: lost text, invisible on hover. The difference comes down to one character, and nothing signals it.

## A Comment Is Written as a Sentence

Capital letter at the start, unless it's a case-sensitive identifier, and a trailing period. True for every form, including fragments and `TODO`s.

```ts
/** Whether this chunk opens the line it belongs to. */
get opensLine(): boolean { ... }
```

---

## Nothing in a Function Body

`../common/comments.md` sets the rule: a comment describes a declaration, and a function body carries none. In TypeScript this plays out at one precise spot, where you were about to explain a line in the middle of a method.

```ts
// No: nobody but whoever reads the implementation will see this text.
protected async execute(): Promise<Response> {
  const callers = callersOf(this.access());

  // Both of these reach Redis and neither needs the other's answer, so they
  // travel together. The cost is that a refused caller now spends a rate
  // limit token.
  const [allowed, withinLimit] = await Promise.all([
    isAllowed(callers, this.webhookVerified()),
    withinRateLimit(this.rateLimitKey(), this.rateLimit()),
  ]);
  ...
}
```

```ts
// Yes: whoever calls `execute` sees the constraint on hover.
/**
 * Answers the request once the caller cleared the access check and the rate limit.
 *
 * @remarks
 * Both checks reach Redis and neither needs the other's answer, so they travel
 * together. A refused caller therefore spends a rate limit token, which is the half
 * of the trade we want: a flood of invalid tokens used to be answered without ever
 * being counted.
 */
protected async execute(): Promise<Response> {
  const callers = callersOf(this.access());
  const [allowed, withinLimit] = await Promise.all([
    isAllowed(callers, this.webhookVerified()),
    withinRateLimit(this.rateLimitKey(), this.rateLimit()),
  ]);
  ...
}
```

`@remarks` is made for this: it holds what overflows the summary without cluttering the line the editor shows first. When the text runs past a few sentences, it goes into the internal documentation, and the declaration keeps only the line that flags the constraint.

## The Documentation Comment

### What the Compiler Reads, and What It Discards

This is the point that decides the rest: **in a `.ts`, typing tags are ignored.** Most of what's left only helps the reader and the editor, `@deprecated`, `@see`, `@link`, `@linkcode`. One exception carries real weight even in a checked `.ts`: `@internal` drives actual tooling, the kind that strips a declaration from a published `.d.ts` when asked to. A declaration exported only so another package can call it or infer a type from it, never meant for a caller to use directly, carries `@internal` instead of full documentation, a short note instead of the usual complete treatment: `/** @internal An implementation detail. Do not use. */`. Its members don't need documenting field by field either, since the note already says why they're bare. The rest of what's left only exists in a checked `.js`.

The reason is simple: the language already has the feature, and it's checked.

| Tag | What replaces it in a `.ts` |
| --- | --- |
| `@type {T}` | the `: T` annotation |
| `@param {T} p` | the typed parameter `p: T` |
| `@returns {T}` | the return type `(): T` |
| `@typedef` | `type` or `interface` |
| `@callback` | a function type |
| `@template T` | generics `<T>` |
| `@satisfies {T}` | the `satisfies` operator |
| `@enum` | `enum`, or a union of literals |
| `@private` `@protected` `@public` | the modifiers of the same name |
| `@readonly` `@override` | the modifiers of the same name |
| `@extends` `@implements` | `extends`, `implements` |
| `@this` | the `this` parameter |
| `/** @type {T} */ (x)` | the assertion `x as T` |

**A type written in a comment is a type nobody checks.** It ages with nothing to signal it. Writing `@param {string} name` above a `name: number` produces no error, which is exactly the false state this rule closes off.

### A One-Sentence Summary, Alone in Its Paragraph

It's the one the editor shows on hover, often cut off at the first line: what runs past doesn't get read. Tags come after the prose, never between two paragraphs.

```ts
/**
 * Deletes the file at `path`.
 *
 * @throws {NotFoundError} When no file exists at `path`.
 * @throws {PermissionError} When the file exists but cannot be deleted.
 */
export function remove(path: string): Promise<void> { ... }
```

### The Grammatical Form Announces the Member's Nature

| What you're documenting | Starts with | Example |
| --- | --- | --- |
| a function whose side effect is the point | a third-person verb | `Connects to the server and fetches the query results.` |
| an accessor whose return value is the point | a noun phrase | `The number of retries left before this request gives up.` |
| a method that does real work to produce its return value | a third-person verb | `Parses a config from the given JSON string.` |
| a non-boolean field or variable | a noun phrase | `The current day of the week.` |
| a boolean | `Whether` plus a noun or gerund | `Whether the modal is currently displayed to the user.` |
| a class, an interface, a type | a noun phrase describing **an instance** | `A user's profile within the application.` |

An accessor and a method look alike here, but the test is what the return value costs to produce. A `get` that just reads a field already computed is a noun phrase. A method named `parse` or `copyWith` does real work each time it runs, so it starts with a verb even though a value is all a caller sees.

### It Never Repeats a Type, or the Signature

The name, the types, and optionality are already in autocomplete. The comment only explains the rest: a unit, a range, a precondition, a side effect, and a default value whenever the signature can't fully carry it. An interface property has no syntax for a default at all, so the comment is the only place it can live:

```ts
export interface CacheOptions {
  /** Milliseconds before an entry expires. Defaults to 5000. */
  ttlMs?: number;
}
```

A parameter's default is visible right in the signature, but a line still earns its place when the value is worth confirming without opening the function:

```ts
// No: the signature already says it.
/**
 * @param timeout {number} The timeout.
 * @returns {boolean} True or false.
 */

// Yes: what the signature can't say.
/**
 * Waits for the socket to answer.
 *
 * @param timeout - Milliseconds before giving up. Defaults to 3000. Must be positive.
 * @returns Whether the socket answered in time.
 */
```

### The Tags That Still Earn Their Keep

No type braces, and a dash after the parameter name.

| Tag | When |
| --- | --- |
| `@param name - ...` | the parameter's role doesn't follow from its name |
| `@returns ...` | the returned value needs a precision the type doesn't give |
| `@throws {Type} ...` | one per error the caller has to catch |
| `@example` | a short usage, in a code block |
| `@defaultValue` | the default value is decided elsewhere than in the signature |
| `@remarks` | what overflows the summary and doesn't fit elsewhere |
| `@see` | a pointer to a declaration or an address |
| `@linkcode` | same as `{@link}`, but renders the target in code font |
| `@deprecated` | **the only one that acts**: the editor strikes through usages, the compiler flags them |

`@deprecated` with no text is a missed opportunity: it says not to use it anymore, never what to use instead.

```ts
/**
 * @deprecated Use `remove` instead. Removed in the next major version.
 */
```

### A Full `@example` Gets Checked, a Fragment Gets Marked

When the project can evaluate the code blocks in a documentation comment, a full, self-contained example is a proof, not a promise: if it stops compiling, the check flags it instead of letting a false doc linger.

A short fragment that doesn't stand on its own, because it shows a call in its context without redeclaring that context, doesn't get that chance: it doesn't compile alone, and that's not a defect to fix. It's marked ` ```ts ignore ` rather than ` ```ts `, which tells the checker to read it without running it. The choice is made at writing time: if the block is short because it deliberately elides the setup, it carries `ignore`; if it's short because it has nothing more to show, it stays checkable as is.

### Links Are Written with `{@link}`

A name cited in plain text stays dead text. `{@linkcode}` is the same link rendered in code font, for a symbol name rather than a run of prose.

```ts
/**
 * Similar to {@link remove}, but never throws.
 *
 * See {@link https://example.com/spec | the specification} for the corner cases.
 *
 * @throws provided {@linkcode messageOrError} when the check fails.
 */
```

### A Getter and Its Setter Get Documented Only Once

Both are presented as a single field: documenting both loses one of the two texts.

```ts
class Pool {
  /**
   * The pH level of the water in the pool.
   *
   * Ranges from 0 to 14, acidic to basic, with 7 neutral.
   */
  get phLevel(): number { ... }
  set phLevel(level: number) { ... }
}
```

### The Comment Comes Before the Decorator

Same rule as an annotation in any other language: the documentation comment sits above the decorator, never between it and the declaration. A decorator that's itself exported follows the ordinary rule for an exported function.

```ts
/** A button that can be flipped on and off. */
@Component({ selector: 'toggle' })
export class ToggleComponent {}
```

### Each Overload Carries Its Own Comment

A function with several overloaded signatures documents every signature in full, never a single comment on the implementation meant to cover all of them.

```ts
/** Shows the document in the given column. */
export function showTextDocument(document: TextDocument, column?: ViewColumn): Thenable<TextEditor>;
/** Shows the document using the given options. */
export function showTextDocument(document: TextDocument, options?: TextDocumentShowOptions): Thenable<TextEditor>;
```

### Every Field of an Interface or a Type

An exported interface, `type`, or class documents **every one** of its members. A half-documented block makes it look like the silent fields have no origin or invariant, when in fact they simply weren't reread, and the reader ends up distrusting the documented ones too.

```ts
// No: two fields out of three leave the reader guessing.
/** A message as its handler sees it. */
export interface QueueMessage<T> {
  readonly id: string;
  readonly data: T;

  /**
   * How many times this message has been delivered, starting at one.
   *
   * It is the server's count, not the payload's, so it cannot drift from what happened.
   */
  readonly attempts: number;
}
```

```ts
// Yes: each field says what its signature doesn't.
/** A message as its handler sees it. */
export interface QueueMessage<T> {
  /** The identifier the queue assigned when the message was enqueued. */
  readonly id: string;

  /** The payload the producer sent, decoded into the handler's own type. */
  readonly data: T;

  /**
   * How many times this message has been delivered, starting at one.
   *
   * It is the server's count, not the payload's, so it cannot drift from what happened.
   */
  readonly attempts: number;
}
```

The first two lines teach almost nothing, and that's on purpose: they cost one line each and make the third one readable, because a field with nothing special says so instead of staying silent.

### What Deserves Documentation

**What's exported**, and only that by default: the functions, classes, types, and constants another file imports. It's the only surface a reader has without opening the implementation, autocomplete shows them the signature and this comment, nothing else.

An internal declaration only gets documented when its name isn't enough, and then it's the name that needs revisiting first.

Two cases fall outside this default: the members of an exported structure, which all get documented without exception, and test files, which carry no comments. The test's name and the assertion message do the work there, and at least they show up when the suite is red.

---

## The Comments That Drive Tooling

A family apart: the only one where removing a comment changes compilation.

```ts
// @ts-expect-error The upstream types are wrong here: the callback is optional.
// lint-disable-next-line no-console -- this is the CLI's own output.
// lint-ignore no-explicit-any
```

These aren't prose, they're instructions, and they're the only `//` allowed to appear in a function body. Three rules:

- **always give the reason**, in the comment. A rule suppression with no reason given is indisputable, and stays that way forever;
- **`@ts-expect-error` rather than `@ts-ignore`**: the first fails the day the error disappears, so it cleans up after itself; the second stays quiet and outlives whatever it was masking;
- **the narrowest scope**: one line, never a file.

---

## Formatting

The content is markdown, and the editor renders it. **Little markup**, **no HTML**. Identifiers and values between backticks to set them apart from prose. Code blocks open with backticks, with the language announced, never with indentation.

````ts
/**
 * Splits a path into its segments.
 *
 * @example
 * ```ts
 * segments("/a/b"); // ["a", "b"]
 * ```
 */
````

## The Writing

The tone and the level of concreteness are in `../common/comments.md`. Here's what's specific to the language.

**Brief**, clear and precise first, short after. **No abbreviations or acronyms** unless they're obvious. **`this` rather than `the`** to refer to the instance a member belongs to.

```ts
class Box<T> {
  /** The value this box wraps. */
  #value: T | null = null;

  /** Whether this box contains a value. */
  get hasValue(): boolean {
    return this.#value !== null;
  }
}
```
