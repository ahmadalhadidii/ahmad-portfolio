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
      process: "Author-directed composition, material development, textures, light, shadow, detailing, atmosphere, Photoshop editing, and digital painting",
      tools: "Photoshop and digital painting tools",
      aiRole: "Early exploratory visualisation for initial renderings and selected graphic elements",
      finalProcess: "Composition, material development, textures, light, shadow, detailing, atmosphere, Photoshop editing, and digital painting by Ahmad Alhadidii",
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
        "Shila (Stone) Museum explores stone as both material and meaning through an architectural journey carved into a quarry. The project transforms the quarry itself into the exhibition, guiding visitors through descending and ascending paths that reveal the relationship between earth, time, and memory. Inspired by a symbolic idea drawn from Hindu philosophy, the journey is conceived as a return to origin and roots, culminating in a final place of arrival and reflection. Architecture becomes an immersive experience that turns geology into a lived and contemplative spatial narrative.",
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
          text: "Shila (Stone) Museum begins where the quarry folds inward. Instead of treating the quarry as a background, the project turns its cut ground into the exhibition itself. The visitor moves into the depth of the stone through carved layers, water, shadow, and open voids shaped by geological time. As the quarry folds, walls, paths, and platforms emerge from the same rock body, making the museum part of the quarry rather than an object placed inside it. The journey transforms the stone’s million-year memory into an experience of material, reflection, and spirit."
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
          text: "Five design principles organise the architectural reading and are re-typeset below the extracted source sketches.",
          items: ["Continuity", "Patterned Light", "Sense of Volume", "Power", "Mandala Core"],
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
          text: "The visitor’s journey is organised through controlled differences in level. Movement begins near the quarry surface and gradually descends into the cut ground, allowing scale, light, temperature, and material character to change with each stage. The descent becomes the museum’s main interpretive experience: a movement from the exposed surface toward the depth, memory, and geological origin of the stone. After the deepest point, the path rises again; the return changes the reading of the same quarry walls and culminates in a place of pause and reflection.",
          facts: [["MOVEMENT", "DESCENT AND RETURN"], ["PRIMARY MEDIUM", "LEVEL CHANGE"], ["EXPERIENCE", "LIGHT, STONE, WATER, SHADOW"], ["SEQUENCE", "SURFACE → DEPTH → ORIGIN → RETURN"]],
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
      archiveSubtitle: "AN ARCHITECTURAL METHODOLOGY FOR HUMAN–MACHINE INTEGRATION",
      navigationTitle: "ManMaTIC — Architectural Methodology",
      theme: "manmatic",
      title: "ManMaTIC",
      definition: "An architectural methodology for translating changing human–machine conditions into institutional and spatial systems.",
      overview: "ManMaTIC is an architectural research methodology developed to translate changing human–machine conditions into institutional and spatial systems. It connects research, evaluation criteria, design dialogue, technological systems, and architectural application within one evolving framework.",
      year: "2026",
      location: "",
      category: "Human–Machine Integration",
      type: "Architectural Research Methodology",
      role: "Architecture, research, systems thinking, visual communication",
      themes: ["Research Institute", "Human–Machine Systems"],
      points: ["DOMAIN / HUMAN–MACHINE INTEGRATION", "STRUCTURE / FIELD → DESIGN → APPLICATION", "STATUS / ACTIVE DEVELOPMENT"],
      featured: true,
      displayOrder: 2,
      sections: [
        {
          code: "01",
          title: "THE MANMATIC FIELD",
          text: "A project-specific knowledge environment that organises research, thesis logic, criteria, case studies, design dialogue, and outputs into a readable operating field.",
          facts: [["RECORD", "002.A"], ["TYPE", "KNOWLEDGE + DESIGN OPERATING ENVIRONMENT"]],
          links: [["ENTER THE FIELD →", "project.html?project=manmatic-field"]]
        },
        {
          code: "02",
          title: "PROTOCOL PORT",
          text: "The first site-specific architectural application of the ManMaTIC methodology, translating its research, criteria, and design dialogue into an institutional project for Aqaba.",
          facts: [["RECORD", "002.B"], ["FUNCTION", "HUMAN–MACHINE INTEGRATION INSTITUTE"], ["LOCATION", "AQABA, JORDAN"]],
          media: {
            src: "assets/images/manmatic/protocol-port-001-1200.jpg",
            width: 1200,
            height: 743,
            alt: "Axonometric drawing of Protocol Port extending across an industrial and logistics landscape with controlled orange elements.",
            caption: "PROTOCOL PORT / APPLICATION 01 / MAIN AXONOMETRIC"
          },
          links: [["ENTER PROTOCOL PORT →", "project.html?project=protocol-port"]]
        }
      ],
      hero: {
        src: "assets/images/manmatic-field-interface-live.png",
        width: 1600,
        height: 1000,
        orientation: "wide",
        fit: "contain",
        mediaClass: "media--wide media--screen",
        alt: "ManMaTIC parent network connecting research, criteria, design dialogue, and architectural application.",
        caption: "MANMATIC / THE FIELD + PROTOCOL PORT / ACTIVE DEVELOPMENT"
      }
    },
    {
      id: "project-manmatic-field",
      slug: "manmatic-field",
      number: "002.A",
      archiveTitle: "THE MANMATIC FIELD",
      archiveSubtitle: "KNOWLEDGE + DESIGN OPERATING ENVIRONMENT",
      navigationTitle: "ManMaTIC System — The Field",
      theme: "manmatic",
      systemMarker: "MANMATIC SYSTEM / THE FIELD",
      systemBack: "project.html?project=project-01",
      title: "The ManMaTIC Field",
      definition: "A project-specific knowledge and design environment that organises research, criteria, dialogue, evidence, and architectural decisions into a readable operating network.",
      overview: "The Field studies a moving subject. Machines, artificial intelligence, automation, data systems, and future work change faster than a conventional linear research process can capture, so research remains active through thesis development, evaluation criteria, design dialogue, and architectural decisions.",
      year: "2026",
      location: "",
      category: "ManMaTIC System / The Field",
      type: "Knowledge and Design Operating Environment",
      relation: "Operational Field within ManMaTIC",
      role: "Architectural research, methodology, field structure, design dialogue, visual communication",
      themeRelation: "Operational Field within ManMaTIC",
      featured: false,
      displayOrder: 97,
      sections: [
        { code: "01", title: "STUDYING A MOVING SUBJECT", text: "Technological conditions continue to change while architecture is being researched and designed. The Field therefore keeps evidence, thesis logic, evaluation criteria, and design decisions connected rather than treating research as a phase that ends before architecture begins." },
        { code: "02", title: "RESEARCH BEFORE ARCHITECTURE", text: "Research is organised as an active project structure. Evidence, case studies, technological change, institutional questions, and spatial implications remain traceable as the architectural problem develops." },
        { code: "03", title: "FROM RESEARCH TO THESIS FRAMEWORK", text: "The research corpus is translated into prospective reading, problem definition, site and context analysis, case studies, theory, function development, programme logic, and system relationships." },
        { code: "04", title: "FROM THESIS TO EVOLUTION CRITERIA", text: "Thesis claims become evaluation criteria that can be compared, questioned, refined, and revised as technological and architectural conditions evolve." },
        { code: "05", title: "FROM CRITERIA TO ORION OPERATING FIELD", text: "Criteria enter an operating field where evidence, proposals, discussion, and architectural decisions can be examined together rather than hidden behind a single output." },
        { code: "06", title: "AUTHOR-LED DESIGN DIALOGUE", text: "The architect remains the author who frames the problem, directs the dialogue, evaluates proposals, contests unsuitable responses, and selects the decisions carried into the project." },
        { code: "07", title: "FIELD INTERFACE", text: "The interface makes the relationships between research nodes, criteria, evidence, dialogue, drawings, systems, and outputs readable.", media: { src: "assets/images/manmatic-field-interface-live.png", width: 1600, height: 1000, alt: "The live ManMaTIC Field interface showing evidence nodes, process links, labels, and project records.", caption: "FIELD INTERFACE / KNOWLEDGE + DESIGN OPERATING ENVIRONMENT" } },
        { code: "08", title: "FIELD DATA STRUCTURE", text: "Search, connections, and selected-node reading logic allow each item to be read individually and as part of the wider project network." },
        { code: "09", title: "MANMATIC FIELD AS AN ADAPTIVE DESIGN FRAMEWORK", text: "New evidence can update the field without separating research from the continuing design process. The framework transfers changing knowledge into criteria, dialogue, and project decisions.", links: [["ENTER LIVE MANMATIC FIELD ↗", "https://www.manmatic.institute/"]] }
      ],
      hero: { src: "assets/images/manmatic-field-interface-live.png", width: 1600, height: 1000, orientation: "wide", fit: "contain", mediaClass: "media--wide media--screen", alt: "Live ManMaTIC Field interface with evidence, criteria, knowledge links, and selected project nodes.", caption: "MANMATIC SYSTEM / THE FIELD" }
    },
    {
      id: "project-02",
      slug: "project-02",
      number: "004",
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
      displayOrder: 4,
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
      number: "002.B",
      archiveTitle: "PROTOCOL PORT",
      archiveSubtitle: "FIRST ARCHITECTURAL APPLICATION OF THE MANMATIC FIELD",
      navigationTitle: "Protocol Port — First ManMaTIC Application",
      title: "Protocol Port",
      definition: "The first architectural application through which ManMaTIC criteria, decision protocols, and human–machine negotiations are tested spatially.",
      overview: "Protocol Port is the first site-specific architectural application of ManMaTIC. It translates the methodology’s research, evaluation criteria, and author-led design dialogue into a Human–Machine Integration Institute for Aqaba.",
      year: "2026",
      location: "Aqaba Digital City / Middle Logistics Area / Aqaba, Jordan",
      category: "ManMaTIC / Architectural Application 01",
      type: "Human–Machine Integration Institute",
      relation: "First Architectural Application of ManMaTIC",
      role: "Architecture, research, systems thinking, visual communication",
      status: "UNDER MODIFICATION",
      statusNote: "STILL NEGOTIATING ITS FINAL FORM.",
      theme: "manmatic",
      systemMarker: "MANMATIC SYSTEM / PROTOCOL PORT",
      systemBack: "project.html?project=project-01",
      featured: false,
      displayOrder: 98,
      sections: [
        { code: "01", title: "PROJECT OPENING", text: "The first architectural application of ManMaTIC: a Human–Machine Integration Institute developed for Aqaba." },
        { code: "02", title: "FUNCTION AND SITE", text: "The institutional programme addresses human–machine integration within Aqaba’s logistics and technological context.", facts: [["FUNCTION", "HUMAN–MACHINE INTEGRATION INSTITUTE"], ["LOCATION", "AQABA DIGITAL CITY / MIDDLE LOGISTICS AREA / AQABA, JORDAN"]] },
        { code: "03", title: "FROM FIELD TO APPLICATION", text: "Research, criteria, protocols, and design dialogue move from the ManMaTIC Field into a site-specific institutional proposal. The Field remains a decision environment; Protocol Port is its first spatial application." },
        { code: "04", title: "DESIGN DEVELOPMENT", text: "Hand drawing and iterative section studies record the author-led development of the project.", media: { src: "assets/images/manmatic/protocol-port-process-002-900.jpg", width: 506, height: 900, alt: "Protocol Port hand sketches arranged around a pen and laptop.", caption: "FIG. 01 / IMAGE 002 / HAND-DRAWN DEVELOPMENT" } },
        { code: "05", title: "ARCHITECTURAL SYSTEM", text: "The developing system coordinates institutional programme, circulation, technical elements, and the project’s relationship to the logistics landscape." },
        { code: "06", title: "IMAGES AND DRAWINGS", text: "Section and elevation studies test the project’s vertical elements, long spatial sequence, and architectural thresholds.", media: { src: "assets/images/manmatic/protocol-port-process-003-900.jpg", width: 653, height: 900, alt: "Protocol Port section and elevation sketches surrounding a tablet drawing.", caption: "FIG. 02 / IMAGE 003 / SECTION AND ELEVATION STUDIES" } },
        { code: "07", title: "STATUS AND NEXT DEVELOPMENT", text: "The architectural application remains iterative while its institutional and spatial systems are refined.", status: "UNDER MODIFICATION", statusNote: "STILL NEGOTIATING ITS FINAL FORM." }
      ],
      hero: { src: "assets/images/manmatic/protocol-port-001-1200.jpg", width: 1200, height: 743, orientation: "wide", fit: "contain", mediaClass: "media--wide media--drawing", alt: "Protocol Port axonometric drawing across Aqaba’s logistics landscape.", caption: "MANMATIC SYSTEM / PROTOCOL PORT / AQABA, JORDAN" }
    },
    {
      id: "project-dabouq-residential",
      slug: "dabouq-residential-building",
      number: "003",
      archiveTitle: "DABOUQ RESIDENTIAL BUILDING",
      archiveSubtitle: "PROFESSIONAL TRAINING PROJECT",
      navigationTitle: "Dabouq Residential Building — Professional Training Project",
      title: "Dabouq Residential Building",
      definition: "A residential building study developed during professional training at BIM Lab.",
      overview: "A residential building study developed during professional training at BIM Lab, involving architectural drawings, elevation development, controlled design adjustments, and visual documentation within an active office workflow.",
      year: "2026",
      location: "Dabouq, Amman, Jordan",
      category: "Professional Training",
      type: "Residential Architecture",
      context: "Professional Training",
      role: "Architectural drawings, elevation development, light design modifications, and visual development under supervision",
      office: "BIM Lab",
      supervision: "Eng. Shaker Khulief",
      featured: true,
      displayOrder: 3,
      points: [
        "Developed during professional training at BIM Lab.",
        "Developed during professional training at BIM Lab and not presented as an independent commission.",
        "Developed during professional training at BIM Lab."
      ],
      hero: { src: "assets/images/dabouq/dabouq-residential-preview.jpg", width: 1600, height: 1600, orientation: "square", fit: "natural", mediaClass: "media--natural", alt: "Architectural presentation drawing of a residential building developed during professional training at BIM Lab in Dabouq, Amman.", caption: "RESIDENTIAL PROJECT / PROFESSIONAL TRAINING AT BIM LAB" }
    }
  ]
};

window.siteContent = siteContent;
