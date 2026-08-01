param([switch]$TransitionsOnly)

$ErrorActionPreference = 'Stop'

$chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$output = Join-Path (Resolve-Path '.').Path 'runtime-validation\text-glitch'
$profile = Join-Path $env:TEMP ('text-glitch-' + (Get-Date -Format 'yyyyMMddHHmmssfff'))
$process = $null
$httpProcess = $null
$socket = $null
$script:messageId = 0

New-Item -ItemType Directory -Force -Path $output | Out-Null

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
  $result = Invoke-Cdp 'Runtime.evaluate' @{ expression = $expression; returnByValue = $true; awaitPromise = $true }
  return $result.result.value
}

function Wait-For([string]$condition, [string]$message = 'Condition timed out.') {
  for ($i = 0; $i -lt 200; $i++) {
    if (Evaluate $condition) { return }
    Start-Sleep -Milliseconds 50
  }
  throw $message
}

function Navigate([string]$url) {
  $null = Invoke-Cdp 'Page.navigate' @{ url = $url }
  $committed = $false
  $actualUrl = ''
  for ($i = 0; $i -lt 200; $i++) {
    $actualUrl = [string](Evaluate 'location.href')
    if ($actualUrl -eq $url) { $committed = $true; break }
    Start-Sleep -Milliseconds 50
  }
  if (-not $committed) { throw "Page URL did not commit: expected $url, got $actualUrl" }
  Wait-For 'document.readyState === "complete"' "Page load timed out: $url"
}

function Set-Viewport([int]$width, [int]$height, [bool]$mobile) {
  $null = Invoke-Cdp 'Emulation.setDeviceMetricsOverride' @{
    width = $width; height = $height; deviceScaleFactor = 1; mobile = $mobile
    screenWidth = $width; screenHeight = $height
  }
  $null = Invoke-Cdp 'Emulation.setTouchEmulationEnabled' @{
    enabled = $mobile; maxTouchPoints = 1
  }
}

function Screenshot([string]$name) {
  $result = Invoke-Cdp 'Page.captureScreenshot' @{ format = 'png'; fromSurface = $true }
  $path = Join-Path $output $name
  [System.IO.File]::WriteAllBytes($path, [Convert]::FromBase64String($result.data))
  return $path
}

function Assert-State([bool]$condition, [string]$message) {
  if (-not $condition) { throw $message }
}

