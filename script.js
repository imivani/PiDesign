(function () {
  const projects = Array.isArray(window.PI_PROJECTS) ? window.PI_PROJECTS : [];
  const gridMount = document.querySelector("[data-project-grid]");
  const railMount = document.querySelector("[data-project-rail]");
  const selectedCardsMount = document.querySelector("[data-selected-cards]");
  const projectDropdown = document.querySelector("[data-project-dropdown]");
  const mobileProjectList = document.querySelector("[data-mobile-project-list]");
  const filters = Array.from(document.querySelectorAll("[data-filter]"));
  const searchInput = document.querySelector("[data-search]");
  const clearButton = document.querySelector("[data-clear]");
  const offerButtons = Array.from(document.querySelectorAll("[data-service]"));
  const projectCount = document.querySelector("[data-project-count]");
  const menuToggle = document.querySelector("[data-menu-toggle]");
  const mobileMenu = document.querySelector("[data-mobile-menu]");
  const stageMore = document.querySelector("[data-stage-more]");
  const navLinks = Array.from(document.querySelectorAll(".desktop-nav a, .mobile-menu a"));

  const stage = {
    root: document.querySelector("[data-project-stage]"),
    image: document.querySelector("[data-stage-image]"),
    category: document.querySelector("[data-stage-category]"),
    title: document.querySelector("[data-stage-title]"),
    description: document.querySelector("[data-stage-description]"),
    location: document.querySelector("[data-stage-location]"),
    year: document.querySelector("[data-stage-year]"),
    type: document.querySelector("[data-stage-type]")
  };

  const detail = {
    root: document.querySelector("[data-project-detail]"),
    title: document.querySelector("[data-detail-title]"),
    meta: document.querySelector("[data-detail-meta]"),
    description: document.querySelector("[data-detail-description]"),
    credit: document.querySelector("[data-detail-credit]"),
    main: document.querySelector("[data-detail-main]"),
    thumbs: document.querySelector("[data-detail-thumbs]"),
    photoGrid: document.querySelector("[data-photo-grid]")
  };

  let activeFilter = "All";
  let query = "";
  let selectedProject = projects[0] || null;
  let revealObserver = null;

  function shortText(text, maxLength) {
    const copy = String(text || "");
    if (copy.length <= maxLength) return copy;
    return `${copy.slice(0, maxLength).trim()}...`;
  }

  function projectMeta(project) {
    return [project.year, `${project.location}, AB`, project.category].filter(Boolean).join(" / ");
  }

  function projectUrl(project) {
    const prefix = document.body.classList.contains("project-page") ? "../../" : "";
    return `${prefix}projects/${project.slug}/index.html`;
  }

  function setText(element, value) {
    if (element) element.textContent = value || "";
  }

  function createImage(src, alt) {
    const image = document.createElement("img");
    image.src = src;
    image.alt = alt;
    image.loading = "lazy";
    image.decoding = "async";
    return image;
  }

  function matchesProject(project) {
    const matchesFilter = activeFilter === "All" || project.category === activeFilter;
    const haystack = [
      project.title,
      project.category,
      project.location,
      project.year,
      project.description,
      project.credit
    ]
      .join(" ")
      .toLowerCase();

    return matchesFilter && (!query || haystack.includes(query));
  }

  function observeReveal(element) {
    if (!element) return;
    if (!revealObserver) {
      element.classList.add("is-visible");
      return;
    }
    element.classList.add("will-reveal");
    revealObserver.observe(element);
  }

  function setupReveal() {
    const baseItems = document.querySelectorAll(
      ".hero-board article, .offer-section, .selected-head, .project-showcase, .archive-head, .project-tools, .project-detail, .project-photo-block, .contact-form-block, .contact-aside"
    );

    if (!("IntersectionObserver" in window) || window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      baseItems.forEach((item) => item.classList.add("is-visible"));
      return;
    }

    revealObserver = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return;
          entry.target.classList.add("is-visible");
          revealObserver.unobserve(entry.target);
        });
      },
      { threshold: 0.12, rootMargin: "0px 0px -8% 0px" }
    );

    baseItems.forEach(observeReveal);
  }

  function renderRail() {
    if (!railMount) return;
    railMount.replaceChildren();

    const featured = projects.filter((project) => project.featured).slice(0, 7);
    const railProjects = featured.length >= 5 ? featured : projects.slice(0, 7);

    railProjects.forEach((project) => {
      const button = document.createElement("button");
      button.className = "rail-item";
      button.type = "button";
      button.dataset.slug = project.slug;
      button.setAttribute("aria-pressed", String(selectedProject && selectedProject.slug === project.slug));

      const title = document.createElement("strong");
      title.textContent = project.title;

      const meta = document.createElement("span");
      meta.textContent = `${project.location}, AB`;

      button.append(title, meta);
      button.addEventListener("click", () => {
        selectProject(project, false);
      });

      railMount.append(button);
    });
  }

  function renderProjectMenus() {
    const menuTargets = [projectDropdown, mobileProjectList].filter(Boolean);
    if (!menuTargets.length) return;

    menuTargets.forEach((target) => {
      target.replaceChildren();
      projects.forEach((project) => {
        const link = document.createElement("a");
        link.href = projectUrl(project);
        link.textContent = project.title;
        target.append(link);
      });
    });
  }

  function renderSelectedCards() {
    if (!selectedCardsMount) return;
    selectedCardsMount.replaceChildren();

    const cardProjects = projects.length > 8 ? projects.slice(3, 11) : projects.slice(0, 8);

    cardProjects.forEach((project) => {
      const link = document.createElement("a");
      link.className = "selected-mini-card";
      link.href = projectUrl(project);
      link.dataset.slug = project.slug;

      const image = createImage(project.image, `${project.title} project preview`);
      const copy = document.createElement("span");
      copy.className = "selected-mini-copy";

      const index = document.createElement("span");
      index.textContent = project.index;

      const title = document.createElement("strong");
      title.textContent = project.title;

      const meta = document.createElement("em");
      meta.textContent = `${project.location}, AB`;

      copy.append(index, title, meta);
      link.append(image, copy);
      selectedCardsMount.append(link);
    });
  }

  function setActiveCards(project) {
    document.querySelectorAll("[data-slug]").forEach((item) => {
      const isActive = item.dataset.slug === project.slug;
      item.classList.toggle("is-active", isActive);
      if (item.classList.contains("rail-item")) {
        item.setAttribute("aria-pressed", String(isActive));
      }
    });
  }

  function updateStage(project) {
    if (!project || !stage.root) return;

    selectedProject = project;
    stage.root.classList.add("is-switching");

    window.setTimeout(() => {
      if (stage.image) {
        stage.image.src = project.image;
        stage.image.alt = `${project.title} project image`;
      }

      setText(stage.category, project.category);
      setText(stage.title, project.title);
      setText(stage.description, shortText(project.description, 154));
      setText(stage.location, `${project.location}, AB`);
      setText(stage.year, project.year);
      setText(stage.type, project.category);
      if (stageMore) stageMore.href = projectUrl(project);
      setActiveCards(project);
      stage.root.classList.remove("is-switching");
    }, 90);
  }

  function updateDetail(project) {
    if (!project || !detail.root) return;

    const gallery = Array.isArray(project.gallery) && project.gallery.length ? project.gallery : [project.image];
    const firstImage = gallery[0];

    setText(detail.title, project.title);
    setText(detail.meta, projectMeta(project));
    setText(detail.description, project.description);
    setText(detail.credit, project.credit || "PI Design Group");

    if (detail.main) {
      detail.main.src = firstImage;
      detail.main.alt = `${project.title} selected project image`;
    }

    if (!detail.thumbs) return;
    detail.thumbs.replaceChildren();

    gallery.slice(0, 3).forEach((src, index) => {
      const thumb = document.createElement("button");
      thumb.type = "button";
      thumb.className = `thumb${index === 0 ? " is-active" : ""}`;
      thumb.setAttribute("aria-label", `Show ${project.title} image ${index + 1}`);
      thumb.append(createImage(src, `${project.title} thumbnail ${index + 1}`));

      thumb.addEventListener("click", () => {
        if (detail.main) {
          detail.main.src = src;
          detail.main.alt = `${project.title} selected project image ${index + 1}`;
        }
        detail.thumbs.querySelectorAll(".thumb").forEach((item) => item.classList.remove("is-active"));
        thumb.classList.add("is-active");
      });

      detail.thumbs.append(thumb);
    });
  }

  function selectProject(project, shouldScroll) {
    if (!project) return;
    updateStage(project);
    updateDetail(project);

    if (shouldScroll && detail.root) {
      detail.root.scrollIntoView({ behavior: "smooth", block: "center" });
    }
  }

  function isPlaceholderProject(project) {
    if (!project) return false;
    if (project.placeholder === true) return true;
    const image = String(project.image || "");
    return image.includes("/site/hero.jpg") || image.endsWith("hero.jpg");
  }

  function createProjectCard(project) {
    const button = document.createElement("a");
    button.className = "project-card";
    const placeholder = isPlaceholderProject(project);
    if (placeholder) button.classList.add("is-placeholder");
    button.href = projectUrl(project);
    button.dataset.slug = project.slug;
    button.setAttribute("aria-label", `View ${project.title}`);

    const media = document.createElement("span");
    media.className = "card-media";

    const indexBadge = document.createElement("span");
    indexBadge.className = "card-index";
    indexBadge.textContent = project.index;

    const categoryBadge = document.createElement("span");
    categoryBadge.className = "card-category";
    categoryBadge.textContent = project.category;

    if (placeholder) {
      const placeholderMark = document.createElement("span");
      placeholderMark.className = "card-placeholder-mark";
      placeholderMark.textContent = project.index;
      media.append(indexBadge, categoryBadge, placeholderMark);
    } else {
      media.append(indexBadge, categoryBadge, createImage(project.image, `${project.title} project image`));
    }

    const copy = document.createElement("span");
    copy.className = "card-copy";

    const title = document.createElement("h3");
    title.textContent = project.title;

    const meta = document.createElement("p");
    meta.textContent = `${project.location}, AB · ${project.year}`;

    const cta = document.createElement("span");
    cta.className = "card-cta";
    const ctaLabel = document.createElement("span");
    ctaLabel.textContent = placeholder ? "Coming soon" : "View project";
    cta.append(ctaLabel);
    cta.insertAdjacentHTML(
      "beforeend",
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6"></path></svg>'
    );

    copy.append(title, meta, cta);
    button.append(media, copy);
    return button;
  }

  const MOBILE_PROJECT_LIMIT = 10;
  let mobileExpanded = false;
  let mobileToggleHandle = null;

  function applyMobileCollapse() {
    if (!gridMount) return;
    const isMobile = window.matchMedia("(max-width: 900px)").matches;
    const cards = Array.from(gridMount.querySelectorAll(".project-card"));

    cards.forEach((card, index) => {
      const shouldHide = isMobile && !mobileExpanded && index >= MOBILE_PROJECT_LIMIT;
      card.classList.toggle("is-mobile-hidden", shouldHide);
    });

    if (mobileToggleHandle) {
      const hidden = isMobile && !mobileExpanded && cards.length > MOBILE_PROJECT_LIMIT;
      mobileToggleHandle.button.hidden = !hidden;
      const remaining = Math.max(cards.length - MOBILE_PROJECT_LIMIT, 0);
      mobileToggleHandle.label.textContent = `Show ${remaining} more project${remaining === 1 ? "" : "s"}`;
    }
  }

  function ensureMobileToggle() {
    if (mobileToggleHandle || !gridMount || !gridMount.parentElement) return;
    const button = document.createElement("button");
    button.type = "button";
    button.className = "project-grid-more";
    button.hidden = true;
    const label = document.createElement("span");
    label.textContent = "Show more projects";
    button.append(label);
    button.insertAdjacentHTML(
      "beforeend",
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M6 9l6 6 6-6"></path></svg>'
    );

    button.addEventListener("click", () => {
      mobileExpanded = true;
      applyMobileCollapse();
    });

    gridMount.parentElement.insertBefore(button, gridMount.nextSibling);
    mobileToggleHandle = { button, label };

    window.addEventListener("resize", applyMobileCollapse, { passive: true });
  }

  function renderProjects() {
    if (!gridMount) return;
    gridMount.replaceChildren();

    const visible = projects.filter(matchesProject);
    visible.forEach((project) => {
      const card = createProjectCard(project);
      gridMount.append(card);
      observeReveal(card);
    });

    if (!visible.length) {
      const empty = document.createElement("div");
      empty.className = "empty-state";
      empty.textContent = "No projects match the current filters.";
      gridMount.append(empty);
    }

    if (projectCount) {
      projectCount.textContent = `${visible.length} ${visible.length === 1 ? "Project" : "Projects"}`;
    }

    if (selectedProject) setActiveCards(selectedProject);

    ensureMobileToggle();
    mobileExpanded = false;
    applyMobileCollapse();
  }

  function setFilter(nextFilter) {
    activeFilter = nextFilter;
    filters.forEach((button) => {
      const isActive = button.dataset.filter === activeFilter;
      button.classList.toggle("is-active", isActive);
      button.setAttribute("aria-pressed", String(isActive));
    });
    renderProjects();
  }

  function initHeroVideo() {
    const video = document.querySelector("[data-hero-video]");
    if (!video) return;

    const source = video.dataset.heroVideo;
    if (!source) return;

    const markReady = () => video.classList.add("is-ready");
    video.addEventListener("loadeddata", markReady, { once: true });
    video.addEventListener("canplay", markReady, { once: true });

    if (video.canPlayType("application/vnd.apple.mpegurl")) {
      video.src = source;
      video.play().catch(() => {});
      return;
    }

    if (window.Hls && window.Hls.isSupported()) {
      const hls = new window.Hls({
        enableWorker: true,
        lowLatencyMode: true,
        backBufferLength: 60
      });

      hls.loadSource(source);
      hls.attachMedia(video);
      hls.on(window.Hls.Events.MANIFEST_PARSED, () => {
        video.play().catch(() => {});
      });
      hls.on(window.Hls.Events.ERROR, (_event, data) => {
        if (data && data.fatal) {
          hls.destroy();
        }
      });
    }
  }

  function initHeaderScroll() {
    const header = document.querySelector("[data-header]");
    if (!header) return;

    const apply = () => {
      const next = window.scrollY > 8;
      header.classList.toggle("is-scrolled", next);
    };
    apply();
    window.addEventListener("scroll", apply, { passive: true });
  }

  function initMenu() {
    if (!menuToggle || !mobileMenu) return;

    menuToggle.addEventListener("click", () => {
      const next = menuToggle.getAttribute("aria-expanded") !== "true";
      menuToggle.setAttribute("aria-expanded", String(next));
      mobileMenu.classList.toggle("is-open", next);
      document.body.classList.toggle("menu-open", next);
    });

    mobileMenu.querySelectorAll("a").forEach((link) => {
      link.addEventListener("click", () => {
        menuToggle.setAttribute("aria-expanded", "false");
        mobileMenu.classList.remove("is-open");
        document.body.classList.remove("menu-open");
      });
    });
  }

  function initNavState() {
    const sections = Array.from(document.querySelectorAll("main section[id]"));
    if (!("IntersectionObserver" in window) || !sections.length) return;

    function setActiveNav(href) {
      navLinks.forEach((link) => {
        link.classList.toggle("is-active", link.getAttribute("href") === href);
      });
    }

    const observer = new IntersectionObserver(
      (entries) => {
        if (window.scrollY < sections[0].offsetTop - 160) {
          setActiveNav("#top");
          return;
        }

        const current = entries
          .filter((entry) => entry.isIntersecting)
          .sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0];

        if (!current) return;
        setActiveNav(`#${current.target.id}`);
      },
      { threshold: [0.26, 0.48, 0.68], rootMargin: "-20% 0px -45% 0px" }
    );

    sections.forEach((section) => observer.observe(section));
    setActiveNav("#top");
  }

  function initProjectViewer() {
    const viewer = document.querySelector("[data-project-viewer]");
    if (!viewer) return;

    const image = viewer.querySelector("[data-viewer-image]");
    const count = viewer.querySelector("[data-viewer-count]");
    const prev = viewer.querySelector("[data-viewer-prev]");
    const next = viewer.querySelector("[data-viewer-next]");
    let zoom = viewer.querySelector("[data-viewer-zoom]");
    const thumbs = Array.from(document.querySelectorAll("[data-viewer-thumb]"));
    const projectTitle = document.querySelector("#project-title")?.textContent || document.title.replace(" | Pi Design Group.", "");

    if (!image || !thumbs.length) return;
    if (!zoom) {
      zoom = document.createElement("button");
      zoom.className = "viewer-zoom";
      zoom.type = "button";
      zoom.dataset.viewerZoom = "";
      zoom.setAttribute("aria-label", "Zoom selected image");
      zoom.innerHTML = '<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="10.5" cy="10.5" r="5.5"></circle><path d="M15 15l5 5"></path></svg>';
      viewer.append(zoom);
    }

    let activeIndex = 0;
    let lightbox = null;
    let lightboxImage = null;
    let lightboxCount = null;
    let lightboxTitle = null;

    thumbs.forEach((thumb, index) => {
      if (!thumb.dataset.indexLabel) thumb.dataset.indexLabel = String(index + 1).padStart(2, "0");
    });

    function imageData(index) {
      const thumb = thumbs[(index + thumbs.length) % thumbs.length];
      return {
        src: thumb.dataset.full,
        alt: thumb.dataset.alt || `${projectTitle} image ${index + 1}`,
        label: thumb.dataset.indexLabel || String(index + 1).padStart(2, "0")
      };
    }

    function show(index) {
      activeIndex = (index + thumbs.length) % thumbs.length;
      const data = imageData(activeIndex);
      viewer.classList.add("is-changing");
      image.src = data.src;
      image.alt = data.alt;
      if (count) count.textContent = `${String(activeIndex + 1).padStart(2, "0")} / ${String(thumbs.length).padStart(2, "0")}`;
      thumbs.forEach((item, itemIndex) => {
        const isActive = itemIndex === activeIndex;
        item.classList.toggle("is-active", isActive);
        item.setAttribute("aria-pressed", String(isActive));
      });
      window.setTimeout(() => viewer.classList.remove("is-changing"), 190);
    }

    function createLightbox() {
      if (lightbox) return;

      lightbox = document.createElement("div");
      lightbox.className = "image-lightbox";
      lightbox.dataset.lightbox = "";
      lightbox.hidden = true;
      lightbox.innerHTML = `
        <button class="lightbox-close" type="button" data-lightbox-close>Close</button>
        <button class="lightbox-nav" type="button" aria-label="Previous image" data-lightbox-prev>&larr;</button>
        <figure class="lightbox-figure">
          <img src="" alt="" data-lightbox-image>
          <figcaption>
            <span data-lightbox-count></span>
            <strong data-lightbox-title></strong>
          </figcaption>
        </figure>
        <button class="lightbox-nav" type="button" aria-label="Next image" data-lightbox-next>&rarr;</button>
      `;
      document.body.append(lightbox);

      lightboxImage = lightbox.querySelector("[data-lightbox-image]");
      lightboxCount = lightbox.querySelector("[data-lightbox-count]");
      lightboxTitle = lightbox.querySelector("[data-lightbox-title]");

      lightbox.querySelector("[data-lightbox-close]")?.addEventListener("click", closeLightbox);
      lightbox.querySelector("[data-lightbox-prev]")?.addEventListener("click", () => setLightbox(activeIndex - 1));
      lightbox.querySelector("[data-lightbox-next]")?.addEventListener("click", () => setLightbox(activeIndex + 1));
      lightbox.addEventListener("click", (event) => {
        if (event.target === lightbox) closeLightbox();
      });

      document.addEventListener("keydown", (event) => {
        if (!lightbox || lightbox.hidden) return;
        if (event.key === "Escape") {
          closeLightbox();
          return;
        }
        if (event.key === "ArrowLeft") setLightbox(activeIndex - 1);
        if (event.key === "ArrowRight") setLightbox(activeIndex + 1);
      });
    }

    function setLightbox(index) {
      show(index);
      const data = imageData(activeIndex);
      if (lightboxImage) {
        lightboxImage.src = data.src;
        lightboxImage.alt = data.alt;
      }
      if (lightboxCount) lightboxCount.textContent = `${String(activeIndex + 1).padStart(2, "0")} / ${String(thumbs.length).padStart(2, "0")}`;
      if (lightboxTitle) lightboxTitle.textContent = projectTitle;
    }

    function openLightbox(index) {
      createLightbox();
      setLightbox(index);
      lightbox.hidden = false;
      document.body.classList.add("lightbox-open");
      window.requestAnimationFrame(() => lightbox.classList.add("is-open"));
    }

    function closeLightbox() {
      if (!lightbox) return;
      lightbox.classList.remove("is-open");
      document.body.classList.remove("lightbox-open");
      window.setTimeout(() => {
        if (lightbox && !lightbox.classList.contains("is-open")) lightbox.hidden = true;
      }, 220);
    }

    thumbs.forEach((thumb, index) => {
      thumb.setAttribute("aria-pressed", String(index === 0));
      thumb.addEventListener("click", () => show(index));
    });

    if (prev) prev.addEventListener("click", () => show(activeIndex - 1));
    if (next) next.addEventListener("click", () => show(activeIndex + 1));
    if (zoom) zoom.addEventListener("click", () => openLightbox(activeIndex));
    image.tabIndex = 0;
    image.setAttribute("role", "button");
    image.setAttribute("aria-label", "Zoom selected image");
    image.addEventListener("click", () => openLightbox(activeIndex));
    image.addEventListener("keydown", (event) => {
      if (event.key !== "Enter" && event.key !== " ") return;
      event.preventDefault();
      openLightbox(activeIndex);
    });

    const photoTiles = Array.from(document.querySelectorAll("[data-photo-tile]"));
    photoTiles.forEach((tile, index) => {
      tile.addEventListener("click", () => openLightbox(index));
    });

    show(0);
  }

  function initContactForm() {
    const form = document.querySelector("[data-contact-form]");
    if (!form) return;

    form.addEventListener("submit", (event) => {
      event.preventDefault();
      if (!form.reportValidity()) return;

      const data = new FormData(form);
      const recipient = form.dataset.recipient || "peter@pidesigngroup.ca";
      const name = String(data.get("name") || "").trim();
      const company = String(data.get("company") || "").trim();
      const email = String(data.get("email") || "").trim();
      const phone = String(data.get("phone") || "").trim();
      const projectType = String(data.get("project_type") || "").trim();
      const message = String(data.get("message") || "").trim();
      const subjectName = company || name || "Website inquiry";
      const subject = `PI Design Group project brief - ${subjectName}`;
      const body = [
        "New project brief from the PI Design Group website.",
        "",
        `Name: ${name}`,
        `Company: ${company || "N/A"}`,
        `Email: ${email}`,
        `Phone: ${phone || "N/A"}`,
        `Project type: ${projectType || "N/A"}`,
        "",
        "Project brief:",
        message
      ].join("\n");

      window.location.href = `mailto:${recipient}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
    });
  }

  function initPageTransitions() {
    const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduceMotion) return;

    document.addEventListener("click", (event) => {
      const link = event.target.closest("a[href]");
      if (!link || event.defaultPrevented) return;
      if (event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
      if (link.target && link.target !== "_self") return;
      if (link.hasAttribute("download")) return;

      const rawHref = link.getAttribute("href") || "";
      if (!rawHref || rawHref.startsWith("#")) return;

      const url = new URL(link.href, window.location.href);
      const current = new URL(window.location.href);
      const skipProtocols = ["mailto:", "tel:", "javascript:"];
      if (skipProtocols.includes(url.protocol)) return;
      if (url.origin !== current.origin) return;
      if (url.href === current.href) return;
      if (url.pathname === current.pathname && url.hash) return;

      event.preventDefault();
      document.body.classList.add("is-leaving");
      window.setTimeout(() => {
        window.location.href = url.href;
      }, 220);
    });
  }

  filters.forEach((button) => {
    button.setAttribute("aria-pressed", String(button.classList.contains("is-active")));
    button.addEventListener("click", () => setFilter(button.dataset.filter));
  });

  const offerPreview = document.querySelector("[data-offer-preview]");
  const offerPreviewImage = document.querySelector("[data-offer-image]");
  const offerPreviewTag = document.querySelector("[data-offer-tag]");
  const offerPreviewProject = document.querySelector("[data-offer-project]");
  const offerPreviewTitle = document.querySelector("[data-offer-title]");
  const offerPreviewBlurb = document.querySelector("[data-offer-blurb]");

  function updateOfferPreview(button) {
    if (!offerPreview) return;
    const num = button.querySelector(".offer-num")?.textContent || "";
    const title = button.dataset.service || button.querySelector("strong")?.textContent || "";
    const image = button.dataset.image;
    const project = button.dataset.project || "";
    const blurb = button.dataset.blurb || "";

    offerPreview.classList.add("is-changing");
    window.setTimeout(() => {
      if (offerPreviewImage && image) {
        offerPreviewImage.src = image;
        offerPreviewImage.alt = `${title} preview`;
      }
      if (offerPreviewTag) offerPreviewTag.textContent = `${num} ${title}`.trim();
      if (offerPreviewProject) offerPreviewProject.textContent = project;
      if (offerPreviewTitle) offerPreviewTitle.textContent = title;
      if (offerPreviewBlurb) offerPreviewBlurb.textContent = blurb;
      offerPreview.classList.remove("is-changing");
    }, 110);
  }

  offerButtons.forEach((button) => {
    button.setAttribute("aria-pressed", String(button.classList.contains("is-active")));

    const activate = () => {
      offerButtons.forEach((item) => {
        const isActive = item === button;
        item.classList.toggle("is-active", isActive);
        item.setAttribute("aria-pressed", String(isActive));
      });
      updateOfferPreview(button);
    };

    button.addEventListener("click", activate);
    button.addEventListener("mouseenter", activate);
    button.addEventListener("focus", activate);
  });

  if (searchInput) {
    searchInput.addEventListener("input", () => {
      query = searchInput.value.trim().toLowerCase();
      renderProjects();
    });
  }

  if (clearButton) {
    clearButton.addEventListener("click", () => {
      query = "";
      if (searchInput) searchInput.value = "";
      setFilter("All");
    });
  }

  setupReveal();
  renderProjectMenus();
  renderRail();
  renderSelectedCards();
  renderProjects();
  selectProject(selectedProject, false);
  initHeroVideo();
  initHeaderScroll();
  initMenu();
  initNavState();
  initProjectViewer();
  initContactForm();
  initPageTransitions();
})();
