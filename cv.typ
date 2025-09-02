// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}

#import "@preview/fontawesome:0.5.0": *

//------------------------------------------------------------------------------
// Style
//------------------------------------------------------------------------------

// const color
#let color-darknight = rgb("#131A28")
#let color-darkgray = rgb("#333333")
#let color-middledarkgray = rgb("#414141")
#let color-gray = rgb("#5d5d5d")
#let color-lightgray = rgb("#999999")

// Default style
#let color-accent-default = rgb("#dc3522")
#let font-header-default = ("Roboto", "Arial", "Helvetica", "Dejavu Sans")
#let font-text-default = ("Source Sans Pro", "Arial", "Helvetica", "Dejavu Sans")
#let align-header-default = center

// User defined style
#let color-accent = rgb("009BC1")
#let color-link = color-darknight
#let font-header = "Helvetica"
#let font-text = "Roboto"

//------------------------------------------------------------------------------
// Helper functions
//------------------------------------------------------------------------------

// icon string parser

#let parse_icon_string(icon_string) = {
  if icon_string.starts-with("fa ") [
    #let parts = icon_string.split(" ")
    #if parts.len() == 2 {
      fa-icon(parts.at(1), fill: color-darknight)
    } else if parts.len() == 3 and parts.at(1) == "brands" {
      fa-icon(parts.at(2), font: "Font Awesome 6 Brands", fill: color-darknight)
    } else {
      assert(false, "Invalid fontawesome icon string")
    }
  ] else if icon_string.ends-with(".svg") [
    #box(image(icon_string))
  ] else {
    assert(false, "Invalid icon string")
  }
}

// contaxt text parser
#let unescape_text(text) = {
  // This is not a perfect solution
  text.replace("\\", "").replace(".~", ". ")
}

// layout utility
#let __justify_align(left_body, right_body) = {
  block[
    #box(width: 4fr)[#left_body]
    #box(width: 1fr)[
      #align(right)[
        #right_body
      ]
    ]
  ]
}

#let __justify_align_3(left_body, mid_body, right_body) = {
  block[
    #box(width: 1fr)[
      #align(left)[
        #left_body
      ]
    ]
    #box(width: 1fr)[
      #align(center)[
        #mid_body
      ]
    ]
    #box(width: 1fr)[
      #align(right)[
        #right_body
      ]
    ]
  ]
}

/// Right section for the justified headers
/// - body (content): The body of the right header
#let secondary-right-header(body) = {
  set text(
    size: 10pt,
    weight: "thin",
    style: "italic",
    fill: color-accent,
  )
  body
}

/// Right section of a tertiaty headers. 
/// - body (content): The body of the right header
#let tertiary-right-header(body) = {
  set text(
    weight: "light",
    size: 9pt,
    style: "italic",
    fill: color-gray,
  )
  body
}

/// Justified header that takes a primary section and a secondary section. The primary section is on the left and the secondary section is on the right.
/// - primary (content): The primary section of the header
/// - secondary (content): The secondary section of the header
#let justified-header(primary, secondary) = {
  set block(
    above: 0.7em,
    below: 0.7em,
  )
  pad[
    #__justify_align[
      #set text(
        size: 12pt,
        weight: "bold",
        fill: color-darkgray,
      )
      #primary
    ][
      #secondary-right-header[#secondary]
    ]
  ]
}

/// Justified header that takes a primary section and a secondary section. The primary section is on the left and the secondary section is on the right. This is a smaller header compared to the `justified-header`.
/// - primary (content): The primary section of the header
/// - secondary (content): The secondary section of the header
#let secondary-justified-header(primary, secondary) = {
  __justify_align[
     #set text(
      size: 10pt,
      weight: "regular",
      fill: color-gray,
    )
    #primary
  ][
    #tertiary-right-header[#secondary]
  ]
}

//------------------------------------------------------------------------------
// Header
//------------------------------------------------------------------------------

#let create-header-name(
  firstname: "",
  lastname: "",
) = {
  
  pad(bottom: 5pt)[
    #block[
      #set text(
        size: 32pt,
        style: "normal",
        font: (font-header),
      )
      #text(fill: color-gray, weight: "thin")[#firstname]
      #text(weight: "bold")[#lastname]
    ]
  ]
}

