var IcomaticUtils = (function() {
return {
fallbacks: [{ from: 'intelligent', 'to': '\ue006' },{ from: 'overhappy', 'to': '\ue00a' },{ from: 'blinking', 'to': '\ue001' },{ from: 'confused', 'to': '\ue002' },{ from: 'kissing', 'to': '\ue008' },{ from: 'naughty', 'to': '\ue009' },{ from: 'shocked', 'to': '\ue00d' },{ from: 'unhappy', 'to': '\ue012' },{ from: 'vampire', 'to': '\ue013' },{ from: 'crying', 'to': '\ue003' },{ from: 'inlove', 'to': '\ue005' },{ from: 'pirate', 'to': '\ue00b' },{ from: 'sealed', 'to': '\ue00c' },{ from: 'silent', 'to': '\ue00e' },{ from: 'sleepy', 'to': '\ue00f' },{ from: 'toothy', 'to': '\ue011' },{ from: 'angry', 'to': '\ue000' },{ from: 'happy', 'to': '\ue004' },{ from: 'thief', 'to': '\ue010' },{ from: 'king', 'to': '\ue007' }],
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