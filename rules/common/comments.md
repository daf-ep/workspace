# Comment

This file says whether a comment is needed and what it should say. The form then depends on the language, and it's in the matching language folder.

## You Comment the Code, and Only the Code

A comment goes in a code file, and nowhere else. Not in scripts, not in configuration files, not in build or orchestration descriptors, not in YAML or JSON.

It's the project that declares what counts as code for it, and the boundary isn't about the language but the reader. An executable language isn't code just for that: a schema, a migration, or a query can very well fall on the side the project doesn't comment, and it's up to the project to say so. A code file is read by someone trying to understand an intent. A configuration file is consumed by a tool, and the person opening it is looking for a value, not a line of reasoning. The why of an infrastructure choice goes into the internal documentation instead, at the spot that matches the modified file.

The rule has a useful side effect: it keeps configuration from becoming the scratch pad where you explain what you couldn't name anywhere else.

## A Comment Sits on a Declaration

A comment describes the thing declared right below it: a class, a function, a method, an accessor, a field, a type. It lives above it, and nowhere else.

**A function body carries none.** What you would have written in the middle moves up to the declaration that contains the passage, or goes down into the internal documentation once it runs past a few lines. Three reasons, and the third is the most useful.

A comment placed in the middle of a body only reaches whoever reads the implementation. Whoever calls it never sees it, even though that's exactly who needs to know that a refused call still spends a token, or that a method assumes an open transaction. Moved up to the declaration, the same text shows up in autocomplete, right when the question comes up.

A body gets split, moved, and rewritten far more often than a signature. A comment left in the middle outlives the line it was explaining, and nothing signals it. On a declaration, it's in plain sight of whoever changes the contract.

And a passage that calls for an explanation in the middle first calls for something else: a named constant, an extracted function, a type that makes the intent verifiable. That's "Naming Comes Before the Comment," further down, and `code.md` takes up the same subject from the angle of form.

**Tooling directives aren't affected.** Suppressing a lint rule or marking an expected error is an instruction for a tool, not prose, and it has to stay attached to the line it targets. The language folder says which ones exist and how to write them.

A `TODO` follows the general rule: it sits on a declaration. When it doesn't mean anything at that spot, it's pointing at work bigger than the line it was placed on, and its place is in the internal documentation.

## You Always Document What's Exported, Never by Paraphrasing

What's exported gets documented, because someone will read it from autocomplete without ever opening the implementation. What the declaration can't say for itself also gets documented: an accepted trade-off, an external service's limit, the special case being handled, a precondition a caller has to hold.

What you don't write is what's already obvious. A comment that paraphrases the line below, that repeats a clear name, or that restates a signature adds nothing and turns false at the first change.

The two cross paths often in the same file, and that's normal. A method whose name says everything gets documented in one sentence, while the one next to it, which caps a memory amount, deserves three lines, because nothing in its name or signature says where the value should come from or what breaks if you pick it wrong.

## An Exported Structure Gets Documented Field by Field

A type, an interface, an exported model carries a comment on **each** of its fields. Not the three that had something to say, all of them.

It's the only rule in this file that asks you to write where there's nothing interesting to say, and it's justified by what the other choice produces. A block where two fields out of five are documented reads like a claim: the other three have no unit, no range, no origin, no invariant. The reader has no way to tell the genuinely obvious field apart from the one nobody reread, so they distrust all five, and the documentation on the first two loses its value.

Each line says what the signature can't: where the value comes from, who fills it, in what unit, between what bounds, what makes it invalid, what it's worth when absent. When a field truly has nothing more than its name, the sentence stays short and names the thing. It costs one line and removes the doubt about the other four.

The rule targets exported structures, the ones that cross a boundary. A structure internal to a file follows the ordinary rule instead.

## A Test Carries No Comment

A test is self-sufficient, or it's poorly written. What you'd want to put in a comment already has two places to go, and both get read exactly when it matters, that is, when the test fails.

The test's name carries the case and the expectation, in a sentence that reads in the suite's output. The assertion message carries what sets this particular call apart from the others. A comment, on the other hand, shows up nowhere when the suite is red, and that's the only moment anyone tries to understand the test.

When the setup needs an explanation, what's needed isn't a comment, it's a name: a named setup function, a named constant instead of an obscure literal, a dataset named for what it represents.