#let create-header-position(
  position: "",
) = {
  set block(
      above: 0.75em,
      below: 0.75em,
    )
  
  set text(
    color-accent,
    size: 9pt,
    weight: "regular",
  )
    
  smallcaps[
    #position
  ]
}

#let create-header-address(
  address: ""
) = {
  set block(
      above: 0.75em,
      below: 0.75em,
  )
  set text(
    color-lightgray,
    size: 9pt,
    style: "italic",
  )

  block[#address]
}

#let create-header-contacts(
  contacts: (),
) = {
  let separator = box(width: 2pt)
  if(contacts.len() > 1) {
    block[
      #set text(
        size: 9pt,
        weight: "regular",
        style: "normal",
      )
      #align(horizon)[
        #for contact in contacts [
          #set box(height: 9pt)
          #box[#parse_icon_string(contact.icon) #link(contact.url)[#contact.text]]
          #separator
        ]
      ]
    ]
  }
}

#let create-header-info(
  firstname: "",
  lastname: "",
  position: "",
  address: "",
  contacts: (),
  align-header: center
) = {
  align(align-header)[
    #create-header-name(firstname: firstname, lastname: lastname)
    #create-header-position(position: position)
    #create-header-address(address: address)
    #create-header-contacts(contacts: contacts)
  ]
}

#let create-header-image(
  profile-photo: ""
) = {
  if profile-photo.len() > 0 {
    block(
      above: 15pt,
      stroke: none,
      radius: 9999pt,
      clip: true,
      image(
        fit: "contain",
        profile-photo
      )
    ) 
  }
}

#let create-header(
  firstname: "",
  lastname: "",
  position: "",
  address: "",
  contacts: (),
  profile-photo: "",
) = {
  if profile-photo.len() > 0 {
    block[
      #box(width: 5fr)[
        #create-header-info(
          firstname: firstname,
          lastname: lastname,
          position: position,
          address: address,
          contacts: contacts,
          align-header: left
        )
      ]
      #box(width: 1fr)[
        #create-header-image(profile-photo: profile-photo)
      ]
    ]
  } else {
    
    create-header-info(
      firstname: firstname,
      lastname: lastname,
      position: position,
      address: address,
      contacts: contacts,
      align-header: center
    )

  }
}

//------------------------------------------------------------------------------
// Resume Entries
//------------------------------------------------------------------------------

#let resume-item(body) = {
  set text(
    size: 10pt,
    style: "normal",
    weight: "light",
    fill: color-darknight,
  )
  set par(leading: 0.65em)
  set list(indent: 1em)
  body
}

#let resume-entry(
  title: none,
  location: "",
  date: "",
  description: ""
) = {
  pad[
    #justified-header(title, location)
    #secondary-justified-header(description, date)
  ]
}

//------------------------------------------------------------------------------
// Data to Resume Entries
//------------------------------------------------------------------------------

#let data-to-resume-entries(
  data: (),
) = {
  let arr = if type(data) == dictionary { data.values() } else { data }
  for item in arr [
    #resume-entry(
      title: if "title" in item { item.title } else { none },
      location: if "location" in item { item.location } else { none },
      date: if "date" in  item { item.date } else { none },
      description: if "description" in item { item.description } else { none }
    )
    #if "details" in item {
      resume-item[
        #for detail in item.details [
          - #detail
        ]
      ]
    }
  ]
}


//------------------------------------------------------------------------------
// Resume Template
//------------------------------------------------------------------------------

