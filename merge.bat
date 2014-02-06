@echo off
type *.htm* > all 2>NUL
ren all all.htm
cleanup.pl -t all.htm 2>> CLEANUP.ERR
