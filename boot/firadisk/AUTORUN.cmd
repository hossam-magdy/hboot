@echo off
::THIS FILE IS STARTED BEFOR WINDOWS INSTALLATION FROM ISO STARTS
::cls
START /min "" "%~d0\boot\_windows_product_keys_.txt"
cmd /k %~dp0LOADISO.cmd
exit
