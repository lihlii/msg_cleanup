@echo off
type *.htm* > all.htm
cleanup.pl -t all.htm 2>> CLEANUP.ERR
