# Yarncrawler  
## Constraint-Driven World-State Reconstruction

[Audio Overview](https://standardgalactic.github.io/yarncrawler/introduction/)

Yarncrawler is a framework for reconstructing reality not by estimation, but by **constraint closure**.

Instead of asking *what is likely*, it asks:

> What must be true, given all observations and all physical laws?

The system models the world as a field:

X = (Φ, v, S)

where:

Φ — scalar density (matter, infrastructure, biomass)  
v — vector flow (movement, transport, dynamics)  
S — entropy (obstruction, ambiguity, hidden activity)  

Reconstruction proceeds by eliminating all inconsistent states until only one remains.

---

## Documents

### [Blog Post](blog-post.md)  
A high-level introduction to the failure of data-heavy approaches and the need for constraint-based reconstruction.  
Establishes the concept of the **fog of information** and motivates closure.

---

### [Conceptual Primer](conceptual-primer.md)  
Introduces the RSVP field and the sheaf-based view of sensing.  
Explains how local observations become global truth through consistency.

---

### [Sensor Modalities](sensor-modalities.md)  
Describes how different sensing technologies act as projection operators on the RSVP field.  
Explains what each modality reveals and what it cannot see.

---

### [Optimization Protocol](optimization-protocol.md)  
Presents the operational framework for achieving closure.  
Introduces cohomological descent, Fisher geometry, and sensor selection strategies.

---

### [Design Specification](design-specification.md)  
Formalizes sensor network architecture using the Identifiability Theorem.  
Defines projection operators, failure modes, and closure conditions.

---

### [Implementation Roadmap](roadmap.md)  
Outlines the staged deployment of the system across planetary, regional, and site scales.  
Describes refinement loops, operator learning, and system integration.

---

## Core Principles

### Constraint Over Data

More data does not guarantee clarity.

Only **structurally distinct constraints** reduce ambiguity.

---

### Closure Over Estimation

A reconstruction is valid only when:

|F| = 1  

There is exactly one world-state consistent with all constraints.

---

### Entropy as Obstruction

S is not noise.

It is the measurable density of unresolved inconsistency.

---

### Dynamics Resolve Ambiguity

Static observations are insufficient.

Time evolution separates indistinguishable states.

---

### Field Completeness

All components are required:

- Φ without v → static illusion  
- v without Φ → empty flow  
- S absent → hidden processes ignored  

---

## Architecture

The system operates as a refinement loop:

1. propose candidate state  
2. project into observation space  
3. measure residuals  
4. update via constrained dynamics  
5. repeat until closure  

This process contracts the feasible set:

F → {X*}

---

## Scale

Yarncrawler is inherently multi-scale:

- planetary → incomplete constraints, large uncertainty  
- regional → refined structure  
- site → full closure  

Consistency is maintained across scales through restriction mappings.

---

## What This Replaces

Traditional approaches:

- statistical estimation  
- probabilistic inference  
- model fitting  

Yarncrawler replaces these with:

- constraint satisfaction  
- geometric contraction  
- dynamical consistency  

---

## Final Statement

Reality is not reconstructed by guessing.

It is reconstructed by eliminating every alternative until only one possibility remains.
