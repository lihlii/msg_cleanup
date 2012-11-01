@echo off
for %%F in (*.htm*) do (cleanup.pl -t "%%F" 2> NUL)
