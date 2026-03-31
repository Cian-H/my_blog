+++
date = '2025-11-17T00:51:14Z'
draft = false
title = 'Fortran features that fascinate me'
+++

Recently, I've been working on a package intended to add zero overhead monadic error handling into
Fortran. I mostly just wanted to see if it could be done, and apparently I enjoy doing silly
things in niche (at least nowadays) programming languages. Like most people who write code for
scientific number crunching I have a bit of a love/hate relationship with this language; it has so
many weird quirks, but it is also just *so easy* to write high performance code in. Even if you
don't like it, you definitely have to respect the fact that the first high level language worked
so well that it's still the goto language for supercomputing. Speaking of `goto`: writing this
package got me thinking about some of the weird, interesting features Fortran has had throughout
its life that you don't really see in most other languages. Wome of these features are really
interesting, and can really get you thinking about just how different programming can be from the
heavily C influenced style most modern languages have adopted.

> I promise: that `goto` segue wasn't planned! It was a happy accident...

## Structured Fortran

Before a lot of these features can be explained I first need to explain "structured" fortran for
those who are unfamiliar with the language. Most modern Fortran code that you might have seen is
"free-form" code. Free-form Fortran code looks a lot more like a modern (albeit strange)
programming language.

```f08
program main
    implicit none

    integer :: i, j

    do i = 1, 10
        j = quadratic(i)
        write (*, *) "x:", i, "| y:", j
    end do
contains
    function quadratic(x) result(y)
        integer, intent(in) :: x
        integer :: y
        y = 2 * x**2 + 4 * x - 2
    end function quadratic
end program main
```

However, a lot of these features existed earlier in the history of the language, in FORTRAN77 and
earlier versions. Structured Fortran was only introduced in Fortran90, all earlier versions of the
language were exclusively the "structured" form of the language.

```f77
      PROGRAM MAIN
      INTEGER I, J, QUADRA

   10 DO 20 I = 1, 10
      J = QUADRA(I)
      WRITE (*, *) "x:", I, "| y:", J
   20 CONTINUE
      END

      INTEGER FUNCTION QUADRA(X)
      INTEGER X
      QUADRA = 2 * X**2 + 4 * X - 2
      RETURN
      END
```

As you can see: the functionally identical code in structured Fortran has some unusual features.
Most of these features (such as the compulsory label gutter on the left of the code) are holdovers
from a time when the language was programmed on punch cards.

