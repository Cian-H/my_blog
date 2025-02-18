+++
date = '2025-02-18T01:23:46Z'
draft = false
title = 'Prolog: if Stockholm syndrome was a programming language'
+++

I have an embarrassing admission to make that will probably raise many eyebrows but please, hear me
out:

> I love Prolog

And before anyone says it: yes, I know I shouldn't. I know it's an obsolete, slow, unoptimisable
borderline undebuggable language. I know it is based on a programming paradigm that is long since
dead and that most programmers (if they're even aware of it) spit on the grave of and bid an enraged
"good riddance" to. Some people might describe it as a kind of Stockholm syndrome I experience as
somebody who spends a lot of time working on symbolic AI concepts but I promise you: you just don't
know Prolog like I do! Prolog really does love me, I swear! It's just that we're going through a
rough patch right now, that's all...

Off-colored jokes aside, any time that I dust off the old SWIPL interpreter and write some Prolog it
can almost feel like I'm in an abusive relationship with the language. I want to love it, I truly
do. It is so elegant, and beautiful, and does things that feel like genuine magic. But it is also
just a nightmare to program in! For reasons that I **think** most people will understand in
principal but not understand the sheer scale of the pain suffered by anyone cursed to walk the path
of Prolog for any length of time.

As a quick comparison, the most common complaint from many people about rust is that the compiler
places too many semantic restrictions on the programmer and that these rules can be frustrating.
While I understand this perspective I do think they should have some empathy for the `rustc`
compiler: how would you feel if you were in the compiler's shoes? How would you feel if you spent
hours, or even days (insert "rust compiler slow" joke here) meticulously crafting logical rules only
for some jackass to come along and poke holes in them? Wouldn't you feel like screaming

```console
the trait bound `WhatTheHellIsThisMonstrosity<Box<Arc<Mutex<[i64; 4]>>>>: From<(i64, i64, u64, &String)>` cannot be satisfied
```

too? Wouldn't you also be a little unsatisfied with that idiot? Not sure? Well, if you're reading
this and you've never written a line of prolog in your life (I imagine most programmers will fall
into this category) then try it! You too can spend hours writing a beautifully crafted set of rules
then cry in dismay as a mathematically perfect engine of logical consistency shits all over your
rules, and insults your logic skills while it is at it! By the time you reach your 5th hackerrank
problem you might just find yourself empathising with `rustc` a little bit...

## The pain of trying to write prolog

Let me try to walk you through the process of solving a simple problem in prolog, so you those who
are lucky enough to have avoided this language can understand what I mean. I am by no means an
expert prolog programmer, but I do have at least several dozen hours of experience writing it for
various experiments and projects. My prolog might be a little rusty, as its been a few moinths but I
am not a _complete_ novice either. So, lets try to solve a classic coin permutations problem in
prolog. Project euler problem 31 should do nicely!

> In the United Kingdom the currency is made up of pound (£) and pence (p). There are eight coins in
> general circulation:
>
>     1p, 2p, 5p, 10p, 20p, 50p, £1 (100p), and £2 (200p).
>
> It is possible to make £2 in the following way:
>
>     1×£1 + 1×50p + 2×20p + 1×5p + 1×2p + 3×1p
>
> How many different ways can £2 be made using any number of coins?

Seems simple enough. In prolog, it is often best to start by defining predicates for our goals.
Basically: prolog's paradigm naturally incentivizes an almost TDD type workflow. Starting simple, we
want a predicate with a number, a list, and a result for the check if the sum equals the number.
Sounds simple enough.

```prolog
sum_equals(N, L, X) :-
    sum_list(L, M),
    X is M =:= N.
```

This predacate sets `M` as the sum of `L`, and then asserts that `X` is the result of an equality
comparison between `M` and `N`. First goal written, makes perfect sense, if we query
`?- sum_equals(10, [7, 3], X).` we should get back `X = true.`. Let's run that to test it and

```console
ERROR: /home/cianh/Programming/prolog_tests/main.pro:3:7: Syntax error: Operator priority clash
```

Ok then. Thanks SWI prolog, very well explained... well, it says line 3 character 7, which is where
the `is` keyword is. Maybe it can't tell which operator takes precedence between `is` and `=:=` so I
need to add clearer brackets? I would have thought that the is keyword should clearly take
precedence here but lets try that and see if it fixes the bug.

```prolog
sum_equals(N, L, X) :-
    sum_list(L, M),
    X is (M =:= N).
```

