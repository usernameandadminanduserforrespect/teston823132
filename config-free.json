@ECHO OFF
ECHO [Compiling Paid Build]
darklua.exe process -c ".\config.json" -v "main.luau" "compiled\release.luau"
ECHO 	- Release compiled!
darklua.exe process -c ".\config-debug.json" -v "main.luau" "compiled\debug.luau"
ECHO 	- Debug compiled!
py PreProcess.py SPWL_Client.luau
ECHO 	- Loader compiled done!
ECHO [Compiling Free Build]
darklua.exe process -c ".\config-free.json" -v "main.luau" "compiled\free.luau"
ECHO 	- Free Build compiled!
ECHO [Done!]