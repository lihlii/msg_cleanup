@echo off
for %%F in (*.js) do (json2tsv.pl "%%F" > "%%F.tsv" 2>> JSON2TSV.ERR)