```prolog
?- sum_equals(10, [7, 3], X).
ERROR: Arithmetic: `(=:=)/2' is not a function
ERROR: In:
ERROR:   [13] _1934 is (10=:=10)
ERROR:   [11] toplevel_call(user:user: ...) at
/nix/store/zp5w45y9qpmp6aybwzgsi26n1aamk33p-swi-prolog-9.2.7/lib/swipl/boot/toplevel.pl:1317
ERROR:
ERROR: Note: some frames are missing due to last-call optimization.
ERROR: Re-run your program in debug mode (:- debug.) to get more detail.
^  Exception: (4) setup_call_cleanup('$toplevel':notrace(call_repl_loop_hook(begin, 0)),
'$toplevel':'$query_loop'(0), '$toplevel':notrace(call_repl_loop_hook(end, 0))) ? creep
```

... Did that interpreter just call me a creep? What the hell?!?! See? I wasn't exaggerating, this
language will **LITERALLY** find the logical inconsistency in your rules and then insult you for it!
Might need a few more iterations. I guess the issue might be that I'm attempting to _assign_ the
comparison result to `X` when I should be _unifying_ them instead? This might be a confusing
distinction coming from a more imperative or functional perspective, but the distinction is
important in logic. Assigning is keeping a value for later, whereas unifying is an actual logical
operation. It wouldn't be very prolog-ey to assign and pass a result out, its more idiomatic to
constrain the result through unification.

```prolog
sum_equals(N, L, X) :-
    sum_list(L, M),
    X = (M =:= N).
```

Yes, thats what the `=` operator means in prolog. Weird right?

```prolog
?- sum_equals(10, [7, 3], X).
X = (10=:=10).
```

Huh? I did not expect that. At least there were no errors, but why on earth is it unifying to an
expression instead of a value? Oh no, im going to have to program a separate path for each outcome
here, amn't I?

```prolog
sum_equals(N, L, true) :-
    sum_list(L, M),
    M =:= N,
    !. % This just tells prolog to return early if it finds a `true`

sum_equals(N, L, false) :-
    sum_list(L, M),
    M =\= N.
```

```prolog
?- sum_equals(10, [7, 3], X).
X = true.

