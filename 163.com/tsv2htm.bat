@echo off
for %%F in (*.tsv) do (perl tsv2htm.pl <"%%F" >"%%F.htm" 2>> TSV2HTM.ERR)
