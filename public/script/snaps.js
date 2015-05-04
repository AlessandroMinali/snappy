// window.onload = function() {
// 	el = document.getElementsByTagName("img");
// 	console.log(el);
// 	for (var i = 0; i < el.length; i++) {
// 		el[i].style.visibility = 'hidden'
// 	}

// 	el2 = document.getElementsByTagName("h2");
// 	for (var i in el2) {
// 		el2[i].innerHTML += ' - Loading one moment please <img src="images/load.gif"/>'
// 	}

// 	var url = window.location.href.split("/")
// 	url = url.slice(3,url.length);

// 	var params = "url="+url;

// 	// checkImage(
// 	// 	url+'.png',
// 	// 	function() {
// 	// 		for (var i = 0; i < el.length; i++) {
// 	// 			el[i].style.visibility = 'visible';
// 	// 		}
// 	// 	},
// 	// 	function() {

// 	// 	}
// 	// )



// 	var http = new XMLHttpRequest();
// 	http.open('POST', '/snap', true);
// 	http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
// 	http.setRequestHeader("X-Requested-With", "XMLHttpRequest");
// 	http.send(params);
// }

// function checkImage (src, good, bad) {
//   var img = new Image();
//   img.onload = good; 
//   img.onerror = bad;
//   img. src = src;
// }