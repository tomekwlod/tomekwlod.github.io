
var manipulation = (function () {

    var domCache = document.createElement('div');

    return {
        after: function (referenceNode, newNode) {
            return this.before(referenceNode.nextSibling, newNode);
        },
        before: function (referenceNode, newNode) {
            referenceNode.parentNode.insertBefore(newNode, referenceNode);
            return this;
        },
        append: function (parentNode, newNode) {
            parentNode.appendChild(newNode);
            return this;
        },
        prepend: function (parentNode, newNode) {
            parentNode.insertBefore(newNode, parentNode.firstChild);
            return this;
        },
        remove: function (node) {
            node.parentNode.removeChild(node);
            return this;
        },
        detach: function (element) { // detach element from DOM, to use it somewhere else

            this.append(domCache, element);

            return element;
        },
        children: function (parent) {
            try {
                // read also about
                // https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeType
                // https://developer.mozilla.org/en-US/docs/Web/API/Element/tagName  - undefined when #text node
                // https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeName
                return Array.prototype.slice.call(parent.childNodes)
            }
            catch (e) {

                throw new Error("manipulation.children() error: " + String(e));
            }
        },

    };
}());

window.manipulation = manipulation;

function trim(string, charlist, direction) {
    direction = direction || 'rl';
    charlist  = (charlist || '').replace(/([.?*+^$[\]\\(){}|-])/g,'\\$1');
    charlist  = charlist || " \\n";
    (direction.indexOf('r')+1) && (string = string.replace(new RegExp('^(.*?)['+charlist+']*$','gm'),'$1'));
    (direction.indexOf('l')+1) && (string = string.replace(new RegExp('^['+charlist+']*(.*)$','gm'),'$1'));
    return string;
}

(function () {

    document.addEventListener('DOMContentLoaded', function() {

        var tmp = document.createElement('div');

        tmp.innerHTML = "\
            <!-- generated by: https://www.favicon-generator.org/ -->\
            <!-- generated by: https://realfavicongenerator.net/favicon_result?file_id=p1e6ljeig5qc41s3r1s418k41qv86#.XqKd1NNKgxw -->\
            <link rel=\"apple-touch-icon\" sizes=\"57x57\" href=\"/apple-icon-57x57.png?\">\
            <link rel=\"apple-touch-icon\" sizes=\"60x60\" href=\"/apple-icon-60x60.png?\">\
            <link rel=\"apple-touch-icon\" sizes=\"72x72\" href=\"/apple-icon-72x72.png?\">\
            <link rel=\"apple-touch-icon\" sizes=\"76x76\" href=\"/apple-icon-76x76.png?\">\
            <link rel=\"apple-touch-icon\" sizes=\"114x114\" href=\"/apple-icon-114x114.png?\">\
            <link rel=\"apple-touch-icon\" sizes=\"120x120\" href=\"/apple-icon-120x120.png?\">\
            <link rel=\"apple-touch-icon\" sizes=\"144x144\" href=\"/apple-icon-144x144.png?\">\
            <link rel=\"apple-touch-icon\" sizes=\"152x152\" href=\"/apple-icon-152x152.png?\">\
            <link rel=\"apple-touch-icon\" sizes=\"180x180\" href=\"/apple-icon-180x180.png?\">\
            <link rel=\"icon\" type=\"image/png\" sizes=\"192x192\"  href=\"/android-icon-192x192.png?\">\
            <link rel=\"icon\" type=\"image/png\" sizes=\"32x32\" href=\"/favicon-32x32.png?\">\
            <link rel=\"icon\" type=\"image/png\" sizes=\"96x96\" href=\"/favicon-96x96.png?\">\
            <link rel=\"icon\" type=\"image/png\" sizes=\"16x16\" href=\"/favicon-16x16.png?\">\
            <link rel=\"manifest\" href=\"/manifest.json\">\
            <link rel=\"manifest\" href=\"/site.webmanifest\">\
            <link rel=\"mask-icon\" href=\"/safari-pinned-tab.svg\" color=\"#5bbad5\">\
            <meta name=\"msapplication-TileColor\" content=\"#ffffff\">\
            <meta name=\"msapplication-TileImage\" content=\"/ms-icon-144x144.png?\">\
            <meta name=\"theme-color\" content=\"#ffffff\">\
            <link rel=\"apple-touch-icon\" sizes=\"180x180\" href=\"/apple-touch-icon.png\">\
        ";

        var h = document.getElementsByTagName('script')[0];

        Array.prototype.slice.call(tmp.children).forEach(function (e) {
            manipulation.after(h, e)
        });
    });
}());

