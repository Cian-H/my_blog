+++
date = '2025-02-17T00:26:56Z'
draft = true
title = 'Fun acts with activation functions'
+++

## In the beginning...

> In the beginning Widrow and Hoff created Adaline and Madaline. Now the networks were flat and
> linear, darkness shrouded the underlying meaning of their neurons, and the spirit of curiosity
> was poring over the matrix mathematics. \
> \
> And Wilson and Cowan said, “Let there be sigmoid,” and there was sigmoid. Wilson saw that the
> sigmoid was good, and he separated the nonlinear from the linear. Cowan called the nonlinear
> “neural networks”, and the linear he called “perceptrons”. And there was tanh, and there was
> softmax — the first S-shaped activations. \
> \
> And Nair and Hinton “Let there be a min between the signs to separate constant from linear”. So
> Hinton made the min and separated the constant below the zero from the linear above it. And it
> was so. Nair called the function “ReLU”. *And then everyone forgot that anything other than ramp
> functions ever existed and the entire field of activation function research stagnated.*

A casual hobbyist building neural networks out of curiosity using any of the modern libraries
would be forgiven for thinking that activation functions only come in 2 varieties: S-shaped and
ramp. That is, however, far from the truth and in fact most mathematical functions (with only a
few, minor caveats) can be used as an activation function. And that, dear (likely nonexistant)
reader, is where we reach the point of this post. I've long held a bit of a fascination for the
different training dynamics and effectiveness of various activation functions in neural networks.
As a result, over my years of tinkering: I've built up quite the weird and wonderful menagerie of
strange and unusual activation functions that I'd like to throw out into the aether of the internet
here for any curious person bored enough to care. Who knows, maybe one or two of them might gain
some traction or spark an idea in somebody's head that might lead to the next sigmoid or ReLU?
I sincerely doubt that the abs function is going to be the next big activation de jour, but knowing
that it is somehow weirdly effective as an activation function might inspire someone else who
shares my curiosity and utter disregard for the time this rabbit hole can absorb from your day. And
now, without further ado I introduce a rundown of a few of my favourite non-standard activation
functions; weird, wonderful, and utterly insane.

## The Weird

### Tish

Outside of your standard sigmoid and ReLU, a new class of self-gating activations has come into
common usage such as `Swish` (aka: `SiLU` in torch). While I wouldn't necessarily class these as
"weird", they are quite interesting. One of these functions that I have often wondered why it
isn't more common is the `Tanh` analogue of `Swish`, a function I've taken to referring to as
`Tish`. Where `Swish` is $\text{Swish}(x) = x \cdot \sigma(x)$, `Tish` is effectively the same
with an added offset $[todo!]$. Comparing these, we see that they achieve extremely similar
shapes.

[todo!]

Training models with these activations find that they perform quite similarly.

[todo!]

However, for simple implementations of neural network frameworks `Tanh` is generally measurably
faster than `Sigmoid`. So, I've long wondered why we often use `Swish`, but the `Tish` analogue
is so rarely used that it isn't a builtin in any neural network library that I'm aware of!

### Splish

Although `Tish` is marginally more efficient than `Swish`, the performance gain is, admittedly,
negligible. In fact, all the common self-gating activations are quite computationally heavy.
This is the main reason why ReLU still holds its position as the first, default activation we
reach for in hidden layers. Did you know though: any half-decent autograd engine (and torch has a
**very** good autograd engine) has no problem calculating gradients for linear spline functions?
This is actually how the "hard" variants of many functions, such as `Hardsigmoid` work: they are
just several lines (in this example 3 lines) and conditional bounds that create a linear spline.
These hard functions are great, because lines are extremely efficient to compute. They're so
efficient, that torch even includes a builtin "hard" variant of `Swish` that is simply a line for
all `x` values outside the range -3 to 3. Inside the range -3 to 3 `Hardswish` follows a quadratic
curve instead. This helps a bit with computational overhead, but the quadratic section of the
function is still more computationally heavy than it could be. So, you might naturally wonder:
can't we just make a `Swish` entirely out of lines? And, in response, I present: "Spline Swish", or
`Splish` for short!

{{< activation_figure src="/posts/fun_acts_with_activation_functions/activation_figure.html" caption="Comparison of <em>SiLU</em>, <em>Hardswish</em>, and <em>Splish</em> activation functions with synchronized axes." >}}

This little 3 line spline is one I threw together by just fitting 3 lines to `Swish` in the range
-5 to 5, a range where 99% of properly normalised values should be comfortably within. And how does
it perform? Well, it actually performs surprisingly well.

{{< activation_figure src="/posts/fun_acts_with_activation_functions/val_acc_figure.html" caption="Validation accuracy curves across 10 training epochs for <em>SiLU</em>, <em>Hardswish</em>, and <em>Splish</em>." >}}

The fact that it trains more like `Swish` than `ReLU` despite being comprised entirely of simple
linear segments is quite surprising, demonstrating that there's a lot more to linear ramp
functions than just `ReLU`.

### Adaptive Piecewise Linear (APL) Activation

Taking this to an extreme: what if we made a function using learned combination of linear splines?
This is what the "Adaptive Piecewise Linear" (APL) activation function does. Obviously, when
initialised this function looks like a simple `Linear` activation. But as the model trains the APL
function [todo!].

[todo!]

