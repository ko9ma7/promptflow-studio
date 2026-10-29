"""PromptFlow v3 browser regression test (Python playwright + Chromium). No external network needed.
Run: python tests/test_dynamic.py
"""
import asyncio
from pathlib import Path
from playwright.async_api import async_playwright

ROOT=Path(__file__).resolve().parents[1]

async def run():
 async with async_playwright() as pw:
  browser=await pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox'])
  page=await browser.new_page(viewport={'width':1460,'height':960},accept_downloads=True)
  errors=[]
  page.on('pageerror',lambda e:errors.append(str(e)))
  html=(ROOT/'index.html').read_text().replace('<script src="assets/catalog.js" defer></script>','').replace('<script src="assets/app.js" defer></script>','').replace('<link rel="stylesheet" href="assets/styles.css">','')
  await page.set_content(html)
  await page.add_style_tag(path=str(ROOT/'assets/styles.css'))
  await page.add_script_tag(path=str(ROOT/'assets/catalog.js'))
  await page.add_script_tag(path=str(ROOT/'assets/app.js'))
  async def prompt():return await page.locator('#promptPreview').inner_text()
  assert not errors, errors
  initial=await prompt();assert 'HTML 인터랙티브 슬라이드' in initial
  await page.screenshot(path=str(ROOT/'docs/screenshot-home.png'),full_page=True)
  # Eight primary formats must each lead to distinct outputs.
  outputs=[]
  for format_id in ['slides','report','ppt','web','doc','video','data','other']:
   await page.locator(f'[data-format="{format_id}"]').click()
   current=await prompt();outputs.append(current)
   assert len(current)>900,(format_id,len(current))
   assert f'- 결과물: ' in current
  assert len(set(outputs))==8,'Format change did not alter prompt'
  # subtypes must make recommendations more specific
  await page.locator('[data-format="ppt"]').click()
  prev=await prompt()
  await page.locator('[data-field="subtype"]').select_option('제안서 PPT')
  assert '제안 표지' in await prompt() and prev!=await prompt(), 'Subtype must change page plan'
  # Main editing makes a new prompt immediately
  await page.locator('[data-format="slides"]').click()
  await page.locator('[data-field="title"]').fill('테슬라 사업 전망')
  assert '테슬라 사업 전망' in await prompt()
  await page.locator('[data-field="ratio"]').select_option('4:3')
  assert '4:3' in await prompt()
  await page.locator('[data-field="provider"]').select_option('Claude')
  assert not (await prompt()).startswith('@Sites')
  # Material/source changes
  await page.locator('[data-stage="1"]').click()
  await page.locator('[data-field="source"]').fill('검증 가능한 시장조사 데이터 표와 원문 기사')
  assert '검증 가능한 시장조사 데이터' in await prompt()
  await page.locator('[data-field="style"]').select_option('미래지향·테크')
  assert '미래지향·테크' in await prompt()
  # Page UX, content, reordering/duplication
  await page.locator('[data-stage="2"]').click()
  assert await page.locator('.page-editor').count()==7
  first=page.locator('.page-editor').first
  await first.locator('[data-pkey="ui"]').select_option('lever')
  await first.locator('[data-pkey="detail"]').fill('Performance / Thrust / Rocket 3가지 옵션')
  assert '세로 레버의 단계 선택' in await prompt() and 'Performance / Thrust / Rocket' in await prompt()
  await page.screenshot(path=str(ROOT/'docs/screenshot-pages.png'),full_page=True)
  before=await prompt()
  await page.locator('[data-paction="clone"]').first.click()
  assert await page.locator('.page-editor').count()==8 and before!=await prompt()
  # Advanced effect prompt must change
  await page.locator('[data-stage="3"]').click()
  before=await prompt()
  await page.locator('[data-effect="year"]').check()
  assert '연도 연동 차트' in await prompt() and before!=await prompt()
  await page.locator('[data-effect="motion"]').check()
  await page.locator('[data-field="motionSeconds"]').fill('20')
  assert '모션그래픽: 20초' in await prompt()
  await page.locator('[data-field="silent"]').check()
  assert '음악 없이' in await prompt()
  # Recipe is a different prompt, not a non-reactive overlay
  await page.locator('[data-recipe="fill"]').click()
  assert '숫자·그래프' in await prompt()
  await page.locator('[data-effect="fill"]').check()
  assert '사용자가 선택한 고급 효과' in await prompt(), 'Effect should switch from recipe to base'
  # Review change must show in revision
  await page.locator('[data-stage="4"]').click()
  await page.locator('[data-field="issueCurrent"]').fill('3페이지 연도 그래프가 선택한 연도를 반영하지 않습니다')
  assert '3페이지 연도 그래프' in await prompt()
  await page.screenshot(path=str(ROOT/'docs/screenshot-revision.png'),full_page=True)
  await page.locator('[data-action="recordRevision"]').click()
  assert await page.locator('.history-item').count()==1
  # Output, QA, GitHub prompt
  await page.locator('[data-stage="5"]').click()
  assert 'GitHub Pages' not in (await prompt()).split('## 8. GitHub Pages')[0][-100:]
  await page.locator('[data-field="github"]').check()
  assert 'github-bootstrap.cmd' in await prompt()
  await page.locator('[data-qa="sources"]').check()
  assert '수치와 자료의 출처가 확인됨' not in await prompt() and '최종 검수 및 누락 보완' in await prompt()
  await page.locator('[data-action="showCheck"]').click()
  # JSON download is a real file
  async with page.expect_download() as dl:
   await page.locator('[data-action="export"]').click()
  d=await dl.value
  assert d.suggested_filename.endswith('.json')
  # Return to base view
  await page.locator('[data-view="base"]').click()
  assert '테슬라 사업 전망' in await prompt()
  # Mobile viewport
  await page.set_viewport_size({'width':390,'height':844})
  await page.screenshot(path=str(ROOT/'docs/screenshot-mobile.png'),full_page=True)
  assert not await page.evaluate('document.documentElement.scrollWidth > window.innerWidth'),'mobile horizontal overflow'
  assert errors==[],errors
  print('PASS: 8 formats, subtype pages, inputs, page interactions, effects, recipes, revisions, QA, JSON download, mobile; JS errors=0')
  await browser.close()

if __name__=='__main__': asyncio.run(run())
