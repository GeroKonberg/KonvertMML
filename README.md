# konvertMML
Have you ever wanted to translate music/sequence data directly from the original SPC files using true S-SMP assembly code into functional AddmusicK MML text files?

konvertMML aims to translate much of the stock N-SPC and other voice commands into SMW's equalivent set, whether it's notes or hex commands or even bracket optimizations if present on a given source material.

This batch repository comes bundled in with a variety of stock and extended sequence readers used across many SNES/SFC titles, alongside with a series of configurable presets optimized for different games. The settings file is simple yet fairly configurable: a pointer to the song index, a pointer for outputting data, where to store the translation program and which song from the index to play from (if applicable).

Once the given input has been patched accordingly, the sound driver will continue to read music data and be bypassed to instead translate every given hex command into AddmusicK's text format which then can be inserted for SMW hacks on success. Since the original music player and language is recycled for this purpose, it is currently the closest known method for accurate direct translations available, not accounting for missing commands and/or other technical issues that may occur with the #amk 4 parser at the moment.

2026 Gero Konberg Foundation et al.
