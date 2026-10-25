+++
date = '2026-10-25T03:52:24Z'
draft = false
title = "We've been doing agentic development wrong"
math = true
+++

So, a bit of a story time here but I promise it's relevant to the title if you follow the thought
process through to the end.

Early on in my programming journey, as a naive fledgling pythonista I pretty quickly developed an
interest in two topics: niche programming languages, and machine learning. My other posts probably
tipped you off to that! So, as happens to pretty much anyone in that part of the Venn diagram I
stumbled across lisp. I had already dabbled in a few non-python languages like C#, F#, and Fortran
(yeah, I was a bit weird...) and, frankly: I **HATED** it! The lack of imperative crutches to fall
back on, the apparent lack of data structures, the realisation that actually everything is a
single structure, the parentheses. HOLY CRAP, THE PARENTHESES! `(torture (was (it)))`

So, I gave up!

Fast forward almost a decade and I was in a bit of a different situation. I had a ton of practical
programming experience, but I really wanted to get to grips with the finer theory of the craft. To
learn that I did some research into which books are considered the landmark texts in computer
science and one caught my attention, a book the CS community affectionately referred to as "The
Wizard Book". That book was, of course, Abelson and Sussman's 1984 "Structure and Interpretation
of Computer Programs" (SICP for short).

![Structure and Interpretation of Computer Programs](https://upload.wikimedia.org/wikipedia/commons/9/9d/SICP_cover.jpg "The cover of SICP")

Oooooh, so weird and wizard-ey. So $\lambda$! And what's with the weird table with the lion foot?

Anyway the only problem was that this book not only uses lisp, it was literally the origin
point for one of the 3 main lisp dialects: "scheme". That almost put me off, but I decided to try
it anyway. I'm not sure if it's the quality of the book, or the fact I'm just a better programmer
than I used to be (probably a bit of both), but 50 pages in _I was hooked_. Where other
programming languages felt like a lego kit I could build what I want with, lisp felt like a
shapeless ball of clay I could sculpt whatever I wanted with! It just *clicked*, and I was having
a ton of fun with it. Soon it began to affect my code accent in other languages. My day-to-day
python scripts for work started to be filled with recursion, trees of nested dictionary, tries,
and monoidal compositions. Even outside of lisp, the wiring allowing me to understand my code as a
mathematical data structure instead of a list of instructions made me a better programmer because
the mental model is closer to what a program *actually is*. A purely imperative program is a
**script**, a **program** is a non-linear data structure.

## Wasn't This Article Supposed to be About Agentic Development?

Yes, and I'm getting to that! So, I was writing some quick little scripts for generating figures
using racket (great language, highly recommend it) and I needed to put together a collection of
boilerplate primitives to build the figures with. Perfect job for an opencode agent to do, right?
Well, as I discovered that day: LLMs are absolutely awful at counting parentheses. They're
actually **great** at writing lisp, but after they write that great code they consistently burn
thousands of tokens just balancing parentheses! So, that led me to think: surely there's an MCP
that can allow an agent to keep track of parentheses? Turns out, there isn't! So, I decided to try
and make one. And it got a bit out of hand... (in a good way)

## Counting Parentheses is Harder Than it Looks

So, balancing parentheses is easy, but pretty quickly I realised that it wasn't enough to just
naively balance the parentheses. Just because we can tell a parenthesis is missing doesn't mean we
can just whack a parenthesis on the end and call it a day. For example, the following snippet is
missing a parenthesis:

```scheme
(define x 3)
(define y 4)
(+ (if (> x 0) x y 10)
```

Our first instinct might be to just add a parenthesis to the end of the function. If we make that
fix, we get the following result:

```scheme
(+ (if (> x 0) x y 10))
;Ill-formed syntax: (if (> x 0) x y 10)
```

Ok, that error makes sense: the `if` here has 3 branches, that's obviously not possible. So then,
what if we move the parenthesis one element further to the left? Couldn't that be a viable
solution?

```scheme
(+ (if (> x 0) x y) 10)
;Value: 13
```

Perfect! Right? Well, not quite. Because we could **also** balance it by putting the parenthesis
after the x instead gives the following:

```scheme
(+ (if (> x 0) x) y 10)
;Value: 17
```

And here is the core of the problem: we can add the missing parenthesis in one of two places, and
depending on which we choose we get totally different results. So, clearly, just naively adding a
parenthesis wherever we first find a valid one is not going to be enough to fix this shortcoming
of LLMs when they write lisp. And this is where the project evolved...

## So, what next?

Ok, so if this doesn't work how can we fix this? Well, to start with our MCP would need to
remove an excess parenthesis to make a valid tree. Then, it would need to be able to
parse the program into a complete tree. Finally, we would need a way to show the agent the nodes
in the tree and ask it "which node needs to be split to restore the intended tree?". But, this
posed a whole new problem: how do we determine which parenthesis is the excess one? This is the
same problem as before but in reverse! But, that second and third step **did** actually spark a
new, better idea. If we're parsing the tree, and then adding a node `split` operation; we've
now done most of the hard work in writing an entire structural editing tool using the "paredit"
set of operations. Paredit has (at its most simple) 6 basic operations: `insert`, `remove`,
`wrap`, `unwrap`, `slurp`, and `barf`. For those who are not lisp programmers (aka: all the
normal programmers who don't have a weird fascination with niche languages), paredit will be a bit
of a new concept, but it isn't actually that complicated. It's basically a series of editor macros
that quickly allow the programmer to make common lisp code edits without needing to manually keep
track of all their parentheses.

{{< structural_figure caption="The six fundamental structural AST editing operations: insert, remove, wrap, unwrap, slurp, and barf." >}}

Although these are usually programmed as macros, you can see from the diagram that, fundamentally,
they're actually all methods of manipulating the tree structure that makes up the lisp program
by shuffling parentheses around. With these 6 basic primitives, many other more complex operations
can also be created. For example: our `split` operation above is basically just a function that
accepts an index ($i$), calls `barf` $n - i$ times, does a `wrap` on the last `barf`ed element,
then runs `slurp` on that new node $n - 1$ times. There are several other compound operations like
this that most packages implement.

{{< compound_figure caption="Common compound structural editing operations composed from the six primitives: split, join, raise, and transpose." >}}

Lisp programmers generally embrace this kind of structural editing and miss it in other languages,
as it allows you to think of your program in terms of its fundamental AST nodes and structure
rather than as lines of text that you have to mentally parse and infer the flow of data through.
This is where that feeling of lisps being an "amorphous ball of clay" comes from: the language
gives you a single data structure (lists), 5 (ish) special forms, and one syntax rule (Polish
notation), and beyond that you're basically just pushing lists around to try and create a tree
with the correct shape.

Anyway: back to how this is relevant to agents.

## Agents Shouldn't Write Programs, They Should SCULPT Them

So, at this point I had realised that:

1. I had already built almost all the machinery for a paredit MCP
2. If the agent simply used paredit for everything, then there'd be no need for function to
    balance parentheses; paredit would keep them balanced naturally

I then realised that if I was parsing the program to a tree anyway it suddenly became trivial
to search for specific nodes in that tree, and that simple code quality metrics like cyclomatic
complexity and duplicate variables become really easy to spot. And, so: the
`structural-editing-mcp` was born! This MCP reads an entire lisp program into a tree that it holds
in memory, and exposes several paredit operations, code navigation operations, and code linting
operations to the agent which it can use to rewrite the program, and then can dump that new tree
back into perfectly formatted lisp code. Once the tree reading/writing had been figured out, the entire process became a simple matter of
list manipulation in memory. Because every node in our AST is represented as a tagged list
(`(:path ... :paren ...)` or `(:path ... :leaf ...)`), operations like inserting a node, wrapping
an expression in parens, or splitting a list at an index reduce to just a few lines of pattern
matching and list slicing:

```lisp
(defun insert-node (tree parent-path index node)
  "Insert AST NODE into the children of the node at PARENT-PATH at INDEX."
  (update-node-at-path tree parent-path
    (lambda (parent)
      (match parent
        ((node p tag children)
         `(:path ,p ,tag ,@(take index children) ,node ,@(drop index children)))
        (_ parent)))))

