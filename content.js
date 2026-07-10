/* ============================================================
   SITE CONTENT
   Edit everything here. The HTML only contains structure —
   all text, links, and project data below feed the page via
   assets/js/main.js
   ============================================================ */

const siteContent = {
  meta: {
    title: "Ahmad Al Hadidii — Architecture Portfolio",
    description:
      "Architecture, design research, computational thinking, and visual systems portfolio by Ahmad Al Hadidii."
  },

  person: {
    name: "Ahmad Al Hadidii",
    shortName: "AHMAD AL HADIDII",
    splitName: ["AHMAD", "AL", "HADIDII"],
    initials: "AH",
    location: "JO",
    timezone: "Asia/Amman",
    email: "alhadidiahamd@gmail.com",
    title: "Architectural Designer / Design Researcher / Computational Design Explorer",
    subtitle:
      "Architectural Designer focused on research-based design, spatial systems, and computational thinking.",
    statement:
      "I read beneath the surface of disorder — tracing the quiet systems, patterns, and relationships that shape what first appears random, and reveal the hidden logic that gives scattered things their structure.",
    secondaryStatement:
      "I work across architecture, research, visual systems, and computational thinking — using design as a way to expose hidden structures, clarify relationships, and turn complex conditions into spatial form."
  },

  nav: [
    { label: "WORK", target: "#work" },
    { label: "METHOD", target: "#method" },
    { label: "PROFILE", target: "#profile" },
    { label: "CONTACT", target: "#contact" }
  ],

  projects: [
    {
      number: "001",
      title: "ManMaTIC Institute",
      category: "Graduation Project / Human–Machine Integration",
      year: "2026",
      image: "assets/images/project-manmatic.jpg",
      role: "Architecture, research, systems thinking, visual communication",
      shortDescription:
        "A research-based institute exploring how humans and intelligent systems collaborate, negotiate, and deploy decisions in real environments.",
      description:
        "ManMaTIC is a proposed Human–Machine Integration Institute in Aqaba, structured around research, simulation, governance, and deployment. The project treats architecture as an operational field where data, models, human review, and spatial systems interact.",
      points: [
        "Develops a spatial framework for human–machine collaboration.",
        "Connects research, simulation, governance, and deployment.",
        "Uses architecture to make technological decision-making visible."
      ],
      meta: ["Aqaba", "Research Institute", "Human–Machine Systems"]
    },
    {
      number: "002",
      title: "From Concrete Fatigue to Green Asset",
      category: "Environmental Legacy Makers Award / Urban Intervention",
      year: "2026",
      image: "assets/images/project-elma.jpg",
      role: "Concept, environmental strategy, visual communication",
      shortDescription:
        "A staircase transformation proposal turning daily urban infrastructure into environmental and social value.",
      description:
        "The project rethinks Jabal Al-Zuhour staircase as more than circulation. Through shade, planting, water management, and social pauses, it turns a repeated daily climb into a green civic asset.",
      points: [
        "Won first place in the Environmental Legacy Makers Award.",
        "Uses the staircase as daily environmental infrastructure.",
        "Introduces a modular tree unit for shade, planting, and water management."
      ],
      meta: ["Amman", "Urban Stairs", "Environmental Design"]
    },
    {
      number: "003",
      title: "Ground of Continuity",
      category: "Cultural Map / Visual Research",
      year: "2026",
      image: "assets/images/project-ground.jpg",
      role: "Mapping, cultural research, graphic composition",
      shortDescription:
        "A cultural map reading Jordan as a ground of continuity between memory, borders, routes, and shared regional identity.",
      description:
        "Ground of Continuity presents Jordan as a cultural crossroads shaped by memory, movement, trade, displacement, desert routes, and shared Arab imagination.",
      points: [
        "Maps cultural relationships rather than only geographic borders.",
        "Uses neighboring territories as fields of memory and exchange.",
        "Combines cartographic logic with cultural storytelling."
      ],
      meta: ["Jordan", "Mapping", "Cultural Representation"]
    },
    {
      number: "004",
      title: "The Mechanics of Becoming",
      category: "Drawing / Human–Machine History",
      year: "2026",
      image: "assets/images/project-mechanics.jpg",
      role: "Concept, digital painting, architectural narrative",
      shortDescription:
        "A spatial timeline of human and machine evolution, carved as a threshold between tools, bodies, and complex systems.",
      description:
        "The Mechanics of Becoming frames human-machine history as a carved architectural passage where milestones, shadows, and visitors become part of a larger temporal mechanism.",
      points: [
        "Uses space as a historical timeline.",
        "Turns technological development into an embodied architectural sequence.",
        "Explores the threshold between tool, human, and machine."
      ],
      meta: ["Speculative Drawing", "Timeline", "Human–Machine"]
    },
    {
      number: "005",
      title: "The Quarry That Folds Inward",
      category: "Museum / Stone Memory",
      year: "2026",
      image: "assets/images/project-quarry.jpg",
      role: "Concept, atmosphere, spatial storytelling",
      shortDescription:
        "A museum concept where the quarry folds inward, turning stone, water, shadow, and void into spatial memory.",
      description:
        "The project treats the quarry as an architectural memory field. Instead of placing a museum inside the landscape, the landscape itself folds into rooms, voids, and shadowed thresholds.",
      points: [
        "Uses quarry logic as spatial generator.",
        "Frames stone as memory, not surface finish.",
        "Builds atmosphere through water, void, shadow, and mass."
      ],
      meta: ["Museum", "Stone", "Atmosphere"]
    }
  ],

  method: {
    label: "[METHOD]",
    titleSplit: ["METH", "O", "D"],
    headline: "Architecture as a way to reveal relationships, not only produce form.",
    intro:
      "I work through research, systems, context, and visual testing — treating architecture as a method for reading hidden structures and translating them into spatial decisions.",
    points: [
      {
        number: "001",
        title: "RESEARCH-BASED DESIGN",
        text: "Architecture starts from reading conditions, references, conflicts, and hidden structures before producing form."
      },
      {
        number: "002",
        title: "SPATIAL SYSTEMS",
        text: "I'm interested in how programs, users, machines, movement, and context operate as connected systems."
      },
      {
        number: "003",
        title: "COMPUTATIONAL THINKING",
        text: "I use digital and computational tools to test relationships, generate alternatives, and clarify decisions."
      },
      {
        number: "004",
        title: "VISUAL STORYTELLING",
        text: "Drawings, diagrams, maps, and atmospheres are treated as part of the argument, not decoration."
      }
    ]
  },

  capabilities: {
    label: "[WHAT I WORK WITH]",
    titleSplit: ["CAPA", "BILI", "TIES"],
    intro: "Not services in the commercial sense. These are the working territories behind the portfolio.",
    items: [
      {
        number: "001",
        title: "ARCHITECTURAL DESIGN",
        text: "Concept development, spatial organization, plans, sections, elevations, and project narratives."
      },
      {
        number: "002",
        title: "DESIGN RESEARCH",
        text: "Research frameworks, case study analysis, theoretical grounding, and project positioning."
      },
      {
        number: "003",
        title: "COMPUTATIONAL DESIGN",
        text: "Parametric thinking, systems logic, iterative testing, digital workflows, and visual experiments."
      },
      {
        number: "004",
        title: "VISUAL COMMUNICATION",
        text: "Portfolio layouts, diagrams, presentation boards, maps, render post-production, and storytelling."
      },
      {
        number: "005",
        title: "BIM + DIGITAL DOCUMENTATION",
        text: "Architectural documentation, Revit workflows, drawing coordination, and structured project files."
      }
    ]
  },

  profile: {
    label: "-- {ARCHITECTURE / RESEARCH / SYSTEMS}",
    titleSplit: ["A", "BOU", "T"],
    heading: "I'M AHMAD AL HADIDII",
    intro: "I'm an architecture student and architectural designer based in Jordan.",
    body: [
      "My work is driven by an interest in how ideas, contexts, human experiences, and emerging technologies can shape meaningful spatial responses.",
      "I approach architecture through research, systems, and visual communication, often exploring references beyond architecture before translating them into spatial and graphic form.",
      "I'm drawn to architecture defined not only by image, but by purpose, memory, use, and contextual logic."
    ],
    facts: [
      "Based in Jordan",
      "Architecture / Design Research / Computational Thinking",
      "Available for internships, collaborations, competitions, and selected freelance visual work"
    ]
  },

  contact: {
    label: "[LET'S TALK]",
    titleWords: ["GOOD", "WORK", "STARTS", "WITH", "CLEAR", "STRUCTURE"],
    email: "alhadidiahamd@gmail.com",
    links: [
      { label: "EMAIL", href: "mailto:alhadidiahamd@gmail.com" },
      { label: "LINKEDIN", href: "#" },
      { label: "GITHUB", href: "#" },
      { label: "PORTFOLIO PDF", href: "#" }
    ]
  },

  footer: {
    left: "©2026",
    center: "AHMAD AL HADIDII",
    right: "JO / ARCHITECTURE / RESEARCH / COMPUTATION"
  }
};

window.siteContent = siteContent;