The license header stays, as everywhere. And an exported harness, one other tests import, is code like the rest: its surface gets documented under the rules above. It's the test file itself that carries nothing.

## Naming Comes Before the Comment

When a passage needs explaining, the first question isn't how to explain it, it's why it needs to be. Three things fix the problem better than a comment, in this order: a named constant instead of a literal, an extracted function whose name says what the comment would have said, an explicit type that makes the intent verifiable by the compiler.

A comment you hesitate to remove almost always signals that one of these three is missing. `code.md` picks up the same subject from the other end, the form code needs so there's nothing left to explain.

## It Says Why, Never What

The what is already written right below, and it'll still be right once the comment has stopped being. A comment that paraphrases the next line doubles the surface to maintain and turns into a lie at the first change.

## The Why That Runs Past a Few Lines Goes Into the Docs

An accepted trade-off, an external service's limit, an architecture decision, a tooling bug worked around, all of that gets written into the internal documentation. The code carries the short reason, on the declaration, the documentation carries the decision and what was ruled out. The rest is in `docs.md`.

It's also where the paragraph you would have placed in the middle of a body goes. When it doesn't fit in two sentences on the declaration, it goes down into the documentation, and the declaration keeps the line that says a constraint exists.

That's what makes the rule workable. You don't remove a comment while losing what it carried, you remove it by writing elsewhere what it said that was true. A comment that doesn't deserve a line of documentation didn't deserve to exist either.

The other way around, every time you change code, you update the documentation that matches it. That's where the context lives, and nowhere else.

## Two Things That Aren't Comments

The license header, at the top of the file, after the shebang if there is one. It's a legal notice, often checked by a CI script, kept as is, with no writing rule applying to it. It's also what explains how a seventy-line script can have thirty lines starting with a hash without carrying a single comment.

The prose a command prints. A line written to standard output to tell a human what just happened is interface, and it speaks to someone reading a terminal, not someone reading the source.

## How to Write It

This section isn't only about comments. **It applies to any text you write, wherever it goes**: a comment, a commit message, a test name, an assertion message, a log line, a label a command prints, a documentation file. The reader is human in every case, and a text that smells like a machine makes that felt everywhere the same way.

A text is written the way you'd explain it to someone sitting next to you, with normal sentences, a subject and a verb. Not a manual, not a telegram.

### Signs You Don't Use

These give away machine-produced text before the vocabulary even does. None has a legitimate use in this repo.

| Sign | Instead |
| --- | --- |
| an arrow, `→` `⇒` `->` `=>` | a word: `becomes`, `means`, `to`, or two separate fields |
| a decorative bullet, `·` `•` `▸` `✓` `✗` | nothing, or a markdown list dash |
| an em dash or en dash used as a connector, `—` `–` | a comma, a colon, a period, or a real conjunction |
| an emoji, a smiley | nothing |
| an exclamation point | a period |
| emphasis capitals | the sentence that says why it matters |
| a drawn separator, `═══` `───` `***` | nothing, the structure is enough |

The hyphen keeps its normal uses: a compound word, a range, a markdown list dash. What's refused is the dash that replaces a sentence structure.

Command output doesn't get a pass either. A measurement reads `0.412 ms per read, or 2427 per second`, not `0.412 ms/op → 2427 ops/s`.

### Vocabulary You Don't Use

Brochure vocabulary, like robust, elegant, powerful, optimized, seamless, or production-ready. And hollow phrases that name nothing, along the lines of "handles the logic," "does the work," or "for performance reasons."

What you write instead is the real thing. The service that misbehaves, the exact case that's a problem, the precise consequence of doing otherwise. An abstract comment can't be verified, and it doesn't go stale either, which is worse, since it outlives what it was describing.

```
No
Handles the edge case for robustness.

Yes
Stripe sends the same event twice when the webhook times out, and the second one
must not create a second invoice, so the handler keys on the event identifier.
```

The test is that someone who lands on it with no knowledge of the context understands what it's for in one reading. If it needs rereading, it missed, and that's the comment to redo.

A comment gets worked like code. The first draft rarely says what you meant, and a comment dashed off costs more than no comment at all, because it gives the impression the question was handled.

## The Language

Code, identifiers, logs, and comments are written in English, whatever language you're working in and whatever language the internal documentation uses. What lives in the source never gets translated.
