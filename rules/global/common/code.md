# Write Code

`comments.md` says whether a comment is needed and what it should say. This file says what the code around it should look like, because a comment doesn't make up for a function you can only understand by reading it twice.

What justifies this file is that code is read far more often than it's written, and almost always by someone looking for something other than what was on your mind while writing it. The reader is in a hurry, doesn't know the context, and has only the source in front of them.

"Clean code" doesn't mean anything on its own. This file says what to put behind it.

## Code Should Read as If a Human Wrote It

This isn't a matter of taste, it's the same criterion as for prose: someone who stumbles on it with no knowledge of the context should understand it in one reading.

**The neighboring file has authority over form.** Naming, structure, how an error is signaled, order of declarations: you write like the code around it, even when you'd do otherwise in an empty repo. A better solution in the abstract but foreign to the code it joins stays a bad solution, because the reader loses more from a convention changing mid-file than they gain from the new one.

**What gives away machine-written code.** None of these is a compile error, which is what makes them easy to let through.

| The sign | What it says |
| --- | --- |
| `process`, `handle`, `doWork`, `data`, `result`, `obj` | the name names nothing, and nobody looked for the one that would have fit |
| `Manager`, `Helper`, `Utils`, `Service` tacked on in place of a subject nobody searched for | the class has no subject, it has a category |
| three near-identical functions with numbered names | a split you suffered through, never chose |
| the same error-handling block copied into every branch | repetition passing for rigor |
| a parameter nobody passes, an option nobody changes the value of | built for an assumed need |
| abbreviations, except the ones anyone can read | space saved against time lost |
| column-aligned `=` signs and comments | the first rename breaks it, and the diff doubles |
| a comment banner separating two sections | the file holds two files, and needs splitting |
| two names differing only by case or a single letter, for operations that behave differently | the name carries a real difference where a reader at the call site can't see it |

**Pleasant to the eye, concretely.** A function fits on screen without scrolling, and when it doesn't, it's doing more than one thing. A line doesn't overflow the width the repo uses. The language's formatter decides the spacing, and you don't argue with it. A file reads top to bottom, the exported surface first and the details after, so you can stop as soon as you've found what you were looking for.

## Vocabulary Doesn't Get Invented Twice

"The neighboring file has authority over form" holds for a file, not for the whole repo. Before naming an operation, you check whether a word already exists elsewhere for the same role, a mutating and non-mutating pair, a network-read verb, a computed accessor, and the name already in place wins over the one you'd have invented, even when the place that carries it is far off in the tree.

The risk doesn't show when reading a single file. `fetch` here, `load` there, `get` elsewhere for the same operation break nothing at compile time, and each of the three names is defensible on its own. What gets lost is the search: someone looking for how this kind of value is read elsewhere in the repo only finds one of the three, and rewrites the second duplicate without knowing it. Criterion 3 of `review.md`, "does this look like the neighboring code," reads here at the scale of the whole repo, not just the open file. It's the same defect the signs table above lists at the scale of a file, moved up a level: nothing at compile time flags three names for one role any more than it flags a `Manager` suffix standing in for a subject nobody looked for.

This isn't the rule of the third use, further down: that one moves duplicated behavior into shared code. Here nothing is duplicated to move, it's the word that diverges while the role stays identical, and the search happens before writing, not after the fact.

## A Function Does the Job It's Named For

The name is a contract, and the body has to keep it exactly: no less, no more.

**The "and" is a naming signal, not a proof, and it needs its own test.** If a function's honest name contains an "and," ask whether either half could be called on its own, and whether some caller would ever want that. When the answer is yes, there are two functions: `validateAndSave` makes two, and a caller who only wanted to validate has no way to say so. When no caller ever wants one half without the other, because the two steps are one atomic operation, the merged name is the honest one, and splitting it only forces every caller to reassemble the two calls by hand. The test only catches a function whose name says "and." A function like `loadWorkspace`, which reads configuration, installs plugins, writes generated files to disk, and prints a summary, carries none of that in its name, and the word test misses it entirely: the name still has to describe everything the body does, not just avoid the word "and."

