"""Build first, then run: python -m unittest discover -s tests -v."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from html.parser import HTMLParser
from pathlib import Path
from threading import Thread
from urllib.parse import unquote, urlsplit
import unittest
import re

from playwright.sync_api import sync_playwright

SITE = Path(__file__).resolve().parents[1] / 'site'


class PageLinks(HTMLParser):
    def __init__(self, path):
        super().__init__()
        self.links = []
        self.ids = set()
        self.feed(path.read_text())

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if 'id' in attrs:
            self.ids.add(attrs['id'])
        if tag == 'a' and 'href' in attrs:
            self.links.append(attrs['href'])


class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


class SiteTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not (SITE / 'index.html').exists():
            raise RuntimeError('Run zensical build --clean before testing')
        cls.server = ThreadingHTTPServer(('127.0.0.1', 0), partial(QuietHandler, directory=str(SITE)))
        cls.thread = Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        cls.base = f'http://127.0.0.1:{cls.server.server_port}'
        cls.playwright = sync_playwright().start()

    @classmethod
    def tearDownClass(cls):
        cls.playwright.stop()
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join()

    def test_internal_links_and_fragments(self):
        pages = {p.resolve(): PageLinks(p) for p in SITE.rglob('*.html')}
        self.assertGreater(len(pages), 30)
        for path, parsed in pages.items():
            for href in parsed.links:
                link = urlsplit(href)
                if link.scheme or link.netloc:
                    continue
                target = (SITE / unquote(link.path).lstrip('/') if link.path.startswith('/')
                          else path.parent / unquote(link.path)) if link.path else path
                if target.is_dir():
                    target /= 'index.html'
                target = target.resolve()
                with self.subTest(page=str(path.relative_to(SITE)), href=href):
                    self.assertTrue(target.exists(), f'Missing target: {target}')
                    if link.fragment and target in pages:
                        self.assertIn(unquote(link.fragment), pages[target].ids)

    def test_platform_navigation_and_support(self):
        for engine in ('chromium', 'firefox', 'webkit'):
            for viewport in ({'width': 1440, 'height': 1000}, {'width': 390, 'height': 844}):
                with self.subTest(engine=engine, viewport=viewport):
                    browser = getattr(self.playwright, engine).launch()
                    self.addCleanup(browser.close)
                    context = browser.new_context(viewport=viewport)
                    page = context.new_page()
                    errors = []
                    page.on('pageerror', lambda error: errors.append(str(error)))
                    page.goto(self.base + '/feature-support/m2/')
                    trigger = page.get_by_role('button', name='Support detail for j414s', exact=True).first
                    trigger.focus()
                    page.keyboard.press('Enter')
                    dialog = page.get_by_role('dialog', name='MacBook Pro 14-inch', exact=True)
                    select = dialog.get_by_label('Operating system')
                    self.assertTrue(dialog.is_visible())
                    self.assertEqual(select.input_value(), '')
                    self.assertEqual(dialog.locator('.feat').count(), 0)
                    self.assertEqual(page.locator(':focus').get_attribute('id'), 'device-modal-platform')
                    select.select_option('windows')
                    self.assertIn('Windows · j414s', dialog.get_by_role('status').inner_text())
                    self.assertEqual(dialog.locator('.feat').filter(has_text='Windows Boot Manager').locator('.feat__state').inner_text(), 'Working')
                    self.assertEqual(dialog.locator('.feat').filter(has_text='GPU acceleration').locator('.feat__state').inner_text(), 'Partial')
                    self.assertEqual(dialog.locator('.feat').filter(has_text='Camera').locator('.feat__state').inner_text(), 'Not working')
                    self.assertIn('WDDM 2.1 in progress', dialog.inner_text())
                    select.select_option('linux')
                    self.assertIn('No Linux support states', dialog.get_by_role('status').inner_text())
                    self.assertNotIn('Windows Boot Manager', dialog.inner_text())
                    self.assertNotIn('WDDM', dialog.inner_text())
                    self.assertIn('Linux kernel boot', dialog.inner_text())
                    self.assertEqual(dialog.locator('.feat:not(.feat--unknown)').count(), 0)
                    select.select_option('windows')
                    self.assertIn('WDDM 2.1 in progress', dialog.inner_text())
                    select.select_option('linux')
                    # OS choice survives instant navigation; no extra dialog is created.
                    page.keyboard.press('Escape')
                    self.assertFalse(dialog.is_visible())
                    self.assertEqual(page.locator(':focus').get_attribute('aria-label'), 'Support detail for j414s')
                    page.evaluate('window.__platformNavigationProbe = true')
                    page.get_by_role('link', name='Next: M3 Series', exact=True).click()
                    page.wait_for_url(re.compile(r'/feature-support/m3/(?:#.*)?$'))
                    self.assertTrue(page.evaluate('window.__platformNavigationProbe'))
                    page.get_by_role('button', name='Support detail for j504', exact=True).first.click()
                    dialog = page.get_by_role('dialog', name='MacBook Pro 14-inch', exact=True)
                    self.assertEqual(dialog.get_by_label('Operating system').input_value(), 'linux')
                    self.assertEqual(page.locator('dialog').count(), 1)
                    dialog.get_by_label('Operating system').select_option('windows')
                    self.assertIn('No Windows support states', dialog.get_by_role('status').inner_text())
                    self.assertEqual(dialog.locator('.feat:not(.feat--unknown)').count(), 0)
                    # The dialog, select and close control fit a narrow viewport.
                    bounds = dialog.bounding_box()
                    self.assertGreaterEqual(bounds['x'], 0)
                    self.assertLessEqual(bounds['x'] + bounds['width'], viewport['width'])
                    self.assertLessEqual(bounds['height'], viewport['height'])
                    dialog.get_by_role('button', name='Close', exact=True).click()
                    page.goto(self.base + '/platforms/overview/')
                    page.locator('.md-content').get_by_role('link', name='Linux guide', exact=True).click()
                    page.wait_for_url(re.compile(r'/platforms/linux/(?:#.*)?$'))
                    page.locator('h1').filter(has_text='Linux on Apple Silicon').wait_for(state='visible')
                    self.assertEqual(errors, [])
                    context.close()
                    browser.close()

    def test_without_javascript(self):
        browser = self.playwright.chromium.launch()
        self.addCleanup(browser.close)
        context = browser.new_context(java_script_enabled=False)
        self.addCleanup(context.close)
        page = context.new_page()
        page.goto(self.base + '/feature-support/m1/')
        self.assertTrue(page.get_by_text('Interactive feature details require JavaScript.', exact=False).is_visible())
        self.assertIn('USB-C is partial', page.locator('.md-content').inner_text())
        page.goto(self.base + '/platforms/overview/')
        self.assertTrue(page.locator('.md-content').get_by_role('link', name='Windows guide', exact=True).is_visible())
        self.assertTrue(page.locator('.md-content').get_by_role('link', name='Linux guide', exact=True).is_visible())


if __name__ == '__main__':
    unittest.main()
