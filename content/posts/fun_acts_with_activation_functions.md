+++
date = '2025-02-17T00:26:56Z'
draft = false
math = true
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
`Tish`. Where `Swish` is $\text{Swish}(x) = x \cdot \sigma(x)$, `Tish` is defined as
$\text{Tish}(x) = x \cdot (\tanh(x) + 1)$. Recalling the standard hyperbolic relation
$\sigma(2x) = \frac{\tanh(x) + 1}{2}$, we can see that $\text{Tish}(x) = 2x \cdot \sigma(2x)$—effectively
a scaled, frequency-doubled cousin of Swish whose gating factor ranges over $(0, 2)$ rather than $(0, 1)$.
Comparing their mathematical curves, we see that they achieve extremely similar shapes.

{{< activation_figure src="/posts/fun_acts_with_activation_functions/tish_figure.html" caption="Comparison of <em>SiLU</em> (Swish) and <em>Tish</em> activation functions with synchronized axes." >}}

Training models with these activations reveals that they perform quite similarly.

{{< activation_figure src="/posts/fun_acts_with_activation_functions/tish_val_acc.html" caption="Validation accuracy curves across 10 epochs for <em>SiLU</em> (96.77%) and <em>Tish</em> (97.48%)." >}}

However, for simple implementations of neural network frameworks, `Tanh` is generally measurably
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

{{< activation_figure src="/posts/fun_acts_with_activation_functions/activation_figure.html" caption="Comparison of <em>SiLU</em>, <em>Splish</em>, and <em>ReLU</em> activation functions with synchronized axes." >}}

This little 3 line spline is one I threw together by just fitting 3 lines to `Swish` in the range
-5 to 5, a range where 99% of properly normalised values should be comfortably within. And how does
it perform? Well, it actually performs surprisingly well.

{{< activation_figure src="/posts/fun_acts_with_activation_functions/val_acc_figure.html" caption="Validation accuracy curves across 10 training epochs for <em>SiLU</em> (96.77%), <em>Splish</em> (97.08%), and <em>ReLU</em> (96.93%)." >}}

The fact that it trains more like `Swish` than `ReLU` despite being comprised entirely of simple
linear segments is quite surprising, demonstrating that there's a lot more to linear ramp
functions than just `ReLU`. In fact, when we run activation maximization ("deep dreaming") to see
what digit archetypes the `Splish` network forms, it synthesizes crisp, well-defined strokes:

<div style="text-align: center; margin: 2rem 0;">
  <img src="/posts/fun_acts_with_activation_functions/splish_dream.png" alt="Splish Activation Feature Visualizations" style="max-width: 100%; border-radius: 8px; border: 1px solid #334155; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.2);" />
  <p style="color: #a0a0a0; font-size: 0.9em; margin-top: 0.5rem;">Synthesized digit archetypes (0&ndash;9) learned by the network using Splish activations.</p>
</div>

### Adaptive Piecewise Linear (APL) Activation

Taking this to an extreme: what if we made a function using a learned combination of linear splines?
This is what the "Adaptive Piecewise Linear" (APL) activation function (Agostinelli et al., 2014) does:

$$f(x) = \max(0, x) + \sum_{s=1}^S a_s \max(0, -x + b_s)$$

When initialised with $a_s = 0$, it looks and acts just like a vanilla `ReLU`. But as the
model trains, gradient descent twiddles with the slope parameters $a_s$ and threshold offsets $b_s$,
carving out its own custom piecewise-linear curve with as many kinks and bends as you give it hinges.

{{< activation_figure src="/posts/fun_acts_with_activation_functions/apl_figure.html" caption="Adaptive Piecewise Linear (APL) activation curves across varying hinge parameter configurations." >}}

{{< activation_figure src="/posts/fun_acts_with_activation_functions/apl_val_acc.html" caption="Validation accuracy curves across 10 epochs for <em>APL</em> (97.27%) compared to standard <em>ReLU</em> (96.93%)." >}}

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
have niche applications in formal neural network verification (where tools like SMT and MILP
solvers find piecewise-linear regions way easier to prove safety bounds for than curvy exponentials)
and on barebones edge hardware or FPGAs where computing transcendental functions is a non-starter.

