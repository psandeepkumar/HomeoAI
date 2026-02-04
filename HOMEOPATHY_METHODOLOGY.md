# Classical Homeopathy Methodology - Technical Reference

This document explains the classical homeopathy principles implemented in HomeoAI.

---

## Core Philosophy

**Classical homeopathy** follows these principles:

1. **Law of Similars**: "Like cures like" - a substance that causes symptoms in healthy people can cure similar symptoms in sick people.
2. **Single Remedy**: One remedy at a time (not combinations).
3. **Minimum Dose**: Smallest effective dose.
4. **Totality of Symptoms**: Treat the whole person, not the disease.
5. **Individualization**: Find the unique remedy (simillimum) for each patient's symptom portrait.

---

## Case Taking Hierarchy

HomeoAI follows this **symptom priority hierarchy** (most to least important):

### 1. MIND Symptoms (Highest Priority)

- **Disposition**: Irritable, mild, yielding, fastidious, etc.
- **Fears**: Greatest fears (dark, death, failure, disease, etc.)
- **Emotional Triggers**: "Ailments from" grief, fright, humiliation, anticipation
- **Will & Intellect**: Memory issues, concentration, decision-making
- **Key Emotions**: What makes them feel secure/insecure

**Why important**: Mental state is most individualized; disease may pass but disposition remains.

### 2. GENERALS (High Priority)

Physical symptoms that affect the **whole person**:

- **Thermals**: Chilly / Hot / Ambithermal
  - _Worse_ in cold weather? _Better_ with warmth?
- **Thirst**: Quantity, frequency, temperature preference
- **Food**: Strong cravings or aversions (salt, sweets, fats, etc.)
- **Sleep**: Quality, position, refreshing or not
- **Dreams**: Recurring themes (falling, pursued, water, etc.)
- **Perspiration**: Profuse, absent, odor, location

**Why important**: Generals individualize the constitutional remedy.

### 3. SRP - Strange, Rare, Peculiar (Medium-High Priority)

Symptoms that are:

- **Strange**: Unusual, unexpected manifestations
- **Rare**: Uncommon in typical presentations
- **Peculiar**: Highly individual to this patient

**Examples:**

- "Headache better hanging head backward"
- "Craves chalk or indigestible things"
- "Laughs while telling sad story"

**Why important**: SRP symptoms uniquely identify the simillimum.

### 4. Locals (Medium Priority)

- **Chief Complaints** structured as L-S-M-C:
  - **L** - Location (where exactly?)
  - **S** - Sensation (burning, stitching, throbbing, etc.)
  - **M** - Modalities (better/worse with motion, weather, time, position, etc.)
  - **C** - Concomitants (nausea with headache, chills with fever, etc.)

**Why important**: Modalities individualize; mere location/sensation is common.

---

## Case Taking Process (Step-by-Step)

### Step 1: Spontaneous Narrative

**Objective**: Let the patient tell their story in their own words.

**Practitioner role:**

- Listen without interrupting
- Observe manner of expression, tone, emphasis
- Note recurring themes

**What to capture:**

- Chief concern in patient's words
- Timeline and triggers
- Emotional context
- What matters most to them

**AI Assist**: Grok summarizes themes and suggests clarifying questions.

---

### Step 2: Chief Complaint (LSMC Detail)

**Objective**: Structure each complaint precisely.

**For each complaint, ask:**

