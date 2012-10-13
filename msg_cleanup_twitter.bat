@echo off
for %%F in (*.htm) do (msg_cleanup_twitter.pl -h "%%F" > "%%F-o.htm" 2> NUL)
