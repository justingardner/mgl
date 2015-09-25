/**
 * Basic Set Data Structure.
 * @constructor
 */

function Set() {
	var data = [];
	var count = 0;
	
	function find(val) {
		for (var i=0;i<data.length;i++) {
			if (data[i] === val) {
				return i;
			}
		}
		return -1;
	}
	
	/**
	 * Function to see if the set contains the given val.
	 * @param val the value to check
	 * @returns {Boolean} true if contains, false if not
	 */
	this.contains = function(val) {
		return find(val) > -1;
	}
	
	/**
	 * Function to insert a value into the set.
	 * @param val the value to insert
	 * @returns {Boolean} true if succeeded, false if not
	 */
	this.insert = function(val) {
		if (! this.contains(val)) {
			data[count++] = val;
			return true;
		}
		return false;
	}
	
	/**
	 * Function to remove a value from the set.
	 * @param val the value to remove
	 * @returns {Boolean} true if removed, false if not found
	 */
	this.remove = function(val) {
		if (this.contains(val)) {
			data.splice(find(val), 1);
			count--;
			return true;
		}
		return false;
	}
	
	/**
	 * Function to grab the contents of the set.
	 * @returns {Array} an array with all the values contained by the set
	 */
	this.toArray = function() {
		var tempArray = new Array(data.length);
		
		for (var i=0;i<tempArray.length;i++) {
			tempArray[i] = data[i];
		}
		
		return tempArray;
	}
}