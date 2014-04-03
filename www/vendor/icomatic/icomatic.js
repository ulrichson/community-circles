var IcomaticUtils = (function() {
return {
fallbacks: [{ from: 'intelligentfilled', 'to': '\ue00c' },{ from: 'overhappyfilled', 'to': '\ue014' },{ from: 'blinkingfilled', 'to': '\ue002' },{ from: 'confusedfilled', 'to': '\ue004' },{ from: 'kissingfilled', 'to': '\ue010' },{ from: 'naughtyfilled', 'to': '\ue012' },{ from: 'shockedfilled', 'to': '\ue01a' },{ from: 'unhappyfilled', 'to': '\ue024' },{ from: 'vampirefilled', 'to': '\ue026' },{ from: 'cryingfilled', 'to': '\ue006' },{ from: 'inlovefilled', 'to': '\ue00a' },{ from: 'piratefilled', 'to': '\ue016' },{ from: 'sealedfilled', 'to': '\ue018' },{ from: 'silentfilled', 'to': '\ue01c' },{ from: 'sleepyfilled', 'to': '\ue01e' },{ from: 'toothyfilled', 'to': '\ue022' },{ from: 'angryfilled', 'to': '\ue000' },{ from: 'happyfilled', 'to': '\ue008' },{ from: 'intelligent', 'to': '\ue00d' },{ from: 'thieffilled', 'to': '\ue020' },{ from: 'kingfilled', 'to': '\ue00e' },{ from: 'overhappy', 'to': '\ue015' },{ from: 'blinking', 'to': '\ue003' },{ from: 'confused', 'to': '\ue005' },{ from: 'kissing', 'to': '\ue011' },{ from: 'naughty', 'to': '\ue013' },{ from: 'shocked', 'to': '\ue01b' },{ from: 'unhappy', 'to': '\ue025' },{ from: 'vampire', 'to': '\ue027' },{ from: 'crying', 'to': '\ue007' },{ from: 'inlove', 'to': '\ue00b' },{ from: 'pirate', 'to': '\ue017' },{ from: 'sealed', 'to': '\ue019' },{ from: 'silent', 'to': '\ue01d' },{ from: 'sleepy', 'to': '\ue01f' },{ from: 'toothy', 'to': '\ue023' },{ from: 'angry', 'to': '\ue001' },{ from: 'happy', 'to': '\ue009' },{ from: 'thief', 'to': '\ue021' },{ from: 'king', 'to': '\ue00f' }],
substitute: function(el) {
    var curr = el.firstChild;
    var next, alt;
    var content;
    while (curr) {
        next = curr.nextSibling;
        if (curr.nodeType === Node.TEXT_NODE) {
            content = curr.nodeValue;
            for (var i = 0; i < IcomaticUtils.fallbacks.length; i++) {
                content = content.replace( IcomaticUtils.fallbacks[i].from, function(match) {
                    alt = document.createElement('span');
                    alt.setAttribute('class', 'icomatic-alt');
                    alt.innerHTML = match;
                    el.insertBefore(alt, curr);
                    return IcomaticUtils.fallbacks[i].to;
                });
            }
            alt = document.createTextNode(content);
            el.replaceChild(alt, curr);
        }
        curr = next;
    }
},
run: function(force) {
    force = typeof force !== 'undefined' ? force : false;
    var s = getComputedStyle(document.body);
    if (('WebkitFontFeatureSettings' in s)
        || ('MozFontFeatureSettings' in s)
        || ('MsFontFeatureSettings' in s)
        || ('OFontFeatureSettings' in s)
        || ('fontFeatureSettings' in s))
        if (!force)
            return;
    var els = document.querySelectorAll('.icomatic');
    for (var i = 0; i < els.length; i++)
        IcomaticUtils.substitute(els[i]);
}
} // end of object
} // end of fn
)()