/*
 * EDITABLE PORTFOLIO CONTENT
 *
 * Keep personal, CV, project, and contact content in this file. Layout,
 * interactions, and rendering belong in index.html, assets/css/style.css,
 * assets/js/main.js, and assets/js/project.js.
 *
 * Empty CV fields are intentional: the source material does not provide those
 * facts. Project placeholders begin with "ADD" so unfinished content remains
 * obvious and cannot be mistaken for portfolio information.
 */

const siteContent = {
  meta: {
    title: "Ahmad Alhadidii — Architecture Portfolio",
    description:
      "Architecture, research, and computational design portfolio by Ahmad Alhadidii.",
    language: "en"
  },

  loader: {
    start: "000",
    end: "100",
    label: "ARCHIVE / INITIALIZING",
    duration: 2300
  },

  nav: [
    { number: "01", label: "PROFILE", target: "#profile" },
    { number: "02", label: "CV", target: "#cv" },
    { number: "03", label: "WORK", target: "#work" },
    { number: "04", label: "METHOD", target: "#method" },
    { number: "05", label: "CONTACT", target: "#contact" }
  ],

  person: {
    name: "Ahmad Alhadidii",
    displayName: "AHMAD ALHADIDII",
    discipline: "ARCHITECTURE / RESEARCH / COMPUTATIONAL DESIGN",
    roles: [
      "Architecture student — Al-Balqa Applied University",
      "Architectural Designer",
      "Design Researcher",
      "Computational Design Explorer"
    ],
    location: "Jordan",
    timezone: "Asia/Amman",
    email: "alhadidiahamd@gmail.com"
  },

  hero: {
    image: {
      src: "assets/images/hero-cover.jpg",
      alt: "ADD HERO IMAGE DESCRIPTION",
      code: "H.01"
    },
    name: "AHMAD ALHADIDII",
    discipline: "ARCHITECTURE / RESEARCH / COMPUTATIONAL DESIGN",
    edition: "SELECTED WORKS 2025–2026",
    location: "BASED IN JORDAN",
    conceptualTitle: "ARCHITECTURE OF ELSEWHERE",
    scrollLabel: "SCROLL TO ENTER"
  },

  profile: {
    number: "01",
    title: "PROFILE",
    portrait: {
      src: "assets/images/portrait.jpg",
      alt: "ADD PORTRAIT DESCRIPTION",
      code: "P.01"
    },
    positionStatement:
      "I work across architecture, research, and computational design, translating complex systems, contexts, and relationships into spatial structures.",
    paragraphs: [
      "My work begins with questions, evidence, and relationships rather than form alone. Through research, visual communication, and computational tools, I develop spatial responses that are legible in purpose, grounded in context, and open to testing and refinement.",
      "I am interested in architecture shaped not only by image, but by the systems, memories, uses, and hidden forms of logic that give it structure."
    ],
    metadata: [
      { label: "NAME", value: "Ahmad Alhadidii" },
      {
        label: "EDUCATION",
        value: "Architecture student — Al-Balqa Applied University"
      },
      { label: "ROLE 01", value: "Architectural Designer" },
      { label: "ROLE 02", value: "Design Researcher" },
      { label: "ROLE 03", value: "Computational Design Explorer" },
      { label: "LOCATION", value: "Based in Jordan" }
    ],
    cvLink: {
      label: "CV / PDF",
      href: "#",
      placeholder: true
    }
  },

  cv: {
    number: "02",
    title: "CV",
    eyebrow: "EDUCATION / PRACTICE / RECOGNITION",
    timeline: {
      experience: [
        {
          index: "01",
          role: "BIM Lab — Architecture Training",
          institution: "",
          location: "",
          date: "",
          description: ""
        },
        {
          index: "02",
          role: "Publication / Research Support",
          institution: "",
          location: "",
          date: "",
          description: ""
        }
      ],
      education: [
        {
          index: "01",
          qualification: "Architecture Student",
          institution: "Al-Balqa Applied University",
          location: "",
          date: "",
          description: ""
        }
      ],
      awards: [
        {
          index: "01",
          title: "Environmental Legacy Makers Award",
          result: "1st Place",
          location: "",
          date: "",
          description: ""
        }
      ]
    },
    supporting: {
      software: [
        "Rhino",
        "Grasshopper",
        "Revit",
        "AutoCAD",
        "Photoshop",
        "Illustrator",
        "D5 Render",
        "Canva"
      ],
      designStrengths: [
        "Research-Based Design",
        "Concept Development",
        "Spatial Storytelling",
        "Computational Thinking",
        "Visual Communication"
      ],
      technicalSkills: ["BIM Documentation"],
      languages: [],
      certifications: []
    },
    links: {
      view: {
        label: "VIEW CV",
        href: "#",
        placeholder: true
      },
      download: {
        label: "DOWNLOAD CV / PDF",
        href: "#",
        placeholder: true
      }
    }
  },

  work: {
    number: "03",
    title: "WORK",
    eyebrow: "SELECTED PROJECTS",
    viewLabel: "VIEW PROJECT"
  },

  projects: [
    {
      id: "project-01",
      slug: "project-01",
      number: "01",
      title: "PROJECT SLOT",
      year: "ADD YEAR",
      location: "ADD LOCATION",
      type: "ADD PROJECT TYPE",
      description: "ADD ONE-LINE PROJECT DESCRIPTION",
      tags: ["ADD TAG 01", "ADD TAG 02"],
      previewImage: {
        src: "assets/images/project-01-preview.jpg",
        alt: "ADD PROJECT 01 PREVIEW IMAGE DESCRIPTION",
        code: "1.0"
      },
      detail: {
        metadata: {
          status: "ADD STATUS",
          role: "ADD ROLE",
          team: "ADD TEAM"
        },
        introduction: {
          statement: "ADD PROJECT CONCEPT STATEMENT",
          question: "ADD PROJECT QUESTION OR PROBLEM",
          response: "ADD MAIN DESIGN RESPONSE"
        },
        information: {
          research: "ADD RESEARCH SUMMARY",
          process: "ADD PROCESS SUMMARY",
          designSystem: "ADD DESIGN SYSTEM SUMMARY",
          technicalDevelopment: "ADD TECHNICAL DEVELOPMENT SUMMARY",
          outcome: "ADD PROJECT OUTCOME"
        },
        images: [
          {
            code: "1.1",
            src: "assets/images/project-01-01.jpg",
            alt: "ADD PROJECT 01 IMAGE 01 DESCRIPTION",
            caption: "ADD IMAGE 01 CAPTION",
            layout: "full"
          },
          {
            code: "1.2",
            src: "assets/images/project-01-02.jpg",
            alt: "ADD PROJECT 01 IMAGE 02 DESCRIPTION",
            caption: "ADD IMAGE 02 CAPTION",
            layout: "half"
          },
          {
            code: "1.3",
            src: "assets/images/project-01-03.jpg",
            alt: "ADD PROJECT 01 IMAGE 03 DESCRIPTION",
            caption: "ADD IMAGE 03 CAPTION",
            layout: "half"
          }
        ]
      }
    },
    {
      id: "project-02",
      slug: "project-02",
      number: "02",
      title: "PROJECT SLOT",
      year: "ADD YEAR",
      location: "ADD LOCATION",
      type: "ADD PROJECT TYPE",
      description: "ADD ONE-LINE PROJECT DESCRIPTION",
      tags: ["ADD TAG 01", "ADD TAG 02"],
      previewImage: {
        src: "assets/images/project-02-preview.jpg",
        alt: "ADD PROJECT 02 PREVIEW IMAGE DESCRIPTION",
        code: "2.0"
      },
      detail: {
        metadata: {
          status: "ADD STATUS",
          role: "ADD ROLE",
          team: "ADD TEAM"
        },
        introduction: {
          statement: "ADD PROJECT CONCEPT STATEMENT",
          question: "ADD PROJECT QUESTION OR PROBLEM",
          response: "ADD MAIN DESIGN RESPONSE"
        },
        information: {
          research: "ADD RESEARCH SUMMARY",
          process: "ADD PROCESS SUMMARY",
          designSystem: "ADD DESIGN SYSTEM SUMMARY",
          technicalDevelopment: "ADD TECHNICAL DEVELOPMENT SUMMARY",
          outcome: "ADD PROJECT OUTCOME"
        },
        images: [
          {
            code: "2.1",
            src: "assets/images/project-02-01.jpg",
            alt: "ADD PROJECT 02 IMAGE 01 DESCRIPTION",
            caption: "ADD IMAGE 01 CAPTION",
            layout: "full"
          },
          {
            code: "2.2",
            src: "assets/images/project-02-02.jpg",
            alt: "ADD PROJECT 02 IMAGE 02 DESCRIPTION",
            caption: "ADD IMAGE 02 CAPTION",
            layout: "half"
          },
          {
            code: "2.3",
            src: "assets/images/project-02-03.jpg",
            alt: "ADD PROJECT 02 IMAGE 03 DESCRIPTION",
            caption: "ADD IMAGE 03 CAPTION",
            layout: "half"
          }
        ]
      }
    },
    {
      id: "project-03",
      slug: "project-03",
      number: "03",
      title: "PROJECT SLOT",
      year: "ADD YEAR",
      location: "ADD LOCATION",
      type: "ADD PROJECT TYPE",
      description: "ADD ONE-LINE PROJECT DESCRIPTION",
      tags: ["ADD TAG 01", "ADD TAG 02"],
      previewImage: {
        src: "assets/images/project-03-preview.jpg",
        alt: "ADD PROJECT 03 PREVIEW IMAGE DESCRIPTION",
        code: "3.0"
      },
      detail: {
        metadata: {
          status: "ADD STATUS",
          role: "ADD ROLE",
          team: "ADD TEAM"
        },
        introduction: {
          statement: "ADD PROJECT CONCEPT STATEMENT",
          question: "ADD PROJECT QUESTION OR PROBLEM",
          response: "ADD MAIN DESIGN RESPONSE"
        },
        information: {
          research: "ADD RESEARCH SUMMARY",
          process: "ADD PROCESS SUMMARY",
          designSystem: "ADD DESIGN SYSTEM SUMMARY",
          technicalDevelopment: "ADD TECHNICAL DEVELOPMENT SUMMARY",
          outcome: "ADD PROJECT OUTCOME"
        },
        images: [
          {
            code: "3.1",
            src: "assets/images/project-03-01.jpg",
            alt: "ADD PROJECT 03 IMAGE 01 DESCRIPTION",
            caption: "ADD IMAGE 01 CAPTION",
            layout: "full"
          },
          {
            code: "3.2",
            src: "assets/images/project-03-02.jpg",
            alt: "ADD PROJECT 03 IMAGE 02 DESCRIPTION",
            caption: "ADD IMAGE 02 CAPTION",
            layout: "half"
          },
          {
            code: "3.3",
            src: "assets/images/project-03-03.jpg",
            alt: "ADD PROJECT 03 IMAGE 03 DESCRIPTION",
            caption: "ADD IMAGE 03 CAPTION",
            layout: "half"
          }
        ]
      }
    },
    {
      id: "project-04",
      slug: "project-04",
      number: "04",
      title: "PROJECT SLOT",
      year: "ADD YEAR",
      location: "ADD LOCATION",
      type: "ADD PROJECT TYPE",
      description: "ADD ONE-LINE PROJECT DESCRIPTION",
      tags: ["ADD TAG 01", "ADD TAG 02"],
      previewImage: {
        src: "assets/images/project-04-preview.jpg",
        alt: "ADD PROJECT 04 PREVIEW IMAGE DESCRIPTION",
        code: "4.0"
      },
      detail: {
        metadata: {
          status: "ADD STATUS",
          role: "ADD ROLE",
          team: "ADD TEAM"
        },
        introduction: {
          statement: "ADD PROJECT CONCEPT STATEMENT",
          question: "ADD PROJECT QUESTION OR PROBLEM",
          response: "ADD MAIN DESIGN RESPONSE"
        },
        information: {
          research: "ADD RESEARCH SUMMARY",
          process: "ADD PROCESS SUMMARY",
          designSystem: "ADD DESIGN SYSTEM SUMMARY",
          technicalDevelopment: "ADD TECHNICAL DEVELOPMENT SUMMARY",
          outcome: "ADD PROJECT OUTCOME"
        },
        images: [
          {
            code: "4.1",
            src: "assets/images/project-04-01.jpg",
            alt: "ADD PROJECT 04 IMAGE 01 DESCRIPTION",
            caption: "ADD IMAGE 01 CAPTION",
            layout: "full"
          },
          {
            code: "4.2",
            src: "assets/images/project-04-02.jpg",
            alt: "ADD PROJECT 04 IMAGE 02 DESCRIPTION",
            caption: "ADD IMAGE 02 CAPTION",
            layout: "half"
          },
          {
            code: "4.3",
            src: "assets/images/project-04-03.jpg",
            alt: "ADD PROJECT 04 IMAGE 03 DESCRIPTION",
            caption: "ADD IMAGE 03 CAPTION",
            layout: "half"
          }
        ]
      }
    },
    {
      id: "project-05",
      slug: "project-05",
      number: "05",
      title: "PROJECT SLOT",
      year: "ADD YEAR",
      location: "ADD LOCATION",
      type: "ADD PROJECT TYPE",
      description: "ADD ONE-LINE PROJECT DESCRIPTION",
      tags: ["ADD TAG 01", "ADD TAG 02"],
      previewImage: {
        src: "assets/images/project-05-preview.jpg",
        alt: "ADD PROJECT 05 PREVIEW IMAGE DESCRIPTION",
        code: "5.0"
      },
      detail: {
        metadata: {
          status: "ADD STATUS",
          role: "ADD ROLE",
          team: "ADD TEAM"
        },
        introduction: {
          statement: "ADD PROJECT CONCEPT STATEMENT",
          question: "ADD PROJECT QUESTION OR PROBLEM",
          response: "ADD MAIN DESIGN RESPONSE"
        },
        information: {
          research: "ADD RESEARCH SUMMARY",
          process: "ADD PROCESS SUMMARY",
          designSystem: "ADD DESIGN SYSTEM SUMMARY",
          technicalDevelopment: "ADD TECHNICAL DEVELOPMENT SUMMARY",
          outcome: "ADD PROJECT OUTCOME"
        },
        images: [
          {
            code: "5.1",
            src: "assets/images/project-05-01.jpg",
            alt: "ADD PROJECT 05 IMAGE 01 DESCRIPTION",
            caption: "ADD IMAGE 01 CAPTION",
            layout: "full"
          },
          {
            code: "5.2",
            src: "assets/images/project-05-02.jpg",
            alt: "ADD PROJECT 05 IMAGE 02 DESCRIPTION",
            caption: "ADD IMAGE 02 CAPTION",
            layout: "half"
          },
          {
            code: "5.3",
            src: "assets/images/project-05-03.jpg",
            alt: "ADD PROJECT 05 IMAGE 03 DESCRIPTION",
            caption: "ADD IMAGE 03 CAPTION",
            layout: "half"
          }
        ]
      }
    },
    {
      id: "project-06",
      slug: "project-06",
      number: "06",
      title: "PROJECT SLOT",
      year: "ADD YEAR",
      location: "ADD LOCATION",
      type: "ADD PROJECT TYPE",
      description: "ADD ONE-LINE PROJECT DESCRIPTION",
      tags: ["ADD TAG 01", "ADD TAG 02"],
      previewImage: {
        src: "assets/images/project-06-preview.jpg",
        alt: "ADD PROJECT 06 PREVIEW IMAGE DESCRIPTION",
        code: "6.0"
      },
      detail: {
        metadata: {
          status: "ADD STATUS",
          role: "ADD ROLE",
          team: "ADD TEAM"
        },
        introduction: {
          statement: "ADD PROJECT CONCEPT STATEMENT",
          question: "ADD PROJECT QUESTION OR PROBLEM",
          response: "ADD MAIN DESIGN RESPONSE"
        },
        information: {
          research: "ADD RESEARCH SUMMARY",
          process: "ADD PROCESS SUMMARY",
          designSystem: "ADD DESIGN SYSTEM SUMMARY",
          technicalDevelopment: "ADD TECHNICAL DEVELOPMENT SUMMARY",
          outcome: "ADD PROJECT OUTCOME"
        },
        images: [
          {
            code: "6.1",
            src: "assets/images/project-06-01.jpg",
            alt: "ADD PROJECT 06 IMAGE 01 DESCRIPTION",
            caption: "ADD IMAGE 01 CAPTION",
            layout: "full"
          },
          {
            code: "6.2",
            src: "assets/images/project-06-02.jpg",
            alt: "ADD PROJECT 06 IMAGE 02 DESCRIPTION",
            caption: "ADD IMAGE 02 CAPTION",
            layout: "half"
          },
          {
            code: "6.3",
            src: "assets/images/project-06-03.jpg",
            alt: "ADD PROJECT 06 IMAGE 03 DESCRIPTION",
            caption: "ADD IMAGE 03 CAPTION",
            layout: "half"
          }
        ]
      }
    }
  ],

  method: {
    number: "04",
    title: "METHOD",
    stages: [
      {
        number: "01",
        title: "RESEARCH",
        sentence:
          "Questions, evidence, and context establish the frame before form is developed.",
        diagram: "research-grid"
      },
      {
        number: "02",
        title: "SYSTEMS",
        sentence:
          "Programs, users, movement, and constraints are read as connected spatial relationships.",
        diagram: "connected-system"
      },
      {
        number: "03",
        title: "TESTING",
        sentence:
          "Options are modelled, compared, and refined against the project criteria.",
        diagram: "iteration-series"
      },
      {
        number: "04",
        title: "TRANSLATION",
        sentence:
          "Research and rules are converted into clear spatial decisions.",
        diagram: "rule-to-space"
      },
      {
        number: "05",
        title: "COMMUNICATION",
        sentence:
          "Drawings, diagrams, and images make the project reasoning legible.",
        diagram: "drawing-layers"
      }
    ]
  },

  contact: {
    number: "05",
    title: "CONTACT",
    availability: "Jordan / Open to professional opportunities",
    links: [
      {
        id: "email",
        label: "EMAIL",
        value: "alhadidiahamd@gmail.com",
        href: "mailto:alhadidiahamd@gmail.com",
        placeholder: false
      },
      {
        id: "linkedin",
        label: "LINKEDIN",
        value: "ADD LINKEDIN URL",
        href: "#",
        placeholder: true
      },
      {
        id: "github",
        label: "GITHUB",
        value: "ADD GITHUB URL",
        href: "#",
        placeholder: true
      },
      {
        id: "instagram",
        label: "INSTAGRAM",
        value: "ADD INSTAGRAM URL",
        href: "#",
        placeholder: true
      },
      {
        id: "cv",
        label: "CV PDF",
        value: "ADD CV PDF",
        href: "#",
        placeholder: true
      },
      {
        id: "portfolio",
        label: "PORTFOLIO PDF",
        value: "ADD PORTFOLIO PDF",
        href: "#",
        placeholder: true
      }
    ]
  },

  footer: {
    copyright: "©2026",
    name: "AHMAD ALHADIDII",
    location: "JORDAN",
    discipline: "ARCHITECTURE / RESEARCH / COMPUTATIONAL DESIGN",
    text: "©2026 — AHMAD ALHADIDII — JORDAN"
  }
};

/* Classic scripts do not expose top-level const bindings on window. */
window.siteContent = siteContent;