**An unannounced side effect is a lie.** A function that checks writes nothing. A function that reads modifies nothing. A function that returns a value doesn't drop a file on the way. The day someone calls it twice to check two inputs is when the defect surfaces, and it won't look like its cause.

**One level of abstraction per function.** The one that orchestrates calls named steps, it doesn't open a file or concatenate a query between two calls. The mix shows at a glance: the eye drops from three lines of domain vocabulary to one line of plumbing, then climbs back up.

**Parameter count is a measurement.** Past three, a type is missing to group them. A boolean switch that picks between two genuinely different operations calls for two named functions instead, because a call with `true` in the last position tells the reader nothing about which one runs. A boolean that only tunes a policy with a safe default, such as whether to retry once more, stays one function: it isn't two behaviors sharing a name, it's one behavior with a dial.

**You extract to name, not to shorten.** An extracted function whose name teaches nothing more than its body just moved the problem over by one step. The good sign that extraction is warranted is having a name to give it.

## A Class Exposes Only What Its Name Justifies

A class is a name, and its members are what the named thing can do or what it carries. It's the same rule as for a function, applied to a list of members instead of a body.

`Person` knows `run()`, `sleep()`, `jump()`, and carries an age and a name. It doesn't know how to send an email, doesn't talk to a database, and doesn't know how to serialize itself to JSON for today's API. Those three things exist, they simply belong to something else.

**The test fits in two readings.** You read the class name, then the list of its members. A member that surprises belongs to another class. Once no name covers the whole list anymore, the class holds two, and it needs splitting before a third subject arrives.

**An accessor exists because the state it exposes belongs to the thing.** A getter and a setter per field, added by reflex, turn the class into a data bag: the logic that should live inside ends up scattered across every caller, each with its own version. The question isn't "how do I read this field" but "what does the caller want to do," and often the answer is one more method and one fewer accessor. The tell that separates a data bag from a class that only looks like one: in a data bag, almost all the accessors are trivial, a field returned or set with nothing behind it. A class with real logic behind most of its methods and a couple of plain accessors on the side doesn't have this defect, even if it also does too much, and that's a different problem to fix by splitting along its subjects, not by removing accessors.

**State closes by default.** Private fields, values that can't change when nothing requires otherwise, and an object valid from the moment it's built rather than one that needs three calls in the right order to initialize. This is about an object whose state lives inside its own construction. A component whose state is owned by a framework's render cycle, set in one pass and completed after mount, isn't built the same way: an intermediate value there, such as a loading flag with no data yet, is a correct step in that lifecycle, not an invalid object, because construction was never where its state lived.

**A class with no state isn't a class.** In a language with first-class functions, a set of functions belongs in a module. Wrapping them in a class you never instantiate only adds a prefix to type.

## Language Mechanisms Serve When the Problem Calls for Them

A language has already solved part of the problem, and its solution is checked by the compiler where ours isn't.

**Polymorphism replaces a type check.** A `switch` on a field that says what kind of object it is is polymorphism written by hand: every `switch` in the repo needs remembering at every new kind, and nothing reminds you. An interface moves that reminder into the compiler, which refuses an incomplete implementation.

**You inherit to be substitutable, never to save lines.** A subclass promises it can be passed anywhere the parent class is expected, and breaking that promise breaks code nobody rereads. Inheriting to grab three useful methods creates a link you'll pay for at the parent's first change. When the need is to share code, that's composition.

**No hierarchy for a single implementation.** An interface with one implementer and one caller is an indirection to cross on every read, for a flexibility nobody uses. It's warranted when several things are genuinely interchangeable, or when the boundary serves to isolate what you don't control. The signal that catches it early: an interface named after its only implementer, like an `IWidget` sitting next to a single class `Widget`. That naming pattern is the tell that the interface was added for form, not for a second implementation that actually exists.