var log = (function () {
    try {
        return console.log
    }
    catch (e) {
        return function () {}
    }
}());

window.log = log;

// edit & profile ribbons
(function () {

    // https://github.com/stopsopa/stopsopa.github.io/edit/master/demos/jquery.elkanatooltip/katownik.html
    // https://stopsopa.github.io/
    // user stopsopa
    // path /pages/css-grid/index.html
    var github = (function (def) {

        let host = def;

        if (/\.github\.io$/.test(location.host)) {

            host = location.host;
        }

        var user = host.replace(/^(.*)\.github\.io$/, '$1');

        // log('user', user)

        let path = location.pathname;

        if ( /\/$/.test(path) ) {

            path += 'index.html';
        }

        // log('path', path)

        var github = `//github.com/${user}/${user}.github.io/edit/master/${path}`;

        // log('github', github)

        return github;

    }("stopsopa.github.io"));

    document.addEventListener('DOMContentLoaded', function () {

        (function () {

            var div = document.createElement('div');

            div.classList.add('github-link');

            manipulation.append(document.body, div);

            var a = document.createElement('a');

            a.innerText = 'edit';

            a.setAttribute('href', github)

            manipulation.append(div, a);

            var css = `
body .github-link {
    top: 0;
    right: 0;
    height: 47px;
    width: 47px;
    position: absolute;
    overflow: hidden;
} 
body .github-link > a {
    border: 1px solid #2d2d2d;
    top: 7px;
    right: -18px;
    position: absolute;
    transform: rotate(45deg);
    padding-left: 20px;
    padding-right: 20px;
    color: white;
    text-decoration: none;
    background-color: #2d2d2d;
} 
body .github-link > a:hover {
    cursor: pointer;
    color: #2d2d2d;
    background-color: white;
}          
            `;
            // https://stackoverflow.com/a/524721
            var head = document.head || document.getElementsByTagName('head')[0],
                style = document.createElement('style');

            style.type = 'text/css';
            if (style.styleSheet){
                style.styleSheet.cssText = css;
            } else {
                style.appendChild(document.createTextNode(css));
            }

            head.appendChild(style);
        }());


        (function () {
            var a = document.createElement('a');

            a.classList.add('github-profile');

            a.innerText = 'profile';

            a.setAttribute('href', '//github.com/stopsopa')

            manipulation.append(document.body, a);

            var css = `
body .github-profile {
    border: 1px solid #2d2d2d;
    top: 6px;
    left: -23px;
    position: absolute;
    transform: rotate(-38deg);
    padding-left: 20px;
    padding-right: 20px;
    color: white;
    text-decoration: none;
    background-color: #2d2d2d;
    font-size: 15px;
    padding-bottom: 2px;
    padding-top: 2px;
} 
body .github-profile:hover {
    cursor: pointer;
    color: #2d2d2d;
    background-color: white;
}          
            `;
            // https://stackoverflow.com/a/524721
            var head = document.head || document.getElementsByTagName('head')[0],
                style = document.createElement('style');

            style.type = 'text/css';
            if (style.styleSheet){
                style.styleSheet.cssText = css;
            } else {
                style.appendChild(document.createTextNode(css));
            }

            head.appendChild(style);
        }());

    });
}());