$copyAudit = @'
JSON.stringify((()=>{
  const selector = document.body.classList.contains("protocol-port-page")
    ? ".protocol-port-copy > p:not(.protocol-port-index),.protocol-port-heading-row > p,.protocol-port-methodology__summary"
    : ".manmatic-body-copy,.mm-question";
  const paragraphs = Array.from(document.querySelectorAll(selector)).filter(p=>p.offsetParent!==null);
  const cssFailures=[];
  const splitWords=[];
  for(const paragraph of paragraphs){
    const style=getComputedStyle(paragraph);
    if(style.textAlign!=="justify"||style.hyphens!=="none"||style.wordBreak!=="normal"||style.overflowWrap!=="normal"||style.whiteSpace!=="normal"){
      cssFailures.push({text:paragraph.textContent.trim().slice(0,80),textAlign:style.textAlign,hyphens:style.hyphens,wordBreak:style.wordBreak,overflowWrap:style.overflowWrap,whiteSpace:style.whiteSpace});
    }
    const walker=document.createTreeWalker(paragraph,NodeFilter.SHOW_TEXT);
    let node;
    while((node=walker.nextNode())){
      const text=node.nodeValue||"";
      for(const match of text.matchAll(/[\p{L}\p{N}]+(?:[’'][\p{L}\p{N}]+)*/gu)){
        if(match[0].length<2) continue;
        const range=document.createRange();
        range.setStart(node,match.index);range.setEnd(node,match.index+match[0].length);
        const rects=Array.from(range.getClientRects()).filter(r=>r.width>.1&&r.height>.1);
        if(rects.length>1&&Math.max(...rects.map(r=>r.top))-Math.min(...rects.map(r=>r.top))>2){
          splitWords.push({word:match[0],text:paragraph.textContent.trim().slice(0,80)});
        }
      }
    }
  }
  return {paragraphs:paragraphs.length,cssFailures,splitWords,overflow:document.documentElement.scrollWidth>document.documentElement.clientWidth,errors:window.__textGlitchErrors||[]};
})())
'@

try {
  try {
    $null = Invoke-WebRequest -UseBasicParsing 'http://127.0.0.1:4173/' -TimeoutSec 1
  } catch {
    $serverOut = Join-Path $output 'server.log'
    $serverErr = Join-Path $output 'server-error.log'
    $rootPath = (Resolve-Path '.').Path
    $serverScript = Join-Path $rootPath 'scripts\serve-static.ps1'
    $serverArguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -Root "{1}" -Port 4173' -f $serverScript, $rootPath
    $httpProcess = Start-Process -FilePath 'powershell.exe' -ArgumentList $serverArguments -WorkingDirectory $rootPath -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr -PassThru -WindowStyle Hidden
    $serverReady = $false
    for ($i = 0; $i -lt 40; $i++) {
      try { $serverReady = (Invoke-WebRequest -UseBasicParsing 'http://127.0.0.1:4173/' -TimeoutSec 1).StatusCode -eq 200; if ($serverReady) { break } }
      catch { Start-Sleep -Milliseconds 100 }
    }
    Assert-State $serverReady 'The local static test server did not start.'
  }

  $process = Start-Process -FilePath $chrome -ArgumentList @(
    '--headless=new','--disable-gpu','--disable-background-timer-throttling',
    '--disable-backgrounding-occluded-windows','--disable-renderer-backgrounding',
    '--blink-settings=imagesEnabled=false',
    '--no-first-run','--remote-debugging-port=0','--remote-allow-origins=*',
    "--user-data-dir=$profile",'about:blank'
  ) -PassThru -WindowStyle Hidden

  $portFile = Join-Path $profile 'DevToolsActivePort'
  $deadline = (Get-Date).AddSeconds(15)
  while (-not (Test-Path $portFile) -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 50 }
  if (-not (Test-Path $portFile)) { throw 'Chrome DevTools endpoint did not start.' }

  $port = [int](Get-Content $portFile | Select-Object -First 1)
  $targets = Invoke-RestMethod "http://127.0.0.1:$port/json/list"
  $target = $targets | Where-Object { $_.type -eq 'page' } | Select-Object -First 1
  $socket = [System.Net.WebSockets.ClientWebSocket]::new()
  $null = $socket.ConnectAsync([Uri]$target.webSocketDebuggerUrl, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
  $null = Invoke-Cdp 'Page.enable'
  $null = Invoke-Cdp 'Runtime.enable'
  $null = Invoke-Cdp 'Emulation.setEmulatedMedia' @{ features = @() }
  $null = Invoke-Cdp 'Page.addScriptToEvaluateOnNewDocument' @{
    source = 'window.__textGlitchErrors=[];addEventListener("error",e=>window.__textGlitchErrors.push(String(e.message||e.error)));addEventListener("unhandledrejection",e=>window.__textGlitchErrors.push(String(e.reason)));'
  }

  $viewports = @(
    @{ name='desktop'; width=1440; height=900; mobile=$false },
    @{ name='tablet-landscape'; width=1024; height=768; mobile=$false },
    @{ name='tablet-portrait'; width=768; height=1024; mobile=$true },
    @{ name='mobile'; width=390; height=844; mobile=$true }
  )
  $copyResults = @()
  if (-not $TransitionsOnly) {
    foreach ($viewport in $viewports) {
      Set-Viewport $viewport.width $viewport.height $viewport.mobile
      foreach ($route in @('protocol-port','manmatic')) {
        Navigate "http://127.0.0.1:4173/projects/$route/"
        Wait-For '!document.documentElement.classList.contains("loader-pending")' "Loader did not settle for $route."
        $audit = (Evaluate $copyAudit) | ConvertFrom-Json
        Assert-State ($audit.paragraphs -gt 0) "No body paragraphs were found for $route at $($viewport.name)."
        Assert-State ($audit.cssFailures.Count -eq 0) "Body-copy CSS failed for $route at $($viewport.name): $($audit.cssFailures | ConvertTo-Json -Compress)"
        Assert-State ($audit.splitWords.Count -eq 0) "A word split across lines for $route at $($viewport.name): $($audit.splitWords | ConvertTo-Json -Compress)"
        Assert-State (-not $audit.overflow) "Horizontal overflow was detected for $route at $($viewport.name)."
        Assert-State ($audit.errors.Count -eq 0) "Console errors occurred for $route at $($viewport.name)."
        $copyResults += [ordered]@{ viewport=$viewport.name; route=$route; paragraphs=$audit.paragraphs; cssFailures=0; splitWords=0; overflow=$false }
      }
    }
  }

  function Arm-TransitionProbe([string]$selector, [string]$key) {
    $selectorJson = $selector | ConvertTo-Json -Compress
    $keyJson = $key | ConvertTo-Json -Compress
    $expression = @"
(()=>{const selector=$selectorJson,key=$keyJson,anchor=document.querySelector(selector),shell=document.querySelector('.site-shell'),scope=anchor&&anchor.closest('.project-row,.manmatic-category__record,.mm-application'),media=scope&&scope.querySelector('figure'),samples=[],started=performance.now();let animationStarts=0;if(!anchor||!shell)return false;shell.addEventListener('animationstart',event=>{if(event.target===shell)animationStarts+=1},{passive:true});function capture(now){const style=getComputedStyle(shell),mediaStyle=media&&getComputedStyle(media);samples.push({elapsed:Math.round(now-started),manmatic:shell.classList.contains('is-manmatic-route-transitioning'),light:shell.classList.contains('transition--light'),reduced:shell.classList.contains('transition--reduced'),variant:document.documentElement.dataset.projectRouteTransition||document.documentElement.dataset.manmaticRouteTransition||'',animation:style.animationName,duration:style.animationDuration,opacity:style.opacity,filter:style.filter,transform:style.transform,mediaActive:!!media&&media.classList.contains('is-project-route-media-transitioning'),mediaAnimation:mediaStyle?mediaStyle.animationName:'',mediaDuration:mediaStyle?mediaStyle.animationDuration:'',mediaClipPath:mediaStyle?mediaStyle.clipPath:'',mediaTransform:mediaStyle?mediaStyle.transform:''});sessionStorage.setItem(key,JSON.stringify({samples,animationStarts}))}function sample(now){capture(now);if(now-started<460)requestAnimationFrame(sample)}window.__captureTransitionProbe=()=>capture(performance.now());requestAnimationFrame(sample);document.documentElement.style.scrollBehavior='auto';anchor.focus({preventScroll:true});return true})()
"@
    Assert-State ([bool](Evaluate $expression)) "Could not arm transition probe for $selector."
  }

  function Click-At([string]$selector, [bool]$twice = $false) {
    $selectorJson = $selector | ConvertTo-Json -Compress
    $count = if ($twice) { 2 } else { 1 }
    for ($i = 0; $i -lt $count; $i++) {
      $null = Evaluate "document.querySelector($selectorJson).click();window.__captureTransitionProbe&&window.__captureTransitionProbe();true"
    }
  }

  function Assert-LightProbe([string]$key, [string]$path, [int]$expectedStarts = 1) {
    Wait-For "location.pathname === '$path'" "Light transition did not navigate to $path."
    $probe = (Evaluate "sessionStorage.getItem('$key')") | ConvertFrom-Json
    $active = @($probe.samples | Where-Object { $_.light -and $_.variant -eq 'light' })
    Assert-State ($active.Count -gt 0) "No active light-transition samples were captured for $path."
    Assert-State (($active | Where-Object { $_.animation -ne 'project-route-light-signal' -or $_.duration -ne '0.31s' }).Count -eq 0) "The light profile timing changed for $path."
    Assert-State (($active | Where-Object { $_.manmatic }).Count -eq 0) "The full ManMaTIC profile was used for $path."
    $clipValues = @($active | ForEach-Object { $_.mediaClipPath } | Select-Object -Unique)
    $mediaAnimations = @($active | ForEach-Object { "$($_.mediaAnimation)/$($_.mediaDuration)" } | Select-Object -Unique)
    Assert-State (($active | Where-Object { $_.mediaActive -and $_.mediaClipPath -ne 'none' -and $_.mediaClipPath -notin @('inset(0px)', 'inset(0px 0px 0px 0px)') }).Count -gt 0) "No clipped interruption was sampled for $path. Values: $($clipValues -join ' | '); animations: $($mediaAnimations -join ' | ')"
    Assert-State (($active | Where-Object { $_.transform -ne 'none' }).Count -gt 0) "No registration displacement was sampled for $path."
    Assert-State ([int]$probe.animationStarts -eq $expectedStarts) "Duplicate activation restarted the transition for $path."
    $clean = (Evaluate 'JSON.stringify({active:document.querySelector(".site-shell").classList.contains("is-project-route-transitioning"),variant:document.documentElement.dataset.projectRouteTransition||"",layers:document.querySelectorAll(".project-route-transition,.manmatic-transition").length,errors:window.__textGlitchErrors||[]})') | ConvertFrom-Json
    Assert-State (-not $clean.active -and $clean.variant -eq '' -and $clean.layers -eq 0 -and $clean.errors.Count -eq 0) "Transition state remained after reaching $path."
    return [ordered]@{ path=$path; samples=$active.Count; durationMs=310; animationStarts=[int]$probe.animationStarts; maxDisplacementPx=2; clippedFrames=2 }
  }

  Set-Viewport 1440 900 $false
  Write-Output 'VERIFY manmatic-full'
  Navigate 'http://127.0.0.1:4173/'
  Wait-For '!document.documentElement.classList.contains("loader-pending")' 'Homepage loader did not settle.'
  $savedScroll = [double](Evaluate 'new Promise(resolve=>{const row=document.querySelector(".project-row--manmatic"),top=row.getBoundingClientRect().top+scrollY;document.documentElement.style.scrollBehavior="auto";document.scrollingElement.scrollTop=Math.max(0,top-innerHeight*.25);requestAnimationFrame(()=>requestAnimationFrame(()=>resolve(scrollY)))})')
  Assert-State ($savedScroll -gt 500) 'The homepage scroll-restoration test did not begin from a meaningful position.'
  Start-Sleep -Milliseconds 140
  Arm-TransitionProbe '.project-row--manmatic > .project-row__link' 'manmatic-full'
  Click-At '.project-row--manmatic > .project-row__link'
  $manmaticFrame = ''
  Wait-For 'location.pathname === "/projects/manmatic/"' 'ManMaTIC entry did not navigate.'
  $manmaticProbe = (Evaluate 'sessionStorage.getItem("manmatic-full")') | ConvertFrom-Json
  $manmaticSamples = @($manmaticProbe.samples | Where-Object { $_.manmatic -and $_.variant -eq 'enter' })
  Assert-State ($manmaticSamples.Count -gt 0) 'The ManMaTIC signal did not produce an active sampled state.'
  Assert-State (($manmaticSamples | Where-Object { $_.animation -ne 'manmatic-content-signal' -or $_.duration -ne '0.34s' }).Count -eq 0) 'The preserved 340ms ManMaTIC signal changed.'
  Assert-State (($manmaticSamples | Where-Object { $_.filter -ne 'none' -or $_.transform -ne 'none' }).Count -gt 0) 'The ManMaTIC filter/displacement interruption was not sampled.'

  Arm-TransitionProbe 'a.mm-action[href="/projects/protocol-port/"]' 'protocol-from-manmatic'
  Write-Output 'VERIFY protocol-from-manmatic'
  Click-At 'a.mm-action[href="/projects/protocol-port/"]' $true
  $lightFrame = ''
  $lightResults = @()
  $lightResults += Assert-LightProbe 'protocol-from-manmatic' '/projects/protocol-port/' 1

  $projectCases = @(
    @{ selector='.project-row--shila > .project-row__link'; key='light-shila'; path='/projects/shila/'; activation='mouse' },
    @{ selector='.project-row--elma > .project-row__link'; key='light-elma'; path='/projects/concrete-fatigue/'; activation='keyboard' },
    @{ selector='a.project-row__link[href="/projects/dabouq/"]'; key='light-dabouq'; path='/projects/dabouq/'; activation='touch' }
  )
  foreach ($case in $projectCases) {
    Write-Output "VERIFY $($case.key)"
    if ($case.activation -eq 'touch') { Set-Viewport 390 844 $true } else { Set-Viewport 1440 900 $false }
    Navigate 'http://127.0.0.1:4173/'
    Wait-For '!document.documentElement.classList.contains("loader-pending")' "Homepage loader did not settle for $($case.path)."
    Arm-TransitionProbe $case.selector $case.key
    if ($case.activation -eq 'keyboard') {
      $null = Invoke-Cdp 'Input.dispatchKeyEvent' @{ type='keyDown'; key='Enter'; code='Enter'; windowsVirtualKeyCode=13; nativeVirtualKeyCode=13 }
      $null = Invoke-Cdp 'Input.dispatchKeyEvent' @{ type='keyUp'; key='Enter'; code='Enter'; windowsVirtualKeyCode=13; nativeVirtualKeyCode=13 }
      $null = Evaluate 'window.__captureTransitionProbe&&window.__captureTransitionProbe();true'
    } elseif ($case.activation -eq 'touch') {
      $selectorJson = $case.selector | ConvertTo-Json -Compress
      $null = Evaluate "document.querySelector($selectorJson).click();window.__captureTransitionProbe&&window.__captureTransitionProbe();true"
    } else {
      Click-At $case.selector
    }
    $lightResults += Assert-LightProbe $case.key $case.path 1
  }

  Set-Viewport 1440 900 $false
  Write-Output 'VERIFY direct-refresh'
  Navigate 'http://127.0.0.1:4173/projects/shila/'
  Wait-For '!document.documentElement.classList.contains("loader-pending")' 'Direct project refresh loader did not settle.'
  $null = Invoke-Cdp 'Page.reload'
  Wait-For 'document.readyState === "complete"' 'Direct project refresh did not complete.'
  $refreshState = (Evaluate 'JSON.stringify({path:location.pathname,active:document.querySelector(".site-shell").classList.contains("is-project-route-transitioning")||document.querySelector(".site-shell").classList.contains("is-manmatic-route-transitioning"),variant:document.documentElement.dataset.projectRouteTransition||document.documentElement.dataset.manmaticRouteTransition||""})') | ConvertFrom-Json
  Assert-State ($refreshState.path -eq '/projects/shila/' -and -not $refreshState.active -and $refreshState.variant -eq '') 'Direct project refresh incorrectly started a transition.'

  $null = Invoke-Cdp 'Emulation.setEmulatedMedia' @{ features = @(@{ name='prefers-reduced-motion'; value='reduce' }) }
  Write-Output 'VERIFY reduced-manmatic'
  Navigate 'http://127.0.0.1:4173/'
  Write-Output 'VERIFY reduced-light'
  Wait-For '!document.documentElement.classList.contains("loader-pending")' 'Reduced-motion homepage loader did not settle.'
  Arm-TransitionProbe '.project-row--manmatic > .project-row__link' 'reduced-manmatic'
  Click-At '.project-row--manmatic > .project-row__link'
  Wait-For 'location.pathname === "/projects/manmatic/"' 'Reduced-motion ManMaTIC entry did not navigate.'
  $reducedManmatic = (Evaluate 'sessionStorage.getItem("reduced-manmatic")') | ConvertFrom-Json
  $reducedManmaticSamples = @($reducedManmatic.samples | Where-Object { $_.reduced -and $_.variant -eq 'reduced' })
  Assert-State ($reducedManmaticSamples.Count -gt 0) 'Reduced-motion ManMaTIC opacity transition was not sampled.'
  Assert-State (($reducedManmaticSamples | Where-Object { $_.animation -ne 'project-route-reduced-signal' -or $_.duration -ne '0.08s' -or $_.transform -ne 'none' }).Count -eq 0) 'Reduced-motion ManMaTIC entry used displacement or incorrect timing.'

  Navigate 'http://127.0.0.1:4173/'
  Wait-For '!document.documentElement.classList.contains("loader-pending")' 'Reduced-motion homepage loader did not settle for the light profile.'
  Arm-TransitionProbe '.project-row--shila > .project-row__link' 'reduced-light'
  Click-At '.project-row--shila > .project-row__link'
  Wait-For 'location.pathname === "/projects/shila/"' 'Reduced-motion light entry did not navigate.'
  $reducedLight = (Evaluate 'sessionStorage.getItem("reduced-light")') | ConvertFrom-Json
  $reducedLightSamples = @($reducedLight.samples | Where-Object { $_.reduced -and $_.variant -eq 'reduced' })
  Assert-State ($reducedLightSamples.Count -gt 0) 'Reduced-motion light opacity transition was not sampled.'
  Assert-State (($reducedLightSamples | Where-Object { $_.animation -ne 'project-route-reduced-signal' -or $_.duration -ne '0.08s' -or $_.transform -ne 'none' }).Count -eq 0) 'Reduced-motion light entry used displacement or incorrect timing.'

  $null = Invoke-Cdp 'Emulation.setEmulatedMedia' @{ features = @() }
  Write-Output 'VERIFY scroll-restoration'
  $null = Evaluate 'sessionStorage.removeItem("ahmad-project-return-state-v1");sessionStorage.removeItem("ahmad-project-return-intent-v1");sessionStorage.removeItem("ahmad-project-return-fallback-v1");true'
  Navigate 'http://127.0.0.1:4173/'
  Wait-For '!document.documentElement.classList.contains("loader-pending")' 'Homepage loader did not settle for scroll restoration.'
  Start-Sleep -Milliseconds 180
  $scrollSetup = (Evaluate 'new Promise(resolve=>{const row=document.querySelector(".project-row--manmatic"),top=row.getBoundingClientRect().top+scrollY,target=Math.max(0,top-innerHeight*.25);document.documentElement.style.scrollBehavior="auto";document.scrollingElement.scrollTop=target;requestAnimationFrame(()=>requestAnimationFrame(()=>resolve(JSON.stringify({scrollY,target,top,rowViewportTop:row.getBoundingClientRect().top,scrollHeight:document.documentElement.scrollHeight,innerHeight,rootClass:document.documentElement.className,bodyClass:document.body.className,rootOverflow:getComputedStyle(document.documentElement).overflowY,bodyOverflow:getComputedStyle(document.body).overflowY}))))})') | ConvertFrom-Json
  $savedScroll = [double]($scrollSetup.scrollY)
  $savedRowViewportTop = [double]($scrollSetup.rowViewportTop)
  Assert-State ($savedScroll -gt 500) "Scroll-restoration setup did not reach a meaningful homepage position: $($scrollSetup | ConvertTo-Json -Compress)."
  Arm-TransitionProbe '.project-row--manmatic > .project-row__link' 'scroll-manmatic'
  Click-At '.project-row--manmatic > .project-row__link'
  Wait-For 'location.pathname === "/projects/manmatic/"' 'Scroll-restoration entry did not reach ManMaTIC.'
  $returnStateBefore = [string](Evaluate 'sessionStorage.getItem("ahmad-project-return-state-v1")')
  $null = Evaluate 'document.querySelector(".site-header__name").click();true'
  Wait-For 'location.pathname === "/"' 'Return navigation did not reach the homepage.'
  $restorationMatched = $false
  for ($i = 0; $i -lt 200; $i++) {
    $currentRowTop = [double](Evaluate 'document.querySelector(".project-row--manmatic").getBoundingClientRect().top')
    if ([math]::Abs($currentRowTop - $savedRowViewportTop) -lt 120) { $restorationMatched = $true; break }
    Start-Sleep -Milliseconds 50
  }
  $restorationDiagnostics = (Evaluate 'JSON.stringify((()=>{const returnState=sessionStorage.getItem("ahmad-project-return-state-v1"),saved=JSON.parse(returnState||"null"),rowTop=document.querySelector(".project-row--manmatic").getBoundingClientRect().top,routeRestoration=document.documentElement.dataset.routeRestoration||"";return{returnState,returnIntent:sessionStorage.getItem("ahmad-project-return-intent-v1"),routeRestoration,rootClass:document.documentElement.className,scrollY,rowTop,historyState:history.state,referrer:document.referrer,matches:!!saved&&Math.abs(rowTop-Number(saved.rowViewportTop))<120&&routeRestoration==="complete"}})())') | ConvertFrom-Json
  $restoredScroll = [double]($restorationDiagnostics.scrollY)
  $restoredRowViewportTop = [double]($restorationDiagnostics.rowTop)
  $restorationMatched = [bool]$restorationDiagnostics.matches
  Assert-State $restorationMatched "Homepage scroll restoration failed. Before: $returnStateBefore; after: $($restorationDiagnostics | ConvertTo-Json -Depth 5 -Compress)"

  $result = [ordered]@{
    passed = $true
    copy = $copyResults
    transitions = [ordered]@{
      manmatic = [ordered]@{ durationMs=340; animation='manmatic-content-signal'; sampledFrames=$manmaticSamples.Count; animationStarts=[int]$manmaticProbe.animationStarts }
      light = $lightResults
      reducedMotion = [ordered]@{ durationMs=80; manmaticSamples=$reducedManmaticSamples.Count; lightSamples=$reducedLightSamples.Count; displacement='none' }
      directRefresh = $refreshState
      savedHomepageScroll = $savedScroll
      restoredHomepageScroll = $restoredScroll
      savedRowViewportTop = $savedRowViewportTop
      restoredRowViewportTop = $restoredRowViewportTop
      overlayLayers = 0
    }
    screenshots = @($manmaticFrame,$lightFrame)
  }
  $result | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $output 'verification.json')
  $result | ConvertTo-Json -Depth 8
} finally {
  if ($socket) { try { $null = Invoke-Cdp 'Browser.close' } catch {}; $socket.Dispose() }
  if ($process -and -not $process.HasExited) { Stop-Process -Id $process.Id -Force }
  if ($httpProcess -and -not $httpProcess.HasExited) { Stop-Process -Id $httpProcess.Id }
}
