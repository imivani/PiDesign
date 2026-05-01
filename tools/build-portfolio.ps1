$ErrorActionPreference = "Stop"

$root = (Resolve-Path ".").Path
$source = Get-Content -LiteralPath (Join-Path $root "project-data.js") -Raw
$json = $source -replace "^\s*window\.PI_PROJECTS\s*=\s*", "" -replace ";\s*$", ""
$projects = $json | ConvertFrom-Json
if (-not ($projects -is [array])) { $projects = @($projects) }

# Real projects only (skip placeholder entries)
$realProjects = @($projects | Where-Object { $_.image -and $_.image -notlike "*hero.jpg" })
$realProjects = @($realProjects | Select-Object -First 27)

# ----------------------------------------------------------------------
# IMAGE COMPRESSION
# ----------------------------------------------------------------------
Add-Type -AssemblyName System.Drawing

$portfolioDir = Join-Path $root "portfolio"
$compressDir = Join-Path $portfolioDir "img"
if (-not (Test-Path -LiteralPath $compressDir)) {
  New-Item -ItemType Directory -Path $compressDir -Force | Out-Null
}

$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$compressCache = @{}

function Compress-Image([string]$relPath, [int]$maxWidth = 1100, [int]$quality = 72) {
  if ([string]::IsNullOrWhiteSpace($relPath)) { return $null }
  $cacheKey = "$relPath|$maxWidth|$quality"
  if ($compressCache.ContainsKey($cacheKey)) { return $compressCache[$cacheKey] }

  $absSrc = Join-Path $root $relPath
  if (-not (Test-Path -LiteralPath $absSrc)) {
    $compressCache[$cacheKey] = $null
    return $null
  }

  $stem = ($relPath -replace "[\\/]", "-") -replace "\.[^.]+$", ""
  $outName = "{0}-w{1}q{2}.jpg" -f $stem, $maxWidth, $quality
  $outPath = Join-Path $compressDir $outName

  $needsBuild = $true
  if (Test-Path -LiteralPath $outPath) {
    $srcInfo = Get-Item -LiteralPath $absSrc
    $outInfo = Get-Item -LiteralPath $outPath
    if ($outInfo.LastWriteTime -ge $srcInfo.LastWriteTime) {
      $needsBuild = $false
    }
  }

  if ($needsBuild) {
    $src = [System.Drawing.Image]::FromFile($absSrc)
    try {
      $ratio = [Math]::Min(1.0, $maxWidth / [double]$src.Width)
      $newW = [int]([Math]::Max(1, [Math]::Round($src.Width * $ratio)))
      $newH = [int]([Math]::Max(1, [Math]::Round($src.Height * $ratio)))
      $bmp = New-Object System.Drawing.Bitmap $newW, $newH, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
      $g = [System.Drawing.Graphics]::FromImage($bmp)
      try {
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $g.Clear([System.Drawing.Color]::White)
        $g.DrawImage($src, 0, 0, $newW, $newH)

        $params = New-Object System.Drawing.Imaging.EncoderParameters 1
        $params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$quality)
        $bmp.Save($outPath, $jpegCodec, $params)
      }
      finally {
        $g.Dispose()
        $bmp.Dispose()
      }
    }
    finally {
      $src.Dispose()
    }
  }

  $rel = "img/$outName"
  $compressCache[$cacheKey] = $rel
  return $rel
}

function Escape-Html([string]$value) {
  if ($null -eq $value) { return "" }
  return [System.Net.WebUtility]::HtmlEncode($value)
}