(function () {
    /* from lodash */
    function isNodeList (obj) {
        return Object.prototype.toString.call(obj) === '[object NodeList]';
    }
    /* from lodash */
    var isNode = (function () {
        function isObjectLike(value) {
            return value != null && typeof value == 'object';
        }
        function isPlainObject(value) { // simplified version of isPlainObject then the one in lodash
            return Object.prototype.toString.call(value) === '[object Object]'
        }
        return function isNode (value) {
            return isObjectLike(value) && value.nodeType === 1 && !isPlainObject(value);
        }
    }());
    manipulation.custommove = function (newParent, elements) {

        if (isNode(elements)) {

            elements = [elements];
        }
        else if (isNodeList(elements)) {
            elements = Array.prototype.slice.call(elements);
        }

        try {
            for (var i = 0, l = elements.length ; i < l ; i += 1 ) {
                newParent.appendChild(elements[i]);
            }
        }
        catch (e) {

            throw "manipulation.custommove - can't iterate through elements"
        }
        return this;
    }
}());

(function () {
    document.querySelector('body > header') || document.addEventListener('DOMContentLoaded', function () {

        var body = document.body;

        log('attr in body - nohead:', body)

        if ( ! body.hasAttribute('nohead')) {

            var header = document.createElement('header');

            header.innerHTML = `
    <a href="/index.html">stopsopa.github.io</a>
`;

            manipulation.prepend(body, header);
        }
    });
}());

(function () {
    document.querySelector('body > footer') || document.addEventListener('DOMContentLoaded', function () {

        var body = document.body;

        log('attr in body - nofoot:', body)

        if ( ! body.hasAttribute('nofoot')) {

            var header = document.createElement('footer');

            header.innerHTML = `footer`;

            manipulation.append(body, header);
        }
    });
}());

// Table of Contents
// WARNING: it has to be executed in domcontentloaded.js after permalink-my.js
// WARNING: it has to be executed in domcontentloaded.js after permalink-my.js
// WARNING: it has to be executed in domcontentloaded.js after permalink-my.js
// WARNING: it has to be executed in domcontentloaded.js after permalink-my.js
// WARNING: it has to be executed in domcontentloaded.js after permalink-my.js
(function () {
    document.querySelector('body > footer') || document.addEventListener('DOMContentLoaded', function () {

        var body = document.body;

        log('attr in body - toc:', body)

        window.toc = function () {}

        if ( ! body.hasAttribute('toc') ) {

            console.log('[toc] not found - table of content will not be rendered')
        }

        window.toc = function () {

            var toc = document.createElement('div');

            toc.classList.add('cards');

            toc.classList.add('toc');

            // Table of content
            (function () {
                var head = document.createElement('h1');

                head.innerText = 'Table of Contents';

                manipulation.append(toc, head)
            })();

            // links
            (function () {

                var ul = document.createElement('ul');

                Array.prototype.slice.call(document.querySelectorAll('h2[id]')).forEach(function (el) {

                    var a = document.createElement('a');

                    a.setAttribute('href', "#" + el.getAttribute('id'))

                    a.innerText = trim(el.innerText, " ¶\n");

                    var li = document.createElement('li');

                    manipulation.append(li, a);

                    manipulation.append(ul, li);

                });

                manipulation.append(toc, ul)
            }());

            // hr at the end
            (function () {

                var hr = document.createElement('div');

                hr.style.border = '1px solid darkgray'
                manipulation.append(toc, hr);
            }());

            // return to top button
            (function() {

                var a = document.createElement('a');

                a.innerText = '^';

                a.setAttribute('href', 'javascript:void(0)');

                a.addEventListener('click', function () {
                    window.scrollTo(0, 0);
                })

                a.style.border = '1px solid blue';
                a.style.padding = '10px';
                a.style.fontSize = '30px';
                a.style.position = 'fixed';
                a.style.right = '2px'
                a.style.bottom = '2px';
                a.style.backgroundColor = 'white';

                manipulation.append(body, a);
            }());

            var inside = document.querySelector('.inside');

            if (inside) {

                manipulation.prepend(inside, toc);
            }
            else {

                manipulation.prepend(body, toc);
            }

            // header.innerHTML = `footer`;
        }
    });
}());

// load common css and js

