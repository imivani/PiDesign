$ErrorActionPreference = "Stop"

$root = (Resolve-Path ".").Path
$source = Get-Content -LiteralPath (Join-Path $root "project-data.js") -Raw
$json = $source -replace "^\s*window\.PI_PROJECTS\s*=\s*", "" -replace ";\s*$", ""
$projects = $json | ConvertFrom-Json
if (-not ($projects -is [array])) { $projects = @($projects) }

# Keep only projects with real cover photos (skip placeholder ones using hero.jpg)
$realProjects = @($projects | Where-Object { $_.image -and $_.image -notlike "*hero.jpg" })
$realProjects = @($realProjects | Select-Object -First 27)

function Escape-Html([string]$value) {
  if ($null -eq $value) { return "" }
  return [System.Net.WebUtility]::HtmlEncode($value)
}

function File-Hash([string]$relPath) {
  if ([string]::IsNullOrWhiteSpace($relPath)) { return $null }
  $abs = Join-Path $root $relPath
  if (-not (Test-Path -LiteralPath $abs)) { return $null }
  return (Get-FileHash -LiteralPath $abs -Algorithm MD5).Hash
}

function Get-StripImages($project) {
  $hashes = @{}
  $picked = New-Object System.Collections.Generic.List[string]

  # Reserve the cover hash so we never repeat the hero in the strip
  $coverHash = File-Hash $project.image
  if ($coverHash) { $hashes[$coverHash] = $true }

  foreach ($img in @($project.gallery)) {
    if ([string]::IsNullOrWhiteSpace($img)) { continue }
    if ($img -eq $project.image) { continue }
    $h = File-Hash $img
    if (-not $h) { continue }
    if ($hashes.ContainsKey($h)) { continue }
    $hashes[$h] = $true
    $picked.Add($img)
    if ($picked.Count -ge 2) { break }
  }

  return ,$picked
}

