# NES Game Development Tutorial

### Build Steps (Mac):

From within the assembler-tutorial repository, run the following shell script to create our NES cartridge:

```commandline
make
```

And the following to run it on the FCEUX emulator:

```commandline
make run
```

This will generate the nes-tutorial.nes file to be played on an NES emulator. We are basically just running an infinite loop (plus some
boilerplate code):

```asm
RESET:

InfiniteLoop:
	JMP InfiniteLoop
```