@echo off
for %%F in (*.htm*) do (msg_cleanup_twitter.pl -t "%%F" 2> NUL)
