# Troubleshooting Guide - HomeoAI Case Wizard

## Issue: Case Not Saving

### Symptoms:

- Clicking "Save Case" shows success message but case doesn't appear in patient's case list
- No error message displayed
- Case data lost after closing the wizard

### Solutions:

#### ✅ **Solution 1: Ensure Required Fields Are Filled**

The final prescription (Step 7) requires:

- **Remedy Name** (mandatory)
- **Potency** (mandatory)

**Steps to fix:**

1. Go to Step 7 (Prescription)
2. Fill in "Remedy Name" field (e.g., "Arsenicum Album")
3. Fill in "Potency" field (e.g., "30C", "200C", "1M")
4. Click "Save Case"

#### ✅ **Solution 2: Use "Save Draft" Regularly**

- Click "Save Draft" button (top right) after completing each step
- This saves your progress even without a final prescription
- Draft cases can be resumed later from the patient's profile

#### ✅ **Solution 3: Check Database Connection**

If drafts also fail to save:

1. Close and restart the app
2. Try creating a new patient first
3. Then create a case for that patient

---

## Issue: Grok Analysis Error - "Credits Exhausted"

### Symptoms:

- Error message: "API Credits Exhausted: Your Grok API account has run out of credits"
- Status code: 429
- Analysis fails immediately

### Cause:

Your Grok AI API account has either:

- Used all available free/paid credits
- Reached monthly spending limit

### Solutions:

#### ✅ **Solution 1: Purchase More Credits (Recommended)**

**Steps:**

1. Visit **https://x.ai/**
2. Sign in with your Grok AI account
3. Navigate to **Billing** or **API Credits**
4. **Purchase more credits** or **increase spending limit**
5. Wait 5-10 minutes for credits to activate
6. Return to HomeoAI and try analysis again

#### ✅ **Solution 2: Complete Case Manually Without AI**

**You can still use the app fully without AI analysis:**

1. **Complete Steps 1-5** normally:
   - Step 1: Spontaneous Narrative
   - Step 2: Chief Complaints
   - Step 3: Physical Generals
   - Step 4: Mental & Emotional
   - Step 5: Peculiar Symptoms

2. **Skip Step 6 (Analysis)**:
   - Don't click "Generate Remedy Suggestions"
   - Just click "Continue" to proceed

3. **Enter Prescription Manually (Step 7)**:
   - Use your homeopathic knowledge
   - Or refer to external repertories/materia medica
   - Enter remedy name and potency directly
   - Click "Save Case"

**Note:** The app stores all case data. You can analyze it with AI later when credits are available.

#### ✅ **Solution 3: Use Alternative API Key**

If you have multiple Grok accounts:

1. Go to **Settings** (☰ menu → Settings)
2. Remove current API key (click "Remove API Key")
3. Enter new API key with available credits
4. Click "Save API Key"
5. Return to case wizard and try again

---

## Issue: Voice Input Not Working

### Symptoms:

- Microphone button doesn't respond
- No transcription appears
- Permission errors

### Solutions:

#### ✅ **Solution 1: Grant Microphone Permission**

**Windows:**

1. Windows will prompt for permission on first use
2. Click **"Allow"** when prompted
3. If you denied it:
   - Go to Windows **Settings → Privacy → Microphone**
   - Enable microphone access for HomeoAI app
   - Restart the app

#### ✅ **Solution 2: Check Microphone Hardware**

1. Test microphone in another app (e.g., Voice Recorder)
2. Ensure microphone is not muted
3. Check default microphone in Windows Sound settings

#### ✅ **Solution 3: Restart Voice Input**

1. Click microphone icon to stop if it's stuck
2. Wait 2 seconds
3. Click again to restart
4. Speak clearly and continuously

---

## Issue: No Remedy Suggestions After Analysis

### Symptoms:

- Analysis completes without error
- No remedies displayed in Step 6
- Empty suggestion list

### Causes & Solutions:

#### ✅ **Cause 1: Insufficient Case Data**

**Minimum required data for AI analysis:**

- Spontaneous Narrative (50+ words)
- At least 1 Chief Complaint with complete LSMC
- Thermals (Chilly/Hot/Normal)
- Mental/Emotional: Disposition + Key Emotions

**Solution:**

