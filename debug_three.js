const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  
  page.on('console', msg => console.log('PAGE LOG:', msg.text()));
  page.on('pageerror', err => console.log('PAGE ERROR:', err.message));
  
  await page.goto('http://localhost:5000', { waitUntil: 'networkidle0' });
  
  const result = await page.evaluate(() => {
    // We need to access the scene, but it's local in script.js
    // However we can check window properties, or maybe run a little script
    
    // Instead of scene, let's just create a new Three scene and see if it works
    if (typeof THREE === 'undefined') return 'THREE IS UNDEFINED';
    
    const canvas = document.querySelector('#bg-canvas');
    if (!canvas) return 'CANVAS NOT FOUND';
    
    // Check if webgl context exists
    const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
    if (!gl) return 'WEBGL CONTEXT NOT FOUND';
    
    return {
        canvasWidth: canvas.width,
        canvasHeight: canvas.height,
        windowScrollY: window.scrollY,
        bodyScrollHeight: document.body.scrollHeight,
        innerHeight: window.innerHeight,
        glContext: 'exists'
    };
  });
  
  console.log(result);
  await browser.close();
})();
