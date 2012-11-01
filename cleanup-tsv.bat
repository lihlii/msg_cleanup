@echo off
for %%F in (*.htm) do (cleanup.pl -t "%%F" > "%%F-o.txt" 2> err.txt)