- **L**: Where exactly? (side, part of body)
- **S**: How does it feel? (use patient's descriptive words)
- **M**: When is it worse/better?
  - Time of day? Weather? Motion? Position? Eating? Pressure?
- **C**: What else happens with it? (other symptoms appearing together)

**Example:**

```
Complaint: Headache
L: Right temple, extending to eye
S: Throbbing, pulsating
M: < morning, < sunlight, > pressure, > lying in dark room
C: With nausea, photophobia
```

---

### Step 3: Physical Generals

**Key questions:**

**Thermals:**

- "Are you generally chilly or hot?"
- "How do you feel in cold/hot weather?"
- "Do you prefer warm or cold drinks?"

**Thirst:**

- "How much water do you drink?"
- "Preference for cold, warm, or room temp?"

**Appetite:**

- "Any strong cravings?" (salt, sweets, sour, spicy, meat, etc.)
- "Foods you cannot tolerate or dislike?"

**Sleep:**

- "Quality of sleep?"
- "Preferred sleeping position?"
- "Do you wake refreshed?"
- "Any recurring dreams?"

---

### Step 4: Mental & Emotional

**Disposition:**

- "How would you describe your temperament?"
- Options: irritable, anxious, mild, fastidious, indifferent, weepy, hurried, sluggish

**Fears:**

- "What are your greatest fears?"
- Common: disease, death, poverty, failure, closed spaces, heights

**Emotional Triggers:**

- "Has this ailment started after any emotional event?"
- Grief, humiliation, anger, fright, anticipation (exams, travel)

---

### Step 5: Review & Mark Peculiar

**Objective**: Identify SRP symptoms from the totality.

**How to identify SRP:**

- Symptoms that stand out as unusual
- Contradictory symptoms (wants covers but also wants windows open)
- Rare manifestations (unilateral symptoms, unusual sensations)

**AI Assist**: Grok highlights potential SRP symptoms with reasoning.

---

### Step 6: Analysis & Repertorization

**Objective**: Map symptoms to remedy rubrics and identify simillimum.

**Process:**

1. Select 4-8 **most characteristic symptoms** (prioritize MIND → GENERALS → SRP)
2. Assign priority/weight to each
3. Grok maps to repertory rubrics (Kent/Synthesis style)
4. Grok suggests top 5 remedies with grades and reasoning
5. Review differential analysis

**Example Rubrics:**

- `MIND - ANXIETY - health, about`
- `GENERALS - FOOD - salt, desire`
- `HEAD - PAIN - throbbing - temples - right`

**Remedy Grading:**

- Grade 3 (bold): Remedy strongly indicated
- Grade 2 (italic): Remedy indicated
- Grade 1 (plain): Remedy sometimes indicated

---

### Step 7: Prescription & Follow-up

**Prescription format:**

- **Remedy name**: Arsenicum album
- **Potency**: 30C, 200C, 1M, etc.
- **Dose**: One dose / 3 pellets / liquid dilution
- **Repetition**: Single dose vs. daily vs. as needed
- **Instructions**: What to observe, when to report

**Follow-up questions:**

- Changes in chief complaint?
- Changes in generals?
- New symptoms (proving)?
- Emotional/mental state shifts?

---

## Grok AI Role in This Workflow

Grok is **NOT** a replacement for practitioner judgment. It assists by:

1. **Summarizing Narratives**: Extracts themes from patient stories
2. **Suggesting Questions**: Identifies gaps in case data
3. **Highlighting SRP**: Points out potentially peculiar symptoms
4. **Repertorization**: Maps symptoms to rubrics (saves manual lookup time)
5. **Differential Analysis**: Compares top remedies from Materia Medica
6. **Not Diagnosing**: Focuses on symptom portraits, not disease labels

**Disclaimer**: All Grok outputs must be verified by the practitioner. This is a tool for efficiency, not automation of clinical decision-making.

---

## Key Homeopathic Concepts

### Totality of Symptoms

The **complete picture** of the patient:

- Mental state + Generals + Peculiars + Locals
- Not just the disease name (e.g., "migraine")

### Simillimum

The **one remedy** that most closely matches the totality.

- Covers most symptoms
- Especially MIND and GENERALS
- Has the characteristic SRP features

### Constitutional vs. Acute Remedy

- **Constitutional**: Matches the person's overall nature (long-term)
- **Acute**: Matches the acute episode (short-term relief)

HomeoAI focuses on **constitutional case taking** but can document acute cases too.

---

## Common Pitfalls (Avoided in HomeoAI)

1. **Diagnosing Disease**: We analyze symptoms, not diagnose pathology
2. **Ignoring Mentals**: Never skip mental/emotional symptoms
3. **Locals Only**: Don't prescribe just on local symptoms (e.g., headache location)
4. **Combining Remedies**: Classical = single remedy
5. **Over-reliance on AI**: Grok assists; practitioner decides

---

## Resources for Further Study

- **Organon of Medicine** by Samuel Hahnemann (foundational text)
- **Repertory of the Homeopathic Materia Medica** by James Tyler Kent
- **Lectures on Homeopathic Philosophy** by J.T. Kent
- **The Science of Homeopathy** by George Vithoulkas
- **Modern repertories**: Synthesis, Complete Repertory

---

**This methodology is embedded in HomeoAI's prompts and UI flow.**
