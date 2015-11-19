/**
 * Function to generate random numbers in a controlled way.
 * Since one cannot set the random number generator seed in
 * JavaScript this solution was devised. The task object
 * has a field, genRandom which contains and array of random numbers.
 * this function grabs a number from that array while growing the array
 * if necessary. To recreate the experiment initialize the task object with
 * the same genRandom field. 
 * @param {Object} task the task object
 * @param {Number} length the length of the array to return, if left undefined a single number will be returned
 * @returns {Number|Array} A single number or array of random numbers between 0 and 1
 * @memberof module:jglTask
 */
function rand(task, length) {
	if (! task.hasOwnProperty("genRandom")) {
		task.genRandom = {};
		task.genRandom.current = 0;
		task.genRandom.nums = new Array(32);
		for (var i =0;i<task.genRandom.nums.length;i++) {
			task.genRandom.nums[i] = Math.random();
		}
	}
	if (length === undefined) {
		if (task.genRandom.current == task.genRandom.nums.length) {
			task.genRandom.nums = randomResize(task.genRandom.nums);
		}

		return task.genRandom.nums[task.genRandom.current++];
	} else {
		while (task.genRandom.current + length >= task.genRandom.nums.length) {
			task.genRandom.nums = randomResize(task.genRandom.nums);
		}
		var temp = new Array(length);
		for (var i=0;i<length;i++) {
			temp[i] = task.genRandom.nums[task.genRandom.current++];
		}
		return temp;
	}
}

/**
 * Function for growing the array of random numbers.
 * @param array the array to grow
 * @returns {Array} the new array, twice the size
 * @memberof module:jglTask
 */
function randomResize(array) {
	var tempArray = new Array(array.length * 2);
	for (var i=0;i<array.length;i++) {
		tempArray[i] = array[i];
	}
	for (var i=array.length;i<tempArray.length;i++) {
		tempArray[i] = Math.random();
	}
	return tempArray;
}