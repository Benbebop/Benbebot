@echo off

title Benbebot

lit install SinisterRectus/discordia

::lit install RiskoZoSlovenska/coro-thread-work

cls

:autorestart

luvit errorcatcher.lua 2> erroroutput.txt

goto autorestart