## The Wonderful

### Soft Exponential (SoftExp)

To open the category of "the wonderful", I want to start with one of my personal favourites: `SoftExp`. This
is a learned, parametric function first described by Godfrey (2015) that can adapt its shape all the way from
a sub-linear logarithmic curve ($\alpha < 0$), through plain linear identity ($\alpha \to 0$), to super-linear
exponential amplification ($\alpha > 0$). This gives you a function that can dynamically learn to
fit almost any smooth curve for the low, low cost of only one extra parameter per layer.

{{< activation_figure src="/posts/fun_acts_with_activation_functions/softexp_figure.html" caption="Soft Exponential (SoftExp) activation parameterized across &alpha; &isin; {-1.0, -0.5, 0.0, 0.5, 1.0}." >}}

Although it quickly fell by the wayside as everyone abandoned parametric activations in favour of just
stacking ever larger, deeper networks; this activation still has some superpowers that make it stand out in
certain niches. For example: in my own research I've found it to be ridiculously useful as an activation in
probabilistic networks based on Belnap bilattices. My hunch is that it works so well there because it acts as
a smoothly differentiable, self-gating, and self-normalising activation all wrapped up into a single neat little formula.

Now, I was secretly hoping it would pull off a miracle on our QMNIST benchmark too, but honestly? It ended up
with a pretty mediocre 92.47% peak validation accuracy (ranking 53rd out of the 62 activations I tested). That
unconstrained exponential branch is notoriously touchy with learning rates, which is a pretty good reminder of
why we mostly stick to boring, parameter-free functions in practice.

{{< activation_figure src="/posts/fun_acts_with_activation_functions/softexp_val_acc.html" caption="Validation accuracy curve for <em>SoftExp</em> across 10 epochs on QMNIST (peak: 92.47%)." >}}

### Wavelet Implicit neural REpresentation (WIRE)

Another interesting adaptive, parametric function is `WIRE` (Saragadam et al., CVPR 2023). Rather
uniquely, this function is based on a continuous Gabor wavelet:

$$f(x) = \cos(\omega_0 x) \exp(-(s_0 x)^2)$$

Because wavelets have compact support in both space and frequency, `WIRE` can capture sharp, high-frequency
details without the nasty high-frequency noise and spectral bias you get from purely periodic activations like
SIREN. That makes it killer for signal processing and Implicit Neural Representations (INRs)—things like NeRFs,
medical imaging reconstruction (low-dose CT and MRI), and non-linear PDEs.

{{< activation_figure src="/posts/fun_acts_with_activation_functions/wire_figure.html" caption="Wavelet Implicit Neural Representation (WIRE) activation curve." >}}

It manages to learn on our QMNIST benchmark too, landing at 90.30% validation accuracy (54th out of 62). Getting
90% shows the network didn't blow up, but standard image classification on flattened pixel vectors really isn't
what wavelets were born to do. Localized Gabor wavelets are meant for low-dimensional coordinate regression
($x, y \to \text{RGB}$), where spatial frequency matters a lot more than it does on 28x28 handwritten digits.

{{< activation_figure src="/posts/fun_acts_with_activation_functions/wire_val_acc.html" caption="Validation accuracy of <em>WIRE</em> across 10 epochs on QMNIST (peak: 90.30%)." >}}

Because of those localized frequency properties, when you run activation maximization to see what digits the
network dreams up, you get these fascinating interference-like stroke patterns:

<div style="text-align: center; margin: 2rem 0;">
  <img src="/posts/fun_acts_with_activation_functions/wire_dream.png" alt="WIRE Activation Feature Visualizations" style="max-width: 100%; border-radius: 8px; border: 1px solid #334155; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.2);" />
  <p style="color: #a0a0a0; font-size: 0.9em; margin-top: 0.5rem;">Synthesized digit archetypes (0&ndash;9) learned using WIRE wavelet activations.</p>
</div>

It's definitely a niche one though, so don't expect to see it in standard LLM or vision transformer
architectures anytime soon.

### GroupSort