# ----------------------------------------------------------------------
# PAGE 01 — COVER
# ----------------------------------------------------------------------
$coverImage = Compress-Image "assets/site/projects/redstone/cover.jpg" 1500 78
$pageCover = @"
    <section class="page page-cover">
      <header class="cover-top">
        <span class="brand">Pi Design Group.</span>
        <span class="meta">Corporate Profile / 2026</span>
      </header>

      <div class="cover-frame">
        <img src="$coverImage" alt="Redstone community landscape">
        <span class="cover-tag">Calgary, Alberta &middot; Landscape Architectural Services</span>
      </div>

      <div class="cover-headline">
        <span class="section-num">[01 / Studio]</span>
        <h1>
          Designing landscapes
          <span>that shape communities.</span>
        </h1>
      </div>

      <footer class="cover-foot">
        <div>
          <span class="label">Studio</span>
          <span class="value">Pi Design Group.</span>
        </div>
        <div>
          <span class="label">Discipline</span>
          <span class="value">Landscape Architecture</span>
        </div>
        <div>
          <span class="label">Location</span>
          <span class="value">Calgary, Alberta</span>
        </div>
        <div>
          <span class="label">Edition</span>
          <span class="value">Profile 2026 / 01</span>
        </div>
      </footer>
    </section>
"@

# ----------------------------------------------------------------------
# PAGE 02 — STUDIO + TEAM + SERVICES
# ----------------------------------------------------------------------
$introArt1 = Compress-Image "assets/site/projects/darcy/cover.jpg" 700 70
$introArt2 = Compress-Image "assets/site/projects/symon/cover.jpg" 700 70
$peterPhoto = Compress-Image "assets/site/projects/redstone/cover.jpg" 800 72
$terryPhoto = Compress-Image "assets/site/projects/seton/cover.jpg" 800 72
$watermarkArt = Compress-Image "assets/site/projects/redstone/gallery-3.jpg" 1200 65

$pageStudio = @"
    <section class="page page-light page-studio">
      <span class="page-mark" aria-hidden="true">
        <img src="$watermarkArt" alt="">
      </span>

      <header class="page-head">
        <span class="brand">Pi Design Group.</span>
        <span class="meta">02 / Corporate Profile</span>
      </header>

      <div class="profile-intro">
        <div class="profile-intro-copy">
          <span class="section-num">[Studio]</span>
          <h2>A boutique landscape architecture studio across Western Canada.</h2>
          <p>PI Design Group is a boutique Landscape Architecture and Planning firm specializing in residential and multifamily developments across Western Alberta. Established over a decade ago, the firm delivers practical, contemporary, and sustainable landscape solutions supported by strong technical execution.</p>
          <p>Licensed to practice in Alberta and British Columbia, PI Design Group has successfully completed more than 70 projects across residential, multifamily, and commercial sectors. Technical production is supported by a team of junior landscape technicians on an outsourced basis &mdash; allowing the studio to scale efficiently while maintaining quality and schedule.</p>
        </div>
        <aside class="profile-intro-art" aria-hidden="true">
          <figure>
            <img src="$introArt1" alt="">
            <figcaption>D&rsquo;Arcy &middot; Residential</figcaption>
          </figure>
          <figure>
            <img src="$introArt2" alt="">
            <figcaption>Symon &middot; Residential</figcaption>
          </figure>
        </aside>
      </div>

      <div class="principals">
        <article class="principal-card">
          <div class="principal-card-text">
            <span class="principal-tag">Practice Lead / 01</span>
            <h3>Peter Imshenetskyy</h3>
            <span class="principal-creds">M.Arch</span>
            <p>20+ years of professional experience in architecture and landscape architecture in Calgary since 2004, supported by a Master&rsquo;s Degree in Architecture earned in 1996.</p>
          </div>
          <div class="principal-card-photo">
            <img src="$peterPhoto" alt="Redstone community landscape">
            <span class="principal-card-credit">Redstone &middot; Community</span>
          </div>
        </article>
        <article class="principal-card">
          <div class="principal-card-text">
            <span class="principal-tag">Practice Lead / 02</span>
            <h3>Terry Klassen</h3>
            <span class="principal-creds">AALA &middot; MBCSLA &middot; RPP &middot; MCIP &middot; CSLA</span>
            <p>40+ years of landscape architectural experience throughout Western Canada, providing deep regulatory, planning, and design leadership across the studio&rsquo;s practice.</p>
          </div>
          <div class="principal-card-photo">
            <img src="$terryPhoto" alt="Seton Crossing commercial landscape">
            <span class="principal-card-credit">Seton Crossing &middot; Commercial</span>
          </div>
        </article>
      </div>

      <div class="profile-services">
        <div class="profile-services-head">
          <span class="section-num">[Services]</span>
          <h2>Landscape services, end to end.</h2>
        </div>
        <div class="profile-services-grid">
          <article><span>(01)</span><strong>Site Analysis &amp; Concept Design</strong><p>Site studies and early visioning that shape the landscape brief.</p></article>
          <article><span>(02)</span><strong>Landscape Design &amp; Detailing</strong><p>Hardscape, softscape, planting, and integrated detail.</p></article>
          <article><span>(03)</span><strong>Construction Documentation</strong><p>Coordinated drawings ready for builders, trades, and approvals.</p></article>
          <article><span>(04)</span><strong>Municipal Approvals</strong><p>Coordination with cities and regulatory partners across Alberta.</p></article>
          <article><span>(05)</span><strong>Consultant Coordination</strong><p>Working alongside architects, engineers, and project teams.</p></article>
          <article><span>(06)</span><strong>Construction Administration</strong><p>On-site studio support to deliver the work as designed.</p></article>
        </div>
      </div>

      <footer class="page-foot">
        <span>Pi Design Group. / Studio</span>
        <span>02</span>
      </footer>
    </section>
