param([int]$Port = 4173)
$ErrorActionPreference = 'Stop'
$Chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$BaseUrl = "http://127.0.0.1:$Port"
$Output = Join-Path (Split-Path -Parent $PSScriptRoot) 'runtime-validation\dabouq-final'
$Profile = Join-Path $env:TEMP ("dabouq-check-" + (Get-Date -Format 'yyyyMMddHHmmssfff'))
$script:Id = 0
$script:Events = [System.Collections.ArrayList]::new()
$script:Assertions = 0

function Assert-State([bool]$Condition, [string]$Message) { if (-not $Condition) { throw $Message }; $script:Assertions++ }
function Receive-Cdp {
  $buffer = New-Object byte[] 65536; $stream = [System.IO.MemoryStream]::new()
  do { $segment = [System.ArraySegment[byte]]::new($buffer); $received = $script:Ws.ReceiveAsync($segment,[System.Threading.CancellationToken]::None).GetAwaiter().GetResult(); $stream.Write($buffer,0,$received.Count) } until ($received.EndOfMessage)
  $text = [Text.Encoding]::UTF8.GetString($stream.ToArray()); $stream.Dispose(); return $text
}
function Invoke-Cdp([string]$Method,$Params=$null) {
  $script:Id++; $payload=@{id=$script:Id;method=$Method}; if($null-ne $Params){$payload.params=$Params}
  $bytes=[Text.Encoding]::UTF8.GetBytes(($payload|ConvertTo-Json -Depth 20 -Compress)); $segment=[ArraySegment[byte]]::new($bytes)
  $null=$script:Ws.SendAsync($segment,[Net.WebSockets.WebSocketMessageType]::Text,$true,[Threading.CancellationToken]::None).GetAwaiter().GetResult()
  while($true){$response=(Receive-Cdp)|ConvertFrom-Json; if($response.id -eq $script:Id){if($response.error){throw $response.error.message};return $response.result};if($response.method){$null=$script:Events.Add($response)}}
}
function Eval([string]$Expression) { $r=Invoke-Cdp 'Runtime.evaluate' @{expression=$Expression;returnByValue=$true;awaitPromise=$true};if($r.exceptionDetails){throw $r.exceptionDetails.text};return $r.result.value }
function Json([string]$Expression) { return ([string](Eval $Expression))|ConvertFrom-Json }
function Wait-For([string]$Expression,[string]$Message) { for($i=0;$i-lt 180;$i++){try{if([bool](Eval $Expression)){return}}catch{};Start-Sleep -Milliseconds 100};throw $Message }
function Viewport([int]$Width,[int]$Height,[bool]$Mobile=$false) { $null=Invoke-Cdp 'Emulation.setDeviceMetricsOverride' @{width=$Width;height=$Height;deviceScaleFactor=1;mobile=$Mobile;screenWidth=$Width;screenHeight=$Height};$null=Invoke-Cdp 'Emulation.setTouchEmulationEnabled' @{enabled=$Mobile;maxTouchPoints=$(if($Mobile){5}else{1})} }
function Navigate([string]$Url) { $null=Invoke-Cdp 'Page.navigate' @{url=$Url};$literal=ConvertTo-Json $Url -Compress;Wait-For "location.href === $literal && document.readyState !== 'loading'" "Did not load $Url" }
function Capture([string]$Name,[bool]$Full=$false) { $p=@{format='png';fromSurface=$true;captureBeyondViewport=$Full};$shot=Invoke-Cdp 'Page.captureScreenshot' $p;[IO.File]::WriteAllBytes((Join-Path $Output "$Name.png"),[Convert]::FromBase64String([string]$shot.data)) }

