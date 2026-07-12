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
  fit: "contain",
  mediaClass: "media--board",
  alt:
    "Architecture of Elsewhere collage combining a white architectural model with planetary studies, technical line drawings, and a dark research field."
};

const siteContent = {
  meta: {
    title: "Ahmad Alhadidii — Architecture Portfolio",
    description:
      "Architecture, design research, and computational design portfolio by Ahmad Alhadidii."
  },

  person: {
    name: "Ahmad Alhadidii",
    displayName: "AHMAD ALHADIDII",
    location: "As-Salt, Jordan",
    portrait: {
      src: "assets/images/profile.webp",
      srcset:
        "assets/images/profile-800.webp 800w, assets/images/profile.webp 1200w",
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
        "The red does not colour the space; it consumes it. It settles over the walls, the structure, and the sky until the whole place feels buried inside one heavy breath. Yet a few thin lines of light remain. They cut through the red, catch the edges, and slowly carve the architecture back into view. What survives is not the building itself, but the trace of light refusing to disappear.",
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
        "Before the place disappears, the red holds it in a final moment between presence and erasure. It fills the air, closes the distance, and leaves the world almost without form. Then a few lines of light begin to cut through, not enough to reveal everything, but enough to pull edges, depth, and space back into existence. What appears is not simply illuminated; it is rescued from the colour that nearly consumed it. If light is the last thing keeping a place alive, what remains when it is gone?",
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
        "Human–Machine History traces the long evolution of the relationship between humans, tools, machines, and technological systems across generations. The journey begins with the Agricultural Revolution, where early tools transformed the way societies lived, worked, and organized themselves. Visitors move through a stone-carved timeline where inventions, mechanisms, and technological milestones unfold across centuries of progress. Through compressed sloping walls, filtered light, and engraved history, the passage turns development into an immersive spatial narrative. As the sequence progresses, the machine is revealed not as something separate from the human, but as part of humanity’s continuous becoming.",
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
        "Before tomorrow becomes real, this room holds both a warning and a beginning. The fractured stone is not only a sign of collapse; it is the image of a human–machine future left without human judgment, where machines continue to move while humans remain outside the logic that guides them. Yet the orange transparent layer suggests another possibility: potential still visible, still unfinished, still waiting to be shaped. This is the last room before tomorrow—a place where fear becomes a question, and the question becomes action. If a better future can still be formed, will you take part in shaping it?",
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
      alt:
        "Near-square sepia interior with fractured stone, suspended machinery, information screens, and a wall inscribed with a text about potential."
    }
  ],

  projects: [
    {
      id: "project-05",
      slug: "project-05",
      number: "001",
      archiveTitle: "SHILA MUSEUM",
      archiveSubtitle: "THE QUARRY THAT FOLDS INWARD",
      navigationTitle: "Shila Museum — The Quarry That Folds Inward",
      title: "The Quarry That Folds Inward",
      definition:
        "A museum concept where the quarry folds inward, turning stone, water, shadow, and void into spatial memory.",
      overview:
        "The project treats the quarry as an architectural memory field. Instead of placing a museum inside the landscape, the landscape itself folds into rooms, voids, and shadowed thresholds.",
      year: "2026",
      location: "",
      category: "Museum / Stone Memory",
      type: "Museum / Atmosphere",
      role: "Concept, atmosphere, spatial storytelling",
      themes: ["Museum", "Stone", "Atmosphere"],
      points: [
        "Uses quarry logic as spatial generator.",
        "Frames stone as memory, not surface finish.",
        "Builds atmosphere through water, void, shadow, and mass."
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
        caption: "SHILA MUSEUM / THE QUARRY THAT FOLDS INWARD / 2026",
        alt:
          "Pale architectural drawing of Shila Museum around a reflective quarry pool, with layered stone volumes and a stair rising overhead."
      }
    },
    {
      id: "project-01",
      slug: "project-01",
      number: "002",
      archiveTitle: "MANMATIC",
      archiveSubtitle: "HUMAN–MACHINE INTEGRATION INSTITUTE",
      navigationTitle: "ManMaTIC — Human–Machine Integration Institute",
      theme: "manmatic",
      title: "ManMaTIC Institute",
      definition:
        "A research-based institute exploring how humans and intelligent systems collaborate, negotiate, and deploy decisions in real environments.",
      overview:
        "ManMaTIC is a proposed Human–Machine Integration Institute in Aqaba, structured around research, simulation, governance, and deployment. The project treats architecture as an operational field where data, models, human review, and spatial systems interact.",
      year: "2026",
      location: "Aqaba",
      category: "Graduation Project / Human–Machine Integration",
      type: "Research Institute",
      role: "Architecture, research, systems thinking, visual communication",
      themes: ["Research Institute", "Human–Machine Systems"],
      points: [
        "Develops a spatial framework for human–machine collaboration.",
        "Connects research, simulation, governance, and deployment.",
        "Uses architecture to make technological decision-making visible."
      ],
      hero: {
        ...sharedPortfolioVisual,
        context:
          "Independent visual narrative developed during the ManMaTIC process; not a literal or accurate rendering of the institute building.",
        caption:
          "ARCHITECTURE OF ELSEWHERE / INDEPENDENT VISUAL NARRATIVE DEVELOPED DURING THE MANMATIC PROCESS / NOT A LITERAL BUILDING RENDERING"
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
      hero: {
        ...sharedPortfolioVisual,
        caption: "Shared portfolio visual / Architecture of Elsewhere"
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
      hero: {
        ...sharedPortfolioVisual,
        caption: "Shared portfolio visual / Architecture of Elsewhere"
      }
    },
    {
      id: "project-04",
      slug: "project-04",
      number: "005",
      navigationTitle: "The Mechanics of Becoming",
      title: "The Mechanics of Becoming",
      definition:
        "A spatial timeline of human and machine evolution, carved as a threshold between tools, bodies, and complex systems.",
      overview:
        "The Mechanics of Becoming frames human-machine history as a carved architectural passage where milestones, shadows, and visitors become part of a larger temporal mechanism.",
      year: "2026",
      location: "",
      category: "Drawing / Human–Machine History",
      type: "Speculative Drawing / Timeline",
      role: "Concept, digital painting, architectural narrative",
      themes: ["Timeline", "Human–Machine"],
      points: [
        "Uses space as a historical timeline.",
        "Turns technological development into an embodied architectural sequence.",
        "Explores the threshold between tool, human, and machine."
      ],
      hero: {
        ...sharedPortfolioVisual,
        caption: "Shared portfolio visual / Architecture of Elsewhere"
      }
    }
  ]
};

window.siteContent = siteContent;
