@echo off
::THIS FILE IS STARTED BEFOR WINDOWS INSTALLATION FROM ISO STARTS
::cls
START /min "" notepad "%~dp0WindowsProductKeys"
cmd /k %~dp0LOADISO.cmd
START /wait "" notepad "%~dp0WindowsProductKeys"
exit
