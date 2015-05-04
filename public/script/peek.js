var page = require('webpage').create();
var system = require('system');
var args = system.args;

page.viewportSize = { width: args[2], height: args[3] };

page.settings.userAgent = args[5];

setTimeout(function() {
		console.log('timeout');
		phantom.exit();
}, 15000);

page.open(args[1], function() {

	setTimeout(function() {
		// try {
		// 	throw 1;
		// } catch (e) {
			console.log('timeout');
			phantom.exit();
		// }
	}, 5000);

	page.evaluate(function() {
		var style = document.createElement('style'),
		text = document.createTextNode('body { background: #fff }');
		style.setAttribute('type', 'text/css');
		style.appendChild(text);
		document.head.insertBefore(style, document.head.firstChild);
	});

	var clipRect = page.evaluate(function (a) { 
		if (a === null) {
			return 1;
		}
		try {
			return document.querySelector(a).getBoundingClientRect(); 
		} catch (e) {
			return 1;
		}
	}, args[6]);

	if (clipRect !== 1) {
		page.clipRect = {
			top:    clipRect.top,
			left:   clipRect.left,
			width:  clipRect.width,
			height: clipRect.height
		};
		window.setTimeout(function() {
			page.render(args[2], {format: 'jpeg', quality: '50'});
			phantom.exit();
		}, 200);

	} else {

		window.setTimeout(function() {
			page.render(args[4], {format: 'jpeg', quality: '50'});
			console.log("done")
			phantom.exit();
		}, 200);
	}
});