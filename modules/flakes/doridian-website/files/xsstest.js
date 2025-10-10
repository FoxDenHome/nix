try {
	alert('Ohi :3');
} catch {}

try {
	console.log('Ohi :3');
} catch {}

(function() {
    const eles = document.getElementsByTagName('script');
    for (let i = 0; i < eles.length; i++) {
        const ele = eles[i];
        const src = ele.src.toLowerCase();
        if (src.includes('//doridian.net/') || src.includes('//f0x.es/')) {
            window._xss_doridian_found = true;
            const img = document.createElement('img');
            img.src = 'https://doridian.net/icon.jpg';
            ele.parentNode.replaceChild(img, ele);
        }
    }
})();