(defun wrap-node (tree path tag)
  "Wrap the node at PATH in a new collection node with TAG (e.g. :paren)."
  (update-node-at-path tree path
    (lambda (node)
      (list :path path tag node))))

(defun split-node (tree path child-index)
  "Split the collection node at PATH into two siblings at CHILD-INDEX."
  (update-node-at-path tree path
    (lambda (node)
      (match node
        ((node p tag children)
         (multiple-value-bind (left right) (halves children child-index)
           `(:path ,p ,tag (:path ,p ,tag ,@left) (:path ,p ,tag ,@right))))
        (_ node)))))
```

And because the program is already in memory as an explicit AST, linting and structural analysis
are equally straightforward. Detecting an anti-pattern like `(if <cond> (progn ...))` (and
suggesting a clean rewrite to `(when <cond> ...)`) is just matching on the operator and checking
the shape of its children:

```lisp
(defun check-if-progn-to-when (node path dialect)
  "Detect (if <cond> (progn <body...>)) and suggest replacing with 'when'."
  (when (single-branch-if-p node)
    (let* ((children (get-node-children node))
           (cond-node (second children))
           (then-node (third children)))
      (multiple-value-bind (is-progn body-nodes) (progn-form-body-nodes then-node)
        (when is-progn
          (make-lint-finding
            :rule :if-progn-to-when
            :path path
            :message "Prefer '(when <cond> ...)' over '(if <cond> (progn ...))'."
            :severity :style
            :suggested-fix (format nil "(when ~A ~{~A~^ ~})"
                                   (sexp-to-string cond-node)
                                   (mapcar #'sexp-to-string body-nodes))))))))
```

Computing McCabe cyclomatic complexity or flagging excessive nesting depth follows the exact same
principle: a simple recursive walk over the node hierarchy that tallies branching forms (`if`, `cond`,
`case`, `loop`):

```lisp
(defun compute-branch-complexity (node &optional (dialect :common-lisp))
  "Compute McCabe cyclomatic complexity of NODE: base 1 + 1 per branching form."
  (let ((complexity 1))
    (labels ((walk (curr)
               (let ((op (node-operator-symbol-name curr)))
                 (when op
                   (incf complexity
                         (branch-form-complexity-increment op (get-node-children curr) dialect)))
                 (dolist (c (get-node-children curr))
                   (walk c)))))
      (walk node)
      complexity)))
```

As you can see this allows us to dramatically simplify most code reading/editing operations, and
maintain code quality. As you may have noticed: I wrote this in common lisp. This was a deliberate
decision because:

1. Lisp is **famously** good at manipulating lisp code
2. Common lisp can be compiled to extremely efficient, near C performance code
3. I like lisp. And, most importantly:
4. Because this MCP can now act as a bootstrap to improve itself via dogfooding

Once this basic bootstrap was complete, we moved on to testing the MCP by developing even more
features for this MCP!

## So, How Well Does It Work?

Well, anecdotally: immediately the feature list grew significantly, as did the line count. What
didn't grow? The token usage. In fact, that continued to shrink further and further over time.
And, based on my own code review (as, admittedly, more of a schemer than a common lisper): the
code consistently seems to have improved. By dogfooding the MCP, the agent found and squashed
dozens of bugs along the way as we added more advanced editing, code awareness, and code analysis
features. In its current form: the MCP server even allows multiple concurrent agents to work
on the tree in parallel, branching off and merging various instances of the program as they work.
It's actually been really cool to see!

Of course, these are just anecdotes. So let's look at some examples. As an example of a code
snippet that the agents improved once they gained structural editing capabilities let's look
at one of the more interesting changes between the commit where structural editing began and the
current repo head.

In the initial bootstrap commit (`6a43976`), `delete-node` duplicated `pop-node`'s traversal logic
almost verbatim—taking 15 lines of explicit subtree updating:

```lisp
(defun delete-node (tree path)
  "Delete the node at PATH."
  (if (null path)
      nil
      (let ((idx (lastcar path)))
        (update-node-at-path tree (butlast path)
          (lambda (parent)
            (match parent
              ((node p tag children)
               `(:path ,p ,tag ,@(take idx children) ,@(drop (1+ idx) children)))
              (_ parent)))))))
