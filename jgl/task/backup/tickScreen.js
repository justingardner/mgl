/**
 * Function that is in charge of ticking the screen.
 * This is the function that is called every frame, i.e. every 17 miliseconds.
 * Here, the screenUpdate callback is called, and the screen is flushed, assuming
 * myscreen.flushMode is > 0. Additional, it keeps track of dropped frames. Now,
 * since JavaScript does not have as much control as mgl does, a dropped frame is 
 * when it takes too long for tickScreen to get called again, i.e. the interval is
 * not running fast enough. It is entirely disconnected from the actual drawing on the screen.
 * @memberof module:jglTask
 */
function tickScreen() {
	
	for (var i=0;i<task.length;i++) {
		var temp = task[i][tnum].callback.screenUpdate(task[i][tnum], myscreen);
		task[i][tnum] = temp[0];
		myscreen = temp[1];
	}
	
	//TODO: skipped a bunch of volume stuff
	switch (myscreen.flushMode) {
	case 0:
		jglFlush();
		break;
	case 1:
		jglFlush();
		myscreen.flushMode = -1;
		break;
	case 2:
		jglNoFlushWait();
		break;
	case 3:
		jglFlushAndWait();
		break;
	default:
		myscreen.fliptime = Infinity;
	}


	if (myscreen.checkForDroppedFrames && myscreen.flushMode >= 0) {
		var fliptime = jglGetSecs();
		

		if ((fliptime - myscreen.fliptime) > myscreen.dropThreshold*myscreen.frametime) {
			myscreen.dropcount++;
		}
		if (myscreen.fliptime != Infinity) {
			myscreen.totalflip += (fliptime - myscreen.fliptime);
			myscreen.totaltick++;
		}
		myscreen.fliptime = fliptime;
	}
	myscreen.tick++;


	if (jglGetKeys().indexOf('esc') > -1) {
		myscreen.userHitEsc = 1;
		finishExp();
	}
	

}