1. Go back through Steps 1-5
2. Ensure all mandatory fields are filled
3. Return to Step 6
4. Click "Generate Remedy Suggestions" again

#### ✅ **Cause 2: API Returned Invalid Response**

**Solution:**

1. Check error message (if any)
2. Wait 30 seconds
3. Try "Generate Remedy Suggestions" again
4. If persists, save draft and try later

---

## Issue: App Crashes or Freezes

### Solutions:

#### ✅ **Solution 1: Force Quit and Restart**

1. Close the app completely
2. Reopen HomeoAI
3. Your draft should be auto-saved
4. Resume from patient's case list

#### ✅ **Solution 2: Clear Cache**

1. Close app
2. Delete: `C:\Users\[YourName]\AppData\Local\homeo_ai\cache`
3. Restart app

---

## Best Practices to Avoid Issues

### 1. **Save Draft Frequently** ⭐

- Click "Save Draft" after completing each step
- Especially before attempting AI analysis
- Prevents data loss

### 2. **Fill Complete Data** 📝

- More complete data = better AI suggestions
- Don't skip LSMC fields in chief complaints
- Include peculiar symptoms

### 3. **Verify API Credits Before Analysis** 💳

- Check Grok account has credits before starting
- Or be prepared to complete manually

### 4. **Review Before Final Save** ✅

- Step 7 requires remedy name + potency
- Double-check prescription details
- Cannot edit after "Save Case" (currently)

### 5. **Use Sample Data for Testing** 🧪

- Settings → Load Sample Data
- Practice with demo patients first
- Learn the workflow without losing real data

---

## Common Error Messages Explained

| Error Message                    | Meaning           | Solution                    |
| -------------------------------- | ----------------- | --------------------------- |
| "API Credits Exhausted"          | No Grok credits   | Purchase credits at x.ai    |
| "Grok API key not configured"    | Missing API key   | Add key in Settings         |
| "Failed to create case record"   | Database error    | Restart app, try again      |
| "Microphone permission required" | No mic access     | Grant permission in Windows |
| "Max retries exceeded"           | Network/API issue | Check internet, try later   |
| "Invalid JSON response"          | Grok API error    | Wait and retry analysis     |

---

## Getting Help

### Check First:

1. ✅ API key configured in Settings?
2. ✅ Internet connection active?
3. ✅ Grok account has credits?
4. ✅ Required fields filled in form?
5. ✅ Using latest version of app?

### Still Having Issues?

- Review [REMEDY_GENERATION_REQUIREMENTS.md](REMEDY_GENERATION_REQUIREMENTS.md) for detailed field requirements
- Check app logs for detailed error messages
- Try with sample data first to isolate the issue

---

## Quick Reference: Field Requirements

### Step 1 - Spontaneous Narrative

- ✅ **Mandatory**: Narrative text (50+ words recommended)

### Step 2 - Chief Complaints

- ✅ **Mandatory**: At least 1 complaint
- ✅ **For each complaint**:
  - Title
  - Location (LSMC - L)
  - Sensation (LSMC - S)
  - Modalities (LSMC - M)
  - Concomitants (LSMC - C) - Optional but helpful

### Step 3 - Physical Generals

- ✅ **Mandatory**: Thermals (Chilly/Hot/Normal)
- ⭕ Recommended: Thirst, Cravings/Aversions, Sleep

### Step 4 - Mental & Emotional

- ✅ **Mandatory**: Disposition, Key Emotions
- ⭕ Recommended: Fears, Emotional Triggers

### Step 5 - Peculiar Symptoms

- ⭕ Optional but very valuable for analysis

### Step 6 - Analysis

- Automatic - just click "Generate Remedy Suggestions"
- Requires Grok API credits

### Step 7 - Prescription

- ✅ **Mandatory for saving**: Remedy Name, Potency
- ⭕ Optional: Dose, Notes, Follow-up Date

---

## Summary

**Most common issues:**

1. 🔴 **Credits exhausted** → Purchase at x.ai or complete manually
2. 🔴 **Case not saving** → Ensure Remedy Name + Potency filled in Step 7
3. 🔴 **Voice not working** → Grant microphone permission
4. 🔴 **No suggestions** → Fill minimum required data in Steps 1-5

**Remember:**

- ✅ Save Draft frequently
- ✅ Complete cases work fine without AI analysis
- ✅ All data is stored locally - private and secure
