// Run with Playwright available in NODE_PATH; no production dependency is added.
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const base = process.env.PORTFOLIO_URL || 'http://127.0.0.1:4173';
const output = path.resolve('runtime-validation/correction');
const suite = process.env.CORRECTION_SUITE || 'all';
const sections = ['profile', 'cv', 'work', 'computation', 'visual-studies', 'contact'];
const projects = ['shila', 'manmatic', 'protocol-port', 'dabouq', 'concrete-fatigue'];
let assertions = 0;
function check(value, message) { assert(value, message); assertions++; }

async function ready(page, route) {
  await page.goto(base + route, {waitUntil:'domcontentloaded'});
  await page.waitForFunction(() => document.documentElement.classList.contains('loader-complete'));
}

async function atSection(page, id) {
  await page.waitForURL(url => url.pathname === '/' && url.hash === '#' + id, {waitUntil:'domcontentloaded'});
  await page.waitForFunction(id => {
    const el = document.getElementById(id);
    const header = document.getElementById('site-header');
    if (!el) return false;
    const bounds = el.getBoundingClientRect();
    const offset = header.getBoundingClientRect().height + 14;
    const maximum = Math.max(0, document.documentElement.scrollHeight - innerHeight);
    const expected = Math.max(0, Math.min(bounds.top + scrollY - offset, maximum));
    return Math.abs(scrollY - expected) < 3 && bounds.bottom > offset && bounds.top < innerHeight;
  }, id);
  check(true, 'Reached visible section ' + id);
}

async function menuLink(page, id, mobile) {
  if (mobile) await page.locator('#nav-toggle').click();
  await page.locator('.site-nav a[href$="#' + id + '"]').click({noWaitAfter:true});
  await atSection(page, id);
}

