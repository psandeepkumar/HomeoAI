# Remedy Generation Requirements

## Mandatory Fields for AI Remedy Suggestions

To generate accurate remedy suggestions using Grok AI, you need to complete the following fields:

### ✅ **MANDATORY (Required for remedy generation)**

#### **Step 1: Spontaneous Narrative**

- **Spontaneous Narrative** - Patient's own words describing their condition
  - This is the MOST IMPORTANT field for classical homeopathy
  - Should be detailed and in patient's own language
  - Minimum recommended length: 50 words

#### **Step 2: Chief Complaints (at least 1 complaint)**

Each complaint must have:

- **Title/Description** - Brief description of the complaint
- **Location** - Where is the symptom felt (LSMC - Location)
- **Sensation** - How does it feel (LSMC - Sensation)
- **Modalities** - What makes it better or worse (LSMC - Modalities)

#### **Step 3: Physical Generals**

- **Thermals** - Chilly, Hot, or Normal (very important for remedy selection)
- At least ONE of the following:
  - Thirst quantity
  - Food cravings
  - Food aversions
  - Sleep quality

#### **Step 4: Mental & Emotional**

- **Disposition** - General personality/temperament
- **Key Emotions** - Current emotional state
- At least ONE of:
  - Fears
  - Emotional triggers

### ⚡ **HIGHLY RECOMMENDED (Improves accuracy)**

#### **Step 2: Chief Complaints**

- **Concomitants** - Symptoms that occur together (LSMC - Concomitants)
- **Multiple complaints** - Having 2-3 complaints gives better analysis

#### **Step 3: Physical Generals**

- **Sleep Position** - How patient sleeps
- **Dreams** - Recurring dream themes
- **Perspiration** - Sweating patterns

#### **Step 4: Mental & Emotional**

- **All emotional fields** - Complete emotional picture

#### **Step 5: Peculiar Symptoms**

- **Strange, Rare & Peculiar symptoms** - Unique symptoms that stand out
  - These are GOLD in homeopathy - unusual symptoms that don't fit the diagnosis

### ⭕ **OPTIONAL (Can be added later)**

#### **Step 6: Analysis**

- This step is AUTOMATIC - just click "Generate Remedy Suggestions"
- AI will analyze all previous data

#### **Step 7: Prescription**

- **Remedy Name** - Selected from AI suggestions or manual entry
- **Potency** - Dosage strength (e.g., 30C, 200C)
- **Follow-up Date** - Optional scheduling

---

## How to Generate Remedies

### Step-by-Step Process:

1. **Complete Steps 1-5** with at least the mandatory fields above
2. **Navigate to Step 6 (Analysis)**
3. **Click "Generate Remedy Suggestions"** button
4. **Wait for AI analysis** (may take 10-30 seconds)
5. **Review suggestions** - You'll see:
   - Grade A, B, C remedies (A is best match)
   - Confidence level
   - Differentiating features
   - Matching symptoms
6. **Go to Step 7 (Prescription)**
7. **Enter final remedy** - Can be from suggestions or your own choice
8. **Click "Save Case"**

---

## Minimum Data for Remedy Generation

**Absolute Minimum** (will work but limited accuracy):

- Spontaneous Narrative (50+ words)
- 1 Chief Complaint with LSMC complete
- Thermals (Chilly/Hot/Normal)
- Disposition
- Key Emotions

**Recommended Minimum** (good accuracy):

- Detailed Spontaneous Narrative (100+ words)
- 2-3 Chief Complaints with complete LSMC
- Physical Generals: Thermals, Thirst, Cravings/Aversions, Sleep
- Mental/Emotional: Disposition, Fears, Key Emotions, Triggers
- At least 1-2 Peculiar Symptoms

**Optimal** (best accuracy):

- Everything above PLUS:
  - Multiple peculiar symptoms
  - Dreams
  - Sleep position
  - Perspiration details
  - Concomitants for all complaints

---

## Important Notes

### 🔴 **Why Remedy Generation Might Fail:**

1. **No API Key** - Grok API key must be configured in Settings
2. **Insufficient Data** - At least minimum mandatory fields required
3. **No Spontaneous Narrative** - This is the foundation of the case
4. **No Chief Complaints** - At least one complete LSMC complaint needed
5. **No Physical Generals** - Thermals are especially critical
6. **Network Issues** - API call requires internet connection

### ✅ **Best Practices:**

1. **Save Draft Frequently** - Click "Save Draft" button after each step
2. **Complete Data** - More complete data = better remedy suggestions
3. **Patient's Words** - Use patient's own language in Spontaneous Narrative
4. **LSMC Structure** - Complete all 4 parts for each chief complaint
5. **Peculiar Symptoms** - Don't skip these - they're very valuable
6. **Review AI Suggestions** - AI provides 3-5 remedies with grades
7. **Final Choice** - Practitioner makes final remedy decision in Step 7

---

## Troubleshooting

### "Generate Remedy Suggestions" button not working?

- ✅ Check: Grok API key configured in Settings
- ✅ Check: Internet connection active
- ✅ Check: Spontaneous Narrative filled
- ✅ Check: At least 1 chief complaint with LSMC
- ✅ Check: Physical Generals - Thermals filled

### No remedies showing after clicking button?

- ✅ Wait 10-30 seconds for AI processing
- ✅ Check for error message (red box)
- ✅ Review case data - ensure minimum fields completed
- ✅ Check Settings for valid API key

### "Save Draft" not working?

- ✅ Now FIXED - saves current step data to database
- ✅ Creates case record with status "draft"
- ✅ Can resume case later from patient's profile

### Voice input not working?

- ✅ Check: Microphone permission granted
- ✅ Windows may ask for permission on first use
- ✅ Click microphone icon in Step 1 (Spontaneous Narrative)
- ✅ Speak clearly, system uses Windows Speech Recognition

---

## Data Quality Guidelines

### Spontaneous Narrative:

```
✅ GOOD: "I've had this terrible headache for 3 months. It's on the right side,
like a hammer pounding. It gets worse when I'm stressed at work, better when
I lie down in a dark room. I also feel nauseous when it's bad."

❌ BAD: "Headache. Right side. Stress."
```

### Chief Complaint LSMC:

```
✅ GOOD:
Location: Right temple, extending to right eye
Sensation: Pounding, throbbing, like a hammer
Modalities: Worse from stress, light, noise; Better from lying in dark room
Concomitants: Nausea, photophobia, visual aura (zigzags)

❌ BAD:
Location: Head
Sensation: Pain
Modalities: Stress
Concomitants: (blank)
```

---

## Summary

**To successfully generate remedy suggestions:**

1. ✅ Configure Grok API key in Settings
2. ✅ Fill Spontaneous Narrative (detailed, patient's words)
3. ✅ Add at least 1 Chief Complaint with complete LSMC
4. ✅ Complete Physical Generals (especially Thermals)
5. ✅ Complete Mental/Emotional (Disposition, Key Emotions)
6. ✅ Navigate to Step 6 and click "Generate Remedy Suggestions"
7. ✅ Wait for AI analysis
8. ✅ Review suggestions and proceed to Step 7
9. ✅ Enter final prescription and Save Case

**The more complete your data, the better the remedy suggestions!**
