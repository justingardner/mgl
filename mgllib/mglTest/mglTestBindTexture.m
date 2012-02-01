% mglTestBindTexture.m
%
%        $Id:$ 
%      usage: mglTestBindTexture()
%         by: justin gardner
%       date: 02/01/12
%    purpose: function to test live textures - this is a fast way
%             to update textures - that is, if you have the same image
%             dimensions and want to change just the alpha channel or the
%             image, this should be quicker than create/delete textures.
%
function retval = mglTestBindTexture()

% check arguments
if ~any(nargin == [0])
  help mglTestBindTexture
  return
end

% which test to run
testAlphaValueChange = true;
testCompleteChange = true;
testAlphaImageChange = true;

% size of texture to display
texWidth = 5;
texHeight = 5;

% size of screen
screenWidth = 16;
screenHeight = 12;

% number of textures for testing
nTextures = 1024;

% open screen
mglOpen(0.8);
mglVisualAngleCoordinates(57,[screenWidth screenHeight]);
mglClearScreen(0.5);
mglFlush;

% make a grating texture
g = mglMakeGrating(texWidth,texHeight,1.5,45,0);
g = 255*(g+1)/2;
g4(:,:,1) = g;
g4(:,:,2) = g;
g4(:,:,3) = g;
g4(:,:,4) = 128;
tex = mglCreateTexture(g4,'xy',1);

% test alpha change
if testAlphaValueChange
  disp(sprintf('(mglTestBindTexture) Testing change in alpha'));
  % clear screen
  mglClearScreen;tic;
  % now draw textures at random positions with random alphas
  % alphas are set by using mglBindTexture
  for i = 1:nTextures
    % set alpha
    mglBindTexture(tex,round(rand*255));
    % display texture
    mglBltTexture(tex,[round((rand-0.5)*screenWidth) round((rand-0.5)*screenHeight) texWidth texHeight]);
  end
  % calculate how much time that took
  liveBufferTime = toc;
  % display
  mglFlush;
  % clear screen
  mglClearScreen;tic;
  % do same thing as above, but create/delete texture
  for i = 1:nTextures
    % create a new texture with a random alpha
    g4(:,:,4) = round(rand*255);
    tex2 = mglCreateTexture(g4);
    % display the texture
    mglBltTexture(tex2,[round((rand-0.5)*screenWidth) round((rand-0.5)*screenHeight) texWidth texHeight]);
    % delete it
    mglDeleteTexture(tex2);
  end
  % calculate time it took
  createTextureTime = toc;
  % display
  mglFlush;
  % display how much faster the live texture took
  disp(sprintf('(mglTestBindTexture) Live texture is %0.2fx faster',createTextureTime/liveBufferTime));
end

% test complete change
if testCompleteChange
  disp(sprintf('(mglTestBindTexture) Testing complete change'));
  % clear screen
  mglClearScreen;tic;
  % now draw textures at random positions with random alphas
  % alphas are set by using mglBindTexture
  for i = 1:nTextures
    % make a new grating at a random orientation
    g = mglMakeGrating(texWidth,texHeight,1.5,rand*360,0);
    g = 255*(g+1)/2;
    g4(:,:,1) = g;
    g4(:,:,2) = g;
    g4(:,:,3) = g;
    g4(:,:,4) = round(rand*255);
    % rebind texture
    mglBindTexture(tex,g4);
    % display texture
    mglBltTexture(tex,[round((rand-0.5)*screenWidth) round((rand-0.5)*screenHeight) texWidth texHeight]);
  end
  % calculate how much time that took
  liveBufferTime = toc;
  % display
  mglFlush;
  % clear screen
  mglClearScreen;tic;
  % do same thing as above, but create/delete texture
  for i = 1:nTextures
    % make a new grating at a random orientation
    g = mglMakeGrating(texWidth,texHeight,1.5,rand*360,0);
    g = 255*(g+1)/2;
    g4(:,:,1) = g;
    g4(:,:,2) = g;
    g4(:,:,3) = g;
    g4(:,:,4) = round(rand*255);
    tex2 = mglCreateTexture(g4);
    % display the texture
    mglBltTexture(tex2,[round((rand-0.5)*screenWidth) round((rand-0.5)*screenHeight) texWidth texHeight]);
    % delete it
    mglDeleteTexture(tex2);
  end
  % calculate time it took
  createTextureTime = toc;
  % display
  mglFlush;
  % display how much faster the live texture took
  disp(sprintf('(mglTestBindTexture) Live texture is %0.2fx faster',createTextureTime/liveBufferTime));
end

% test alpha image change
if testAlphaImageChange
  disp(sprintf('(mglTestBindTexture) Testing alpha image change'));
  % clear screen
  mglClearScreen;tic;
  % now draw textures at random positions with random alphas
  % alphas are set by using mglBindTexture
  for i = 1:nTextures
    % make a random sized gaussian window
    g = round(255*mglMakeGaussian(texWidth,texHeight,rand*3*texWidth/21,rand*3*texHeight/21));
    % rebind texture
    mglBindTexture(tex,g);
    % display texture
    mglBltTexture(tex,[round((rand-0.5)*screenWidth) round((rand-0.5)*screenHeight) texWidth texHeight]);
  end
  % calculate how much time that took
  liveBufferTime = toc;
  % display
  mglFlush;
  % clear screen
  mglClearScreen;tic;
  % do same thing as above, but create/delete texture
  for i = 1:nTextures
    % make a random sized gaussian window
    g4(:,:,4) = round(255*mglMakeGaussian(texWidth,texHeight,rand*3*texWidth/21,rand*3*texHeight/21));
    tex2 = mglCreateTexture(g4);
    % display the texture
    mglBltTexture(tex2,[round((rand-0.5)*screenWidth) round((rand-0.5)*screenHeight) texWidth texHeight]);
    % delete it
    mglDeleteTexture(tex2);
  end
  % calculate time it took
  createTextureTime = toc;
  % display
  mglFlush;
  % display how much faster the live texture took
  disp(sprintf('(mglTestBindTexture) Live texture is %0.2fx faster',createTextureTime/liveBufferTime));
end

% delete texture
mglDeleteTexture(tex);

% close screen
mglClose;


