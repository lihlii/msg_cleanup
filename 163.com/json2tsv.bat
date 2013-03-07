@echo off
for %%F in (*.html) do (json2tsv.pl "%%F" > "%%F.tsv" 2>> JSON2TSV.ERR)
