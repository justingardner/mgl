/**
 * Function for generating an XML object from a javascript object.
 * Requires that the root tag be places around the return value.
 * This is the xml tagname scheme:
 * All objects are surrounded by an object tag, every field of an
 * object has its own tagname. Arrays are surrounded by array tag
 * names. Array tags have an attribute type, with either cell or mat
 * as the value. mat means its a numeric array and can be a matrix in matlab.
 * cell means the array contains non-numeric elements. Every value is enclosed in
 * a val tag. val tags also have a type attribute, with a value num or str. num means
 * it isNumeric, str means its not.
 * @param {Any} object the object to XMLify
 * @param {String} xml should always be left undefined
 * @returns {String} The XML version of the given object, object 
 * field names are tags, array tag starts an array, val tag for value of a given item.
 * @memberof module:jglTask
 */
function genXML(object, xml) {
	if (xml === undefined) {
		xml = "";
	}
	if ($.type(object) == "object") {
		var fieldNames = fields(object);
		xml += "<object>";
		for (var i =0; i<fieldNames.length;i++) {
			if (fieldNames[i] != "callback" && fieldNames[i] != "psiTurk") {
				xml += "<" + fieldNames[i] + ">";
				xml += genXML(object[fieldNames[i]]);
				xml += "</" + fieldNames[i] + ">";
			}
		}
		xml += "</object>";
	} else if ($.isArray(object)) {
		if (isNumeric(object)) {
			xml += '<array type=&quot;mat&quot;>'; // &quot; is an escaped " in xml
		} else {
			xml += '<array type=&quot;cell&quot;>';
		}
		for (var i = 0;i<object.length;i++) {
			xml += genXML(object[i]);
		}
		xml += "</array>";
	} else {
		if (isNumeric(object)) {
			xml += '<val type=&quot;num&quot;>' + object + '</val>';
		} else {
			xml += '<val type=&quot;str&quot;>' + object + '</val>';
		}
	}
	return xml;
}

/**
 * Function to save all of the data to the database.
 * This function creates a large object xml string containing
 * the jglData object, the task array, the myscreen object, and
 * all stimulus objects that have been registered with initStimulus.
 * The xml is then saved in the database using psiTurk with the key
 * experimentXML.
 * @memberof module:jglTask
 */
function saveAllData() {
	/*
	 * xml will represent an xml object with jglData, task, myscreen, and all
	 * the stimuli as fields. The generateMat function in matlab can then use
	 * the xml to make a mat file
	 */
	
	var xml = "<object>";
	
	xml += "<jglData>";
	xml += genXML(jglData);
	xml += "</jglData>";
	
	xml += "<task>";
	xml += genXML(task);
	xml += "</task>";
	
	xml += "<myscreen>";
	xml += genXML(myscreen);
	xml += "</myscreen>";
	
	// Get all stimuli registered using initStimulus.
	for (var i=0;i<myscreen.stimulusNames.length;i++) {
		xml += "<" + myscreen.stimulusNames[i] + ">";
		xml += eval("genXML(" + myscreen.stimulusNames[i] + ");");
		xml += "</" + myscreen.stimulusNames[i] + ">";
	}
	
	xml += "</object>";
	
	// Save data.
	myscreen.psiTurk.recordUnstructuredData("experimentXML", xml);
	myscreen.psiTurk.saveData({
		success: function() {
			myscreen.psiTurk.completeHIT();
		},
		error: function() {alert("error!!!");}
	});
	
}