function Project-Page($project, [int]$pageNum) {
  $title = Escape-Html $project.title
  $description = Escape-Html $project.description
  $category = Escape-Html $project.category
  $location = Escape-Html $project.location
  $year = Escape-Html $project.year
  $coverImage = "../" + $project.image
  $coverAlt = Escape-Html "$($project.title) project image"

  $strip = Get-StripImages $project
  $stripHtml = ""
  if ($strip.Count -gt 0) {
    $items = New-Object System.Collections.Generic.List[string]
    foreach ($img in $strip) {
      $alt = Escape-Html "$($project.title) detail"
      $src = "../$img"
      $items.Add(@"
          <figure><img src="$src" alt="$alt"></figure>
"@)
    }
    $stripClass = if ($strip.Count -eq 1) { "project-strip project-strip-1" }
                  elseif ($strip.Count -eq 2) { "project-strip project-strip-2" }
                  else { "project-strip project-strip-3" }
    $stripHtml = @"
      <div class="$stripClass">
$($items -join "`n")
      </div>
"@
  }

  $extraCredit = ""
  if ($project.credit) {
    $creditField = Escape-Html $project.credit
    $extraCredit = @"
          <div><dt>Credit</dt><dd>$creditField</dd></div>
"@
  } else {
    $extraCredit = @"
          <div><dt>Studio</dt><dd>Pi Design Group.</dd></div>
"@
  }

  $pageNumLabel = "{0:00}" -f $pageNum
  $pageHeadMeta = "$pageNumLabel / Selected Project"

@"
    <section class="page page-project">
      <header class="page-head page-head-dark">
        <span class="brand">Pi Design Group.</span>
        <span class="meta">$pageHeadMeta</span>
      </header>

      <div class="project-hero">
        <img src="$coverImage" alt="$coverAlt">
        <div class="project-hero-card">
          <span class="section-num">[$category]</span>
          <h2>$title</h2>
          <span class="project-meta">$location, AB &middot; $year &middot; $category</span>
        </div>
      </div>

      <div class="project-body">
        <div class="project-copy">
          <p>$description</p>
        </div>
        <dl class="project-meta-grid">
          <div><dt>Location</dt><dd>$location, AB</dd></div>
          <div><dt>Completion</dt><dd>$year</dd></div>
          <div><dt>Type</dt><dd>$category</dd></div>
$extraCredit
        </dl>
      </div>
$stripHtml
      <footer class="page-foot">
        <span>Pi Design Group. / $title</span>
        <span>$pageNumLabel</span>
      </footer>
    </section>
"@
}

# Pages 01, 02, 03
$pageCover = @"
    <section class="page page-cover">
      <header class="cover-top">
        <span class="brand">Pi Design Group.</span>
        <span class="meta">Portfolio / 2026</span>
      </header>

      <div class="cover-frame">
        <img src="../assets/site/projects/redstone/cover.jpg" alt="Redstone community landscape">
        <span class="cover-tag">Calgary, Alberta &middot; Landscape Architectural Services</span>
      </div>

      <div class="cover-headline">
        <span class="section-num">[01]</span>
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
          <span class="value">Portfolio 2026 / 01</span>
        </div>
      </footer>
    </section>
"@

$pageStudio = @"
    <section class="page page-light">
      <header class="page-head">
        <span class="brand">Pi Design Group.</span>
        <span class="meta">02 / Studio</span>
      </header>

      <div class="studio-grid">
        <div class="studio-copy">
          <span class="section-num">[Studio]</span>
          <h2>Spaces that move from concept to construction.</h2>
          <p class="lede">PI Design Group is a Calgary-based landscape architecture studio working with builders, developers, and project teams across Alberta to shape outdoor environments that feel considered, buildable, and lasting.</p>
          <p>The studio specializes in residential, commercial, and community-scale landscape design &mdash; guiding each project from early visioning through municipal approvals and into the field, where the work becomes real. The result is outdoor space that integrates planning, planting, and detail with the architecture and the community around it.</p>
          <p>Every brief is approached the same way: study the site, listen to the team, design with intent, and document with the rigor needed for builders to deliver the work as drawn.</p>
        </div>

        <aside class="studio-stats">
          <div>
            <span class="stat-value">Calgary</span>
            <span class="stat-label">Studio</span>
          </div>
          <div>
            <span class="stat-value">52+</span>
            <span class="stat-label">Projects across Alberta</span>
          </div>
          <div>
            <span class="stat-value">4</span>
            <span class="stat-label">Core sectors served</span>
          </div>
          <div>
            <span class="stat-value">Concept &rarr; Construction</span>
            <span class="stat-label">Full-service studio</span>
          </div>
        </aside>
      </div>

      <div class="studio-rule"></div>

      <div class="studio-tags">
        <span>Residential</span>
        <span>Commercial</span>
        <span>Mixed-use</span>
        <span>Community</span>
        <span>Single family</span>
        <span>City approvals</span>
        <span>Construction documentation</span>
      </div>

      <footer class="page-foot">
        <span>Pi Design Group.</span>
        <span>02</span>
      </footer>
    </section>
"@

$pageServices = @"
    <section class="page page-sand">
      <header class="page-head">
        <span class="brand">Pi Design Group.</span>
        <span class="meta">03 / Services</span>
      </header>

      <div class="services-head">
        <span class="section-num">[Services]</span>
        <h2>What We Offer, Built with Intention.</h2>
        <p>From concept to completion, each space is shaped with purpose. Five lanes the studio leads, applied across every project type.</p>
      </div>

      <div class="services-grid">
        <article class="service-row">
          <span class="num">(01)</span>
          <h3>Landscape Architecture</h3>
          <p>Site planning, grading, planting, and integrated landscape detail from concept through buildable documentation.</p>
        </article>
        <article class="service-row">
          <span class="num">(02)</span>
          <h3>Community Planning</h3>
          <p>Open-space planning and community-scale strategies that shape the rhythm of new neighborhoods.</p>
        </article>
        <article class="service-row">
          <span class="num">(03)</span>
          <h3>3D Visualization</h3>
          <p>Visualize the project before construction with rendered concepts, 3D models, and design walkthroughs.</p>
        </article>
        <article class="service-row">
          <span class="num">(04)</span>
          <h3>Construction Drawings</h3>
          <p>Coordinated technical drawings ready for builders, trades, and city approvals.</p>
        </article>
        <article class="service-row">
          <span class="num">(05)</span>
          <h3>Consultation</h3>
          <p>Direct studio support from briefs and reviews to material selection and city approvals.</p>
        </article>
      </div>

      <footer class="page-foot">
        <span>Pi Design Group.</span>
        <span>03</span>
      </footer>
    </section>
"@

# Build closing page using top 3 covers from the curated list (cover, then 2 distinct projects)
$closingProjects = @($realProjects | Select-Object -First 3)
$closingFigures = New-Object System.Collections.Generic.List[string]
foreach ($cp in $closingProjects) {
  $imgSrc = "../" + $cp.image
  $imgAlt = Escape-Html $cp.title
  $figTitle = Escape-Html $cp.title
  $figCat = Escape-Html $cp.category
  $closingFigures.Add(@"
        <figure>
          <img src="$imgSrc" alt="$imgAlt">
          <figcaption>$figTitle &middot; $figCat</figcaption>
        </figure>
"@)
}
$closingFiguresHtml = ($closingFigures -join "`n")

$pageClosing = @"
    <section class="page page-cover page-closing">
      <header class="cover-top">
        <span class="brand">Pi Design Group.</span>
        <span class="meta">Get in touch</span>
      </header>

      <div class="closing-strip">
$closingFiguresHtml
      </div>

      <div class="closing-block">
        <span class="section-num">[Contact]</span>
        <h1>
          Ready to start
          <span>a landscape project?</span>
        </h1>
        <p>Tell us about your project. PI Design Group works with builders, developers, and project teams to shape outdoor spaces that move from concept to construction.</p>
      </div>

      <div class="closing-methods">
        <div>
          <span class="label">Call</span>
          <span class="value">403-510-4071</span>
        </div>
        <div>
          <span class="label">Email</span>
          <span class="value">peter@pidesigngroup.ca</span>
        </div>
        <div>
          <span class="label">Studio</span>
          <span class="value">Calgary, Alberta</span>
        </div>
        <div>
          <span class="label">Web</span>
          <span class="value">pidesigngroup.ca</span>
        </div>
      </div>

      <footer class="cover-foot closing-foot">
        <span>&copy; 2026 PI Design Group.</span>
        <span>Landscape Architectural Services</span>
        <span>Portfolio 2026 / 01</span>
      </footer>
    </section>
"@

# Assemble project pages
$projectSections = New-Object System.Collections.Generic.List[string]
$pageNum = 4
foreach ($project in $realProjects) {
  $projectSections.Add((Project-Page $project $pageNum))
  $pageNum += 1
}
$projectsHtml = ($projectSections -join "`n")

$totalPages = 3 + $realProjects.Count + 1

$head = @"
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Pi Design Group. &mdash; Portfolio 2026</title>
    <link rel="stylesheet" href="portfolio.css">
  </head>
  <body>
"@

$tail = @"
  </body>
</html>
"@

$fullHtml = $head + "`n" + $pageCover + "`n" + $pageStudio + "`n" + $pageServices + "`n" + $projectsHtml + "`n" + $pageClosing + "`n" + $tail
$outPath = Join-Path $root "portfolio\portfolio.html"
Set-Content -LiteralPath $outPath -Value $fullHtml -Encoding UTF8

Write-Output ("Wrote portfolio.html with {0} project pages ({1} pages total)." -f $realProjects.Count, $totalPages)
