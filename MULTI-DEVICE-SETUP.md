# Multi-Device Sync — Setup & Usage (v2: photos/videos bhi sync)

## Ab kya sync hota hai
**Sab kuchh** — Labourers, Masons, Drivers, Supervisors, Attendance, Payments,
Vehicles, Equipment, Inventory, Udhar, Rent, Notes, aur **site photos/videos bhi**.
Ek mobile pe change karo, sab jude hue mobiles mein turant (real-time) dikhega —
internet on hona chahiye.

Jis mobile ne kabhi "Multi-Device Sync" on nahi kiya, us par app bilkul pehle jaisa
hi chalega (fully local, full access) — kuch nahi badla.

## Zaroori: 2 jagah setup karna hai (Firebase Console)

### 1) Firestore Rules
Firestore Database → Rules mein, apni existing rules ke saath ye **add** karo:
```
match /companies/{companyId} {
  allow read, write: if true;
  match /{document=**} {
    allow read, write: if true;
  }
}
```

### 2) Storage Rules (photos/videos ke liye)
Build → Storage mein jaao. Agar Storage pehli baar use ho raha hai to "Get Started"
dabake enable karo (default/Spark plan bhi chalega). Fir Rules tab mein:
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /companies/{companyId}/media/{allPaths=**} {
      allow read, write: if true;
    }
  }
}
```

⚠️ **Security note**: Jaise aapke existing collections (pushTokens, textBackups) mein
koi login system nahi hai, waise hi ye bhi hai — jisके paas invite link/QR hai wo hi
judh sakta hai. Invite link sirf jisko add karna hai usi ko bhejo, kisi group mein
public mat karo.

## Use kaise karein
1. **Admin mobile**: Drawer → Multi-Device Sync → "🚀 Is Mobile Ko Admin Banao"
   (ye mojooda saara data + photos cloud pe upload karega, thoda time lag sakta hai
   agar bahut saare photos/videos hain)
2. "➕ Naya Device Add Karo" → naam likho → har section ke liye permission choose
   karo (Access Nahi / Sirf Dekhna / Dekhna + Add-Edit) → "Invite Link/QR Banao"
3. Woh QR doosre mobile se scan karwao ya link WhatsApp pe bhejo
4. Doosra mobile link kholega → naam confirm karke "Company Se Judo" → uska
   local data replace hoke company ka pura data + photos/videos download honge
   (progress dikhega), fir live-sync shuru ho jayega
5. Admin kabhi bhi "Multi-Device Sync" screen se kisi device ki permission badal
   sakta hai ya "Remove" kar sakta hai (turant access hat jayegi)

## Baaki limitations
- Kuch pages jahan add/edit list ke andar hi hota hai (jaise Other Expenses), unme
  is version mein poore page ka view control hota hai — ek-ek button ko alag se
  lock karna extra kaam hoga (bata dena agar chahiye).
- Do mobile agar **ek hi second mein ek hi record** edit karein to jo baad mein
  save hua wahi final rahega (last-write-wins).
- Bahut zyada (jaise sainkado) photos/videos ke liye upload/download mein time
  lagega — Storage free plan mein bhi kaafi jagah milti hai (5GB+), paisa nahi
  lagega normal use mein.

## Deploy
Naya `index.html` apne Vercel project mein purane wale ki jagah daal ke redeploy
kar do. Baaki files (manifest.json, ai-assistant.js, send-reminders.js,
service-worker.js, package.json) same hain, unme koi change nahi hai.
