/**
 * Function to initialize the parameter object for the rand callback.
 * @param {Object} parameter the parameter object that needs initializing
 * @returns {Array} the first element is the initialized parameter object,
 * the second is a number, 1 means it was already initialized, 0 means it was not
 * @memberof module:jglTask
 */
function initRandomization(parameter) {
	var alreadyInitialized = false;
	
	if (parameter.hasOwnProperty("n_")) {
		console.log("initRandomization: Re-initialized parameters");
		alreadyInitialized = true;
	}
	parameter.names_ = [];
	parameter.n_ = [];
	parameter.size_ = [];
	parameter.totalN_ = [];

	
	var names = fields(parameter);
	
	var n = 0;
	
	for (var i = 0; i < names.length;i++) {
		if (isEmpty(names[i].match("_$"))) {
			parameter.names_[n++] = names[i];
		}
	}
	
	parameter.n_ = parameter.names_.length;
	
	for (var i=0;i<parameter.n_;i++) {
		var paramsize = eval("size(parameter." + parameter.names_[i] + ");");
		parameter.size_[i] = paramsize;
	}
	
	parameter.totalN_ = prod(parameter.size_);
	
	return [parameter, alreadyInitialized];
}