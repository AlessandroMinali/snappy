var page = require('webpage').create();

phantom.onError = function(msg, trace) {
  var msgStack = ['PHANTOM ERROR: ' + msg];
  if (trace && trace.length) {
    msgStack.push('TRACE:');
    trace.forEach(function(t) {
      msgStack.push(' -> ' + (t.file || t.sourceURL) + ': ' + t.line + (t.function ? ' (in function ' + t.function +')' : ''));
    });
  }
  console.error(msgStack.join('\n'));
  phantom.exit(1);
};

page.viewportSize = {width: 640, height: 960};
page.settings.userAgent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:35.0) Gecko/20100101 Firefox/35.0';


page.open('http://google.com', function() {
  page.evaluate(function() {
  var style = document.createElement('style'),
      text = document.createTextNode('body { background: #fff }');
  style.setAttribute('type', 'text/css');
  style.appendChild(text);
  document.head.insertBefore(style, document.head.firstChild);
	});
  page.render('github.png');
  phantom.exit();
});