(async () => {
  fs.mkdirSync(output, { recursive: true });
  const browser = await chromium.launch({
    executablePath: process.env.CHROME_PATH || 'C:/Program Files/Google/Chrome/Application/chrome.exe',
    headless: true
  });
  const errors = [];
  try {
    for (const width of [1440, 390]) {
      const page = await browser.newPage({ viewport: { width, height: 900 }, reducedMotion: 'reduce' });
      page.on('pageerror', error => errors.push(error.message));
      const sources = width === 1440
        ? ['/', ...projects.map(slug => '/projects/' + slug + '/'), '/visuals/architecture-of-elsewhere/']
        : ['/', '/projects/shila/', '/visuals/architecture-of-elsewhere/'];
      if (suite === 'all' || suite === 'navigation') {
      for (const source of sources) {
        console.log(width + 'px navigation from ' + source);
        for (const id of sections) {
          await ready(page, source);
          if (!await page.locator('.site-nav a[href$="#' + id + '"]').count()) continue;
          // Seed a stale return intent to reproduce the original navigation conflict.
          await page.evaluate(() => sessionStorage.setItem('ahmad-project-return-intent-v1', JSON.stringify({kind:'fallback', projectPath:'/projects/manmatic/'})));
          await menuLink(page, id, width < 960);
          check(!(await page.evaluate(() => document.documentElement.scrollWidth > innerWidth)), 'No overflow after ' + source + ' -> ' + id);
        }
      }
      await ready(page, '/projects/shila/');
      await page.locator('.project-navigation a[href="/#work"]').click();
      await atSection(page, 'work');
      await ready(page, '/visuals/architecture-of-elsewhere/');
      await page.locator('.visual-record__all').click();
      await atSection(page, 'visual-studies');
      await page.goBack();
      check(page.url().includes('/visuals/architecture-of-elsewhere/'), 'Browser Back returns to visual');
      await page.goForward();
      await atSection(page, 'visual-studies');

      await ready(page, '/#work');
      await atSection(page, 'work');
      const card = page.locator('.project-row__link[href="/projects/shila/"]');
      await card.click();
      await page.waitForURL('**/projects/shila/');
      await page.goBack();
      await page.waitForFunction(() => document.querySelector('#shila-project').getBoundingClientRect().top < innerHeight && document.querySelector('#shila-project').getBoundingClientRect().bottom > 0);
      check(true, 'History restores a visible project card');

      }
      if (suite === 'all' || suite === 'edges') {
        for (const source of ['/projects/shila/', '/visuals/architecture-of-elsewhere/']) {
          await ready(page, source);
          await page.evaluate(() => sessionStorage.setItem('ahmad-project-return-intent-v1', JSON.stringify({kind:'fallback', projectPath:'/projects/manmatic/'})));
          if (width < 960) await page.locator('#nav-toggle').click();
          await page.locator('.site-nav a[href="/"]').click({noWaitAfter:true});
          await page.waitForURL(url => url.pathname === '/' && !url.hash, {waitUntil:'domcontentloaded'});
          await page.waitForFunction(() => document.documentElement.classList.contains('loader-complete') && scrollY < 1);
          check(true, 'Index ignores stale project restoration from ' + source);
        }
        await ready(page, '/#work');
        await atSection(page, 'work');
        await page.evaluate(() => window.scrollTo({top:0,behavior:'instant'}));
        await menuLink(page, 'work', width < 960);
        check(true, 'Repeated same-hash navigation realigns the actual section');
      }
      if (suite === 'all' || suite === 'gallery') {
      await ready(page, '/#visual-studies');
      await atSection(page, 'visual-studies');
      await page.waitForFunction(() => document.querySelector('[data-visual-slider]').dataset.visualInitialized === 'true');
      check(await page.locator('.visual-slide__open,.visual-links,.visual-slider__progress').count() === 0, 'No CTA, ribbon or progress strip');
      const visitedVisuals = new Set();
      for (let index = 0; index < 5; index++) {
        const link = page.locator('.visual-slide.is-active .visual-slide__image-link');
        const href = await link.getAttribute('href');
        visitedVisuals.add(href);
        await link.focus();
        await page.keyboard.press('Tab');
        await page.keyboard.press('Shift+Tab');
        check(await link.evaluate(el => getComputedStyle(el).outlineStyle !== 'none'), 'Visible image-link keyboard focus');
        await page.keyboard.press('Enter');
        await page.waitForURL(base + href, {waitUntil:'domcontentloaded'});
        check(true, 'Visual image opens ' + href);
        await page.goBack();
        await page.waitForFunction(() => document.querySelector('[data-visual-slider]')?.dataset.visualInitialized === 'true');
        for (let next = 0; next <= index; next++) await page.locator('[data-visual-next]').click();
      }
      check(visitedVisuals.size === 5, 'All five distinct Visual destinations tested');
      const activeImage = page.locator('.visual-slide.is-active .visual-slide__image-link');
      await activeImage.scrollIntoViewIfNeeded();
      const imageBox = await activeImage.boundingBox();
      const priorNumber = await page.locator('[data-visual-current]').textContent();
      await page.mouse.move(imageBox.x + imageBox.width * .7, imageBox.y + 30);
      await page.mouse.down();
      await page.mouse.move(imageBox.x + imageBox.width * .3, imageBox.y + 30, {steps:8});
      await page.mouse.up();
      check(new URL(page.url()).pathname === '/', 'Dragging a linked visual does not navigate');
      check(await page.locator('[data-visual-current]').textContent() !== priorNumber, 'Dragging still advances gallery');
      const mouseLink = page.locator('.visual-slide.is-active .visual-slide__image-link');
      const mouseHref = await mouseLink.getAttribute('href');
      await mouseLink.click({noWaitAfter:true});
      await page.waitForURL(base + mouseHref, {waitUntil:'domcontentloaded'});
      check(true, 'Mouse click on image opens corresponding detail');
      await page.goBack({waitUntil:'domcontentloaded'});
      await menuLink(page, 'contact', width < 960);
      const gif = page.locator('.contact__intro > .contact__name img');
      await gif.scrollIntoViewIfNeeded();
      await page.waitForFunction(() => document.querySelector('.contact__name img').complete);
      const dimensions = await gif.boundingBox();
      check(Math.abs(dimensions.width / dimensions.height - 1100 / 260) < .001, 'Contact GIF proportion');
      check(await page.locator('img[src$="ahmad_name_old_printer_transparent.gif"]').count() === 1, 'Exactly one GIF instance');
      check(await gif.getAttribute('alt') === 'Ahmad Alhadidii', 'Accessible name');
      check(await page.locator('.closing-identity').count() === 0, 'Repeated closing identity removed');
      check(!(await page.locator('.contact__links').innerText()).includes('↗'), 'Contact arrows removed');
      check(await page.locator('.manmatic-threshold__mark path').count() > 0, 'Original symbol paths restored');
      check(await page.locator('.manmatic-branch > span').count() === 0, 'Redundant ManMaTIC entry labels removed');
      await page.waitForTimeout(1800);
      await page.screenshot({path:path.join(output, width + '-contact-verified.png')});
      }
      console.log('Passed ' + width + 'px ' + suite + ' checks');
      await page.close();
    }

    if (suite === 'all' || suite === 'autoplay') {
    // Browser virtual time exercises the real 45,000ms timer without waiting minutes.
    const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
    page.on('pageerror', error => errors.push(error.message));
    await ready(page, '/#visual-studies');
    await atSection(page, 'visual-studies');
    await page.waitForFunction(() => document.querySelector('[data-visual-slider]').dataset.visualInitialized === 'true');
    await page.clock.install();
    await page.clock.pauseAt(new Date());
    await page.mouse.move(0, 0);
    const slider = page.locator('[data-visual-slider]');
    const number = () => page.locator('[data-visual-current]').textContent();
    await slider.dispatchEvent('mouseleave');
    await page.clock.fastForward(44999);
    check(await number() === '01', 'No advance before 45 seconds');
    await page.clock.fastForward(1);
    check(await number() === '02', 'Advance at 45 seconds');
    for (const expected of ['03', '04', '05', '01']) {
      await page.clock.fastForward(45000);
      check(await number() === expected, 'Autoplay loop reaches ' + expected);
    }
    await slider.dispatchEvent('mouseenter');
    await page.clock.fastForward(90000);
    check(await number() === '01', 'Hover pauses');
    await slider.dispatchEvent('mouseleave');
    await page.clock.fastForward(45000);
    check(await number() === '02', 'Hover exit resumes');
    await page.locator('[data-visual-next]').focus();
    await page.clock.fastForward(90000);
    check(await number() === '02', 'Keyboard focus pauses');
    await page.evaluate(() => document.activeElement.blur());
    await page.clock.fastForward(44999);
    check(await number() === '02', 'Focus exit restarts full interval');
    await page.clock.fastForward(1);
    check(await number() === '03', 'Focus exit resumes');
    await page.clock.fastForward(30000);
    await page.locator('[data-visual-next]').dispatchEvent('click');
    await page.clock.fastForward(44999);
    check(await number() === '04', 'Manual interaction resets interval');
    await page.clock.fastForward(1);
    check(await number() === '05', 'Reset interval advances at 45 seconds');
    await page.evaluate(() => {
      window.dispatchEvent(new WheelEvent('wheel'));
      document.getElementById('profile').scrollIntoView({behavior:'instant'});
    });
    await page.clock.runFor(40);
    await page.clock.fastForward(90000);
    check(await number() === '05', 'Offscreen gallery pauses');
    await slider.scrollIntoViewIfNeeded();
    await page.clock.runFor(40);
    await page.clock.fastForward(45000);
    check(await number() === '01', 'Visible gallery resumes');
    await page.emulateMedia({reducedMotion:'reduce'});
    await page.clock.fastForward(90000);
    check(await number() === '01', 'Reduced motion pauses autoplay');
    await page.emulateMedia({reducedMotion:'no-preference'});
    await page.clock.runFor(40);
    const detachedNumber = await number();
    await page.evaluate(() => {
      window.removedGallery = document.querySelector('[data-visual-slider]');
      window.removedGallery.remove();
    });
    await page.clock.fastForward(90000);
    check(await page.evaluate(() => window.removedGallery.querySelector('[data-visual-current]').textContent) === detachedNumber, 'Unmount clears the timer before another advance');
    await page.close();
    }
    check(errors.length === 0, 'No uncaught browser errors: ' + errors.join('; '));
    fs.writeFileSync(path.join(output, 'verification-' + suite + '.json'), JSON.stringify({assertions, errors, passed:true}, null, 2));
    console.log('PASS: ' + assertions + ' correction assertions');
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exit(1); });
