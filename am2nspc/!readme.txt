AddmusicK 1.0.11 to N-SPC converter

How to use the batch converter as intended:

1) Create any SPC file using a stock, unmodified version of AddmusicK 1.0.11.
2) Make sure the MML has a song intro maker '/' somewhere, even if no intro is necessary.
3) Run it through AddmusicK and copy over the SPC output under the new name "input.spc".
4) Execute the batch file "am1011-2nspc.bat" or open cmd and type in ' asar --no-title-check "am1011-2nspc.asm" "output.sfc" ' for ROM output.
5) Once successful, open "output.sfc", wait a bit and then dump the output SPC file using an emulator of your choice once the song has been converted and loaded in.
6) The SPC should now be able to be recognized by VGMTrans as it is now using the compatible standard N-SPC voice command set ($E0-$FF).
7) If it still fails to load, try patching it using the spcTagger.ips which adds in further identification as needed for 6).

8) Have fun! For any additional issues that may occur during the translation process, please create an issue here with exact details so we can replicate it and come up with a solution as possible.
