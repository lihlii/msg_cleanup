@echo off
for %%F in (*.htm) do (cleanup.pl -h "%%F" > "%%F-o.htm" 2>> CLEANUP.ERR)