?- sum_equals(10, [8, 3], X).
X = false.
```

SUCCESS!!! Now that we have a sum_equals predicate, we're going to need one that returns all
possible combinations of a list. For this, we will need to create a predicate that takes a list and
expands each value out so that we have enough of each to make up the whole £2 with only that type of
coin. We'll need a helper predicate to achieve this (`repeat_element`), and then the main predicate
(`pad_coins`).

```prolog
pad_coins([], _, []).
pad_coins([H|T], N, Result) :-
    repeat_element(H, N // H, RepeatedH),
    pad_coins(T, N, RepeatedT),
    append(RepeatedH, RepeatedT, Result),
    !.

repeat_element(_, 0, []).
repeat_element(E, N, [E|T]) :-
    N > 0,
    N1 is N - 1,
    repeat_element(E, N1, T).
```

```prolog
?- pad_coins([2, 5, 10], 10, X).
X = [2, 2, 2, 2, 2, 5, 5, 10].
```

This time, I managed to get it right first time. Great! Finally, we need to be able to get every
possible permutation of this list. This isn't too hard to do in prolog actually, but SWI prolog
provides a handy `permutation` function, so lets just use that. Oh! And we need to remember to apply
an aggressive pruning condition to try and help optimise performance a bit, so lets prune out every
list with a sum greater than `N`. When writing prolog it's important to bare in mind that the engine
will exhaustively search each branch via backtracking, so conditions like this can **dramatically**
increase performance.

However, at this point, the improvement in performance probably won't be enough. This program will
end up running out of RAM, and triggering an OOM error. Yes, I know the implementation was lazy, and
brute-force. And before anyone says it: I do know this should be solved with more of a dynamic
programming solution. The reason I've spent this time going down this path is to demonstrate
something:

1. You can't be lazy when writing prolog, it won't let you get away with that
2. Prolog is difficult and esoteric to debug
3. I am _extremely_ tired, it's 1am, and i don't feel like being precious about programming best
   practice when I really want to go to bed and i'm 99% sure nobody will ever read this
4. Prolog is mean to me

## Why do you still love Prolog then?

This is the natural question to ask when a language turns out to be as frustrating as Prolog can be.
However, I think most programmers already know the answer even if they don't want to admit it:

> It makes you feel smart

Genuinely, there is an indescribable feeling of satisfaction and "I did that!" when you actually get
a Prolog program to work properly and it isn't an incomprehensible mess. Is that a good thing for a
programming language? Hell no! If I am surprised and feel like a genius if I can write a basic
program in your language: it's a shite language. Every now and then though, when the conditions are
just right, and the domain fits, and the stars align Prolog produces the most elegant solution you
have ever seen and suddenly, it was all worth it. Or, at least, that's what you tell yourself.

Moreso than just the feeling of accomplishment it gives you, I think I love the **idea** of Prolog a
lot more than the **reality**. When somebody says:

> I have this cool language to show you. You don't actually define what the program does, you just
> define what you want from it! And then, a mathematically perfect and exhaustive engine explores
> all possible solutions for your problem and gives them all to you!

It sounds like genius. It sounds like the perfect way to program. It sounds too good to be true. So,
let's start by looking at Prolog at it's best, so you can understand why I want so desperately to
love it despite its flaws.

## Where Prolog shines: finite sets of simple, logical rules

Lets take a simple problem that most programmers have tried to solve, that turns out to be tricker
than you might think in an imperative language. Lets solve a sudoku!

Luckily, for this one, we have a handy little page on
[Rosetta code](https://rosettacode.org/wiki/Sudoku) that we can pull some prebuilt solutions from to
get an idea of how these solutions look in various languages. We should probably start with the
universal lingua franca of programming: the venerable C programming language. How do we solve a
sudoku in C? Cutting it down to just the main logic of the solution, we get:

```C
#include <stdio.h>

void show(int *x)
{
    int i, j;
    for (i = 0; i < 9; i++) {
        if (!(i % 3)) putchar('\n');
        for (j = 0; j < 9; j++)
            printf(j % 3 ? "%2d" : "%3d", *x++);
        putchar('\n');
    }
}

int trycell(int *x, int pos)
{
    int row = pos / 9;
    int col = pos % 9;
    int i, j, used = 0;

    if (pos == 81) return 1;
    if (x[pos]) return trycell(x, pos + 1);

    for (i = 0; i < 9; i++)
        used |= 1 << (x[i * 9 + col] - 1);

    for (j = 0; j < 9; j++)
        used |= 1 << (x[row * 9 + j] - 1);

    row = row / 3 * 3;
    col = col / 3 * 3;
    for (i = row; i < row + 3; i++)
        for (j = col; j < col + 3; j++)
            used |= 1 << (x[i * 9 + j] - 1);

    for (x[pos] = 1; x[pos] <= 9; x[pos]++, used >>= 1)
        if (!(used & 1) && trycell(x, pos + 1)) return 1;

    x[pos] = 0;
    return 0;
}

void solve(const char *s)
{
    int i, x[81];
    for (i = 0; i < 81; i++)
        x[i] = s[i] >= '1' && s[i] <= '9' ? s[i] - '0' : 0;

    if (trycell(x, 0))
        show(x);
    else
        puts("no solution");
}
```

Oooookay then. Being honest: I've never been great at `C`, so maybe it's just me but I didn't expect
that solution to require bit shifting. Maybe it's just my origins as a lowly python scrub that is
the problem? Maybe the solution would make more sense to me in a high level language like python? It
would probably be shorter too, right?

```python
def printGrid(grid):
    for i in range(0, 9):
        if i > 0 and i % 3 == 0:
            print("------+-------+------", end="")
            print()
        for j in range(0, 9):
            if j > 0 and j % 3 == 0: print("| ", end="")
            n = grid[i][j]
            c = "." if n == 0 else str(n)
            print(c, end=" ")
        print()

def valid(row, col, n):
    res = True
    for i in range(0, 9):
        for j in range(0, 9):
            if ( i == row or j == col or
                 i // 3 == row // 3 and j // 3 == col // 3 ):
                if grid[i][j] == n: res = False
    return res

def solve(grid):
    for row in range(0, 9):
        for col in range(0, 9):
            if grid[row][col] == 0:
                for n in (range(1, 10)):
                    if valid(row, col, n):
                        grid[row][col] = n
                        solve()
                        grid[row][col] = 0
                return
    printGrid(grid)
    input("\nPress enter to check for more solutions\n")
```

Oh wow... do i see a triply nested for loop making recursive call, conditioned on a doubly nested
for loop? Moving swiftly along before I go on a 5,000 word rant about that terrible python code:
functional bros, what you got? Surely functional languages solve this? You always go on about how
lovely and clean functional solutions are compared to imperative ones! Let's see the solution, as
implemented in the posterchild of functional languages: haskell.

```Haskell
module Sudoku
    (Sudoku,
     readSudoku,
     runSudoku,
     evalSudoku,
     execSudoku,
     showSudoku,
     valAt, rowAt, colAt, boxAt,
     place)
     where
import Data.Array.Diff
import MonadNondet
import Control.Monad.State

newtype Sudoku a = Sudoku (StateT (DiffUArray (Int,Int) Int) Nondet a)
    deriving (Functor, Monad, MonadPlus)

initialSudokuArray = listArray ((1,1),(9,9)) [0,0..]

runSudoku (Sudoku k) = runNondet (runStateT k initialSudokuArray)

evalSudoku = fst . runSudoku
execSudoku = snd . runSudoku

showSudoku = Sudoku $ do
    a <- get
    return $ unlines [unwords [show (a ! (i,j)) | j <- [1..9]] | i <- [1..9]]

readSudoku :: String -> Sudoku ()
readSudoku xs = sequence_ $ do
    (i,ys) <- zip [1..9] (lines xs)
    (j,n)  <- zip [1..9] (words ys)
    return $ place (i,j) (read n)

valAt' (i,j) = do
    a <- get
    return (a ! (i,j))

rowAt' (i,j) = mapM valAt' [(i, k) | k <- [1..9]]

colAt' (i,j) = mapM valAt' [(k, j) | k <- [1..9]]

boxAt' (i,j) = mapM valAt' [(i' + u, j' + v) | u <- [1..3], v <- [1..3]]
  where i' = ((i-1) `div` 3) * 3
        j' = ((j-1) `div` 3) * 3

valAt = Sudoku . valAt'
rowAt = Sudoku . rowAt'
colAt = Sudoku . colAt'
boxAt = Sudoku . boxAt'

place :: (Int,Int) -> Int -> Sudoku ()
place (i,j) n = Sudoku $ do
    v <- valAt' (i,j)
    when (v == 0 && n /= 0) $ do
        rs <- rowAt' (i,j)
        cs <- colAt' (i,j)
        bs <- boxAt' (i,j)
        guard $ (n `notElem`) $ rs ++ cs ++ bs
        a <- get
        put (a // [((i,j),n)])
```

Ok (and i say this as a serial enjoyer of the monads): what the hell is that??? What am I looking at
here? As the meme goes: where's the whitepaper explaining `MonadNondet` here??? I'm no expert at
haskell but still, I just dont get it.

So, last but not least, lets have a look at the prolog implementation.

```Prolog
:- use_module(library(clpfd)).

sudoku(Rows) :-
        length(Rows, 9), maplist(length_(9), Rows),
        append(Rows, Vs), Vs ins 1..9,
        maplist(all_distinct, Rows),
        transpose(Rows, Columns), maplist(all_distinct, Columns),
        Rows = [A,B,C,D,E,F,G,H,I],
        blocks(A, B, C), blocks(D, E, F), blocks(G, H, I).

length_(L, Ls) :- length(Ls, L).

blocks([], [], []).
blocks([A,B,C|Bs1], [D,E,F|Bs2], [G,H,I|Bs3]) :-
        all_distinct([A,B,C,D,E,F,G,H,I]),
        blocks(Bs1, Bs2, Bs3).
```

Now **that** is an elegant solution! A translation for any non-prolog (i.e: sane) programmers that
might be reading, this code:

-   Defines that a row must have 9 unique numbers between 1 and 9
-   Applies the same rule to the columns
-   Defines that a block is a 3x3 grid of unique numbers between 1 and 9
-   Declares that the blocks to the right of those that have been checked should also be checked

The prolog engine then mathematically searches every possible solution and returns the ones that
satisfy these simple logical rules. It does it in so few lines, yet they're all readable. All
sensible. All beautiful.

Another area where prolog absolutely shines is in programming GUIs. It might seem strange at first,
looking at this strange logic programming language and wondering how you would even use it to
program a UI. But remember, prolog is a **declarative** logic programming language, and nowadays
declarative UI libraries are all the rage. There is no ends to the amount of praise heaped on
svelte, flutter, and swiftUI from developers. So of course, the OG of declarative programming might
have some surprises for modern programmers in how it handles UI. To see what I mean, let's look at
Rosetta code's "GUI Component Interaction" problem solved in a modern language considered great at
GUIs (C# specifically), a modern beloved web framework (svelte), and prolog.

### C#

```csharp
using System;
using System.ComponentModel;
using System.Windows.Forms;

class RosettaInteractionForm : Form
{
    class NumberModel: INotifyPropertyChanged
    {

        Random rnd = new Random();

        public event PropertyChangedEventHandler PropertyChanged = delegate {};

        int _value;
        public int Value
        {
            get { return _value; }
            set
            {
                _value = value;
                PropertyChanged(this, new PropertyChangedEventArgs("Value"));
            }
        }

        public void ResetToRandom(){
            Value = rnd.Next(5000);
        }
    }

    NumberModel model = new NumberModel{ Value = 0};

    RosettaInteractionForm()
    {
        var tbNumber = new MaskedTextBox
                        {
                            Mask="0000",
                            ResetOnSpace = false,
                            Dock = DockStyle.Top
                        };
        tbNumber.DataBindings.Add("Text", model, "Value");

        var btIncrement = new Button{Text = "Increment", Dock = DockStyle.Bottom};
        btIncrement.Click += delegate
                        {
                            model.Value++;
                        };
        var btDecrement = new Button{Text = "Decrement", Dock = DockStyle.Bottom};
        btDecrement.Click += delegate
                        {
                            model.Value--;
                        };
        var btRandom = new Button{ Text="Reset to Random", Dock = DockStyle.Bottom };
        btRandom.Click += delegate
                        {
                            if (MessageBox.Show("Are you sure?", "Are you sure?", MessageBoxButtons.YesNo) == DialogResult.Yes)
                                model.ResetToRandom();
                        };
        Controls.Add(tbNumber);
        Controls.Add(btIncrement);
        Controls.Add(btDecrement);
        Controls.Add(btRandom);
    }
    static void Main()
    {
        Application.Run(new RosettaInteractionForm());
    }
}
```

### Svelte

```svelte
<script>
  let value = 0;

  function increment() {
    value++;
  }

  function randomize() {
    if (confirm("Are you sure you want to generate a random number?")) {
      value = Math.floor(Math.random() * 1000);
    }
  }

  function handleInput() {
    if (isNaN(value)) {
      alert("Please enter a valid number.");
      value = 0;
    } else {
      value = parseInt(value);
    }
  }
</script>

<style>
  .container {
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 20px;
  }

  input[type="number"] {
    margin-bottom: 10px;
    padding: 5px;
    border: 1px solid #ccc;
    border-radius: 4px;
    width: 150px;
    text-align: center;
  }

  button {
    padding: 8px 12px;
    margin: 5px;
    border: none;
    border-radius: 4px;
    background-color: #007bff;
    color: white;
    cursor: pointer;
  }
</style>

<div class="container">
  <label for="value">Value:</label>
  <input type="number" id="value" bind:value on:blur={handleInput} />

  <button on:click={increment}>Increment</button>
  <button on:click={randomize}>Random</button>
</div>
```

### Prolog

```prolog
dialog('GUI_Interaction', [
    object := GUI_Interaction,
    parts := [
         GUI_Interaction := dialog('Rosetta Code'),
         Input_field := text_item(input_field),
         Increment := button(increment),
         Random := button(random)
    ],
    modifications := [Input_field := [label  := 'Value :', length := 28]],
    layout := [
        area(Input_field, area(54, 24, 251, 24)),
        area(Increment, area(54, 90, 80, 24)),
        area(Random, area(230, 90, 80, 24))
    ],
    behaviour := [
        Increment := [message := message(@prolog, increment, Input_field )],
        Random := [message := message(@prolog, my_random, Input_field)],
        Input_field := [
            message := message(
                @prolog,
                input,
                GUI_Interaction,
                Increment,
                @receiver,
                @arg1
            )
        ]
    ]
]).

gui_component :- make_dialog(S, 'GUI_Interaction'), send(S, open).

increment(Input) :-
    get(Input, selection, V),
    atom_number(V, Val),
    Val1 is Val + 1,
    send(Input, selection, Val1).

my_random(Input) :-
    new(D, dialog('GUI Interaction')),
    send(D, append(label(lbl,'Confirm your choice !'))),
    send(D, append(button(ok, message(D, return, ok)))),
    send(D, append(button(cancel, message(D, return, ko)))),
    send(D, default_button(ok)),
    get(D, confirm, Rval),
    free(D),
    (Rval = ok -> X is random(10000), send(Input, selection, X)).

input(Gui, Btn, Input, Selection) :-
    catch(
        (term_to_atom(T, Selection), number(T), send(Gui, focus, Btn)),
        _,
        (send(@display, inform, 'Please type a number !'), send(Input,clear))
    ).
```

Putting aside the prolog-isms and the muiltilanguage syntax of svelte, the similarities in approach
the approach taken by the 2 languages here aren't too different. In fact, if we put aside the
definitions for the functions being grouped at the bottom of the prolog file and look at what is
above the `gui_component` line theyre strangely similar! They both have a block describing layout
(`<div>`/`layout`), a block describing the style (`<style>`/`modifications`), and a block describing
the behaviour (`<script>`/`behaviour`). Sure, there are some differences, but for languages in
completely different language families with 45 years between their initial release the similarity is
kinda dumbfounding. Contrast it with the C# code, which takes a much more object oriented approach.
C# constructs a bunch of object that all have properties and behaviours bound to them. Both
approaches work, but I do rather prefer the approach that results in a separation based on function
(i.e: the declarative approach) rather than locality. As time progresses, more and more modern UI
frameworks rediscover this declarative approach pioneered by prolog and that really is a testament
to just how nice this style of writing GUIs is.

You may now be asking "what's the problem?". The language looks really great, right? It does cool
stuff, it does it in an enjoyable way to work with, prolog really does love me right??? Well, if we
continue the strained analogy of an abusive relationship with Prolog: this is Prolog buying me
flowers, wining and dining me, and laughing at my crappy jokes. This is Prolog in love-bombing mode.
But sadly, it only does that so it can get its hooks into me...

## Where Prolog fails: literally anything else!

Ok, so if Prolog can be so clean and beautiful then why has it gone extinct outside of certain
circles like symbolic AI research? Well, lets take a look at how prolog performs at some other
simple programming tasks. How about some simple binary search? It's a simple, classic algorithm that
every programmer has implemented a thousand times before. If prolog can solve a sudoku as elegantly
as above, surely a binary search in prolog is a clean, one-line case of "if greater go right if less
than go left", right? Ok, I've danced around it long enough, you know by my tone that I'm being
facetious here. It's actually horrifying...

```prolog
bin_search(Elt,List,Result):-
  length(List,N), bin_search_inner(Elt,List,1,N,Result).

bin_search_inner(Elt,List,J,J,J):-
  nth(J,List,Elt).
bin_search_inner(Elt,List,Begin,End,Mid):-
  Begin < End,
  Mid is (Begin+End) div 2,
  nth(Mid,List,Elt).
bin_search_inner(Elt,List,Begin,End,Result):-
  Begin < End,
  Mid is (Begin+End) div 2,
  nth(Mid,List,MidElt),
  MidElt < Elt,
  NewBegin is Mid+1,
  bin_search_inner(Elt,List,NewBegin,End,Result).
bin_search_inner(Elt,List,Begin,End,Result):-
  Begin < End,
  Mid is (Begin+End) div 2,
  nth(Mid,List,MidElt),
  MidElt > Elt,
  NewEnd is Mid-1,
  bin_search_inner(Elt,List,Begin,NewEnd,Result).
```

Ok, so if you speak prolog it makes perfect sense I suppose. We split our list in two, compare the
midpoint to the ends, select a sublist, rinse and repeat. But look at the amount of repetition on
each branch, the inflation of arguments being passed up and down the callstack here. It could be
worse I suppose; at least it tail recurses and the top level interface at `bin search` is nice.
Comparing to a python function just makes the prolog implementation look positively painful.

```python
def binary_search(l, value):
    low, high = 0, len(l)-1
    while low <= high:
        mid = (low + high) // 2
        if l[mid] > value:
            high = mid-1
        elif l[mid] < value:
            low = mid+1
        else:
            return mid
    return -1
```

And it's not just binary searches where this problem appears. Browse the
[Rosetta code prolog page](https://rosettacode.org/wiki/Category:Prolog) and buckle up for a wild
ride where you will go hoarse from saying "what the hell is that?!?!" over and over.

## Conclusion

Prolog sucks, and I love it. That is the end of my rant about an obsolete, dead programming language
that almost nobody has ever written in their life. Why have I written it then? Cos I do symbolic ML
and apparently I hate myself. I desperately need to go to sleep now. Good night.
