param(
  [string]$BaseUrl = 'http://127.0.0.1:4173'
)

$ErrorActionPreference = 'Stop'

$chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$root = (Resolve-Path (Split-Path -Parent $PSScriptRoot)).Path
$output = Join-Path $root 'runtime-validation\regression-pass'
$frameDirectory = Join-Path $output ('recording-frames-' + (Get-Date -Format 'yyyyMMddHHmmssfff'))
$profile = Join-Path $env:TEMP ('portfolio-regression-' + (Get-Date -Format 'yyyyMMddHHmmssfff'))
$process = $null
$socket = $null
$script:messageId = 0
$script:frameNumber = 0
$script:results = [System.Collections.Generic.List[object]]::new()

New-Item -ItemType Directory -Force -Path $output, $frameDirectory | Out-Null

function Receive-Message {
  $buffer = New-Object byte[] 1048576
  $stream = [System.IO.MemoryStream]::new()
  do {
    $segment = [System.ArraySegment[byte]]::new($buffer)
    $received = $socket.ReceiveAsync($segment, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
    if ($received.Count -gt 0) { $stream.Write($buffer, 0, $received.Count) }
  } until ($received.EndOfMessage)
  $text = [System.Text.Encoding]::UTF8.GetString($stream.ToArray())
  $stream.Dispose()
  return $text
}

function Invoke-Cdp([string]$method, $params = $null) {
  $script:messageId++
  $id = $script:messageId
  $payload = @{ id = $id; method = $method }
  if ($null -ne $params) { $payload.params = $params }
  $bytes = [System.Text.Encoding]::UTF8.GetBytes(($payload | ConvertTo-Json -Depth 30 -Compress))
  $segment = [System.ArraySegment[byte]]::new($bytes)
  $null = $socket.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
  do { $response = (Receive-Message) | ConvertFrom-Json } until ($response.id -eq $id)
  if ($response.error) { throw "$method failed: $($response.error.message)" }
  return $response.result
}

function Evaluate([string]$expression) {
  $result = Invoke-Cdp 'Runtime.evaluate' @{
    expression = $expression
    returnByValue = $true
    awaitPromise = $true
  }
  return $result.result.value
}

function Get-Json([string]$expression) {
  for ($attempt = 0; $attempt -lt 12; $attempt++) {
    try {
      $json = Evaluate "JSON.stringify($expression)"
      if ($null -ne $json) { return $json | ConvertFrom-Json }
    } catch {
      if ($attempt -eq 11) { throw }
    }
    Start-Sleep -Milliseconds 50
  }
  throw "The browser returned no JSON value for: $expression"
}

function Wait-For([string]$expression, [int]$attempts = 160) {
  for ($i = 0; $i -lt $attempts; $i++) {
    if (Evaluate $expression) {
      if ($expression -match '^location\.pathname' -and -not (Evaluate 'document.readyState === "complete"')) {
        Start-Sleep -Milliseconds 50
        continue
      }
      return
    }
    Start-Sleep -Milliseconds 50
  }
  $currentUrl = try { Evaluate 'location.href' } catch { '[execution context unavailable]' }
  throw "Condition timed out: $expression (current URL: $currentUrl)"
}

function Navigate([string]$path) {
  $url = if ($path -match '^https?://|^about:') { $path } else { "$BaseUrl$path" }
  $null = Invoke-Cdp 'Page.navigate' @{ url = $url }
  Wait-For 'document.readyState === "complete"'
}

function Set-Viewport([int]$width, [int]$height, [bool]$mobile = $false) {
  $null = Invoke-Cdp 'Emulation.setDeviceMetricsOverride' @{
    width = $width
    height = $height
    screenWidth = $width
    screenHeight = $height
    deviceScaleFactor = 1
    mobile = $mobile
  }
}

function Save-Png([string]$path) {
  $capture = Invoke-Cdp 'Page.captureScreenshot' @{
    format = 'png'
    fromSurface = $true
    captureBeyondViewport = $false
  }
  [System.IO.File]::WriteAllBytes($path, [Convert]::FromBase64String($capture.data))
}

function Screenshot([string]$name) {
  $path = Join-Path $output $name
  Save-Png $path
  return $path
}

function Record-Frame {
  $script:frameNumber++
  $path = Join-Path $frameDirectory ('frame-{0:D4}.png' -f $script:frameNumber)
  Save-Png $path
}

function Record-Hold([int]$count = 3, [int]$delay = 70) {
  for ($i = 0; $i -lt $count; $i++) {
    Record-Frame
    Start-Sleep -Milliseconds $delay
  }
}

function Click([string]$selector) {
  $quoted = $selector | ConvertTo-Json -Compress
  $null = Evaluate "document.querySelector($quoted).click();true"
}

function Assert-State([bool]$condition, [string]$name, $details = $null) {
  $script:results.Add([ordered]@{
    name = $name
    passed = $condition
    details = $details
  })
}

function Get-Rect([string]$selector) {
  $quoted = $selector | ConvertTo-Json -Compress
  return Get-Json "(()=>{const r=document.querySelector($quoted).getBoundingClientRect();return{x:r.x,y:r.y,width:r.width,height:r.height}})()"
}

function Dispatch-MouseDrag([string]$selector, [double]$fromRatio, [double]$toRatio, [bool]$record = $false) {
  $rect = Get-Rect $selector
  $startX = $rect.x + $rect.width * $fromRatio
  $endX = $rect.x + $rect.width * $toRatio
  $y = $rect.y + [Math]::Min($rect.height * 0.55, $rect.height - 12)
  $null = Invoke-Cdp 'Input.dispatchMouseEvent' @{ type = 'mouseMoved'; x = $startX; y = $y }
  $null = Invoke-Cdp 'Input.dispatchMouseEvent' @{ type = 'mousePressed'; x = $startX; y = $y; button = 'left'; buttons = 1; clickCount = 1 }
  for ($i = 1; $i -le 6; $i++) {
    $x = $startX + (($endX - $startX) * $i / 6)
    $null = Invoke-Cdp 'Input.dispatchMouseEvent' @{ type = 'mouseMoved'; x = $x; y = $y; button = 'left'; buttons = 1 }
    if ($record) { Record-Frame }
    Start-Sleep -Milliseconds 35
  }
  $null = Invoke-Cdp 'Input.dispatchMouseEvent' @{ type = 'mouseReleased'; x = $endX; y = $y; button = 'left'; buttons = 0; clickCount = 1 }
}

function Dispatch-TouchGesture([string]$selector, [double]$deltaX, [double]$deltaY) {
  $rect = Get-Rect $selector
  $startX = $rect.x + $rect.width * 0.68
  $startY = $rect.y + [Math]::Min($rect.height * 0.48, $rect.height - 18)
  $point = @{ x = $startX; y = $startY; radiusX = 2; radiusY = 2; force = 1; id = 1 }
  $null = Invoke-Cdp 'Input.dispatchTouchEvent' @{ type = 'touchStart'; touchPoints = @($point) }
  for ($i = 1; $i -le 5; $i++) {
    $move = @{
      x = $startX + ($deltaX * $i / 5)
      y = $startY + ($deltaY * $i / 5)
      radiusX = 2
      radiusY = 2
      force = 1
      id = 1
    }
    $null = Invoke-Cdp 'Input.dispatchTouchEvent' @{ type = 'touchMove'; touchPoints = @($move) }
    Start-Sleep -Milliseconds 35
  }
  $null = Invoke-Cdp 'Input.dispatchTouchEvent' @{ type = 'touchEnd'; touchPoints = @() }
}

function Dispatch-TouchPointerGesture([string]$selector, [double]$deltaX, [double]$deltaY) {
  $quoted = $selector | ConvertTo-Json -Compress
  $null = Evaluate @"
(()=>{
  const target=document.querySelector($quoted);
  const rect=target.getBoundingClientRect();
  const startX=rect.x+rect.width*.68;
  const startY=rect.y+Math.min(rect.height*.48,rect.height-18);
  const emit=(type,x,y,buttons)=>target.dispatchEvent(new PointerEvent(type,{
    bubbles:true,cancelable:true,composed:true,pointerId:97,pointerType:"touch",
    isPrimary:true,button:0,buttons:buttons,clientX:x,clientY:y
  }));
  emit("pointerdown",startX,startY,1);
  for(let step=1;step<=5;step+=1){
    emit("pointermove",startX+($deltaX*step/5),startY+($deltaY*step/5),1);
  }
  emit("pointerup",startX+$deltaX,startY+$deltaY,0);
  return true;
})()
"@
}

function Load-HomeSection([string]$selector, [string]$readyExpression) {
  Navigate '/'
  Write-Output 'PHASE fresh-home'
  Wait-For '!document.documentElement.classList.contains("loader-pending")'
  $quoted = $selector | ConvertTo-Json -Compress
  $null = Evaluate "document.querySelector($quoted).scrollIntoView({block:'center'});true"
  Wait-For $readyExpression
  Start-Sleep -Milliseconds 850
}

try {
  $null = Invoke-WebRequest -UseBasicParsing "$BaseUrl/" -TimeoutSec 3
  $process = Start-Process -FilePath $chrome -ArgumentList @(
    '--headless=new',
    '--disable-gpu',
    '--disable-background-timer-throttling',
    '--disable-backgrounding-occluded-windows',
    '--disable-renderer-backgrounding',
    '--no-first-run',
    '--remote-debugging-port=0',
    '--remote-allow-origins=*',
    "--user-data-dir=$profile",
    'about:blank'
  ) -PassThru -WindowStyle Hidden

  $portFile = Join-Path $profile 'DevToolsActivePort'
  $deadline = (Get-Date).AddSeconds(15)
  while (-not (Test-Path $portFile) -and (Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 50
  }
  if (-not (Test-Path $portFile)) { throw 'Chrome DevTools endpoint did not start.' }

  $port = [int](Get-Content $portFile | Select-Object -First 1)
  $targets = Invoke-RestMethod "http://127.0.0.1:$port/json/list"
  $target = $targets | Where-Object { $_.type -eq 'page' } | Select-Object -First 1
  $socket = [System.Net.WebSockets.ClientWebSocket]::new()
  $null = $socket.ConnectAsync([Uri]$target.webSocketDebuggerUrl, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
  $null = Invoke-Cdp 'Page.enable'
  $null = Invoke-Cdp 'Runtime.enable'
  $null = Invoke-Cdp 'Page.addScriptToEvaluateOnNewDocument' @{
    source = 'window.__regressionErrors=[];addEventListener("error",e=>window.__regressionErrors.push(String(e.message||e.error)));addEventListener("unhandledrejection",e=>window.__regressionErrors.push(String(e.reason)));'
  }

  Set-Viewport 1440 900
  Navigate '/'
  Wait-For 'document.documentElement.classList.contains("loader-pending") && !document.querySelector(".loader").classList.contains("is-black-flash")'
  $freshLoader = Get-Json '(()=>{const l=document.querySelector(".loader");return{present:Boolean(l),display:getComputedStyle(l).display,background:getComputedStyle(l).backgroundColor,pending:document.documentElement.classList.contains("loader-pending")}})()'
  Assert-State ($freshLoader.present -and $freshLoader.display -ne 'none' -and $freshLoader.background -eq 'rgb(255, 255, 255)') 'Fresh homepage shows the original white loader' $freshLoader
  Wait-For '!document.documentElement.classList.contains("loader-pending")'

  Click '.project-row--manmatic > .project-row__link'
  Wait-For 'location.pathname === "/projects/manmatic/"'
  Write-Output 'PHASE manmatic-entry'
  $manmaticEntry = Get-Json '({loaderCount:document.querySelectorAll(".loader").length,pending:document.documentElement.classList.contains("loader-pending"),mainVisible:getComputedStyle(document.querySelector("main")).visibility!=="hidden"})'
  Assert-State ($manmaticEntry.loaderCount -eq 0 -and -not $manmaticEntry.pending -and $manmaticEntry.mainVisible) 'Homepage to ManMaTIC is immediate and loader-free' $manmaticEntry
  Record-Hold 3

  Click '.site-header__name'
  Wait-For 'location.pathname === "/"'
  Write-Output 'PHASE manmatic-exit'
  Start-Sleep -Milliseconds 45
  for ($i = 0; $i -lt 10; $i++) {
    Record-Frame
    if ($i -eq 2) { $transitionShot = Screenshot '01-manmatic-to-white-home.png' }
    Start-Sleep -Milliseconds 65
  }
  $exitState = Get-Json '(()=>{const t=document.querySelector(".manmatic-transition");return{homeBackground:getComputedStyle(document.body).backgroundColor,loaderDisplay:getComputedStyle(document.querySelector(".loader")).display,transitionBackground:getComputedStyle(t).backgroundColor,active:t.classList.contains("is-route-glitch"),beforeHeight:getComputedStyle(t,"::before").height,afterHeight:getComputedStyle(t,"::after").height}})()'
  Assert-State ($exitState.homeBackground -eq 'rgb(255, 255, 255)' -and $exitState.loaderDisplay -eq 'none' -and $exitState.transitionBackground -eq 'rgba(0, 0, 0, 0)') 'ManMaTIC exit reveals the white homepage under transparent glitch bands' $exitState

  $navigationCases = @(
    @{ name = 'Shila'; selector = '.project-row--shila > .project-row__link'; path = '/projects/shila/' },
    @{ name = 'Dabouq'; selector = '.project-row--dabouq > .project-row__link'; path = '/projects/dabouq/' },
    @{ name = 'ELMA — TREE UNIT'; selector = '.project-row--elma > .project-row__link'; path = '/projects/concrete-fatigue/' }
  )
  foreach ($case in $navigationCases) {
    Write-Output "PHASE route-$($case.name)"
    Navigate '/'
    Click $case.selector
    Wait-For "location.pathname === '$($case.path)'"
    $state = Get-Json '({loaderCount:document.querySelectorAll(".loader").length,pending:document.documentElement.classList.contains("loader-pending"),mainVisible:Boolean(document.querySelector("main"))})'
    Assert-State ($state.loaderCount -eq 0 -and -not $state.pending -and $state.mainVisible) "Homepage to $($case.name) is loader-free" $state
    Click '.site-header__name'
    Wait-For 'location.pathname === "/"'
  }

  Navigate '/projects/shila/'
  Write-Output 'PHASE project-to-project'
  Click 'a[href="/projects/manmatic/"]'
  Wait-For 'location.pathname === "/projects/manmatic/"'
  $projectToProject = Get-Json '({loaderCount:document.querySelectorAll(".loader").length,pending:document.documentElement.classList.contains("loader-pending")})'
  Assert-State ($projectToProject.loaderCount -eq 0 -and -not $projectToProject.pending) 'Project-to-project navigation is loader-free' $projectToProject

  Navigate '/'
  Write-Output 'PHASE browser-history'
  Click '.project-row--elma > .project-row__link'
  Wait-For 'location.pathname === "/projects/concrete-fatigue/"'
  $null = Evaluate 'history.back();true'
  Wait-For 'location.pathname === "/"'
  Start-Sleep -Milliseconds 120
  $back = Get-Json '({routeGlitch:document.querySelector(".manmatic-transition")?.classList.contains("is-route-glitch")||false,listenerReady:document.documentElement.dataset.projectNavigationReady,loaderDisplay:getComputedStyle(document.querySelector(".loader")).display})'
  $null = Evaluate 'history.forward();true'
  Wait-For 'location.pathname === "/projects/concrete-fatigue/"'
  Start-Sleep -Milliseconds 120
  $forward = Get-Json '({routeGlitch:document.querySelector(".manmatic-transition")?.classList.contains("is-route-glitch")||false,listenerReady:document.documentElement.dataset.projectNavigationReady,loaderCount:document.querySelectorAll(".loader").length})'
  Assert-State ($back.routeGlitch -and $back.listenerReady -eq 'true' -and $back.loaderDisplay -eq 'none') 'Browser Back restores one clean homepage transition' $back
  Assert-State ($forward.routeGlitch -and $forward.listenerReady -eq 'true' -and $forward.loaderCount -eq 0) 'Browser Forward restores one clean project transition' $forward

  $detailRoutes = @(
    '/projects/manmatic/',
    '/projects/shila/',
    '/projects/dabouq/',
    '/projects/concrete-fatigue/',
    '/projects/protocol-port/',
    '/visuals/architecture-of-elsewhere/',
    '/visuals/drawn-out-of-red/',
    '/visuals/stone-by-moonlight/',
    '/visuals/the-mechanics-of-becoming/',
    '/visuals/the-last-room-before-tomorrow/'
  )
  foreach ($route in $detailRoutes) {
    Write-Output "PHASE direct-$route"
    Navigate $route
    $direct = Get-Json '({loaderCount:document.querySelectorAll(".loader").length,pending:document.documentElement.classList.contains("loader-pending"),visible:Boolean(document.querySelector("main"))})'
    Assert-State ($direct.loaderCount -eq 0 -and -not $direct.pending -and $direct.visible) "Direct route is loader-free: $route" $direct
  }

  $viewports = @(
    @{ width = 1440; height = 900; mobile = $false },
    @{ width = 1024; height = 1366; mobile = $true },
    @{ width = 820; height = 1180; mobile = $true },
    @{ width = 768; height = 1024; mobile = $true },
    @{ width = 430; height = 932; mobile = $true },
    @{ width = 390; height = 844; mobile = $true },
    @{ width = 360; height = 800; mobile = $true }
  )
  $shilaViewports = @()
  foreach ($viewport in $viewports) {
    Write-Output "PHASE shila-$($viewport.width)"
    Set-Viewport $viewport.width $viewport.height $viewport.mobile
    Navigate '/projects/shila/'
    Wait-For 'document.querySelector(".shila-board__hero img").complete'
    $null = Evaluate 'document.querySelectorAll("[data-shila-reveal]").forEach(n=>n.classList.add("is-visible"));true'
    Start-Sleep -Milliseconds 850
    $alignment = Get-Json "(()=>{const h=document.querySelector('.shila-board__hero').getBoundingClientRect(),i=document.querySelector('.shila-board__inner').getBoundingClientRect(),img=document.querySelector('.shila-board__hero img');return{width:$($viewport.width),height:$($viewport.height),heroLeft:h.left,innerLeft:i.left,heroRight:h.right,innerRight:i.right,leftDelta:Math.abs(h.left-i.left),rightDelta:Math.abs(h.right-i.right),overflow:document.documentElement.scrollWidth>document.documentElement.clientWidth,naturalRatio:img.naturalWidth/img.naturalHeight,renderedRatio:img.getBoundingClientRect().width/img.getBoundingClientRect().height}})()"
    $shilaViewports += $alignment
    Assert-State ($alignment.leftDelta -lt 1 -and $alignment.rightDelta -lt 1 -and -not $alignment.overflow -and [Math]::Abs($alignment.naturalRatio - $alignment.renderedRatio) -lt 0.01) "Shila hero aligns at $($viewport.width)x$($viewport.height)" $alignment
    if ($viewport.width -eq 1440) { $shilaDesktop = Screenshot '02-shila-desktop-1440.png' }
    if ($viewport.width -eq 820) { $shilaTablet = Screenshot '03-shila-tablet-820.png' }
    if ($viewport.width -eq 390) { $shilaMobile = Screenshot '04-shila-mobile-390.png' }
  }

  $manmaticViewports = @(
    @{ width = 1440; height = 900; mobile = $false; shot = '05-manmatic-desktop-1440.png' },
    @{ width = 820; height = 1180; mobile = $true; shot = '06-manmatic-tablet-820.png' },
    @{ width = 390; height = 844; mobile = $true; shot = '07-manmatic-mobile-390.png' }
  )
  $manmaticStates = @()
  foreach ($viewport in $manmaticViewports) {
    Write-Output "PHASE manmatic-$($viewport.width)"
    Set-Viewport $viewport.width $viewport.height $viewport.mobile
    Navigate '/projects/manmatic/'
    $null = Evaluate 'document.querySelector(".mm-diagram--wide").scrollIntoView({block:"center"});document.querySelectorAll("[data-image-reveal]").forEach(n=>n.classList.add("is-visible"));true'
    Wait-For 'document.querySelector(".mm-diagram--wide img").complete'
    Start-Sleep -Milliseconds 850
    $surface = Get-Json "(()=>{const img=document.querySelector('.mm-diagram--wide img'),wrap=img.closest('.mm-diagram');return{width:$($viewport.width),body:getComputedStyle(document.body).backgroundColor,imageBackground:getComputedStyle(img).backgroundColor,wrapperBackground:getComputedStyle(wrap).backgroundColor,opacity:getComputedStyle(img).opacity,filter:getComputedStyle(img).filter,mixBlend:getComputedStyle(img).mixBlendMode,overflow:document.documentElement.scrollWidth>document.documentElement.clientWidth}})()"
    $manmaticStates += $surface
    Assert-State ($surface.body -eq 'rgb(39, 39, 39)' -and $surface.imageBackground -eq 'rgba(0, 0, 0, 0)' -and $surface.wrapperBackground -eq 'rgba(0, 0, 0, 0)' -and $surface.opacity -eq '1' -and $surface.filter -eq 'none' -and $surface.mixBlend -eq 'normal' -and -not $surface.overflow) "ManMaTIC diagrams integrate at $($viewport.width)px" $surface
    $null = Screenshot $viewport.shot
  }

  Set-Viewport 1440 900
  Write-Output 'PHASE visuals-desktop'
  Load-HomeSection '#visual-studies' 'document.querySelector("[data-visual-slider]")?.dataset.visualInitialized === "true"'
  $visualStart = [int](Evaluate 'document.querySelector("[data-visual-current]").textContent')
  Record-Hold 3
  Dispatch-MouseDrag '[data-visual-viewport]' .76 .22 $true
  Start-Sleep -Milliseconds 120
  Record-Hold 3
  $visualMouse = [int](Evaluate 'document.querySelector("[data-visual-current]").textContent')
  Click '[data-visual-next]'
  $visualButton = [int](Evaluate 'document.querySelector("[data-visual-current]").textContent')
  $null = Evaluate 'document.querySelector("[data-visual-slider]").focus();true'
  $null = Invoke-Cdp 'Input.dispatchKeyEvent' @{ type = 'keyDown'; key = 'ArrowRight'; code = 'ArrowRight'; windowsVirtualKeyCode = 39 }
  $null = Invoke-Cdp 'Input.dispatchKeyEvent' @{ type = 'keyUp'; key = 'ArrowRight'; code = 'ArrowRight'; windowsVirtualKeyCode = 39 }
  $visualKeyboard = [int](Evaluate 'document.querySelector("[data-visual-current]").textContent')
  Wait-For 'document.querySelector(".visual-slide.is-active img")?.complete && document.querySelector(".visual-slide.is-active img")?.naturalWidth > 0'
  Start-Sleep -Milliseconds 820
  $visualDesktop = Screenshot '08-visuals-desktop.png'
  Assert-State ($visualMouse -eq (($visualStart % 5) + 1)) 'Visuals mouse drag advances exactly one slide' @{ start = $visualStart; end = $visualMouse }
  Assert-State ($visualButton -eq (($visualMouse % 5) + 1)) 'Visuals Next button advances exactly one slide' @{ start = $visualMouse; end = $visualButton }
  Assert-State ($visualKeyboard -eq (($visualButton % 5) + 1)) 'Visuals keyboard arrow advances exactly one slide' @{ start = $visualButton; end = $visualKeyboard }

  $null = Invoke-Cdp 'Emulation.setTouchEmulationEnabled' @{ enabled = $true; maxTouchPoints = 5 }
  Set-Viewport 390 844 $true
  Write-Output 'PHASE visuals-touch'
  Load-HomeSection '#visual-studies' 'document.querySelector("[data-visual-slider]")?.dataset.visualInitialized === "true"'
  $touchStart = [int](Evaluate 'document.querySelector("[data-visual-current]").textContent')
  Dispatch-TouchPointerGesture '[data-visual-viewport]' -210 4
  Start-Sleep -Milliseconds 820
  $touchEnd = [int](Evaluate 'document.querySelector("[data-visual-current]").textContent')
  $pageBefore = [double](Evaluate 'scrollY')
  Dispatch-TouchGesture '[data-visual-viewport]' 3 -180
  Start-Sleep -Milliseconds 180
  $pageAfter = [double](Evaluate 'scrollY')
  Wait-For 'document.querySelector(".visual-slide.is-active img")?.complete && document.querySelector(".visual-slide.is-active img")?.naturalWidth > 0'
  $visualMobile = Screenshot '09-visuals-mobile.png'
  Assert-State ($touchEnd -eq (($touchStart % 5) + 1)) 'Visuals touch swipe advances exactly one slide' @{ start = $touchStart; end = $touchEnd }
  Assert-State ([Math]::Abs($pageAfter - $pageBefore) -gt 20) 'Vertical touch over Visuals scrolls the page' @{ before = $pageBefore; after = $pageAfter }

  Set-Viewport 1440 900
  Write-Output 'PHASE computation-desktop'
  Load-HomeSection '#computation' 'document.querySelector("[data-computational-rail]")?.dataset.computationalRailInitialized === "true"'
  $railStart = [double](Evaluate 'document.querySelector("[data-computational-rail]").scrollLeft')
  Record-Hold 3
  Dispatch-MouseDrag '[data-computational-rail]' .8 .18 $true
  Start-Sleep -Milliseconds 100
  Record-Hold 3
  $railMouse = [double](Evaluate 'document.querySelector("[data-computational-rail]").scrollLeft')
  $railRect = Get-Rect '[data-computational-rail]'
  $null = Invoke-Cdp 'Input.dispatchMouseEvent' @{ type = 'mouseWheel'; x = $railRect.x + $railRect.width / 2; y = $railRect.y + $railRect.height / 2; deltaX = 420; deltaY = 0 }
  Start-Sleep -Milliseconds 100
  $railWheel = [double](Evaluate 'document.querySelector("[data-computational-rail]").scrollLeft')
  $null = Evaluate 'document.querySelector("[data-computational-rail]").scrollLeft=1e9;true'
  Start-Sleep -Milliseconds 180
  $railEnd = Get-Json '(()=>{const r=document.querySelector("[data-computational-rail]"),v=document.querySelector("[data-computation-video]");return{left:r.scrollLeft,limit:r.scrollWidth-r.clientWidth,dragging:r.classList.contains("is-dragging"),videoPaused:v.paused,videoHydrated:v.dataset.sourceHydrated}})()'
  $computationDesktop = Screenshot '10-computation-desktop.png'
  Assert-State ($railMouse -gt $railStart + 40 -and $railWheel -gt $railMouse) 'Computational rail supports mouse drag and horizontal trackpad input' @{ start = $railStart; afterDrag = $railMouse; afterWheel = $railWheel }
  Assert-State ([Math]::Abs($railEnd.left - $railEnd.limit) -lt 2 -and -not $railEnd.dragging) 'Computational rail reaches and stops at its final panel' $railEnd

  Set-Viewport 820 1180 $true
  Write-Output 'PHASE computation-touch'
  Load-HomeSection '#computation' 'document.querySelector("[data-computational-rail]")?.dataset.computationalRailInitialized === "true"'
  $railTouchStart = [double](Evaluate 'document.querySelector("[data-computational-rail]").scrollLeft')
  Dispatch-TouchPointerGesture '[data-computational-rail]' -260 4
  Start-Sleep -Milliseconds 180
  $railTouchEnd = [double](Evaluate 'document.querySelector("[data-computational-rail]").scrollLeft')
  $railPageBefore = [double](Evaluate 'scrollY')
  Dispatch-TouchGesture '[data-computational-rail]' 2 -190
  Start-Sleep -Milliseconds 180
  $railPageAfter = [double](Evaluate 'scrollY')
  $ratioBefore = Get-Json '(()=>{const r=document.querySelector("[data-computational-rail]");r.scrollLeft=(r.scrollWidth-r.clientWidth)*.6;return{left:r.scrollLeft,limit:r.scrollWidth-r.clientWidth}})()'
  Start-Sleep -Milliseconds 120
  Set-Viewport 1024 1366 $true
  Start-Sleep -Milliseconds 220
  $ratioAfter = Get-Json '(()=>{const r=document.querySelector("[data-computational-rail]");return{left:r.scrollLeft,limit:r.scrollWidth-r.clientWidth,dragging:r.classList.contains("is-dragging")}})()'
  $computationTablet = Screenshot '11-computation-tablet.png'
  Assert-State ($railTouchEnd -gt $railTouchStart + 40) 'Computational rail supports touch swipe' @{ start = $railTouchStart; end = $railTouchEnd }
  Assert-State ([Math]::Abs($railPageAfter - $railPageBefore) -gt 20 -and -not $ratioAfter.dragging) 'Vertical touch over Computational Design scrolls the page and clears drag state' @{ before = $railPageBefore; after = $railPageAfter; dragging = $ratioAfter.dragging }
  $beforeRatio = $ratioBefore.left / [Math]::Max(1, $ratioBefore.limit)
  $afterRatio = $ratioAfter.left / [Math]::Max(1, $ratioAfter.limit)
  Assert-State ([Math]::Abs($beforeRatio - $afterRatio) -lt 0.04) 'Computational rail preserves its active position after resize' @{ before = $beforeRatio; after = $afterRatio }

  $null = Invoke-Cdp 'Emulation.setEmulatedMedia' @{ features = @(@{ name = 'prefers-reduced-motion'; value = 'reduce' }) }
  Navigate '/'
  Click '.project-row--manmatic > .project-row__link'
  Wait-For 'location.pathname === "/projects/manmatic/"'
  $reduced = Get-Json '({loaderCount:document.querySelectorAll(".loader").length,routeGlitch:document.querySelector(".manmatic-transition")?.classList.contains("is-route-glitch")||false})'
  Assert-State ($reduced.loaderCount -eq 0 -and -not $reduced.routeGlitch) 'Reduced motion skips internal route animation without adding a loader' $reduced
  $null = Invoke-Cdp 'Emulation.setEmulatedMedia' @{ features = @() }

  $errors = Get-Json 'window.__regressionErrors'
  Assert-State ($errors.Count -eq 0) 'No uncaught browser errors' $errors

  $ffmpeg = (Get-Command ffmpeg -ErrorAction Stop).Source
  $recording = Join-Path $output 'portfolio-regression-recording.mp4'
  & $ffmpeg -hide_banner -loglevel error -y -framerate 8 -i (Join-Path $frameDirectory 'frame-%04d.png') -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -movflags +faststart $recording
  if ($LASTEXITCODE -ne 0) { throw 'FFmpeg could not encode the regression recording.' }
  if (Test-Path -LiteralPath $frameDirectory) {
    Remove-Item -LiteralPath $frameDirectory -Recurse -Force
  }

  $report = [ordered]@{
    passed = @($script:results | Where-Object { $_.passed }).Count
    failed = @($script:results | Where-Object { -not $_.passed }).Count
    tests = $script:results
    shilaViewports = $shilaViewports
    manmaticViewports = $manmaticStates
    recording = $recording
    screenshots = @(
      $transitionShot,
      $shilaDesktop,
      $shilaTablet,
      $shilaMobile,
      (Join-Path $output '05-manmatic-desktop-1440.png'),
      (Join-Path $output '06-manmatic-tablet-820.png'),
      (Join-Path $output '07-manmatic-mobile-390.png'),
      $visualDesktop,
      $visualMobile,
      $computationDesktop,
      $computationTablet
    )
  }
  $report | ConvertTo-Json -Depth 12 | Set-Content -Encoding utf8 (Join-Path $output 'interaction-verification.json')
  $report | ConvertTo-Json -Depth 12

  if ($report.failed -gt 0) {
    throw "$($report.failed) regression checks failed. See interaction-verification.json."
  }
}
finally {
  if ($socket) {
    try { $null = Invoke-Cdp 'Browser.close' } catch {}
    $socket.Dispose()
  }
  if ($process -and -not $process.HasExited) {
    Stop-Process -Id $process.Id -Force
  }
}