$failure=$null;$process=$null;$serverProcess=$null
try {
  Assert-State (Test-Path $Chrome) 'Chrome unavailable.'
  New-Item -ItemType Directory -Force $Output,$Profile|Out-Null
  try { $serverReady=(Invoke-WebRequest -UseBasicParsing "$BaseUrl/" -TimeoutSec 1).StatusCode -eq 200 } catch { $serverReady=$false }
  if(-not $serverReady){$root=Split-Path -Parent $PSScriptRoot;$serverArgs='-m http.server {0} --bind 127.0.0.1 --directory "{1}"' -f $Port,$root;$serverProcess=Start-Process python -ArgumentList $serverArgs -PassThru -WindowStyle Hidden;for($i=0; $i -lt 100 -and -not $serverReady; $i++){Start-Sleep -Milliseconds 100;try{$serverReady=(Invoke-WebRequest -UseBasicParsing "$BaseUrl/" -TimeoutSec 1).StatusCode -eq 200}catch{$serverReady=$false}}}
  Assert-State $serverReady 'Local server unavailable.'
  $process=Start-Process $Chrome -ArgumentList @('--headless=new','--disable-gpu','--no-first-run','--remote-debugging-port=0','--remote-allow-origins=*',"--user-data-dir=$Profile",'about:blank') -PassThru -WindowStyle Hidden
  $portFile=Join-Path $Profile 'DevToolsActivePort';for($i=0; $i -lt 150 -and -not (Test-Path $portFile); $i++){Start-Sleep -Milliseconds 100};Assert-State (Test-Path $portFile) 'Chrome endpoint unavailable.'
  $debugPort=[int](Get-Content $portFile|Select-Object -First 1)
  $targets=Invoke-RestMethod "http://127.0.0.1:$debugPort/json/list"
  $target=@($targets | Where-Object {$_.type -eq 'page'})[0]
  $script:Ws=[Net.WebSockets.ClientWebSocket]::new();$null=$script:Ws.ConnectAsync([Uri]$target.webSocketDebuggerUrl,[Threading.CancellationToken]::None).GetAwaiter().GetResult()
  foreach($method in @('Page.enable','Runtime.enable','Network.enable','Log.enable')){$null=Invoke-Cdp $method}
  $viewports=@(@{n='1920';w=1920;h=1080;m=$false},@{n='1440';w=1440;h=900;m=$false},@{n='1024';w=1024;h=768;m=$false},@{n='834';w=834;h=1112;m=$true},@{n='768';w=768;h=1024;m=$true},@{n='430';w=430;h=932;m=$true},@{n='390';w=390;h=844;m=$true})
  foreach($v in $viewports) {
    Viewport $v.w $v.h $v.m
    Navigate "$BaseUrl/projects/dabouq/"
    Wait-For 'document.body.classList.contains("is-loaded") || !document.getElementById("loader") || getComputedStyle(document.getElementById("loader")).visibility === "hidden"' 'Loader did not finish.'
    Wait-For 'document.querySelector(".dabouq-hero img").complete && document.querySelector(".dabouq-hero img").naturalWidth > 0' 'Hero image failed to load.'
    $state=Json 'JSON.stringify({overflow:document.documentElement.scrollWidth-document.documentElement.clientWidth,galleries:[...document.querySelectorAll("[data-gallery-group]")].map(g=>({ready:g.dataset.galleryReady,count:g.querySelectorAll(".shila-gallery__slide:not([data-gallery-clone])").length,counter:g.querySelector("[data-gallery-counter]")?.textContent.trim(),marks:g.querySelectorAll("[data-gallery-progress] i").length})),rows:getComputedStyle(document.querySelector(".dabouq-row--details")).gridTemplateColumns,images:[...document.querySelectorAll(".dabouq-board img[src]")].map(i=>({loaded:!i.complete||i.naturalWidth>0,cw:i.clientWidth,ch:i.clientHeight,fit:getComputedStyle(i).objectFit}))})'
    Assert-State ([double]$state.overflow -le 1) "Horizontal overflow at $($v.n)."
    Assert-State ($state.galleries.Count -eq 3 -and ($state.galleries|Where-Object ready -ne 'true').Count -eq 0) "Gallery init failed at $($v.n)."
    Assert-State ((@($state.galleries | ForEach-Object {$_.count}) -join ',') -eq '2,2,4') "Gallery sequence mismatch at $($v.n)."
    Assert-State ((@($state.galleries | ForEach-Object {$_.marks}) -join ',') -eq '2,2,4') "Progress marks mismatch at $($v.n)."
    Assert-State ((@($state.galleries | ForEach-Object {$_.counter}) -join ',') -eq 'IMAGE 01 / 02,IMAGE 01 / 02,IMAGE 01 / 04') "Initial slide order mismatch at $($v.n)."
    Assert-State (($state.images|Where-Object {$_.loaded -ne $true}).Count -eq 0) "Broken media at $($v.n)."
    if($v.w -le 834){Assert-State (-not $state.rows.Contains(' ')) "Detail row did not stack at $($v.n)."}
    if($v.w -le 834){Wait-For 'document.querySelector(".dabouq-opening h1").textContent === "DABOUQ RESIDENTIAL BUILDING"' 'Opening title did not settle.'}
    Start-Sleep -Milliseconds 500
    Capture "dabouq-$($v.n)-top"
  }
  Viewport 1440 900 $false;Navigate "$BaseUrl/projects/dabouq/";Wait-For 'document.querySelectorAll("[data-gallery-ready=true]").length === 3' 'Desktop sliders not ready.';$null=Eval 'document.documentElement.style.scrollBehavior="auto";document.body.style.scrollBehavior="auto";document.querySelector(".dabouq-row--first").scrollIntoView({block:"start",behavior:"instant"});true';Wait-For 'document.querySelector(".dabouq-row--first img").complete && document.querySelector(".dabouq-row--first img").naturalWidth > 0' 'First project row did not load.';Start-Sleep -Milliseconds 800;Capture 'dabouq-1440-first-row';$null=Eval 'document.querySelector(".dabouq-row--details").scrollIntoView({block:"start",behavior:"instant"});true';Wait-For '[...document.querySelectorAll(".dabouq-row--details img")].every(i=>i.complete&&i.naturalWidth>0)' 'Detail row did not load.';Start-Sleep -Milliseconds 800;Capture 'dabouq-1440-details';$before=Eval 'document.querySelector("[data-gallery-group=dabouq-renders] [data-gallery-counter]").textContent';$null=Eval 'document.querySelector("[data-gallery-group=dabouq-renders] [data-gallery-next]").click();true';Wait-For 'document.querySelector("[data-gallery-group=dabouq-renders] [data-gallery-counter]").textContent.includes("02 / 02")' 'Next control failed.';$null=Eval 'document.querySelector("[data-gallery-group=dabouq-facade]").dispatchEvent(new KeyboardEvent("keydown",{key:"ArrowRight",bubbles:true}));true';Wait-For 'document.querySelector("[data-gallery-group=dabouq-facade] [data-gallery-counter]").textContent.includes("02 / 02")' 'Keyboard control failed.';$null=Eval 'document.querySelector("[data-gallery-group=dabouq-parametric]").scrollIntoView({block:"start",behavior:"instant"});true';Wait-For 'document.querySelector("[data-gallery-group=dabouq-parametric] img").complete && document.querySelector("[data-gallery-group=dabouq-parametric] img").naturalWidth > 0' 'Workflow image did not load.';Wait-For 'document.querySelector(".dabouq-gallery--workflow figcaption").textContent === "PARAMETRIC BRICK PATTERN"' 'Workflow caption did not settle.';Capture 'dabouq-1440-workflow';$null=Eval 'document.querySelector(".dabouq-section").scrollIntoView({block:"start",behavior:"instant"});true';Wait-For 'document.querySelector(".dabouq-section img").complete && document.querySelector(".dabouq-section img").naturalWidth > 0' 'Section image did not load.';Start-Sleep -Milliseconds 800;Capture 'dabouq-1440-section';Assert-State ($before -eq 'IMAGE 01 / 02') 'Initial render was not 3.1.'
  Viewport 390 844 $true;Navigate "$BaseUrl/projects/dabouq/";Wait-For 'document.querySelectorAll("[data-gallery-ready=true]").length === 3' 'Mobile sliders not ready.';$null=Eval 'document.documentElement.style.scrollBehavior="auto";document.body.style.scrollBehavior="auto";const g=document.querySelector("[data-gallery-group=dabouq-parametric]");g.scrollIntoView({block:"center",behavior:"instant"});const v=g.querySelector(".shila-gallery__viewport");const r=v.getBoundingClientRect();v.setPointerCapture=()=>{};v.hasPointerCapture=()=>false;v.releasePointerCapture=()=>{};const e=(type,x)=>new PointerEvent(type,{pointerId:7,pointerType:"touch",button:0,clientX:x,clientY:r.top+r.height*.5,bubbles:true,cancelable:true});v.dispatchEvent(e("pointerdown",r.left+r.width*.78));v.dispatchEvent(e("pointermove",r.left+r.width*.18));v.dispatchEvent(e("pointerup",r.left+r.width*.18));true';Wait-For 'document.querySelector("[data-gallery-group=dabouq-parametric] [data-gallery-counter]").textContent.includes("02 / 04")' 'Touch-pointer swipe handler failed.'
  $null=Invoke-Cdp 'Emulation.setEmulatedMedia' @{media='';features=@(@{name='prefers-reduced-motion';value='reduce'})};Navigate "$BaseUrl/projects/dabouq/";Wait-For 'document.querySelectorAll("[data-gallery-ready=true]").length === 3' 'Reduced-motion page did not initialize.';Assert-State ([bool](Eval 'matchMedia("(prefers-reduced-motion: reduce)").matches')) 'Reduced-motion emulation was not applied.'
  Navigate "$BaseUrl/";Wait-For 'document.querySelector("a[href=\"/projects/dabouq/\"]")' 'Homepage Dabouq link missing.';$null=Eval 'document.querySelector("a[href=\"/projects/dabouq/\"]").click();true';Wait-For 'location.pathname === "/projects/dabouq/"' 'Homepage navigation failed.';$null=Eval 'history.back();true';Wait-For 'location.pathname === "/"' 'Browser Back failed.'
  Navigate "$BaseUrl/projects/shila/";Wait-For 'document.querySelectorAll("[data-gallery-ready=true]").length === 2' 'Shila shared sliders did not initialize.';Assert-State ([bool](Eval '[...document.querySelectorAll("[data-gallery-group]")].every(g=>g.querySelector("[data-gallery-counter]").textContent.startsWith("IMAGE ")&&g.querySelectorAll("[data-gallery-progress] i").length>1)')) 'Shila shared indicators are incomplete.'
  Navigate "$BaseUrl/projects/concrete-fatigue/";Wait-For 'document.querySelectorAll("[data-gallery-ready=true]").length === 2' 'ELMA shared sliders did not initialize.';Assert-State ([bool](Eval '[...document.querySelectorAll("[data-gallery-group]")].every(g=>g.querySelector("[data-gallery-counter]").textContent.startsWith("IMAGE ")&&g.querySelectorAll("[data-gallery-progress] i").length>1)')) 'ELMA shared indicators are incomplete.'
  $errors=@($script:Events|Where-Object {$_.method -eq 'Runtime.exceptionThrown' -or ($_.method -eq 'Runtime.consoleAPICalled' -and $_.params.type -eq 'error')});Assert-State ($errors.Count-eq 0) 'Runtime or console errors were emitted.'
  Write-Output "Dabouq runtime verification PASS: $script:Assertions assertions."
} catch {$failure=$_} finally {if($script:Ws){$script:Ws.Dispose()};if($process -and -not $process.HasExited){Stop-Process $process.Id -Force};if($serverProcess -and -not $serverProcess.HasExited){Stop-Process $serverProcess.Id -Force}}
if($failure){throw $failure}