This one might *actually* be my favourite random trivia fact in neural network design... (I'm fun
at parties, I swear...). Did you know that many *algorithms* are differentiable? And many of those
that aren't are pseudodifferentiable. With that in mind, can we differentiate a sorting algorithm
and use that as an activation? In fact, we can! Sorting is just a piecewise-linear operation; as long as the
inputs aren't identical, sorting is mathematically just multiplying by a permutation matrix $P_x$. The
Jacobian of a sort with respect to its input is literally that permutation matrix, which means
backpropagation through a sort simply "unsorts" the incoming gradients by applying $P_x^T$.

Using that fact, we can create a sort that *appears* to just be an `Identity` activation when we plot it
across individual coordinate axes.

{{< activation_figure src="/posts/fun_acts_with_activation_functions/groupsort_figure.html" caption="GroupSort activation function with group size 2." >}}

But here's the fun bit: using a sort as an activation is **consistently** significantly more
effective than standard linear or identity activations! When I ran this on the QMNIST benchmark, `GroupSort`
(with a group size of 2) clocked in at a wild **97.51% validation accuracy**, placing **#4 out of all 62
activations I tested**! That completely smokes pure `Identity` (92.94%) and comfortably beats `ReLU` (96.93%).

Why on earth does sorting work this well? It turns out someone actually proved the math on this: Anil et al.
(ICML 2019) showed that GroupSort is an *isometry* ($L_2$ norm preserving). Because sorting just shuffles
elements without stretching them, its Jacobian is orthogonal almost everywhere. That preserves gradient
norms from layer to layer, making GroupSort networks strictly 1-Lipschitz with zero vanishing or exploding
gradients. Even cooler: while standard 1-Lipschitz activations (like ReLU) suffer from gradient attenuation
and can't represent all 1-Lipschitz functions without ballooning in width, GroupSort is mathematically
proven to be a universal approximator for *any* 1-Lipschitz function.

{{< activation_figure src="/posts/fun_acts_with_activation_functions/groupsort_val_acc.html" caption="Validation accuracy comparison: <em>GroupSort</em> (97.51%) vs <em>Identity</em> (92.94%) vs <em>ReLU</em> (96.93%)." >}}

And here's what the category archetypes look like when dreamed through pure isometric sorting:

<div style="text-align: center; margin: 2rem 0;">
  <img src="/posts/fun_acts_with_activation_functions/groupsort_dream.png" alt="GroupSort Activation Feature Visualizations" style="max-width: 100%; border-radius: 8px; border: 1px solid #334155; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.2);" />
  <p style="color: #a0a0a0; font-size: 0.9em; margin-top: 0.5rem;">Synthesized digit archetypes (0&ndash;9) learned using GroupSort activations.</p>
</div>

Whatever the reason, I thought it was *extremely* cool when I discovered that sorting functions
are viable as activation functions, even if sorting wide layers has a bit too much runtime overhead for everyday production models.

## The Utterly Insane

### A* as an Activation Function

So, remember how that last one discussed the fact that many algorithms are differentiable? Well,
according to Mensch and Blondel (ICML 2018), dynamic programming algorithms can be made fully
differentiable just by swapping out the hard min/max operations for smoothed LogSumExp operators
($\text{softmin}_\gamma$). As such, we can treat the hidden feature dimension as a multi-stage trellis
graph—where negative activation values represent edge traversal costs—and run a forward pass of the smoothed
Bellman equation to turn A* shortest-path finding into an attention-like feature gate!

So, if we do that, what do we see? Well, to start with: we see this extremely strange activation
function plot.

{{< activation_figure src="/posts/fun_acts_with_activation_functions/astar_figure.html" caption="Smoothed Bellman / A* dynamic programming trellis gate activation profile." >}}

But does it work? See for yourself!

{{< activation_figure src="/posts/fun_acts_with_activation_functions/astar_val_acc.html" caption="Validation accuracy of <em>Soft A*</em> (96.98%) compared to <em>ReLU</em> (96.93%) across 10 epochs." >}}

