# [**Getting Started with Famicom / NES Game Development: A Personal Chronicle**](nes-tutorial.asm)

### Sections

1. [**Motivation**](#motivation)
2. [**The Famicom Boilerplate**](#the-famicom-boilerplate)
3. [**Build Steps (Mac)**](#build-steps-mac)
4. [**Our First Famicom Cartridge**](#our-first-famicom-cartridge)

### Motivation

I love the NES (or in particular, its japanese counterpart, the Famicom). Beyond the fact that it is a revolutionary piece of culture with a set of incredible-ageing games, I love its development lore. After reading Nathan Altice's [**I Am Error**](https://mitpress.mit.edu/books/i-am-error), a "complex material histories of the NES platform, from code to silicon", I became kind of obsessed with the way it worked—from code to silicon.

At around the time I read Altice's book, I was beginning a master's degree in computer science at NYU Tandon School of Engineering, hoping for a career change into software engineering (I had previously studied chemical engineering). Finding myself that early in my computer science career, I was not exactly ready to take on something as daunting and (as I later found out) poorly-documented as game development for a console that is over forty years old.

Almost four years late, and now that I am an adjunct professor of computer science at Tandon, I finally find myself at a level where I believe that learning this stuff is actually possible—and something that I can potentially turn into a lecture series and teach it to students like myself. I will be following [**Jonathan Moody's**](http://thevirtualmountain.com/) [**tutorial series**](http://thevirtualmountain.com/nes/2017/03/06/getting-started-with-nes-game-development.html), which I found to be one of the best ones out there.

So here it is: literal wish fulfillment.

### The Famicom Boilerplate

Every Famicom file will start with the following directives:

```asm
	.inesprg 1    		; Defines the number of 16kb PRG banks
	.ineschr 1    		; Defines the number of 8kb CHR banks
	.inesmap 0    		; Defines the NES mapper
	.inesmir 1    		; Defines VRAM mirroring of banks
```

These seem to be hardware-related, so I won't worry too much about them for now. Afterward, we call the `.bank` directive to add a bank of memory, where our code will reside:

```asm
	.bank 0				; Add a bank of memory
	.org $C000			; Define where in the CPU’s address space it is located
```

Since we're only looking to get our code to assemble at this point, we are basically just running an infinite loop:

```asm
RESET:

InfiniteLoop:
	JMP InfiniteLoop

NMI:
	RTI
```

The CPU has a few memory addresses set aside to define three interrupt vectors (`NMI`, `RESET`, and `IRQ`). These three vectors will each take up 2 bytes of memory and are located at the range `$FFFA`-`$FFFF`. We won’t deal with the `IRQ` now, but apparently all we need to know is that it is an interrupt for mappers and audio.

Next, we define a second bank, where our sprite and music data will eventually decide:

```asm
	.bank 1
	.org $FFFA			; The IRQ, which we will se to 0 for now
	.dw NMI				; non-maskable interrupt
	.dw RESET
	.dw 0
```

<sub>The `.dw` directive is used to define a "word", meaning 2 bytes of data.</sub>

### Build Steps (Mac)

From within the assembler-tutorial repository, run the following `Makefile` script to create our NES cartridge:

```commandline
make
```

And the following to run it on the Nestopia emulator:

```commandline
make run
```

### Our First Famicom Cartridge

The result is a black screen (which is more progress on Famicom development that I've done in the last two years, so I'm pretty happy):

![tutorial](assets/tutorial.png)