"@

# ----------------------------------------------------------------------
# PAGE 03 — PROJECT GRID
# ----------------------------------------------------------------------
$gridItems = New-Object System.Collections.Generic.List[string]
foreach ($p in $realProjects) {
  $thumb = Compress-Image $p.image 700 70
  $title = Escape-Html $p.title
  $location = Escape-Html $p.location
  $year = Escape-Html $p.year
  $category = Escape-Html $p.category
  $gridItems.Add(@"
        <article class="grid-card">
          <span class="grid-card-media">
            <img src="$thumb" alt="$title">
          </span>
          <span class="grid-card-copy">
            <strong>$title</strong>
            <em>$location &middot; $year</em>
            <span>$category</span>
          </span>
        </article>
"@)
}
$gridItemsHtml = ($gridItems -join "`n")

$projectCount = $realProjects.Count
$pageProjects = @"
    <section class="page page-sand page-projects">
      <header class="page-head">
        <span class="brand">Pi Design Group.</span>
        <span class="meta">03 / Selected Work</span>
      </header>

      <div class="projects-head">
        <div>
          <span class="section-num">[Projects]</span>
          <h2>$projectCount selected projects across Alberta.</h2>
        </div>
        <p>Residential, multifamily, mixed-use, and commercial landscapes &mdash; designed and delivered by PI Design Group. More projects, including 2025 and 2026 work, are released on the studio website.</p>
      </div>

      <div class="projects-grid">
$gridItemsHtml
      </div>

      <footer class="page-foot">
        <span>Pi Design Group. / Selected Work</span>
        <span>03 &middot; pidesigngroup.ca</span>
      </footer>
    </section>
"@

$head = @"
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Pi Design Group. &mdash; Corporate Profile 2026</title>
    <link rel="stylesheet" href="portfolio.css">
  </head>
  <body>
"@

$tail = @"
  </body>
</html>
"@

$fullHtml = $head + "`n" + $pageCover + "`n" + $pageStudio + "`n" + $pageProjects + "`n" + $tail
$outPath = Join-Path $portfolioDir "portfolio.html"
Set-Content -LiteralPath $outPath -Value $fullHtml -Encoding UTF8

Write-Output ("Wrote 3-page corporate profile with {0} project thumbnails." -f $projectCount)
