/**
 * Function to write to a trace.
 * @param {Number} data for response positive values are keyCodes, negative are mouse presses
 * @param {Number} tracenum the trace to write to
 * @param {Number} force NOT USED defaults to 0
 * @param {Number} eventTime the time the event occured defaults to the current time
 * @memberof module:jglTask
 */
function writeTrace(data, tracenum, force, eventTime) {
	if (force === undefined) {
		force = 0;
	}
	if (eventTime === undefined) {
		eventTime = jglGetSecs();
	}
	
	if ((tracenum > 0)) {
		myscreen.events.tracenum[myscreen.events.n] = tracenum;
		myscreen.events.data[myscreen.events.n] = data;
		myscreen.events.ticknum[myscreen.events.n] = myscreen.tick;
		myscreen.events.time[myscreen.events.n] = eventTime;
		myscreen.events.force[myscreen.events.n] = force;
		myscreen.events.n++;
	}
	
 }