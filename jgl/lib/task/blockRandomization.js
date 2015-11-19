/**
 * Generates block randomized combination of parameters. Unlike mgl it does
 * not randomly permutate the entire set of parameters. It only permutates
 * each block of trials individually. 
 * @memberof module:jglTask
 */
var blockRandomization = function(task, parameter, previousParamIndexes) {
	if (previousParamIndexes === undefined) {
		var temp = initRandomization(parameter);
		parameter = temp[0];
		if (! parameter.hasOwnProperty("doRandom_")) {
			parameter.doRandom_ = 1;
		}
		return parameter;
	}
	
	
	var paramIndexes = [];
	var block = {};
	block.parameter = {};
	for (var paramnum = 0;paramnum<parameter.n_;paramnum++) {
		paramIndexes[paramnum] = [];
		for (var i = 0; i< parameter.totalN_ / parameter.size_[paramnum];i++) {

			if (parameter.doRandom_) {
				paramIndexes[paramnum] = paramIndexes[paramnum].concat(randPerm(task, parameter.size_[paramnum]));
			} else {
				paramIndexes[paramnum] = paramIndexes[paramnum].concat(jglMakeArray(0,1,parameter.size_[paramnum]));
			}
		}
		eval("block.parameter." + parameter.names_[paramnum] + " = index(parameter." + parameter.names_[paramnum] + ",paramIndexes[paramnum], false);");
	}
	block.trialn = parameter.totalN_;
	return block;
}