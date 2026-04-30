$ErrorActionPreference = "Stop"

$root = (Resolve-Path ".").Path
$source = Get-Content -LiteralPath (Join-Path $root "project-data.js") -Raw
$json = $source -replace "^\s*window\.PI_PROJECTS\s*=\s*", "" -replace ";\s*$", ""
$projects = $json | ConvertFrom-Json
if (-not ($projects -is [array])) {
  $projects = @($projects)
}
$outRoot = Join-Path $root "projects"

function Escape-Html([string]$value) {
  if ($null -eq $value) { return "" }
  return [System.Net.WebUtility]::HtmlEncode($value)
}

function Rel-Asset([string]$value) {
  return "../../" + ($value -replace "\\", "/")
}

function Project-Href($project) {
  return "../../projects/$($project.slug)/index.html"
}

function Viewer-Thumbs($project) {
  $images = @($project.gallery)
  if ($images.Count -eq 0) { $images = @($project.image) }

  $items = New-Object System.Collections.Generic.List[string]
  for ($i = 0; $i -lt $images.Count; $i++) {
    $src = Rel-Asset $images[$i]
    $alt = Escape-Html "$($project.title) gallery image $($i + 1)"
    $active = if ($i -eq 0) { " is-active" } else { "" }
    $indexLabel = "{0:00}" -f ($i + 1)
    $items.Add(@"
          <button class="project-viewer-thumb$active" type="button" data-viewer-thumb data-full="$src" data-alt="$alt" data-index-label="$indexLabel" aria-label="Show image $($i + 1)">
            <img src="$src" alt="$alt">
          </button>
"@)
  }

  return ($items -join "`n")
}

function Project-Page($project, [int]$index) {
  $previous = $projects[($index - 1 + $projects.Count) % $projects.Count]
  $next = $projects[($index + 1) % $projects.Count]
  $credit = ""
  if ($project.credit) {
    $credit = "<p>$(Escape-Html $project.credit)</p>"
  }

  $title = Escape-Html $project.title
  $description = Escape-Html $project.description
  $category = Escape-Html $project.category
  $location = Escape-Html $project.location
  $year = Escape-Html $project.year
  $indexLabel = Escape-Html $project.index
  $image = Rel-Asset $project.image
  $viewerThumbs = Viewer-Thumbs $project
  $firstGallery = @($project.gallery)
  if ($firstGallery.Count -eq 0) { $firstGallery = @($project.image) }
  $firstImage = Rel-Asset $firstGallery[0]
  $prevTitle = Escape-Html $previous.title
  $nextTitle = Escape-Html $next.title
  $prevHref = Project-Href $previous
  $nextHref = Project-Href $next

@"
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="$description">
    <title>$title | Pi Design Group.</title>
    <link rel="stylesheet" href="../../styles.css">
  </head>
  <body class="project-page">
    <header class="site-header" data-header>
      <a class="brand-word" href="../../index.html#top" aria-label="Pi Design Group home">Pi Design Group.</a>
      <nav class="desktop-nav" aria-label="Primary navigation">
        <a href="../../index.html#top">Home</a>
        <a href="../../index.html#studio">Studio</a>
        <div class="project-menu">
          <a class="is-active" href="../../index.html#projects">Projects</a>
          <div class="project-dropdown" data-project-dropdown></div>
        </div>
        <a href="../../index.html#services">Services</a>
        <a href="../../index.html#contact">Contact</a>
      </nav>
      <button class="menu-toggle" type="button" aria-label="Open menu" aria-expanded="false" aria-controls="mobile-menu" data-menu-toggle>
        <span></span>
        <span></span>
      </button>
    </header>

    <nav class="mobile-menu" id="mobile-menu" aria-label="Mobile navigation" data-mobile-menu>
      <a href="../../index.html#top">Home</a>
      <a href="../../index.html#studio">Studio</a>
      <a href="../../index.html#projects">Projects</a>
      <div class="mobile-project-list" data-mobile-project-list></div>
      <a href="../../index.html#services">Services</a>
      <a href="../../index.html#contact">Contact</a>
    </nav>

    <main class="project-page-main">
      <section class="project-page-hero" aria-labelledby="project-title">
        <div class="project-hero-copy">
          <a class="back-link" href="../../index.html#projects">Back to projects</a>
          <span class="project-page-index">[$indexLabel] $category</span>
          <h1 id="project-title">$title</h1>
          <p>$description</p>
          $credit
          <dl class="project-page-meta">
            <div>
              <dt>Location</dt>
              <dd>$location, AB</dd>
            </div>
            <div>
              <dt>Completion</dt>
              <dd>$year</dd>
            </div>
            <div>
              <dt>Project Type</dt>
              <dd>$category</dd>
            </div>
          </dl>
        </div>
        <div class="project-hero-media">
          <img src="$image" alt="$title project image">
        </div>
      </section>

      <section class="project-gallery-section" aria-labelledby="gallery-title">
        <div class="project-gallery-head">
          <div>
            <span class="section-num">[Gallery]</span>
            <h2 id="gallery-title">Image Set</h2>
          </div>
          <p>A focused gallery from $title, arranged as a single view with a clear image sequence.</p>
        </div>
        <div class="project-viewer" data-project-viewer>
          <button class="viewer-control viewer-prev" type="button" aria-label="Previous image" data-viewer-prev>&larr;</button>
          <img src="$firstImage" alt="$title selected gallery image" data-viewer-image>
          <button class="viewer-zoom" type="button" aria-label="Zoom selected image" data-viewer-zoom>
            <svg viewBox="0 0 24 24" aria-hidden="true">
              <circle cx="10.5" cy="10.5" r="5.5"></circle>
              <path d="M15 15l5 5"></path>
            </svg>
          </button>
          <button class="viewer-control viewer-next" type="button" aria-label="Next image" data-viewer-next>&rarr;</button>
          <div class="project-viewer-caption">
            <span data-viewer-count>01 / 01</span>
            <strong>$title</strong>
          </div>
        </div>
        <div class="project-viewer-thumbs" data-viewer-thumbs>
$viewerThumbs
        </div>
      </section>

      <nav class="project-page-nav" aria-label="Adjacent projects">
        <a href="$prevHref">
          <span>Previous project</span>
          <strong>$prevTitle</strong>
        </a>
        <a href="$nextHref">
          <span>Next project</span>
          <strong>$nextTitle</strong>
        </a>
      </nav>
    </main>

    <footer class="site-footer">
      <div class="footer-inner">
        <a class="brand-word" href="../../index.html#top">Pi Design Group.</a>
        <nav aria-label="Footer navigation">
          <a href="../../index.html#projects">Projects</a>
          <a href="../../index.html#services">Services</a>
          <a href="../../index.html#contact">Contact</a>
        </nav>
        <div class="footer-contact">
          <a href="mailto:peter@pidesigngroup.ca">peter@pidesigngroup.ca</a>
          <span>Calgary, Alberta</span>
        </div>
        <p>&copy; 2026 PI Design Group. Landscape architectural services.</p>
      </div>
    </footer>

    <script src="../../project-data.js"></script>
    <script src="../../script.js"></script>
  </body>
</html>
"@
}

New-Item -ItemType Directory -Force -Path $outRoot | Out-Null

for ($i = 0; $i -lt $projects.Count; $i++) {
  $project = $projects[$i]
  $dir = Join-Path $outRoot $project.slug
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $html = Project-Page $project $i
  Set-Content -LiteralPath (Join-Path $dir "index.html") -Value $html -Encoding UTF8
}

Write-Output "Generated $($projects.Count) project pages."
