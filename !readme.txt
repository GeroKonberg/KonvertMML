KonvertMML
Batch-convert & translate SPC sequence data into AddmusicK MML.

How to use the batch converters as intended:

1) Copy over any SPC file into this folder and rename it 'input.spc".
2) Go into the '/presets' folder and search if the game in question is supported as of right now.
3) If confirmed, copy over all the necessary parameters from there into the local "settings.asm" for accurate translations.
4) Execute the batch file "konvertMML.bat" or open cmd and type in ' asar --no-title-check "settings.asm" "output.spc" ' for bypassing the SPC driver upon output.
5) Once successful, open "output.spc" using an SPC memory debugger, wait for a bit and than copy over the new MML output (stored either at 0x7000 or the very beginning 0x0200, see settings.asm) as is into a text file to be run through AddmusicK.
6) Now that the sequence data has been fully translated, it is now up to the porter to adjust song volume (w), instrument data (@/$DA$xx) and more to their preferences: depending on the song quality, further optimize the output before finally inserting it into homebrew and other SMW modding projects.

7) Have fun! For any additional issues that may occur during the translation process, please create an issue here with exact details so we can replicate it and come up with a solution as possible.


The latest SPC files and soundtracks can be obtained here:
https://spc.joshw.info/
https://snesmusic.org/v2/