#let resume(
  title: "CV",
  author: (:),
  date: datetime.today().display("[month repr:long] [day], [year]"),
  profile-photo: "",
  body,
) = {
  
  set document(
    author: author.firstname + " " + author.lastname,
    title: title,
  )
  
  set text(
    font: (font-text),
    size: 11pt,
    fill: color-darkgray,
    fallback: true,
  )
  
  set page(
    paper: "a4",
    margin: (left: 15mm, right: 15mm, top: 10mm, bottom: 10mm),
    footer: context [
      #set text(
        fill: gray,
        size: 8pt,
      )
      #__justify_align_3[
        #smallcaps[#date]
      ][
        #smallcaps[
          #author.firstname
          #author.lastname
          #sym.dot.c
          CV
        ]
      ][
        #counter(page).display()
      ]
    ],
  )
  
  // set paragraph spacing

  set heading(
    numbering: none,
    outlined: false,
  )
  
  show heading.where(level: 1): it => [
    #set block(
      above: 1.5em,
      below: 1em,
    )
    #set text(
      size: 16pt,
      weight: "regular",
    )
    
    #align(left)[
      #text[#strong[#text(color-accent)[#it.body.text.slice(0, 3)]#text(color-darkgray)[#it.body.text.slice(3)]]]
      #box(width: 1fr, line(length: 100%))
    ]
  ]
  
  show heading.where(level: 2): it => {
    set text(
      color-middledarkgray,
      size: 12pt,
      weight: "thin"
    )
    it.body
  }
  
  show heading.where(level: 3): it => {
    set text(
      size: 10pt,
      weight: "regular",
      fill: color-gray,
    )
    smallcaps[#it.body]
  }
  
  // Other settings
  show link: set text(fill: color-link)

  // Contents
  create-header(firstname: author.firstname,
                lastname: author.lastname,
                position: author.position,
                address: author.address,
                contacts: author.contacts,
                profile-photo: profile-photo,)
  body
}


// Typst custom formats typically consist of a 'typst-template.typ' (which is
// the source code for a typst template) and a 'typst-show.typ' which calls the
// template's function (forwarding Pandoc metadata values as required)
//
// This is an example 'typst-show.typ' file (based on the default template  
// that ships with Quarto). It calls the typst function named 'article' which 
// is defined in the 'typst-template.typ' file. 
//
// If you are creating or packaging a custom typst template you will likely
// want to replace this file and 'typst-template.typ' entirely. You can find
// documentation on creating typst templates here and some examples here:
//   - https://typst.app/docs/tutorial/making-a-template/
//   - https://github.com/typst/templates

#show: resume.with(
  title: [CV],
  author: (
    firstname: unescape_text("Edgar"),
    lastname: unescape_text("Rodríguez-Huerta"),
    address: unescape_text("Data Science, Sustainability and Supply Chain Mapping | £2.1m in Co-I & PI grant funding | FWCI: 1.42"),
    position: unescape_text("Rights Lab Senior Research Fellow in Social Sustainability and Complex Systems"),
    contacts: ((
      text: unescape_text("edgar.rodriguezhuerta\@nottingham.ac.uk"),
      url: unescape_text("edgar.rodriguezhuerta\@nottingham.ac.uk"),
      icon: unescape_text("fa envelope"),
    ), (
      text: unescape_text("0000-0002-6887-0040"),
      url: unescape_text("https:\/\/orcid.org/0000-0002-6887-0040"),
      icon: unescape_text("fa brands orcid"),
    ), (
      text: unescape_text("LinkedIn"),
      url: unescape_text("https:\/\/www.linkedin.com/in/edgarodriguez/"),
      icon: unescape_text("fa brands linkedin"),
    )),
  ),
)

= Experience
<experience>
#data-to-resume-entries(data: yaml("assets/yml/work_academic.yml"))

= Industry Experience
<industry-experience>
#data-to-resume-entries(data: yaml("assets/yml/work_non_academic.yml"))

= Education
<education>
#data-to-resume-entries(data: yaml("assets/yml/education.yml"))

= Selected publications
<selected-publications>
== Peer reviewed
<peer-reviewed>
- #strong[Rodríguez-Huerta];, E., Leão L., Landman, T. (2025). Climate change, decent work and workers' health in Brazil: theoretical considerations. Revista Brasileira de Saúde Ocupacional #link("https://nottingham-repository.worktribe.com/output/46458837")[`https://nottingham-repository.worktribe.com/output/46458837`]

