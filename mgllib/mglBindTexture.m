% mglBindTexture.m
%
%        $Id:$ 
%      usage: mglBindTexture(tex,newdata)
%         by: justin gardner
%       date: 02/01/12
%    purpose: This implements a faster way to change textures on the fly.
%             For example, if you want to just change the alpha of an
%             image it can be 4x faster than creating and deleting textures.
%             It is a bit faster if you want to change the whole alpha image
%             or the whole image. For now, it only works for 4D textures.
%             Run mglTestBindTexture to test how much faster this is.
%
%             Note that you have to create the texture with liveBuffer (third
%             argument set to true. See examples below.
%
%             To change the alpha (when the alpha is uniform),
%             First do normal setup for making a texture
%             mglOpen(0);
%             mglVisualAngleCoordinates(57,[16 12]);
%             mglClearScreen(0.5);
%             g = mglMakeGrating(3,3,1.5,45,0);
%             g = 255*(g+1)/2;
%             g4(:,:,1) = g;
%             g4(:,:,2) = g;
%             g4(:,:,3) = g;
%             g4(:,:,4) = 128;
%             tex = mglCreateTexture(g4,[],1);
%
%             mglBltTexture(tex,[-5 0 3 3]);
%             mglBindTexture(tex,255);
%             mglBltTexture(tex,[5 0 3 3]);
%             mglFlush;
%
%             %You can also use this to just the whole alpha channel
%             mglClearScreen;
%             g = round(255*mglMakeGaussian(3,3,3/7,3/7));
%             mglBindTexture(tex,g);
%             mglBltTexture(tex,[0 4 3 3]);
%             mglFlush
%
%             % To change the whole texture
%             mglClearScreen;
%             g = mglMakeGrating(3,3,2.5,45,0);
%             g = 255*(g+1)/2;
%             g4(:,:,1) = g;
%             g4(:,:,2) = g;
%             g4(:,:,3) = g;
%             g4(:,:,4) = round(255*mglMakeGaussian(3,3,3/7,3/7));
%             mglBindTexture(tex,g4);
%             mglBltTexture(tex,[0 -4 3 3]);
%             mglFlush

