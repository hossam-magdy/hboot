@echo off
::THIS FILE IS STARTED BEFOR WINDOWS INSTALLATION FROM ISO STARTS
::cls
START /min "" "%~d0\docs\WindowsProductKeys.txt"
cmd /k %~dp0LOADISO.cmd
exit
