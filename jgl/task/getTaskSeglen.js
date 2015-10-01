/**
 * Function to get task seglen.
 * @param task the task object.
 * @returns {Array} [seglen, task]
 * @memberof module:jglTask
 */
function getTaskSeglen(task) {
	
	var seglen;
	if (task.timeInTicks || task.timeInVols) {
		seglen = add(task.segmin, floor(multiply(rand(numel(task.segmax)), (add(subtract(task.segmax, task.segmin), 1)))));
	} else {
		seglen = add(task.segmin, multiply(rand(task, numel(task.segmax)), subtract(task.segmax, task.segmin)));
		var temp = find(or(isinf(task.segmin), isinf(task.segmax)));
		jQuery.map(temp, function(n,i) {
			seglen[n] = Infinity;
		});
	}
	
	var nansegs = find(isnan(seglen));
	if (! isEmpty(nansegs)) {
		for (var i=0;i<nansegs.length;i++) {
			seglen[nansegs[i]] = task.segdur[nansegs[i]][sum(greaterThan(rand(task), task.segprob[nansegs[i]]))];
		}
	}
	return [seglen, task];
	// TODO: line 44 randstate
}