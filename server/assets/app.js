var App = (function() {
    var self;
    
    return function App() {
	if (self)
	    return self;
	if (!(this instanceof App))
	    return new App();
	self = this;
	window.onerror = self.reportError;

	makeDialog("#setup-dialog", { dialogClass: "no-close" });
	$("#setup-dialog .progress").progressbar({ value: false }).show();

	makeDialog("#error-dialog", {
	    dialogClass: "no-close error-dialog",
	    buttons: { "Okay": function() { $(this).dialog("close"); } }
	});

	$("#empty-graph .add").click(function() {
	    $("#add").click();
	});

	$("#empty-graph .all").click(function() {
	    $("#node-filter .all").click();
	});

	var initialize = (function() {
	    var initializing = [];

	    return function(props) {
		var defer = $.Deferred();
		if (!Array.isArray(props))
		    props = [props];
		props.forEach(function(prop) {
		    var klass = eval(prop.substr(0, 1).toUpperCase() + prop.substr(1));
		    if (klass.length)
			initializing.push(prop);
		    self[prop] = new klass(function() {
			initializing.splice(initializing.indexOf(prop), 1);
			if (initializing.length === 0)
			    defer.resolve();
		    });
		});
		return defer;
	    }
	})();

	initialize("server").then(function() {
	    return initialize(["nodeFilter", "edgeFilter", "graphClasses",
			       "sidebar", "addMovies", "search", "progress",
                               "debug", "graph", "addVoiceActors", "elmBridge"]);
	}).then(function() {
	    withElectron().then(function(electron) {
		$("body").addClass("electron");
		$("a.external").click(function(e) {
		    e.preventDefault();
		    electron.remote.shell.openExternal($(this).prop("href"));
		});
		electron.webFrame.setVisualZoomLevelLimits(1, 1);
		electron.ipcRenderer.send("app-ready");
	    });
	    defer(function() {
		$("body").addClass("visible");

		defer(function() {
		    $("#wrapper").css("opacity", 1);
		    $("#sidebar").css("opacity", 1);
		}, 20);
	    }, 20);
	});
    }
})();

App.prototype = {
    reportError: function(err) {
	if (err.indexOf("SVGMatrix") !== -1)
	    return;
	$("#error-dialog").text(err).dialog("open");
    }
};

App.debug = false;

$(document).ready(App);