![Fortran punch cards](https://upload.wikimedia.org/wikipedia/commons/f/f8/GfhR_%2823%29.jpg "A stack of fortran punch cards")

Here, you'll know if code is structured or free-form Fortran because structured Fortran will be
written in block capitals (as is convention in the Fortran programming community).

## Implicit types (and no, not in the way you're thinking)

Long before we had type systems with static analyzers that could derive implicit types for
variables, Fortran also had implicit typing all the way back in 1957. Well, as long as you used
variable names that aligned with mathematical convention that is. Any variable name starting with
`I`, `J`, `K`, `L`, `M`, or `N` was assumed to be an `INTEGER` by the compiler, and **anything**
else was just assumed to be a `REAL`. Needless to say: this became a massive pain in the ass
whenever anyone tried to write anything more complicated than a direct translation of a
mathematical formula. Want to call the first measurement from your sensor `INITIAL` so you know
it's the initial starting value? Whoops, sorry! You just passed a `REAL` to a variable of type
`INTEGER` because `INITIAL` starts with `I`. Ever wondered why basically all Fortran programs
start with the line `implicit none`? This is why; to disable this feature.

Still, though: let's be honest when you write `i` in any programming language we pretty much
always mean an integer. I'm not saying this was a good idea, im just saying that maybe if python
assumed all my `i` variables were integers we could optimise those painfully slow for loops a
bit...

## Arithmetic IF

With those basics out of the way: on to the really interesting things! The first of these (and
the one that I sometimes find myself wishing for in modern languages) is the "arithmetic if"
statement. In the earliest days of Fortran: the concept of an "if statement" as we know it today
wasn't quite as obvious as you might think. Most earlier experimental attempts to create assembler
preprocessors (which eventually evolved into programming languages) simply used combinations of
conditional line execution and jumps for control flow. Fortran introduced the first `IF`, but it
wasn't an `if` that most programmers today would recognize; it was the "arithmetic" `IF`.

```f77
      PROGRAM MAIN
      WRITE (*, *) "Enter a number: "
      READ (*, *) I
      IF (i - 10) 10, 20, 30
   10 WRITE (*, *) "You entered a number less than 10."
      GOTO 40
   20 WRITE (*, *) "You entered the number 10."
      GOTO 40
   30 WRITE (*, *) "You entered a number greater than 10."
   40 CONTINUE
      END
```

The arithmetic if allows you to branch in 3 directions depending on whether the result of an
expression is less than, equal to, or greater than 0. This may sound somewhat pointless, but is
actually extremely useful when writing functions calculating mathematical formulae (which makes
sense, it is the "FORmula TRANslator" after all!) and fuzzy logic. Following the lead of ALGOL60,
this particular language feature was eventually replaced with the standard boolean `if` in
FORTRAN IV, and an `if/else` block in FORTRAN77, eventually being phased out completely in the
Fortran 2018 standard. It's quite clear why it was phased out as it tended to create spaghetti
code, but it's a cool little feature that makes you wonder "what if" about parallel universes
where arithmetic if became the standard and control flow is based on Kleene logic instead of
Boolean logic.


## Enter the `ENTRY` keyword

Continuing the trend of whacky control flow constructs, we have the `ENTRY` keyword. This keyword
allows you to create **multiple entrypoints** for a single function. (note: a `subroutine` is just
a `function` that has no return value)

```f08
program main
    call primary()
    call secondary()
end program main

subroutine primary()
    write(*, *) "Primary entrypoint"
entry secondary()
    write(*, *) "Secondary entrypoint"
end subroutine primary
```

```txt
Primary entrypoint
Secondary entrypoint
Secondary entrypoint
```

You might ask:

- When will I ever use this?
- Should I ever use this?
- Do we still need this?

And the answer to every one of those questions is "no!". It's a feature that can appear useful at
first... until you realise it's easy to achieve the exact same thing in almost any language.

```python
def primary()
    print("Primary entrypoint")
    secondary()

def secondary()
    print("Secondary entrypoint")
```

And as a bonus: using this approach allows us to control what values are passed through the
boundary between the two entrypoints while avoiding the undefined behaviour that occurs if you
try to use a variable defined in `primary` inside the body of `secondary`. This feature was
just a terrible idea that it's definitely a good thing that we don't do anymore.

## Equivalence, aka: type punning on crack

Before C's type casting, Fortran had a similar idea implemented the opposite way around. This
gives all the danger of type casting, but now with double the footguns! Where C allows us to treat
a variable as a different type via casting, and punning the `EQUIVALENCE` keyword in Fortran
allows us to cram two different variables into the exact same memory space. You may ask: how is
this different from type punning? And the answer is that the moment we put `EQUIVALENCE`
**anywhere** in our code we have now created silent type punning throughout the **entire**
codebase. In essence we have taken the classic type punning footgun, multiplied it by however
many times we have used any of the variables in our code, and pointed every single one square
at our foot. And all it takes is one a light touch to **one** of the triggers to set off **every
single footgun**!

```f08
program equivalence_footgun
    implicit none

    integer :: secret_int
    real :: harmless_float
    real, dimension(5) :: data_array

    equivalence (secret_int, harmless_float, data_array(3))

    data_array = [1.0, 2.0, 3.14159, 4.0, 5.0]

    write (*, *) "Harmless Float is: ", harmless_float

    secret_int = 987654321

    write (*, *) "Float is now: ", harmless_float
    write (*, *) "Array element 3 is now: ", data_array(3)
end program equivalence_footgun
```

```txt
Harmless Float is:    3.14159012
Float is now:    1.69684563E-03
Array element 3 is now:    1.69684563E-03
```

## Conclusion

Anyway, that's just a list of a few features that I find interesting (in good ways and bad ways)
from the various versions of Fortran throughout its history. It's mostly just been a ramble about
something that's been on my mind as I've been playing around with this package for adding monadic
errors to Fortran. If anyone randomly comes across this and is wondering how that weird side
project went you can have a look at the repo [https://github.com/Cian-H/formerr](here). It's a fun
little attempt to take a clean, modern language feature and retrofit it into a wonderful but messy
language that all our modern HPC languages owe their origins to.
