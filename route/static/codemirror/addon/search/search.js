(function(a){if(typeof exports=="object"&&typeof module=="object"){a(require("../../lib/codemirror"),require("./searchcursor"),require("../dialog/dialog"))}else{if(typeof define=="function"&&define.amd){define(["../../lib/codemirror","./searchcursor","../dialog/dialog"],a)}else{a(CodeMirror)}}})(function(n){function k(w,v){if(typeof w=="string"){w=new RegExp(w.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g,"\\$&"),v?"gi":"g")}else{if(!w.global){w=new RegExp(w.source,w.ignoreCase?"gi":"g")}}return{token:function(y){w.lastIndex=y.pos;var x=w.exec(y.string);if(x&&x.index==y.pos){y.pos+=x[0].length||1;return"searching"}else{if(x){y.pos=x.index}else{y.skipToEnd()}}}}}function j(){this.posFrom=this.posTo=this.lastQuery=this.query=null;this.overlay=null}function s(v){return v.state.search||(v.state.search=new j())}function e(v){return typeof v=="string"&&v==v.toLowerCase()}function b(v,w,x){return v.getSearchCursor(w,x,e(w))}function d(v,y,z,w,x){v.openDialog(y,w,{value:z,selectValueOnOpen:true,closeOnEnter:false,onClose:function(){q(v)},onKeyDown:x})}function p(v,y,w,z,x){if(v.openDialog){v.openDialog(y,x,{value:z,selectValueOnOpen:true})}else{x(prompt(w,z))}}function l(w,y,x,v){if(w.openConfirm){w.openConfirm(y,v)}else{if(confirm(x)){v[0]()}}}function i(v){return v.replace(/\\(.)/g,function(w,x){if(x=="n"){return"\n"}if(x=="r"){return"\r"}return x})}function h(w){var v=w.match(/^\/(.*)\/([a-z]*)$/);if(v){try{w=new RegExp(v[1],v[2].indexOf("i")==-1?"":"i")}catch(x){}}else{w=i(w)}if(typeof w=="string"?w=="":w.test("")){w=/x^/}return w}var u='Search: <input type="text" style="width: 10em" class="CodeMirror-search-field"/> <span style="color: #888" class="CodeMirror-search-hint">(Enter to continue to retrieve the next one)</span><div class="Dialog-close">X</div>';function t(v,x,w){x.queryText=w;x.query=h(w);v.removeOverlay(x.overlay,e(x.query));x.overlay=k(x.query,e(x.query));v.addOverlay(x.overlay);if(v.showMatchesOnScrollbar){if(x.annotate){x.annotate.clear();x.annotate=null}x.annotate=v.showMatchesOnScrollbar(x.query,e(x.query))}}function m(v,y,x,z){var C=s(v);if(C.query){return f(v,y)}var B=v.getSelection()||C.lastQuery;if(x&&v.openDialog){var w=null;var A=function(E,D){n.e_stop(D);if(!E){return}if(E!=C.queryText){t(v,C,E);C.posFrom=C.posTo=v.getCursor()}if(w){w.style.opacity=1}f(v,D.shiftKey,function(F,H){var G;if(H.line<3&&document.querySelector&&(G=v.display.wrapper.querySelector(".CodeMirror-dialog"))&&G.getBoundingClientRect().bottom-4>v.cursorCoords(H,"window").top){(w=G).style.opacity=0.4}})};d(v,u,B,A,function(E,G){var D=n.keyName(E);var F=n.keyMap[v.getOption("keyMap")][D];if(!F){F=v.getOption("extraKeys")[D]}if(F=="findNext"||F=="findPrev"||F=="findPersistentNext"||F=="findPersistentPrev"){n.e_stop(E);t(v,s(v),G);v.execCommand(F)}else{if(F=="find"||F=="findPersistent"){n.e_stop(E);A(G,E)}}});if(z&&B){t(v,C,B);f(v,y)}}else{p(v,u,"Search for:",B,function(D){if(D&&!C.query){v.operation(function(){t(v,C,D);C.posFrom=C.posTo=v.getCursor();f(v,y)})}})}}function f(v,w,x){v.operation(function(){var y=s(v);var z=b(v,y.query,w?y.posFrom:y.posTo);if(!z.find(w)){z=b(v,y.query,w?n.Pos(v.lastLine()):n.Pos(v.firstLine(),0));if(!z.find(w)){return}}v.setSelection(z.from(),z.to());v.scrollIntoView({from:z.from(),to:z.to()},20);y.posFrom=z.from();y.posTo=z.to();if(x){x(z.from(),z.to())}})}function q(v){v.operation(function(){var w=s(v);w.lastQuery=w.query;if(!w.query){return}w.query=w.queryText=null;v.removeOverlay(w.overlay);if(w.annotate){w.annotate.clear();w.annotate=null}})}var a=' <input type="text" style="width: 10em" class="CodeMirror-search-field"/> <span style="color: #888" class="CodeMirror-search-hint">(Use /re/ syntax for regexp search)</span>';var g='To: <input type="text" style="width: 10em" class="CodeMirror-search-field"/>';var o="replace? <button>Yes</button> <button>No</button> <button>All</button> <button>Cancel</button>";function c(v,w,x){v.operation(function(){for(var z=b(v,w);z.findNext();){if(typeof w!="string"){var y=v.getRange(z.from(),z.to()).match(w);z.replace(x.replace(/\$(\d)/g,function(A,B){return y[B]}))}else{z.replace(x)}}})}function r(v,x){if(v.getOption("readOnly")){return}var y=v.getSelection()||s(v).lastQuery;var w=x?"Replace all:":"replace:";p(v,w+a,w,y,function(z){if(!z){return}z=h(z);p(v,g,"Change:","",function(D){D=i(D);if(x){c(v,z,D)}else{q(v);var C=b(v,z,v.getCursor("from"));var B=function(){var F=C.from(),E;if(!(E=C.findNext())){C=b(v,z);if(!(E=C.findNext())||(F&&C.from().line==F.line&&C.from().ch==F.ch)){return}}v.setSelection(C.from(),C.to());v.scrollIntoView({from:C.from(),to:C.to()});l(v,o,"replace?",[function(){A(E)},B,function(){c(v,z,D)}])};var A=function(E){C.replace(typeof z=="string"?D:D.replace(/\$(\d)/g,function(F,G){return E[G]}));B()};B()}})})}n.commands.find=function(v){q(v);m(v)};n.commands.findPersistent=function(v){q(v);m(v,false,true)};n.commands.findPersistentNext=function(v){m(v,false,true,true)};n.commands.findPersistentPrev=function(v){m(v,true,true,true)};n.commands.findNext=m;n.commands.findPrev=function(v){m(v,true)};n.commands.clearSearch=q;n.commands.replace=r;n.commands.replaceAll=function(v){r(v,true)}});(function(a){if(typeof exports=="object"&&typeof module=="object"){a(require("../../lib/codemirror"))}else{if(typeof define=="function"&&define.amd){define(["../../lib/codemirror"],a)}else{a(CodeMirror)}}})(function(a){var b=a.Pos;function c(k,i,l,g){this.atOccurrence=false;this.doc=k;if(g==null&&typeof i=="string"){g=false}l=l?k.clipPos(l):b(0,0);this.pos={from:l,to:l};if(typeof i!="string"){if(!i.global){i=new RegExp(i.source,i.ignoreCase?"ig":"g")}this.matches=function(p,t){if(p){i.lastIndex=0;var m=k.getLine(t.line).slice(0,t.ch),r=0,o,s;for(;;){i.lastIndex=r;var q=i.exec(m);if(!q){break}o=q;s=o.index;r=o.index+(o[0].length||1);if(r==m.length){break}}var n=(o&&o[0].length)||0;if(!n){if(s==0&&m.length==0){o=undefined}else{if(s!=k.getLine(t.line).length){n++}}}}else{i.lastIndex=t.ch;var m=k.getLine(t.line),o=i.exec(m);var n=(o&&o[0].length)||0;var s=o&&o.index;if(s+n!=m.length&&!n){n=1}}if(o&&n){return{from:b(t.line,s),to:b(t.line,s+n),match:o}}}}else{var e=i;if(g){i=i.toLowerCase()}var f=g?function(m){return m.toLowerCase()}:function(m){return m};var j=i.split("\n");if(j.length==1){if(!i.length){this.matches=function(){}}else{this.matches=function(o,q){if(o){var p=k.getLine(q.line).slice(0,q.ch),m=f(p);var n=m.lastIndexOf(i);if(n>-1){n=d(p,m,n);return{from:b(q.line,n),to:b(q.line,n+e.length)}}}else{var p=k.getLine(q.line).slice(q.ch),m=f(p);var n=m.indexOf(i);if(n>-1){n=d(p,m,n)+q.ch;return{from:b(q.line,n),to:b(q.line,n+e.length)}}}}}}else{var h=e.split("\n");this.matches=function(n,p){var t=j.length-1;if(n){if(p.line-(j.length-1)<k.firstLine()){return}if(f(k.getLine(p.line).slice(0,h[t].length))!=j[j.length-1]){return}var s=b(p.line,h[t].length);for(var o=p.line-1,m=t-1;m>=1;--m,--o){if(j[m]!=f(k.getLine(o))){return}}var u=k.getLine(o),q=u.length-h[0].length;if(f(u.slice(q))!=j[0]){return}return{from:b(o,q),to:s}}else{if(p.line+(j.length-1)>k.lastLine()){return}var u=k.getLine(p.line),q=u.length-h[0].length;if(f(u.slice(q))!=j[0]){return}var r=b(p.line,q);for(var o=p.line+1,m=1;m<t;++m,++o){if(j[m]!=f(k.getLine(o))){return}}if(f(k.getLine(o).slice(0,h[t].length))!=j[t]){return}return{from:r,to:b(o,h[t].length)}}}}}}c.prototype={findNext:function(){return this.find(false)},findPrevious:function(){return this.find(true)},find:function(f){var e=this,i=this.doc.clipPos(f?this.pos.from:this.pos.to);function g(j){var k=b(j,0);e.pos={from:k,to:k};e.atOccurrence=false;return false}for(;;){if(this.pos=this.matches(f,i)){this.atOccurrence=true;return this.pos.match||true}if(f){if(!i.line){return g(0)}i=b(i.line-1,this.doc.getLine(i.line-1).length)}else{var h=this.doc.lineCount();if(i.line==h-1){return g(h)}i=b(i.line+1,0)}}},from:function(){if(this.atOccurrence){return this.pos.from}},to:function(){if(this.atOccurrence){return this.pos.to}},replace:function(g,f){if(!this.atOccurrence){return}var e=a.splitLines(g);this.doc.replaceRange(e,this.pos.from,this.pos.to,f);this.pos.to=b(this.pos.from.line+e.length-1,e[e.length-1].length+(e.length==1?this.pos.from.ch:0))}};function d(i,g,h){if(i.length==g.length){return h}for(var f=Math.min(h,i.length);;){var e=i.slice(0,f).toLowerCase().length;if(e<h){++f}else{if(e>h){--f}else{return f}}}}a.defineExtension("getSearchCursor",function(f,g,e){return new c(this.doc,f,g,e)});a.defineDocExtension("getSearchCursor",function(f,g,e){return new c(this,f,g,e)});a.defineExtension("selectMatches",function(g,f){var e=[];var h=this.getSearchCursor(g,this.getCursor("from"),f);while(h.findNext()){if(a.cmpPos(h.to(),this.getCursor("to"))>0){break}e.push({anchor:h.from(),head:h.to()})}if(e.length){this.setSelections(e,0)}})});(function(a){if(typeof exports=="object"&&typeof module=="object"){a(require("../../lib/codemirror"),require("../dialog/dialog"))}else{if(typeof define=="function"&&define.amd){define(["../../lib/codemirror","../dialog/dialog"],a)}else{a(CodeMirror)}}})(function(a){function b(e,i,g,j,h){if(e.openDialog){e.openDialog(i,h,{value:j,selectValueOnOpen:true})}else{h(prompt(g,j))}}var d='Jump to line: <input type="text" style="width: 10em" class="CodeMirror-search-field"/> <span style="color: #888" class="CodeMirror-search-hint">(Use line:column or scroll% syntax)</span>';function c(e,g){var f=Number(g);if(/^[-+]/.test(g)){return e.getCursor().line+f}else{return f-1}}a.commands.jumpToLine=function(e){var f=e.getCursor();b(e,d,"Jump to line:",(f.line+1)+":"+f.ch,function(i){if(!i){return}var h;if(h=/^\s*([\+\-]?\d+)\s*\:\s*(\d+)\s*$/.exec(i)){e.setCursor(c(e,h[1]),Number(h[2]))}else{if(h=/^\s*([\+\-]?\d+(\.\d+)?)\%\s*/.exec(i)){var g=Math.round(e.lineCount()*Number(h[1])/100);if(/^[-+]/.test(h[1])){g=f.line+g+1}e.setCursor(g-1,f.ch)}else{if(h=/^\s*\:?\s*([\+\-]?\d+)\s*/.exec(i)){e.setCursor(c(e,h[1]),f.ch)}}}})};a.keyMap["default"]["Alt-G"]="jumpToLine"});(function(a){if(typeof exports=="object"&&typeof module=="object"){a(require("../../lib/codemirror"),require("./searchcursor"),require("../scroll/annotatescrollbar"))}else{if(typeof define=="function"&&define.amd){define(["../../lib/codemirror","./searchcursor","../scroll/annotatescrollbar"],a)}else{a(CodeMirror)}}})(function(b){b.defineExtension("showMatchesOnScrollbar",function(g,f,e){if(typeof e=="string"){e={className:e}}if(!e){e={}}return new c(this,g,f,e)});function c(e,j,i,h){this.cm=e;this.options=h;var f={listenForChanges:false};for(var k in h){f[k]=h[k]}if(!f.className){f.className="CodeMirror-search-match"}this.annotation=e.annotateScrollbar(f);this.query=j;this.caseFold=i;this.gap={from:e.firstLine(),to:e.lastLine()+1};this.matches=[];this.update=null;this.findMatches();this.annotation.update(this.matches);var g=this;e.on("change",this.changeHandler=function(l,m){g.onChange(m)})}var d=1000;c.prototype.findMatches=function(){if(!this.gap){return}for(var g=0;g<this.matches.length;g++){var f=this.matches[g];if(f.from.line>=this.gap.to){break}if(f.to.line>=this.gap.from){this.matches.splice(g--,1)}}var h=this.cm.getSearchCursor(this.query,b.Pos(this.gap.from,0),this.caseFold);var e=this.options&&this.options.maxMatches||d;while(h.findNext()){var f={from:h.from(),to:h.to()};if(f.from.line>=this.gap.to){break}this.matches.splice(g++,0,f);if(this.matches.length>e){break}}this.gap=null};function a(e,g,f){if(e<=g){return e}return Math.max(g,e+f)}c.prototype.onChange=function(k){var l=k.from.line;var e=b.changeEnd(k).line;var f=e-k.to.line;if(this.gap){this.gap.from=Math.min(a(this.gap.from,l,f),k.from.line);this.gap.to=Math.max(a(this.gap.to,l,f),k.from.line)}else{this.gap={from:k.from.line,to:e+1}}if(f){for(var h=0;h<this.matches.length;h++){var j=this.matches[h];var g=a(j.from.line,l,f);if(g!=j.from.line){j.from=b.Pos(g,j.from.ch)}var m=a(j.to.line,l,f);if(m!=j.to.line){j.to=b.Pos(m,j.to.ch)}}}clearTimeout(this.update);var n=this;this.update=setTimeout(function(){n.updateAfterChange()},250)};c.prototype.updateAfterChange=function(){this.findMatches();this.annotation.update(this.matches)};c.prototype.clear=function(){this.cm.off("change",this.changeHandler);this.annotation.clear()}});(function(a){if(typeof exports=="object"&&typeof module=="object"){a(require("../../lib/codemirror"),require("./matchesonscrollbar"))}else{if(typeof define=="function"&&define.amd){define(["../../lib/codemirror","./matchesonscrollbar"],a)}else{a(CodeMirror)}}})(function(d){var c={style:"matchhighlight",minChars:2,delay:100,wordsOnly:false,annotateScrollbar:false,showToken:false,trim:true};function j(n){this.options={};for(var m in c){this.options[m]=(n&&n.hasOwnProperty(m)?n:c)[m]}this.overlay=this.timeout=null;this.matchesonscroll=null;this.active=false}d.defineOption("highlightSelectionMatches",false,function(m,p,n){if(n&&n!=d.Init){l(m);clearTimeout(m.state.matchHighlighter.timeout);m.state.matchHighlighter=null;m.off("cursorActivity",i);m.off("focus",h)}if(p){var o=m.state.matchHighlighter=new j(p);if(m.hasFocus()){o.active=true;f(m)}else{m.on("focus",h)}m.on("cursorActivity",i)}});function i(m){var n=m.state.matchHighlighter;if(n.active||m.hasFocus()){a(m,n)}}function h(m){var n=m.state.matchHighlighter;if(!n.active){n.active=true;a(m,n)}}function a(m,n){clearTimeout(n.timeout);n.timeout=setTimeout(function(){f(m)},n.options.delay)}function b(n,r,p,o){var q=n.state.matchHighlighter;n.addOverlay(q.overlay=e(r,p,o));if(q.options.annotateScrollbar&&n.showMatchesOnScrollbar){var m=p?new RegExp("\\b"+r+"\\b"):r;q.matchesonscroll=n.showMatchesOnScrollbar(m,false,{className:"CodeMirror-selection-highlight-scrollbar"})}}function l(m){var n=m.state.matchHighlighter;if(n.overlay){m.removeOverlay(n.overlay);n.overlay=null;if(n.matchesonscroll){n.matchesonscroll.clear();n.matchesonscroll=null}}}function f(m){m.operation(function(){var n=m.state.matchHighlighter;l(m);if(!m.somethingSelected()&&n.options.showToken){var u=n.options.showToken===true?/[\w$]/:n.options.showToken;var t=m.getCursor(),v=m.getLine(t.line),o=t.ch,p=o;while(o&&u.test(v.charAt(o-1))){--o}while(p<v.length&&u.test(v.charAt(p))){++p}if(o<p){b(m,v.slice(o,p),u,n.options.style)}return}var r=m.getCursor("from"),s=m.getCursor("to");if(r.line!=s.line){return}if(n.options.wordsOnly&&!g(m,r,s)){return}var q=m.getRange(r,s);if(n.options.trim){q=q.replace(/^\s+|\s+$/g,"")}if(q.length>=n.options.minChars){b(m,q,false,n.options.style)}})}function g(m,r,q){var o=m.getRange(r,q);if(o.match(/^\w+$/)!==null){if(r.ch>0){var p={line:r.line,ch:r.ch-1};var n=m.getRange(p,r);if(n.match(/\W/)===null){return false}}if(q.ch<m.getLine(r.line).length){var p={line:q.line,ch:q.ch+1};var n=m.getRange(q,p);if(n.match(/\W/)===null){return false}}return true}else{return false}}function k(n,m){return(!n.start||!m.test(n.string.charAt(n.start-1)))&&(n.pos==n.string.length||!m.test(n.string.charAt(n.pos)))}function e(o,n,m){return{token:function(p){if(p.match(o)&&(!n||k(p,n))){return m}p.next();p.skipTo(o.charAt(0))||p.skipToEnd()}}}});