The answer is: it doesn't just learn, it genuinely kicks ass. It clocked in at a peak of **96.98% validation
accuracy** (18th out of 62), casually beating both `ReLU` (96.93%) and `SiLU` (96.77%)! Still, it's kind of
insane that the A* pathfinding algorithm can be dropped straight into a neural network as an element-wise
activation function. (I've also tested this with Rule 110 cellular automata and Newton-Raphson implicit
solvers for Kepler's planetary orbits, but I thought A* would be the most fun example to share).

And yes, our pathfinding network dreams up remarkably crisp digit archetypes:

<div style="text-align: center; margin: 2rem 0;">
  <img src="/posts/fun_acts_with_activation_functions/astar_dream.png" alt="Soft A* Activation Feature Visualizations" style="max-width: 100%; border-radius: 8px; border: 1px solid #334155; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.2);" />
  <p style="color: #a0a0a0; font-size: 0.9em; margin-top: 0.5rem;">Synthesized digit archetypes (0&ndash;9) learned using Soft A* dynamic programming activations.</p>
</div>

### Batman Activation

Yes... this is exactly what it sounds like... you can, in fact, turn any drawing into an activation
function. Using our trick from earlier where we demonstrated that splines are autodifferentiable,
and combining it with a handy smooth blending gate:

$$\text{blend}(a, b, u, \text{thresh}) = (1 - \sigma(k(u - \text{thresh}))) \cdot a + \sigma(k(u - \text{thresh})) \cdot b$$

which smoothly transitions between piecewise functions based on boundary thresholds, we can stitch together
the 6 elliptic and polynomial curves of the famous 2011 Batman Equation into a continuous,
differentiable activation function.

{{< activation_figure src="/posts/fun_acts_with_activation_functions/batman_figure.html" caption="The Batman Activation Function, smoothly blending cowl, ear, shoulder, and wing curves." >}}

And, yet again, this somehow learns!

{{< activation_figure src="/posts/fun_acts_with_activation_functions/batman_val_acc.html" caption="Validation accuracy curve for the <em>Batman Activation</em> reaching 86.67% on QMNIST." >}}

On our QMNIST benchmark, the Batman Activation pulls off a respectable **86.67% validation accuracy**
(55th out of 62). To prove that it's actually learning real features rather than flailing in the dark,
I ran activation maximization ("deep dreaming") to see what digit archetypes the Batman network sees:

<div style="text-align: center; margin: 2rem 0;">
  <img src="/posts/fun_acts_with_activation_functions/batman_dream.png" alt="Batman Activation Feature Visualizations" style="max-width: 100%; border-radius: 8px; border: 1px solid #334155; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.2);" />
  <p style="color: #a0a0a0; font-size: 0.9em; margin-top: 0.5rem;">Synthesized digit archetypes (0&ndash;9) learned by the network using Batman activations.</p>
</div>

While this might seem completely pointless, it does demonstrate one thing: that neural networks are
remarkably adaptable.

## What's the Point of This?

All of this is, really, just intended to show just how adaptable and flexible neural networks are,
and just how varied activation functions can be! While you're unlikely to ever want to embed the
bat signal in your model's mathematics, I hope this has inspired anyone who may or may not be
reading to be a bit more creative with your activation functions. Don't disregard them just
because this niche of research has stagnated: these are one of the first active areas of
significant breakthroughs in neural network development and remain a **powerful** tool for
creating uniquely capable models.

If you want to poke around the implementations, play with the interactive visualizations, or run
the benchmarks yourself, all the code, models, and configs are open source in the
[`activation_function_playground`](https://github.com/Cian-H/activation_function_playground) repository.

Once upon a time, we thought `Sigmoid` and `Tanh` were going to be the endpoint of activation
function development, then `ReLU` shook the world of deep learning. We thought `ReLU` was the
simplest possible activation with few downsides, then we discovered `Swish`, `GELU`, and other
self-gating functions that don't suffer the same vanishing gradient issues. Just because we think
we have it solved this time doesn't mean somebody won't think up another activation function that
turns the world of ML research on its head, and who knows: your "stupid" activation function could
turn out to be that next function. And if it isn't, you can at least have fun embedding
inappropriate drawings into your artificially "intelligent" models!
