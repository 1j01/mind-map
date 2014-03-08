/*
chrome.storage / localStorage agnostic document saving and loading
*/
documents = {};

var $notif = $("<div id=notif></div>");
function notif(msg, className){
	$notif.text(msg);
	$notif.attr("class", className);
	$notif.appendTo("body").fadeIn(20);
	$notif.finish().delay(1000).fadeOut(5000);
}
function error(msg){ notif(msg, "error"); }
function success(msg){ notif(msg, "success"); }

var chrome_storage = typeof chrome === "object" && chrome.storage && chrome.storage.
//sync;
local;

//try to save a document
function save_doc(doc_name){
	if (chrome_storage) {
		var o = {};
		o[doc_name] = documents[doc_name];
		chrome_storage.set(o);
	} else {
		try {
			var doc = documents[doc_name];
			var json = JSON.stringify(doc);
			try {
				localStorage[doc_name] = json;
				success("Saved! (Only locally, so watch out!)");
			} catch(e) {
				error("Failed to save to local storage!");
			}
		} catch(e) {
			error("Something has gone seriously wrong.\n"+e);
		}
	}
}

//try to load a document
//on sucesss, callback(doc)
//on error, callback()
function load_doc(doc_name, callback){
	if (chrome_storage) {
		chrome_storage.get(doc_name, function(items){
			if(chrome.runtime.lastError){
				error(chrome.runtime.lastError);
			}else{
				var doc = items[doc_name];
				documents[doc_name] = doc;
			}
			callback && callback(doc);
		});
	} else {
		try {
			try {
				var json = localStorage[doc_name];
			} catch(e) {
				error("Access to local storage denied. \n(Please enable cookies)");
			}
			if(json){
				var doc = JSON.parse(json);
				documents[doc_name] = doc;
			}
		} catch(e) {
			error("Failed to parse document!"+e);
		}
		callback && callback(doc);
	}
}

