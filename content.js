/*
 * Shared portfolio data used by the reusable project page.
 * Stable project IDs and slugs are public routes; array order is the archive order.
 */

const sharedPortfolioVisual = {
  src: "assets/images/architecture-of-elsewhere-2400.jpg",
  srcset:
    "assets/images/architecture-of-elsewhere-1400.jpg 1400w, assets/images/architecture-of-elsewhere-2400.jpg 2400w",
  width: 2400,
  height: 1293,
  orientation: "wide",
  fit: "contain",
  mediaClass: "media--board",
  alt:
    "Architecture of Elsewhere collage combining a white architectural model with planetary studies, technical line drawings, and a dark research field."
};

const siteContent = {
  meta: {
    title: "Ahmad Alhadidii — Architecture & Design Portfolio",
    description:
      "The architecture and design portfolio of Ahmad Alhadidii — أحمد الحديدي, presenting architectural projects, design research, computational work, drawings, and visual explorations."
  },

  person: {
    name: "Ahmad Alhadidii",
    displayName: "AHMAD ALHADIDII",
    location: "As-Salt, Jordan",
    portrait: {
      src: "assets/images/profile.webp",
      srcset: "",
      width: 1200,
      height: 1500,
      orientation: "portrait",
      fit: "contain",
      mediaClass: "media--portrait media--cutout",
      label: "PROFILE IMAGE / 001",
      title: "AHMAD ALHADIDII",
      caption: "SUBJECT RECORD / ARCHITECTURE · RESEARCH · COMPUTATION",
      alt:
        "Portrait of Ahmad Alhadidii wearing round glasses and a dark pinstriped jacket."
    },
    roles: [
      "Architect",
      "Design Researcher",
      "Computational Designer"
    ]
  },

  visuals: [
    {
      id: "visual-architecture-of-elsewhere",
      slug: "architecture-of-elsewhere",
      index: "01",
      title: "Architecture of Elsewhere",
      year: "2026",
      category: "Visual Narrative / Conceptual Architecture",
      description:
        "Somewhere between the last drawn line and the first built wall, the ground begins to slip away from the familiar. Paths stretch forward, fragments hover, and the building appears as if it is still deciding what world it belongs to. Above it, distant planets turn the horizon from an ending into an opening. Architecture of Elsewhere holds that unfinished moment when a place is no longer entirely here, but has not yet fully arrived anywhere else.",
      emphasis: "Architecture of Elsewhere",
      accent: "#9b5b35",
      context:
        "This image originated from a shot developed during the ManMaTIC process, but it is presented here as an independent visual narrative and architectural experiment. It is not an accurate image or literal rendering of the ManMaTIC building; the actual design does not resemble this architecture.",
      src: "assets/images/architecture-of-elsewhere-2400.jpg",
      srcset:
        "assets/images/architecture-of-elsewhere-1400.jpg 1400w, assets/images/architecture-of-elsewhere-2400.jpg 2400w",
      width: 2400,
      height: 1293,
      orientation: "wide",
      fit: "contain",
      mediaClass: "media--wide media--board",
      caption: "VISUAL 01 / ARCHITECTURE OF ELSEWHERE / 2026",
      authorship: "Ahmad Alhadidii",
      process: "Original composition, digital drawing, and manual post-production",
      tools: "Digital drawing and image-editing tools",
      aiRole: "None",
      alt:
        "Architectural collage with pale ramped building forms, a black research field, the code A-H26, planetary studies, and white technical linework."
    },
    {
      id: "visual-drawn-out-of-red",
      slug: "drawn-out-of-red",
      index: "02",
      title: "Drawn Out of Red",
      year: "2026",
      category: "Visual Narrative / Atmospheric Study",
      description:
        "Before the place disappears, red holds it in a final moment between presence and erasure. It fills the air, closes the distance, and leaves the world almost without form. Then a few lines of light cut through—not enough to reveal everything, but enough to pull edges, depth, and space back into existence. What appears is not simply illuminated; it is rescued from the colour that nearly consumed it. Drawn Out of Red asks: if light is the last thing keeping a place alive, what remains when it is gone?",
      emphasis: "Drawn Out of Red",
      accent: "#8f241f",
      context: "Independent visual narrative / atmospheric study.",
      src: "assets/images/drawn-out-of-red.webp",
      srcset:
        "assets/images/drawn-out-of-red-1400.webp 1400w, assets/images/drawn-out-of-red.webp 2400w",
      width: 2400,
      height: 1293,
      orientation: "wide",
      fit: "contain",
      mediaClass: "media--wide media--cinematic",
      caption: "VISUAL 02 / DRAWN OUT OF RED / 2026",
      authorship: "Ahmad Alhadidii",
      process: "Original composition, digital drawing, and manual post-production",
      tools: "Digital drawing and image-editing tools",
      aiRole: "None",
      alt:
        "Red and black architectural visualization of a low complex beneath a dark red sky, traced with thin luminous lines."
    },
    {
      id: "visual-stone-by-moonlight",
      slug: "stone-by-moonlight",
      index: "03",
      title: "Stone by Moonlight",
      year: "2026",
      category: "Visual Narrative / Material and Light Study",
      relatedProject: "Shila Museum",
      description:
        "Before the night passes, the stone is given one quiet moment beneath the moon. Its roughness no longer speaks only of weight; in the pale light, something ancient begins to feel intimate. The stair does not lead toward a destination, but keeps the body within this encounter, allowing the stone to disappear and return with every step. Stone by Moonlight holds a brief meeting between earth and sky—between something shaped over millions of years and the light that touches it for only a night.",
      emphasis: "Stone by Moonlight",
      accent: "#8b603d",
      context:
        "Related to Shila Museum; presented through the visual narrative of stone, light, and spatial encounter rather than as an explanation of the full project.",
      src: "assets/images/stone-by-moonlight.webp",
      srcset:
        "assets/images/stone-by-moonlight-1400.webp 1400w, assets/images/stone-by-moonlight.webp 2400w",
      width: 2400,
      height: 1293,
      orientation: "wide",
      fit: "contain",
      mediaClass: "media--wide media--board",
      caption: "VISUAL 03 / STONE BY MOONLIGHT / 2026",
      authorship: "Ahmad Alhadidii",
      process: "Original composition, digital drawing, and manual post-production",
      tools: "Digital drawing and image-editing tools",
      aiRole: "None",
      alt:
        "Architectural collage of a stepped interior drawn in luminous multicoloured lines beneath a grayscale moon."
    },
    {
      id: "visual-the-mechanics-of-becoming",
      slug: "the-mechanics-of-becoming",
      index: "04",
      title: "The Mechanics of Becoming",
      year: "2026",
      category: "Spatial Narrative / Human–Machine History",
      description:
        "Human–Machine History traces the long evolution of the bond between humans, tools, machines, and technological systems. The journey begins with the Agricultural Revolution, when early tools changed how societies lived, worked, and organized themselves. Visitors move through a stone-carved timeline as inventions and mechanisms unfold across centuries of progress. Compressed sloping walls, filtered light, and engraved histories turn development into an immersive spatial sequence. The Mechanics of Becoming reveals the machine not as something separate from the human, but as part of humanity’s continuous becoming.",
      emphasis: "The Mechanics of Becoming",
      accent: "#835b37",
      context: "Human–Machine History / immersive spatial narrative.",
      src: "assets/images/the-mechanics-of-becoming.webp",
      srcset:
        "assets/images/the-mechanics-of-becoming-1100.webp 1100w, assets/images/the-mechanics-of-becoming.webp 1724w",
      width: 1724,
      height: 1293,
      orientation: "landscape",
      fit: "contain",
      mediaClass: "media--landscape media--render",
      caption: "VISUAL 04 / THE MECHANICS OF BECOMING / 2026",
      authorship: "Ahmad Alhadidii",
      process: "Author-directed composition, material development, textures, light, shadow, stone detailing, atmosphere, Photoshop editing, and digital painting",
      tools: "Photoshop and digital painting tools",
      aiRole: "Early exploratory visualisation for initial renderings and selected graphic elements",
      finalProcess: "Composition, material development, textures, light, shadow, stone detailing, atmosphere, Photoshop editing, and digital painting by Ahmad Alhadidii",
      alt:
        "Warm sepia corridor of monumental engraved stone walls, an olive tree, mechanical artefacts, and a solitary walking figure."
    },
    {
      id: "visual-the-last-room-before-tomorrow",
      slug: "the-last-room-before-tomorrow",
      index: "05",
      title: "The Last Room Before Tomorrow",
      year: "2026",
      category: "Speculative Spatial Narrative / Human–Machine Futures",
      description:
        "Before tomorrow becomes real, this room holds both a warning and a beginning. The fractured stone is not merely a sign of collapse; it images a human–machine future left without human judgment, where machines continue to move while people remain outside the logic that guides them. Yet the transparent orange layer suggests another possibility: potential remains visible, unfinished, and waiting to be shaped. The Last Room Before Tomorrow is where fear becomes a question, and the question becomes action. If a better future can still be formed, will you take part in shaping it?",
      emphasis: "The Last Room Before Tomorrow",
      accent: "#9a4d2b",
      context:
        "Conceptually connected to ManMaTIC; presented as an independent visual narrative rather than a literal project rendering.",
      src: "assets/images/the-last-room-before-tomorrow.webp",
      srcset:
        "assets/images/the-last-room-before-tomorrow-900.webp 900w, assets/images/the-last-room-before-tomorrow.webp 1272w",
      width: 1272,
      height: 1293,
      orientation: "square",
      fit: "contain",
      mediaClass: "media--square media--render",
      caption: "VISUAL 05 / THE LAST ROOM BEFORE TOMORROW / 2026",
      authorship: "Ahmad Alhadidii",
      process: "Author-directed composition, material development, textures, light, shadow, detailing, atmosphere, Photoshop editing, and digital painting",
      tools: "Photoshop and digital painting tools",
      aiRole: "Early exploratory visualisation for initial renderings and selected graphic elements",
      finalProcess: "Composition, material development, textures, light, shadow, detailing, atmosphere, Photoshop editing, and digital painting by Ahmad Alhadidii",
      alt:
        "Near-square sepia interior with fractured stone, suspended machinery, information screens, and a wall inscribed with a text about potential."
    }
  ],

  computations: [
    {
      id: "computational-study-01",
      slug: "animated-parametric-model",
      number: "01",
      title: "COMPUTATIONAL STUDY 01 / ANIMATED PARAMETRIC MODEL",
      subtitle: "TITLE PENDING SCRIPT INSPECTION",
      statement: "A computational study authored through a Rhino and Grasshopper workflow. The geometric operation, controlled parameters, transformation driver, and final title remain deliberately unstated until the original definition and animation are available for inspection.",
      sequence: ["Input", "Script", "Transformation", "Behaviour", "Spatial Output"],
      status: "SOURCE FILES REQUIRED",
      sourceRequirements: ["Rhino model", "Grasshopper definition", "Animation video", "Model photographs"],
      equation: null,
      media: []
    },
    {
      id: "computational-study-02",
      slug: "lemniscate-ramp",
      number: "02",
      title: "LEMNISCATE RAMP",
      subtitle: "FROM EQUATION TO CIRCULATION",
      statement: "A mathematical curve is translated into an architectural path. The equation field remains blank until the exact curve and expression can be verified from the original script.",
      sequence: ["Equation", "Curve", "Control Geometry", "Ramp", "Movement"],
      status: "EQUATION AND SOURCE FILES REQUIRED",
      sourceRequirements: ["Grasshopper definition", "Equation source", "Curve geometry", "Process animation"],
      equation: null,
      media: []
    }
  ],

  projects: [
    {
      id: "project-05",
      slug: "project-05",
      number: "001",
      archiveTitle: "SHILA (STONE) MUSEUM",
      archiveSubtitle: "THE QUARRY THAT FOLDS INWARD",
      navigationTitle: "Shila (Stone) Museum — The Quarry That Folds Inward",
      title: "The Quarry That Folds Inward",
      definition:
        "A museum concept where the quarry folds inward, turning stone, water, shadow, and void into spatial memory.",
      overview:
        "Shila (Stone) Museum explores stone as both material and meaning through an architectural journey carved into a quarry. The quarry becomes the exhibition: descending and ascending paths reveal relationships between earth, time, water, and memory, culminating in a place of arrival and reflection.",
      year: "2025",
      location: "Sadahalli Quarry / Bengaluru, India",
      category: "The Drawing Board 2025 / Echoes in Stone",
      type: "Museum of Geology / Quarry Intervention",
      role: "Concept, site response, spatial narrative, design development, drawing, visual communication",
      themes: ["Museum", "Stone", "Atmosphere"],
      points: [
        "Uses quarry logic as spatial generator.",
        "Frames stone as memory, not surface finish.",
        "Builds atmosphere through water, void, shadow, and mass."
      ],
      featured: true,
      displayOrder: 1,
      sections: [
        {
          code: "02",
          title: "THE QUARRY THAT FOLDS INWARD",
          text: "Shila (Stone) Museum begins where the quarry folds inward. Instead of treating the quarry as a background, the project turns its cut ground into the exhibition itself. The visitor moves into the depth of the stone through carved layers, water, shadow, and open voids shaped by geological time. As the quarry folds, walls, paths, and platforms emerge from the same rock body, making the museum part of the quarry rather than an object placed inside it."
        },
        {
          code: "03",
          title: "THE QUARRY AS AN EXISTING CONDITION",
          text: "Granite extraction has already produced walls, voids, ledges, platforms, and a deep water field. The approach remains compressed between eucalyptus trees before opening into the quarry. Existing cut lines, changing water levels, retaining walls, and the long granite wall establish the intervention’s scale and orientation.",
          facts: [
            ["LOCATION", "Sadahalli Quarry, Bengaluru"],
            ["MATERIAL", "Granite"],
            ["QUARRY WALL DEPTH", "Approx. 45–50 m"],
            ["PRIMARY EXISTING WALL", "Approx. 100 m"],
            ["WATER", "Seasonally variable"],
            ["APPROACH", "Eucalyptus grove"],
            ["HEIGHT LIMIT", "Entry-platform level"]
          ],
          media: {
            src: "assets/images/shila/shila-site-plan.jpg",
            width: 1200,
            height: 924,
            alt: "Surface site plan showing Shila Museum aligned with the quarry water edge, entry, geological area, promenade, and foyer.",
            caption: "SITE PLAN / SURFACE / EXTRACTED FROM SHILLA02 SOURCE BOARD"
          }
        },
        {
          code: "04",
          title: "DESIGN PRINCIPLES",
          text: "Five source-board principles organise the architectural reading. Their drawings will be separated only when the original high-resolution board is supplied.",
          items: ["Continuity", "Patterned Light", "Sense of Volume", "Principle 04 / source label incomplete", "Mandala Core"],
          media: {
            src: "assets/images/shila/shila-principles.jpg",
            width: 1200,
            height: 382,
            alt: "Five hand-drawn Shila design principles exploring continuity, patterned light, volume, an incomplete fourth source label, and the mandala core.",
            caption: "DESIGN PRINCIPLES / EXTRACTED FROM SHILLA02 SOURCE BOARD"
          }
        },
        {
          code: "05",
          title: "THE DESCENT AS EXPERIENCE",
          text: "The visitor’s journey is organised through controlled differences in level. Movement begins near the quarry surface and gradually descends into the cut ground, changing light, temperature, scale, and material character. After the deepest point, the path rises again and the same quarry walls are encountered from a different direction.",
          media: {
            src: "assets/images/shila/shila-user-experience.jpg",
            width: 1200,
            height: 470,
            alt: "Axonometric fragment showing the descending visitor sequence through Shila Museum.",
            caption: "USER EXPERIENCE / DESCENT AND RETURN"
          }
        },
        {
          code: "06",
          title: "SPATIAL JOURNEY",
          items: ["Approach", "Threshold", "Descent", "Water Edge", "Quarry Depth", "Core", "Ascent", "Reflection"]
        },
        {
          code: "07",
          title: "STONE, WATER, AND REFLECTION",
          text: "The intervention is positioned between exposed granite surfaces and quarry water. Reflection extends the stone beyond its physical edge, allowing the museum to be read as mass, shadow, and mirrored depth."
        },
        {
          code: "08",
          title: "PLANS AND PROGRAMME",
          text: "Strata 1–B1 organises reception, administration, service, exhibition, auditorium, circulation, and a final vista point along the quarry edge.",
          media: {
            src: "assets/images/shila/shila-plan-b1.jpg",
            width: 1200,
            height: 934,
            alt: "Strata 1–B1 plan showing nine numbered rooms along the quarry edge.",
            caption: "PLAN 01 / STRATA 1–B1 / SOURCE BOARD SHILLA03"
          },
          roomIndex: [
            ["01", "Reception"], ["02", "Administration"], ["03", "Office"],
            ["04", "Service"], ["05", "Terrace"], ["06", "Exhibition"],
            ["07", "Auditorium"], ["08", "Exhibition Corridor"], ["09", "Vista Point"]
          ],
          groups: [
            ["EXHIBITION AND PUBLIC", "Permanent galleries / student labs / temporary exhibition / mini-theatre / shop / café / visitor services"],
            ["EDUCATION AND RESEARCH", "Seminar room / research lab / archive / library / administration"],
            ["ADMINISTRATION AND STORAGE", "Staff facilities / artefact storage / maintenance"],
            ["OUTDOOR AND ACCESS", "Open-air theatre / parking / arrival / pathways / quarry platforms"]
          ]
        },
        {
          code: "09",
          title: "SECTIONS / ELEVATIONS",
          text: "The source board records the main elevation and west elevation. Further section orientation and cut labels remain unpublished until their complete drawings are supplied.",
          media: {
            src: "assets/images/shila/shila-elevations.jpg",
            width: 1200,
            height: 782,
            alt: "Main and west elevation drawings extracted from the Shila source board.",
            caption: "MAIN ELEVATION / WEST ELEVATION / SOURCE BOARD SHILLA03"
          }
        }
      ],
      hero: {
        src: "assets/images/shilla.webp",
        srcset:
          "assets/images/shilla-1400.webp 1400w, assets/images/shilla.webp 2400w",
        width: 2400,
        height: 1293,
        orientation: "wide",
        fit: "contain",
        mediaClass: "media--wide media--drawing",
        caption: "SHILA (STONE) MUSEUM / THE QUARRY THAT FOLDS INWARD / 2025",
        alt:
          "Pale architectural drawing of Shila Museum around a reflective quarry pool, with layered stone volumes and a stair rising overhead."
      }
    },
    {
      id: "project-01",
      slug: "project-01",
      number: "002",
      archiveTitle: "MANMATIC",
      archiveSubtitle: "FIELD TO APPLICATION",
      navigationTitle: "ManMaTIC — Field to Application",
      theme: "manmatic",
      title: "ManMaTIC",
      definition: "An architectural methodology for translating changing human–machine conditions into institutional and spatial systems.",
      overview: "ManMaTIC is an architectural research methodology developed to study human–machine integration as a continuously changing subject. It connects research, thesis development, evaluation criteria, author-led design dialogue, technological systems, and spatial decisions within one evolving framework. Rather than producing one fixed formal answer, the methodology establishes a structure through which changing technological conditions can be translated into specific architectural institutions.",
      year: "2026",
      location: "",
      category: "Human–Machine Integration",
      type: "Architectural Research Methodology",
      role: "Architecture, research, systems thinking, visual communication",
      themes: ["Research Institute", "Human–Machine Systems"],
      points: ["DOMAIN / HUMAN–MACHINE INTEGRATION", "STRUCTURE / RESEARCH → CRITERIA → DESIGN → APPLICATION", "STATUS / ACTIVE DEVELOPMENT"],
      featured: true,
      displayOrder: 2,
      sections: [
        {
          code: "01",
          title: "METHODOLOGY",
          text: "MANMATIC is an architectural research methodology developed to study human–machine integration as a continuously changing subject. Research, criteria, design dialogue, technological systems, and spatial decisions remain connected within one evolving framework.",
          facts: [["TYPE", "ARCHITECTURAL RESEARCH METHODOLOGY"], ["DOMAIN", "HUMAN–MACHINE INTEGRATION"], ["STRUCTURE", "RESEARCH → CRITERIA → DESIGN → APPLICATION"], ["STATUS", "ACTIVE DEVELOPMENT"]]
        },
        {
          code: "02",
          title: "THE FIELD",
          text: "The ManMaTIC Field is a project-specific knowledge environment that organises research, thesis logic, case studies, evaluation criteria, design discussions, drawings, systems, and outputs into a readable network. It allows architectural decisions to be traced, compared, questioned, refined, and expanded while the technological subject continues to change.",
          links: [["OPEN MANMATIC FIELD ↗", "https://www.manmatic.institute/"]],
          facts: [["FIELD TYPE", "KNOWLEDGE AND DESIGN OPERATING ENVIRONMENT"], ["FIELD STATE", "ACTIVE RESEARCH NETWORK"]]
        },
        {
          code: "03",
          title: "THESIS + CRITERIA",
          text: "The Field began with the methodological problem of studying a moving subject: machines, artificial intelligence, automation, data systems, and future work evolve faster than conventional architectural research can fully capture. Research therefore remains active through thesis, criteria, design dialogue, and architectural development.",
          groups: [
            ["01 / RESEARCH BEFORE ARCHITECTURE", "Research is treated as an active design structure rather than a preliminary phase."],
            ["02 / FROM RESEARCH TO THESIS FRAMEWORK", "Prospective reading, problem definition, site and context analysis, case studies, theory, function development, programme logic, and system relationships establish the thesis framework."],
            ["03 / FROM THESIS TO EVOLUTION CRITERIA", "Thesis claims are translated into criteria that can be traced, compared, questioned, and revised."],
            ["04 / FROM CRITERIA TO ORION OPERATING FIELD", "Criteria enter an operating field where proposals, evidence, and architectural decisions can be examined together."],
            ["05 / AUTHOR-LED DESIGN DIALOGUE", "The architect remains the author who directs, evaluates, contests, and selects within the human–machine dialogue."]
          ]
        },
        {
          code: "04",
          title: "FIELD INTERFACE",
          text: "The interface makes relationships between research nodes, evidence, criteria, dialogue, drawings, systems, and outputs readable. The manual explains how this information is organised and how selected-node logic supports adaptive knowledge transfer.",
          groups: [["06 / FIELD INTERFACE AND DATA STRUCTURE", "Search, nodes, connections, and selected-node reading panels reveal how project knowledge is related."], ["07 / ADAPTIVE KNOWLEDGE TRANSFER", "New evidence can update the field without separating research from the continuing design process."]],
          media: { src: "assets/images/manmatic-field-live.png", width: 1600, height: 1000, alt: "The actual ManMaTIC Field interface with its node network and reading structure.", caption: "THE MANMATIC FIELD / INTERFACE AND DATA STRUCTURE" }
        },
        {
          code: "05",
          title: "PROTOCOL PORT",
          text: "The Field does not end as a diagram or archive. Its research, criteria, protocols, and design dialogue are translated into a site-specific institutional proposal. Protocol Port is the first architectural application of this process: a Human–Machine Integration Institute developed for Aqaba.",
          status: "UNDER MODIFICATION",
          statusNote: "STILL NEGOTIATING ITS FINAL FORM.",
          facts: [["RELATION", "FIRST ARCHITECTURAL APPLICATION OF MANMATIC"], ["FUNCTION", "HUMAN–MACHINE INTEGRATION INSTITUTE"], ["LOCATION", "AQABA DIGITAL CITY / MIDDLE LOGISTICS AREA / AQABA, JORDAN"]],
          media: {
            src: "assets/images/manmatic/protocol-port-001-1200.jpg",
            width: 1200,
            height: 743,
            alt: "Axonometric drawing of Protocol Port extending across an industrial and logistics landscape with controlled orange elements.",
            caption: "PROTOCOL PORT / APPLICATION 01 / MAIN AXONOMETRIC"
          },
          gallery: [
            { src: "assets/images/manmatic/protocol-port-process-002-900.jpg", width: 506, height: 900, alt: "Protocol Port hand sketches arranged around a pen and laptop.", caption: "PROCESS 002 / HAND-DRAWN DEVELOPMENT" },
            { src: "assets/images/manmatic/protocol-port-process-003-900.jpg", width: 653, height: 900, alt: "Protocol Port elevation sketches and tablet drawing study.", caption: "PROCESS 003 / SECTION AND ELEVATION STUDIES" }
          ]
        }
      ],
      hero: {
        src: "assets/images/manmatic-field-live.png",
        width: 1600,
        height: 1000,
        orientation: "wide",
        fit: "contain",
        mediaClass: "media--wide media--screen",
        alt: "Live ManMaTIC field interface showing the project research network and evidence structure.",
        caption: "THE MANMATIC FIELD / VERIFIED LIVE FIELD CAPTURE"
      }
    },
    {
      id: "project-02",
      slug: "project-02",
      number: "003",
      navigationTitle: "From Concrete Fatigue to Green Asset",
      title: "From Concrete Fatigue to Green Asset",
      definition:
        "A staircase transformation proposal turning daily urban infrastructure into environmental and social value.",
      overview:
        "The project rethinks Jabal Al-Zuhour staircase as more than circulation. Through shade, planting, water management, and social pauses, it turns a repeated daily climb into a green civic asset.",
      year: "2026",
      location: "Amman",
      category: "Environmental Legacy Makers Award / Urban Intervention",
      type: "Urban Stairs / Environmental Design",
      role: "Concept, environmental strategy, visual communication",
      themes: ["Urban Stairs", "Environmental Design"],
      points: [
        "Won first place in the Environmental Legacy Makers Award.",
        "Uses the staircase as daily environmental infrastructure.",
        "Introduces a modular tree unit for shade, planting, and water management."
      ],
      featured: true,
      displayOrder: 3,
      hero: {
        src: "assets/images/green-asset-1920.jpg",
        srcset:
          "assets/images/green-asset-1200.jpg 1200w, assets/images/green-asset-1920.jpg 1920w",
        width: 1920,
        height: 1080,
        orientation: "wide",
        fit: "contain",
        mediaClass: "media--wide media--drawing",
        caption: "FROM CONCRETE FATIGUE TO GREEN ASSET / TREE UNIT IDENTITY STUDY / 2026",
        alt:
          "Environmental design board mapping the transformation of a concrete stair into a vertical garden through infrastructure, social, and natural units."
      }
    },
    {
      id: "project-03",
      slug: "project-03",
      number: "004",
      navigationTitle: "Ground of Continuity",
      title: "Ground of Continuity",
      definition:
        "A cultural map reading Jordan as a ground of continuity between memory, borders, routes, and shared regional identity.",
      overview:
        "Ground of Continuity presents Jordan as a cultural crossroads shaped by memory, movement, trade, displacement, desert routes, and shared Arab imagination.",
      year: "2026",
      location: "Jordan",
      category: "Cultural Map / Visual Research",
      type: "Mapping / Cultural Representation",
      role: "Mapping, cultural research, graphic composition",
      themes: ["Mapping", "Cultural Representation"],
      points: [
        "Maps cultural relationships rather than only geographic borders.",
        "Uses neighboring territories as fields of memory and exchange.",
        "Combines cartographic logic with cultural storytelling."
      ],
      featured: false,
      displayOrder: 99,
      hero: {
        src: "assets/images/ground-of-continuity-2200.jpg",
        srcset:
          "assets/images/ground-of-continuity-1400.jpg 1400w, assets/images/ground-of-continuity-2200.jpg 2200w",
        width: 2200,
        height: 1556,
        orientation: "landscape",
        fit: "contain",
        mediaClass: "media--landscape media--map",
        caption: "GROUND OF CONTINUITY / JORDAN THROUGH MEMORY, MOVEMENT, AND EXCHANGE / 2026",
        alt:
          "Layered cultural map positioning Jordan among regional routes, memory fields, craft traditions, desert passages, and shared histories."
      }
    },
    {
      id: "project-protocol-port",
      slug: "protocol-port",
      number: "002",
      archiveTitle: "PROTOCOL PORT",
      archiveSubtitle: "FIRST ARCHITECTURAL APPLICATION OF THE MANMATIC FIELD",
      navigationTitle: "Protocol Port — First ManMaTIC Application",
      title: "Protocol Port",
      definition: "The first architectural application through which ManMaTIC criteria, decision protocols, and human–machine negotiations are tested spatially.",
      overview: "Protocol Port translates the ManMaTIC Field from research structure into an architectural application. Its current form remains under modification while field criteria and project decisions continue to be tested.",
      year: "2026",
      location: "Aqaba Digital City / Middle Logistics Area / Aqaba, Jordan",
      category: "ManMaTIC / Architectural Application 01",
      type: "Human–Machine Integration Institute",
      role: "Architecture, research, systems thinking, visual communication",
      status: "UNDER MODIFICATION",
      statusNote: "STILL NEGOTIATING ITS FINAL FORM.",
      theme: "manmatic",
      parentSystem: "project-01",
      featured: false,
      displayOrder: 98,
      points: [
        "Field criteria are translated into architectural decisions.",
        "Human review, machine proposals, contestation, and authorisation remain visible in the process.",
        "Images 001–003 record the architectural application and its author-led development process."
      ]
    },
    {
      id: "project-khalda-residential",
      slug: "khalda-residential-building",
      number: "004",
      archiveTitle: "KHALDA RESIDENTIAL BUILDING",
      archiveSubtitle: "PROFESSIONAL TRAINING PROJECT",
      navigationTitle: "Khalda Residential Building — Professional Training Project",
      title: "Khalda Residential Building",
      definition: "A residential building study developed during professional training at BIM Lab.",
      overview: "A residential building study developed during professional training at BIM Lab, involving architectural plans, elevations, design development, drawings, and presentation visuals within an active office workflow.",
      year: "2025",
      location: "Khalda / Amman, Jordan",
      category: "Professional Training",
      type: "Residential Architecture",
      role: "Architectural plans, elevations, design development, drawings, and presentation visuals under supervision",
      office: "BIM Lab",
      supervision: "Eng. Shaker Khulief",
      featured: true,
      displayOrder: 4,
      points: [
        "Developed during professional training at BIM Lab.",
        "Work was produced within an active office workflow and is not presented as an independent commission.",
        "Image 004 remains unlinked until its original file is supplied."
      ]
    }
  ]
};

window.siteContent = siteContent;