(function () {

    // <link rel="stylesheet" href="../../css/normalize.css">

    [
        '/css/normalize.css',
        '/css/main.css',
        '/js/aceedit/jquery.aceedit.css',
        '//fonts.googleapis.com/css?family=Open+Sans:300,400',
    ].forEach(function (u) {

        // https://stackoverflow.com/a/524721
        var head = document.head || document.getElementsByTagName('head')[0],
            style = document.createElement('link');

        // style.type = 'text/css';

        style.setAttribute('rel', 'stylesheet');

        style.setAttribute('href', u);

        head.appendChild(style);
    })
}());

// load additional js files
(function () {

    // <script src="./js/polyfill.js"></script>
    // <script src="./js/permalink-my.js"></script>

    [
        '/js/polyfill.js',
        '/js/permalink-my.js',
        '/js/domcontentloaded.js',
        '/js/lodash-4.17.10.js',
        '/js/ace/ace-builds-1.3.3/src-min-noconflict/ace.js',
    ].forEach(function (u) {

        // https://stackoverflow.com/a/524721
        var head = document.head || document.getElementsByTagName('head')[0],
            script = document.createElement('script');

        // script.async = false;

        script.setAttribute('src', u);

        head.appendChild(script);
    })
}());

// sorting lists [data-do-sort] attribute
(function () {
    document.addEventListener('DOMContentLoaded', function () {
       Array.prototype.slice.call(document.querySelectorAll('[data-do-sort]')).forEach(function (parent) {

           var children = manipulation.children(parent)

           var tmp = [];

           children.forEach(function (child) {

               var text = trim(child.tagName ? child.innerText.toLocaleLowerCase() : String(child.textContent));

               text && tmp.push({
                   tagName: child.tagName,
                   node: child,
                   text: text,
               })
           });

           var newList = tmp.sort(function (a, b) {

               if (a.text === b.text) {

                   return 0
               }

               return a.text < b.text ? 1 : -1;
           })
           .map(function (n) {

               manipulation.prepend(parent, n.node)
           });
       });
    });
}());