- Tigchelaar, M., Jackson, B., Selig, E., Davis, A., O'Regan, E., Trond, K., Nakayama, S., Boyd, D., Cheung, W., #strong[Rodríguez-Huerta];, E., Williams, C., Decker Sparks, J. (2025). Conceptualization of Decent Work in Fishing in a Changing Climate. #emph[Marine Policy];. #link("https://doi.org/10.1016/j.marpol.2025.106846")[`https://doi.org/10.1016/j.marpol.2025.106846`]

- Boyd, D., Jackson, B., Decker Sparks, J., Giles M. F, Girindran, R., Gosiling, S., Trodd, Z. Ni Bhriain, L., #strong[Rodríguez-Huerta];, E. (2024). The future of decent work: Forecasting heat stress and the intersection of sustainable development challenges in India's brick kilns. #emph[Sustainable Development];, #link("https://doi.org/10.1002/sd.3272")[`https://doi.org/10.1002/sd.3272`]

- Blackstone, N.T., Battaglia K., #strong[Rodríguez-Huerta];, E., Bell, B., Decker Sparks J., Cash S., Conrad Z., Nikkhah A., Jackson B., Matteson J., Gao S., Fuller K., Zhang F.F., Webb P. (2024). Diets cannot be sustainable without ensuring the well-being of communities, workers, and animals in food value chains. #emph[Nature Food];, #link("https://doi.org/10.1038/s43016-024-01048-0")[`https://doi.org/10.1038/s43016-024-01048-0`]

- Lumley-Sapanski A., #strong[Rodríguez-Huerta];, E., Young, M., Nicholson A., Schwarz K. (2024). Criminalizing survivors of modern slavery: the United Kingdom's National Referral Mechanism as a border-making process. #emph[Journal of Social Policy];, #link("https://doi.org/10.1017/S0047279424000230")[`https://doi.org/10.1017/S0047279424000230`]

- Blackstone, N.T., #strong[Rodríguez-Huerta];, E., Battaglia K., Jackson B., Jackson E., Benoît Norris C., Decker Sparks, J.L. (2023). Forced labour risk is pervasive in the US land-based food supply. #emph[Nature Food];. #link("https://doi.org/10.1038/s43016-023-00794-x")[`https://doi.org/10.1038/s43016-023-00794-x`]

== Non-Peer reviewed
<non-peer-reviewed>
- Cockayne, J., #strong[Rodríguez-Huerta] E., Burcu, O. (2022). The Energy of Freedom? Solar Energy, Modern Slavery and the Just Transition. #emph[Research report];, 70,000 words, funded by the British Academy: #link("https://www.thebritishacademy.ac.uk/publications/the-energy-of-freedom-solar-energy-modern-slavery-and-the-just-transition/")[`https://www.thebritishacademy.ac.uk/publications/the-energy-of-freedom-solar-energy-modern-slavery-and-the-just-transition/`]

- Boyd, D., #strong[Rodríguez-Huerta];, E., Jackson B., Decker Sparks, J.L. (2021). The Social and Ecological Impacts of Supply Chains. #emph[Research report];, 16,000 words, funded by the World Wide Fund for Nature.

== Under review/Development
<under-reviewdevelopment>
- #strong[Rodríguez-Huerta];, E., Bell, B., Jackson, B., Blackstone, N.T., Battaglia, K., Marquez, A.S., Benoît Norris, C., Decker Sparks, J.L., Conrad, Z., Matteson, J. (anticipated 2025). The human cost of current and recommended diets in the U.S. (#emph[under second review for Nature Food];). #link("https://doi.org/10.21203/rs.3.rs-4999594/v1%5D")[`https://doi.org/10.21203/rs.3.rs-4999594/v1`]

- #strong[Rodríguez-Huerta];, E., Jackson, B., Blackstone, N.T., Decker Sparks, J.L., (anticipated 2025). Modern slavery's carbon cost in supply chains: the case of Brazilian soy and sugarcane. #emph[Book chapter for Supply Chains and the SDGs (Elgar Companion)];.

- #strong[Rodríguez-Huerta];, E., Trevizan. A., Landman, T., et al.~(anticipated 2026). Exploratory Analysis of the interrelationships between occupational health and decent work (#emph[in preparation for World Development];).

