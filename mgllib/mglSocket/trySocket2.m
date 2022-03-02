clear;
clc;

mglMakeSocket();

%%
mglSetParam('verbose', 1);

[commands, types] = mglSocketCommandTypes()
class(commands.mglDots)