// ace editor
(function () {

    // https://developer.mozilla.org/en-US/docs/Web/API/Element/matches#Polyfill
    if (!Element.prototype.matches) {
        Element.prototype.matches =
            Element.prototype.matchesSelector ||
            Element.prototype.mozMatchesSelector ||
            Element.prototype.msMatchesSelector ||
            Element.prototype.oMatchesSelector ||
            Element.prototype.webkitMatchesSelector ||
            function(s) {
                var matches = (this.document || this.ownerDocument).querySelectorAll(s),
                    i = matches.length;
                while (--i >= 0 && matches.item(i) !== this) {}
                return i > -1;
            };
    }

    function unique(pattern) { // node.js require('crypto').randomBytes(16).toString('hex');
        pattern || (pattern = 'xyxyxy');
        return pattern.replace(/[xy]/g,
            function(c) {
                var r = Math.random() * 16 | 0,
                    v = c == 'x' ? r : (r & 0x3 | 0x8);
                return v.toString(16);
            });
    }

    var p, editors = {};

    window.doace = function () {

        var _waitForPromise;

        if ( typeof window.waitForPromise === 'function' ) {

            _waitForPromise = Promise.resolve(window.waitForPromise());
        }
        else {

            _waitForPromise = Promise.resolve();
        }

        if (!p) {

            p = _waitForPromise.then(function () {
                return new Promise(function (resolve) {
                    (function run() {
                        if (window._ && window.ace && window.ace.edit) {

                            document.body.addEventListener('click', function (e) {

                                var el = e.target;

                                var match = el.matches('[data-lang] > .copy');

                                if (match) {

                                    var editor = editors[el.parentNode.dataset.ace];

                                    if (editor) {

                                        log("found editory, let's copy");

                                        var textarea = document.createElement('textarea');
                                        manipulation.append(document.body, textarea);
                                        textarea.value = editor.getValue();
                                        textarea.select();
                                        document.execCommand('copy');
                                        textarea.value = "";
                                        manipulation.remove(textarea);

                                        (function () {

                                            el.dataset.or = el.dataset.or || el.innerHTML;

                                            el.innerHTML = '☑️';

                                            setTimeout(function () {
                                                el.innerHTML = el.dataset.or;
                                            }, 1000);

                                        }());
                                    }

                                    log('clicked .copy');
                                }
                                else {

                                    log('something else clicked');
                                }
                            });

                            resolve()
                        }
                        else {
                            setTimeout(run, 100);
                        }
                    }());
                });
            });
        }

        p.then(function () {
            Array.prototype.slice.call(document.querySelectorAll('[type="editor"], [type="syntax"]')).forEach(function (el) {

                if (el.classList.contains('handled')) {

                    log('ace - handled')

                    return true;
                }

                var script, editor, div, t = '', d;

                /**
                 * Lets simplify syntax
                 * from
                 *
                 *  <div class="editor">
                 *      <script type="editor" data-lang="js" data-w="95%">
                 *      </script>
                 *  </div>
                 *
                 *  to
                 *
                 *  <script class="editor" type="editor" data-lang="js" data-w="95%"></script>
                 *
                 *  and then execute old logic
                 */
                (function () {

                    div = document.createElement('div');

                    manipulation.after(el, div);

                    manipulation.custommove(div, el);

                    var attr = Array.prototype.slice.call(el.attributes);

                    for (var i = 0, l = attr.length ; i < l ; i += 1 ) {

                        if (attr[i].name.toLowerCase() === 'class') {

                            continue;
                        }

                        div.setAttribute(attr[i].name, attr[i].value);
                    }

                    el = div;
                })();

                script = el.querySelector('script');

                d = el.dataset.h;
                d && (el.style.height = d);
                d = el.dataset.w;
                d && (el.style.width = d);

                if (!script) {

                    log('ace - no script child found');

                    return true;
                }

                t = script.innerHTML;

                manipulation.remove(script);

                div = el.cloneNode(false);

                div.removeAttribute('data-lang');
                div.removeAttribute('data-w');
                div.removeAttribute('data-h');

                el.classList.add('handled');

                manipulation.append(el, div);

                div.classList.remove('editor')
                div.classList.remove('syntax')

                var clear = document.createElement('div');

                clear.style.clear = 'both';

                manipulation.append(el, clear);

                // manipulation.after(el, clear.cloneNode(false))

                editor = ace.edit(div);

                var un = unique();

                editors[un] = editor;

                el.dataset.ace = un;

                var copy = document.createElement('div');
                copy.classList.add('copy');
                copy.innerHTML = '📋';

                manipulation.prepend(el, copy);

                editor.getSession().setTabSize(4);
                editor.setTheme("ace/theme/idle_fingers");
                editor.getSession().setUseWrapMode(true);

                d = el.dataset.lang;
                (d == 'js') && (d = 'javascript');
                d && editor.getSession().setMode("ace/mode/"+d);

                el.classList.contains('syntax') && editor.setReadOnly(true);  // false to make it editable
                //        editor.getSession().setMode("ace/mode/javascript");
                editor.setValue(_.unescape(t).replace(/^ *\n([\s\S]*?)\n *$/g, '$1'));
                // editor.setValue(t);
                editor.clearSelection();
                // editor.setOptions({
                //     maxLines: Infinity
                // });


                var heightUpdateFunction = function() {

                    // http://stackoverflow.com/questions/11584061/
                    var newHeight =
                        editor.getSession().getScreenLength()
                        * editor.renderer.lineHeight
                        + editor.renderer.scrollBar.getWidth();

                    // log('new height', newHeight);

                    var h = newHeight.toString();

                    // h += 1000;

                    h += 'px';

                    div.style.height = h;

                    // Array.prototype.slice.call(document.querySelector('.editor').querySelectorAll('[class]'))
                    //     .map(e => e.style.height = h)
                    // ;
                    // $('#editor').height(newHeight.toString() + "px");
                    // $('#editor-section').height(newHeight.toString() + "px");

                    // This call is required for the editor to fix all of
                    // its inner structure for adapting to a change in size
                    editor.resize();
                };

                // Set initial size to match initial content
                heightUpdateFunction();

                // Whenever a change happens inside the ACE editor, update
                // the size again
                editor.getSession().on('change', heightUpdateFunction);

            })
        });
    }

    document.addEventListener('DOMContentLoaded', function () {
        window.doace();
    })

}());