- #strong[Rodríguez-Huerta];, E., Walker, R., Ní Bharain, L., Boyd, D., Jackson, B., (anticipated 2026). Exploration of off-season labour patterns for Indian brick kiln workers (#emph[in preparation for International Journal of Operations & Production Management];).

- Jackson, B., #strong[Rodríguez-Huerta];, E., Marshall, H., Pereira, A.C., Chandler, C., Light, M., Iqbal, S., Boyd, D., Decker Sparks, J.L. (anticipated 2026). Measuring the co-occurrence of tree loss and modern slavery in Brazil between 2001-2021 (#emph[in preparation TBD];).

== Other selected outcomes
<other-selected-outcomes>
- #strong[Rodriguez Huerta];, E., (2024-ongoing). Multilingual website for dissemination activities and results of the project 'Climate Change, Occupational Health, and Decent Work: Worker Vulnerabilities and Responses in Brazilian Agriculture' #emph[Digital Artefact: Website Content] #link("https://www.clidewo.com")[`https://www.clidewo.com`]

- Jackson, B., #strong[Rodriguez Huerta];, E., Boyd, D., Girindran, R., Ni Bhriain, L., & Trodd, Z. (2024). Environmental Impacts Training Module: Assessing Risks to Workers in India (Versions: English, Hindi, Punjabi & Bengali) #emph[Digital Artefact: Website Content] #link("https://nottingham-repository.worktribe.com/output/44691673")[`https://nottingham-repository.worktribe.com/output/44691673`]

- #strong[Rodriguez Huerta];, E., (2023). Interactive Visualizations to expand on results from the 'Forced labor risk is pervasive in the US land-based food supply (Blackstone et al.~2023). #emph[Digital Artefact: Website Content] #link("https://sites.tufts.edu/lasting/data/")[`https://sites.tufts.edu/lasting/data/`]

= Grants and Fellowships
<grants-and-fellowships>
#data-to-resume-entries(data: yaml("assets/yml/grants.yml"))

= Awards
<awards>
#data-to-resume-entries(data: yaml("assets/yml/award.yml"))

= Selected Events and Collaborations
<selected-events-and-collaborations>
#data-to-resume-entries(data: yaml("assets/yml/conferences.yml"))

= Teaching
<teaching>
== Graduate
<graduate>
#data-to-resume-entries(data: yaml("assets/yml/teaching.yml"))

== Seminars
<seminars>
#data-to-resume-entries(data: yaml("assets/yml/workshop.yml"))

= Selected extra training
<selected-extra-training>
#data-to-resume-entries(data: yaml("assets/yml/training.yml"))

= Skills and Languages
<skills-and-languages>
== Languages \
<languages>
#emph[Spanish (Native)];, #emph[English (Fluent)]

== Programming and Markdown language \
<programming-and-markdown-language>
#emph[R];, #emph[SQL (intermediate)];, #emph[Quarto]

== Software \
<software>
#emph[Tableau \[Desktop and Prep\], Rstudio, QGIS, OpenLCA, Zotero, VosViewer, Xerte (intermediate), Affinity (learning), Observable (learning)]

= Academic Service
<academic-service>
== Grants and Journals Reviewed \
<grants-and-journals-reviewed>
#emph[British Academy for Knowledge frontiers: Just Transition];, #emph[Journal of Cleaner Production];, #emph[Energy Policy];, #emph[Hydrogeology Journal];, #emph[Joule];, #emph[Anti-Trafficking Review];, #emph[Economía Creativa];.

== Student Supervision \
<student-supervision>
- PhD Students: 3 supervised -- Topics in Food Systems
- MSc Students: 4 supervised -- Research in data extraction, and regional development
- Support for MSc students from the Technical University of Denmark (DTU) for the project "Sociotechnical dimension of renewable energies" (Apr 2024).
- BSc Students: 3 supervised -- Placement students related to data science projects and just transition

== Societes \
<societes>
- Member of #link("https://www.thebritishacademy.ac.uk/early-career-researcher-network/")[`The British Academy Career Researcher Network`] since 2023.