**A type rather than a runtime check.** A string carrying a convention gets checked everywhere it passes and gets missed one time in ten. A type that makes an incorrect state impossible to write gets checked once, at construction. Same reasoning for errors: the language's mechanism, not a homemade return code half the callers will ignore.

## The Third Use Moves Into Shared Code

This is the rule that demands the most discipline, because it plays out at the moment you're in a hurry. When `.claude/dpw/code.md` exists, it says how many uses this project tolerates before sharing; the number that follows is the one that applies by default.

**Two uses, you look. Three, you share.** The first duplicate might be a coincidence, and a bad abstraction costs more than a duplication: it gets paid at every reading and comes apart badly. At the third, it isn't a coincidence anymore.

This count applies inside a single unit of publication, the boundary within which code ships under one version. Across that boundary, between two components that release on their own schedule, the count doesn't decide anything: it's the question further down, whether these two places will change together, that does. Sharing code across a publication boundary means both sides now depend on the same version of the same thing, and updating it becomes a change both have to accept at once. When two components were split into separate units precisely so each could move at its own pace, leaving a third occurrence unshared across that boundary isn't a lapse, it's the choice that keeps the split meaningful.

**A function two zones use doesn't live in either.** Leaving it with one makes that zone a dependency of the other, for a single function, and the resulting link has no reason to exist. It moves to wherever the project declares for shared code, and both callers import it from there.

**What moves up loses its original context.** A shared function doesn't know who calls it. If it needs a parameter to tell its callers apart, it isn't shareable: these are two functions that look alike, and merging them produces a body every new caller widens with a branch.

**Resemblance of the text isn't the criterion, the reason to change is.** Two blocks identical today that will evolve for two different reasons don't get merged. The question to ask is: will these two places change together? If the answer is no, these are two things that look alike, and the resemblance is an accident.

**The shared code never knows its users.** Dependencies run from the specific to the general, and an import that goes from the shared code back to whoever uses it signals the split is wrong.

**A shared place isn't a dumping ground.** You organize by subject, never by nature: one file for time, one for addresses, one for currency, never a file of utilities, helpers, or miscellany. A name that doesn't say what it holds becomes the place where you put what you don't want to sort, then the place where nothing can be found anymore. The moment to split is when a second subject shows up, not later: a shared file that starts with time and gains address gets a second file at that point, before the first one needs a rename to undo a name that no longer says what it holds.

## You Split Into Files, But Not Into Crumbs

**A file has one subject, and its name says so.** When it takes two words joined by "and" to say what it holds, it holds two things. Three signs confirm it: you scroll to find a declaration you just read, two unrelated pieces of work touch the same file, and the imports at the top mix two worlds.

**What changes together stays together.** A type and the functions that handle it, a case and its variants. Splitting in the middle of a subject forces you to open two files to understand one mechanism, and to edit two for one change.

**A file per declaration costs more than it earns.** Twenty six-line files demand twenty openings and twenty imports to read what one file would have shown at a glance.

## Write for Six Months From Now

**The reader six months from now is almost always yourself**, and you'll have forgotten all of today's reasoning. Naming correctly now is what serves that reader, because now is the only moment you know the intent.

**Preparing for the future isn't guessing at it.** An extension point nobody implements, an option nobody passes, a layer that only forwards: all of that is weight laid down for an imagined need, and the real need rarely shows up where you planned for it. What's easy to change beats what's already been twisted for a hypothetical case, and when in doubt you take the reversible option.

**You leave the passage better than you found it.** A name that's stopped being true gets fixed, dead code gets removed, a duplicate that just hit its third use moves up. Without turning the passage into a rewrite: what has nothing to do with today's work goes into another commit, and `push.md` says how.

## What Review Judges

Criterion 4 of `review.md`, the simplest form that works, is the one this file feeds. The questions it asks are the same ones taken from the other end: what can be removed without losing anything, which abstraction serves only once, which duplicate was left behind.
