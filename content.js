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
    roles: [
      "Architectural Designer",
      "Design Researcher",
      "Computational Design Explorer"
    ]
  },

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
        ...sharedPortfolioVisual,
        caption: "Shared portfolio visual / Architecture of Elsewhere"
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
        caption: "Architecture of Elsewhere / ManMaTIC Institute / 2026"
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