```

Once the agent was given AST inspection and refactoring capabilities, it quickly spotted that
`delete-node` was just `pop-node` where the extracted element was discarded. In the current HEAD,
`delete-node` has been cleanly collapsed to a single line:

```lisp
(defun delete-node (tree path)
  "Delete the node at PATH."
  (nth-value 0 (pop-node tree path)))
```

As another example, the initial implementation of `swap-nodes` attempted a naive double-overwrite:
`(overwrite-node (overwrite-node tree path1 node2) path2 node1)`. This worked most of the time, but
broke whenever path indices shifted or whenever one node was an ancestor of another. During
refactoring the agent noticed this structural fragility, added ancestor collision detection
(`prefix-of-p`), and rewrote `swap-nodes` into a single-pass AST traversal that swaps subtrees and
automatically reindexes all paths in place.

```lisp
(defun swap-nodes (tree path1 path2)
  "Swap the nodes at PATH1 and PATH2 in a single pass."
  (when (equal path1 path2) (return-from swap-nodes tree))
  (when (or (prefix-of-p path1 path2)
            (prefix-of-p path2 path1))
    (error 'invalid-path-error
           :path (list path1 path2)
           :tree tree
           :message "Cannot swap ancestor and descendant nodes"))
  (let ((node1 (get-node-at-path tree path1))
        (node2 (get-node-at-path tree path2)))
    (unless node1
      (error 'invalid-path-error :path path1 :tree tree :message (fmt "Node not found at path ~A" path1)))
    (unless node2
      (error 'invalid-path-error :path path2 :tree tree :message (fmt "Node not found at path ~A" path2)))
    (labels ((walk (node curr-path)
               (cond
                 ((equal curr-path path1)
                  (reindex-paths node2 curr-path))
                 ((equal curr-path path2)
                  (reindex-paths node1 curr-path))
                 (t
                  (match node
                    ((node p tag children)
                     (list* :path p tag
                            (loop for child in children
                                  for i of-type fixnum from 0
                                  for child-path = (append curr-path (list i))
                                  collect (if (or (prefix-of-p child-path path1)
                                                  (prefix-of-p child-path path2))
                                            (walk child child-path)
                                            child))))
                    (_ node))))))
      (walk tree '()))))
```

In fact, to test if this was just a perceived win or a tangible benefit I devised a test to compare
performance with and without the MCP. To test this a low powered, local agent was given the task of
performing a code quality review on a small lisp program both with and without the MCP. For this, I
used `minicpm5-1b:gguf:q8` (run locally via the `magnitude` provider inside `opencode`) to try and
refactor the following code snippet from `lisp-mcp-test`:

```lisp
(defun process-request (req)
  (if req
    (let ((auth (get-header req "Authorization")))
      (if auth
        (let ((user (authenticate auth)))
          (if user
            (let ((payload (get-body req)))
              (if payload
                (if (validate-payload payload)
                  (execute-request user payload)
                  (error 'invalid-payload))
                (error 'missing-payload)))
            (error 'unauthorized)))
        (error 'missing-auth)))
    (error 'empty-request)))

(defun make-api-call (method url headers body)
  (format t "Making ~a request to ~a~%" method url)
  ())
```

The tasks were simple for any human lisp programmer:

1. **Flatten `process-request`**: eliminate the deeply nested "arrow code" while preserving all
    error conditions.
2. **Reorder `make-api-call` arguments**: change the signature to `(url method &key headers body)`
    and update every call site across all functions in the file (`sync-user`, `fetch-dashboard`,
    and `update-preferences`).

The difference between standard text editing and structural MCP editing was night and day:

Without the MCP the 1B parameter model was absolute garbage. To update `make-api-call`, it had to
run multiple regex search-and-replace edits, manually counting arguments and trying (and failing)
to format the new `:headers` and `:body` plists without dropping parentheses. Flattening
`process-request` required constructing a large multi-clause `cond` from scratch, and it repeatedly
tripped over balancing parentheses, burned tokens in thought loops, and required multiple
verification passes with SBCL to fix syntax errors. After a lot of thrashing about it eventually
solved the task burning over 15,000 tokens to get the following code:

```lisp
(defun process-request (req)
  (let*
    ((auth (when req (get-header req "Authorization")))
      (user (when auth (authenticate auth)))
      (payload (when user (get-body req))))
    (cond
      ((null req) (error 'empty-request))
      ((null auth) (error 'missing-auth))
      ((null user) (error 'unauthorized))
      ((null payload) (error 'missing-payload))
      ((not (validate-payload payload)) (error 'invalid-payload))
      (t (execute-request user payload)))))

(defun make-api-call (url method &key headers body)
  (format t "Making ~a request to ~a~%" method url)
  ())

(defun sync-user (user)
  (make-api-call
    (format () "https://api.example.com/users/~a" (user-id user))
    :post
    :headers (list (cons "Authorization" (user-token user))
                   (cons "Content-Type" "application/json"))
    :body (serialize-json (user-data user))))
```

With the MCP the exact same 1B model performed the entire multi-call-site refactoring in a
single atomic command! Every single invocation across the entire file was transformed structurally,
with zero token overhead spent counting lines, commas, or parentheses. Updating the function
signature and replacing `process-request`'s body were then each completed with clean, surgical
`ast_modify` overwrites at exact AST paths (`[0, 8, 2]` and `[0, 2, 3]`). These 3, low cost steps
resulted in a success on the first attempt, using ~2,500 tokens and returning the following code:

```lisp
(defun process-request (req)
  (let*
    ((auth (and req (get-header req "Authorization")))
     (user (and auth (authenticate auth)))
     (payload (and user (get-body req))))
    (cond
      ((not req) (error 'empty-request))
      ((not auth) (error 'missing-auth))
      ((not user) (error 'unauthorized))
      ((not payload) (error 'missing-payload))
      ((not (validate-payload payload)) (error 'invalid-payload))
      (t (execute-request user payload)))))

(defun make-api-call (url method &key headers body)
  (format t "Making ~a request to ~a~%" method url)
  ())

(defun sync-user (user)
  (make-api-call
    (format () "https://api.example.com/users/~a" (user-id user))
    :post
    :headers (list (cons "Authorization" (user-token user))
                   (cons "Content-Type" "application/json"))
    :body (serialize-json (user-data user))))
```

Because the MCP handles tree serialization and guarantees syntactic validity, even a compact 1B
model that normally stumbles over Lisp syntax was able to execute complex, multi-site refactorings
flawlessly on the first try.

## Conclusion

Overall, this was a fun little project. And it resulted in an MCP I've actually found myself using
quite a lot when I'm writing little babashka scripts or racket analyses. It has also convinced me
that the future of agentic development likely lies in direct AST manipulation by the agents. Of
course, this does pose quite a roadblock with many languages that aren't lisp; lisp is unique in
that you're effectively writing an AST by hand when you write lisp. But that doesn't mean it
can't be done for other languages. This has tempted me to maybe try something similar in python using
`ast.parse` and `ast.unparse`, but I suspect it wouldn't be anywhere near as simple as it sounds.
In the meantime, I will remain content with my cool little project that manages to demonstrate
that there is still a lot of value to be had for this old, 1950's programming language in modern
ML pipelines if you just give it a bit of a polish and some modern tooling.
