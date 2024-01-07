// utilities
var get = function (selector, scope) {
  scope = scope ? scope : document;
  return scope.querySelector(selector);
};

var getAll = function (selector, scope) {
  scope = scope ? scope : document;
  return scope.querySelectorAll(selector);
};

// setup typewriter effect in the terminal demo
if (document.getElementsByClassName('demo').length > 0) {
  var i = 0;
  var txt = `shell_sock_server.sh -k server.key    \
  -c server.crt                                    \
  -C ca-chain.crt -p 22447 --media-port 2223       \
  -t /tmp/tempor -l /var/log/shell_sock
  Loading configuration...
Configurations are loaded !
/usr/bin/socat
SIGNALLING SERVER START 0.0.0.0:22447
SIGNALLING SERVER START 0.0.0.0:2223
2024/01/07 17:22:58 socat[3837061] N listening on AF=2 0.0.0.0:2223
2024/01/07 17:22:58 socat[3837062] N listening on AF=2 0.0.0.0:22447
  `
  var speed = 5;

  function typeItOut () {
    if (i < txt.length) {
      document.getElementsByClassName('demo')[0].innerHTML += txt.charAt(i);
      i++;
      setTimeout(typeItOut, speed);
    }
  }

  setTimeout(typeItOut, 1800);
}


// setup typewriter effect in the terminal demo
if (document.getElementsByClassName('demo-client').length > 0) {
  var z = 0;
  var txt_client = `./shell_sock_client.sh -s proxyLinux -p 22447 --media-port 2223 -k client.key -c client.crt -C ca-cert.crt -t /tmp/shell_sock -l /var/run/shell_sock
Loading configuration
Configurations are loaded
..Startging to connect to: proxy:22447
  `
  var client_speed = 15;

  function typeItOutClient () {
    if (z < txt_client.length) {
      document.getElementsByClassName('demo-client')[0].innerHTML += txt_client.charAt(z);
      z++;
      setTimeout(typeItOutClient, client_speed);
    }
  }

  setTimeout(typeItOutClient, 1800);
}



// toggle tabs on codeblock
window.addEventListener("load", function() {
  // get all tab_containers in the document
  var tabContainers = getAll(".tab__container");

  // bind click event to each tab container
  for (var i = 0; i < tabContainers.length; i++) {
    get('.tab__menu', tabContainers[i]).addEventListener("click", tabClick);
  }

  // each click event is scoped to the tab_container
  function tabClick (event) {
    var scope = event.currentTarget.parentNode;
    var clickedTab = event.target;
    var tabs = getAll('.tab', scope);
    var panes = getAll('.tab__pane', scope);
    var activePane = get(`.${clickedTab.getAttribute('data-tab')}`, scope);

    // remove all active tab classes
    for (var i = 0; i < tabs.length; i++) {
      tabs[i].classList.remove('active');
    }

    // remove all active pane classes
    for (var i = 0; i < panes.length; i++) {
      panes[i].classList.remove('active');
    }

    // apply active classes on desired tab and pane
    clickedTab.classList.add('active');
    activePane.classList.add('active');
  }
});

//in page scrolling for documentaiton page
var btns = getAll('.js-btn');
var sections = getAll('.js-section');

function setActiveLink(event) {
  // remove all active tab classes
  for (var i = 0; i < btns.length; i++) {
    btns[i].classList.remove('selected');
  }

  event.target.classList.add('selected');
}

function smoothScrollTo(i, event) {
  var element = sections[i];
  setActiveLink(event);

  window.scrollTo({
    'behavior': 'smooth',
    'top': element.offsetTop - 20,
    'left': 0
  });
}

if (btns.length && sections.length > 0) {
  for (var i = 0; i<btns.length; i++) {
    btns[i].addEventListener('click', smoothScrollTo.bind(this,i));
  }
}

// fix menu to page-top once user starts scrolling
window.addEventListener('scroll', function () {
  var docNav = get('.doc__nav > ul');

  if( docNav) {
    if (window.pageYOffset > 63) {
      docNav.classList.add('fixed');
    } else {
      docNav.classList.remove('fixed');
    }
  }
});

// responsive navigation
var topNav = get('.menu');
var icon = get('.toggle');

window.addEventListener('load', function(){
  function showNav() {
    if (topNav.className === 'menu') {
      topNav.className += ' responsive';
      icon.className += ' open';
    } else {
      topNav.className = 'menu';
      icon.classList.remove('open');
    }
  }
  icon.addEventListener('click', showNav);
});