This function is particularly interesting as it almost serves as a stepping stone towards the
concept of a Kolmogorov-Arnold Network (KAN), wherein the *activation function* is learned rather
than the weights and biases of the neurons. That being said, this isn't quite the same, since it
has no mechanism for converting the APL spline to a single representation like a KAN activation.
You could also look at APL as analogous to using a simple multilayer perceptron as your
activation (which is also entirely viable to use as an activation, by the way), but this
observation actually highlights the exact problem with APL activations that makes them somewhat
redundant; anything they can learn to represent could equally be represented by just adding a few
more neurons with `ReLU` activations. In fact: by separating out these parameters into neurons we
would also have the advantage of making it easier for the execution engine to parallelise that
computation. For this reason: APL activations are almost never used, though they do still
have niche applications in [todo!].

## The Wonderful

### Soft Exponential (SoftExp)

To open the category of "the wonderful", I want to open with one of my favourites: `SoftExp`. This
function is a learned, parametric function first described by [todo!] that can adapt its shape from
a [todo!], through [todo!], to a [todo!]. This results in a function that can dynamically learn to
fit almost any smooth curve for the low, low cost of only one extra parameter per activation layer.

[todo!]

Although it quickly fell by the wayside as we abaondoned parametric activations in favour of ever
larger, deeper networks; this activation still has some uses that make it stand out from other
activations in certain niches. For example: in my own research I have found it to be extremely
useful as an activation in probabilistic networks based on Belnap bilattices. My suspicion is that
it works well for this because it act as a smoothly differentiable, self-gating, and
self-normalising activation all in a single function. Even for simple tasks such as our QMNIST
benchmark here, it yields the best results of all activations tested [verify!].

[todo!]

### Wavelet Implicit neural REpresentation (WIRE)

Another interesting adaptive, parametric function is `WIRE`. Rather uniquely, this function is
based on a parametric combination of several wavelets. This function is particularly useful in
signal processing applications [verify!] and in niches like [todo!].

[todo!]

It does reasonably well on our QMNIST benchmark too though [verify!], yielding the [todo!] highest
accuracy of the tested functions.

[todo!]

It is a bit of a niche one though, so don't expect to see it in any papers next time you scan
through arXiv.

### GroupSort

This one might *actually* be my favourite random trivia fact in neural network design... (I'm fun
at parties, I swear...). Did you know that many *algorithms* are differentiable? And many of those
that aren't are pseudodifferentiable. With that in mind, can we differentiate a sorting algorithm
and use that as an activation? In fact, we can! The differential of a sort is simply the Jacobian
of that sort [verify!]. Using that fact, we can create a sort that *appears* to just be an
`Identity` activation when we plot it.

[todo!]

But here's the fun bit: for some reason using a sort as an activation is **consistently**
significantly more effective than an activation. I haven't looked into why (yet), but my current
speculation is that it is creating some kind of structural inductive bias that disincentivizes
shared, delocalised representations across multiple neurons. [verify!]

[todo!]

Whatever the reason, I thought it was *extremely* cool when I discovered that sorting functions
are viable as activation functions, even if it's a somewhat impractical as a real-world
activation.

## The Utterly Insane

### A* as an Activation Function

So, remember how that last one discussed the fact that many algorithms are differentiable? Well,
according to [todo!], all _dynamic programming_ algorithms are fully differentiable. As such, we
can take the quintessential dynamic algorithm, A*, and use that as an activation function! So,
if we do that, what do we see? Well, to start with: we see this extremely strange activation
function plot.

[todo!]

But does it work? See for yourself!

[todo!]

The answer is: it learns. Though, it doesn't do a great job of it. [verify!] Still, it's kind of
insane that the A* algorithm can be used as an activation function. I've also tested this with
rule 110 cellular automata and Newton's method for convergence, but I thought A star would be the
most fun example to share.

### Batman Activation

Yes... this is exactly what it sounds like... you can, in fact, turn any drawing into an activation
function. Using our trick from earlier where we demonstrated that splines are autodifferentiable,
and combining it with the hand [todo!] function (which allows us to smoothly interpolate between
any functions based on a single parameter) we can, for example, turn a drawing of the batman logo
into a working, viable activation function.

[todo!]

And, yet again, this somehow learns!

[todo!]

While this might seem pointless, it does demonstrate one thing: that neural networks are
remarkably adaptable.

## What's the Point of This?

All of this is, really, just intended to show just how adaptable and flexible neural networks are,
and just how varied activation functions can be! While you're unlikely to ever want to embed the
bat signal in your model's mathematics, I hope this has inspired anyone who may or may not be
reading to be a bit more creative with your activation functions. Don't disregard them just
because this niche of research has stagnated: these are one of the first active areas of
significant breakthroughs in neural network development and remain a **powerful** tool for
creating uniquely capable models.

Once upon a time, we thought `Sigmoid` and `Tanh` were going to be the endpoint of activation
function development, then `ReLU` shook the world of deep learning. We thought `ReLU` was the
simplest possible activation with few downsides, then we discovered `Swish`, `GELU`, and other
self-gating functions that don't suffer the same vanishing gradient issues. Just because we think
we have it solved this time doesn't mean somebody won't think up another activation function that
turns the world of ML research on it's head, and who knows: your "stupid" activation function could
turn out to be that next function. And if it isn't, you can at least have fun embedding
inappropriate drawings into your artificially "intelligent" models!
