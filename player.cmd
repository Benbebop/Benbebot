@echo off

title Benbebot-Audio-Player

cls

:autorestart

cd /d G:\botbebop

luvit errorcatcher-audioplayer.lua 2> errorhandle\error-a.proxy

type errorhandle\error-a.proxy > errorhandle\error-a.log

goto autorestart