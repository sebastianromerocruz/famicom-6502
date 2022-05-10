# NES Game Development Tutorial

### Build Steps (Mac):

From within the assembler-tutorial repository, run the following shell script:

```
./build.sh
```

This will generate the nes-tutorial.nes file to be played on an NES emulator. We are basically just running an infinite loop (plus some
boilerplate code):

```ams
RESET:

InfiniteLoop:
	JMP InfiniteLoop
```