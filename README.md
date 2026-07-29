Enam Trims — Production Planning System (Phase 1)
A live, shared web app that replaces manual copy/paste into 24 Excel tabs.
Import your ERP export once, and Check / Partial / HOLD / Outsource / WFM /
Committed / risk dashboard all update automatically.
Files:
`schema.sql` — run once in Supabase (or re-run — it's safe to run again)
`index.html` — the whole app (no build step)
What's new in this update
"Claim Admin Access" button — no more SQL Editor to become the first
Admin. If nobody in the workspace is Admin yet, you'll see a banner with
a button right in the app; click it and you're Admin. See "Create your
first account" below. Re-run `schema.sql` for this — it adds the function
that makes it work.
Sign in with your real work email again — after trying a
username-only login, we went back to real email + password. The
username-only version needed a fake internal email address behind the
scenes to satisfy Supabase, and that fake address caused real problems
(rejected as invalid, hit email rate limits, got out of sync with the
app). Real email avoids all of that outright. A friendly display name
(e.g. "rahatul" from rahatul@enamtrims.com) still shows in Manage Users
and "updated by" fields — you just sign in with the real address.
Planning Master page — a dedicated page (separate from All Jobs) that
works exactly like your Excel "Planning Master" tab did, once we actually
traced its formulas: every column there except Job No was a VLOOKUP off
ERP DATA. The only thing a person ever typed was the Job No itself. So
this page is the same idea — a working list you build by adding Job
Numbers (paste from Excel, or upload a file), and everything else
(customer, EDD, qty, hold status…) is already there automatically, because
it's the same underlying data as your ERP import — no VLOOKUP needed.
Once a job's on the list, set Priority (Urgent/High/Normal/Low),
Planned Date, and Planning Notes on it to decide what runs next.
Untick "On Plan" to take a job back off the list.
Browser can save your email/password, the same way it does on other
sites — sign in once, choose "Save password" when the browser offers, and
it'll auto-fill next time.
Dark / light mode — toggle at the bottom of the sidebar. Remembers your
choice per device.
Per-user, per-page permissions — as Admin, go to Manage Users →
Manage page access for any user to control exactly which pages they can
see, and (for Planning/Admin accounts) which pages they can edit in.
Every column is now editable (not just Committed EDD / Hold Reason) —
click any cell on a page you have edit rights to and type directly, like a
spreadsheet. Press Enter to save, Esc to cancel, or just click away.
Every column has a filter — click the ▾ next to any column header for
an Excel-style checklist filter, searchable, with your active filters shown
next to the search box (and a "Clear column filters" button).
⚠️ If you already have this app deployed: re-run the updated `schema.sql`
once in Supabase's SQL Editor — it's safe to run again on top of existing
data (nothing is dropped), and it removes the old username-uniqueness rule
that no longer applies now that login is by email. Then replace `index.html`
with this new version (keep your existing `SUPABASE_URL` / `SUPABASE_ANON_KEY`
lines).
---
1. Set up Supabase (5 minutes)
Go to https://supabase.com → your project (or create a new one).
Open SQL Editor → paste the entire contents of `schema.sql` → Run.
This creates the `jobs`, `profiles`, and `import_log` tables plus security rules.
Open Authentication → Providers → make sure Email is enabled.
(Optional but recommended for internal tools) Open Authentication →
Settings → turn OFF "Confirm email" so new accounts can sign in
immediately without waiting on a confirmation email. Since everyone now
signs up with a real, working company email, it's fine to leave this ON
too if you'd rather people confirm their address first — that's a real
choice now, not a workaround.
Open Project Settings → API. Copy two values:
Project URL (looks like `https://xxxxx.supabase.co`)
anon public key (a long string — NOT the `service_role` key)
2. Configure the app
Open `index.html` in a text editor. Near the top, find:
```js
const SUPABASE_URL = "YOUR_SUPABASE_PROJECT_URL";
const SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_PUBLIC_KEY";
```
Replace both with the values from step 1.5. Save the file.
3. Create your first account and make yourself Admin
Deploy the app first (step 4 below), or just open `index.html` locally in
a browser (double-click it — it works without a server).
Click "Create an account", sign up with your real work email
(e.g. `rahatul@enamtrims.com`) and a password.
Sign in. Since nobody on this workspace is Admin yet, you'll see a
banner at the top: "No Admin has been set up yet" with a
Claim Admin Access button — click it. That's it, no SQL needed.
(This banner appears for anyone who's not Admin, but the button only
works while zero Admin accounts exist — the first click wins, and after
that it disappears for everyone.)
You'll now see Import Data and Manage Users in the sidebar.
From Manage Users, promote your Planning coordinator's account to
the Planning role once they sign up (they can edit committed EDD,
hold reasons, and import data; they can't delete jobs or change roles).
From the same page you can also fine-tune exactly which pages each person
can see and edit — see "Managing who sees / edits what" below.
If the banner doesn't show up (e.g. you already fought through this with
SQL before this feature existed), you can always fall back to Supabase →
SQL Editor:
```sql
update profiles set role = 'admin' where email = 'rahatul@enamtrims.com';
```
Forgot password? If "Confirm email" is on and you have real SMTP/email
configured in Supabase, the normal password-reset flow works. Otherwise, an
Admin can reset it directly in Supabase → Authentication → Users → find the
account → Reset password.
4. Deploy (GitHub + Vercel)
Create a new GitHub repo, upload `index.html` (and this README) to it.
Go to https://vercel.com → Add New Project → import that repo.
Framework preset: Other (it's a static file, no build command needed).
Deploy. Vercel will give you a URL like `https://your-app.vercel.app`.
Share that URL with your team. Each person signs up with their email;
you assign their role from Manage Users.
5. Day-to-day use
Import Data (Admin/Planning only): paste rows copied straight from
your ERP export (include the header row), or upload the `.csv`/`.xlsx`
export file directly. The app matches columns automatically — it's
built to read the same columns as your ERP "Job Register" export
(Job No, Customer, Department, EDD, Hold Status, Delivered Qty,
Required Qty, etc.). Existing jobs are updated by Job No; new ones
are added. Nothing is deleted by an import.
Planning Master: add jobs to your working list by pasting Job Numbers
(one per line — copy straight from column A of your old Excel Planning
Master tab, or from anywhere) or uploading a file with a Job No column.
A job has to already be imported from ERP before it can be added here.
Once it's on the list, click into Priority / Planned Date / Planning
Notes to fill them in. Untick "On Plan" to remove a job from the list —
this doesn't touch the job's ERP data at all, just takes it off Planning's
active view.
Dashboard: risk-ranked list of jobs, department load, and hold/material/
overdue snapshot — built for management to see what's at risk and why.
Every column is editable on any page you have edit rights to — click
a cell to type directly, Enter to save, Esc to cancel. The only fields
that come purely from ERP and aren't meant to be hand-edited are the ones
without a click cursor (e.g. Job No, Risk).
How the risk score works
Each open job accumulates points (capped at 100), so multiple problems on
the same job stack up:
Condition	Points
Overdue vs EDD (not yet delivered)	+40
On Hold	+30
Material shortage (Required Qty > 0)	+20
Partially delivered with EDD ≤ 2 days away	+10
Bands: 70+ Critical · 40–69 High · 20–39 Medium · 1–19 Low · 0 On Track
The Risk column itself isn't directly editable — it's always calculated live
from the fields above it (EDD, Hold, Required Qty, Delivered Qty). To change
a job's risk, edit the underlying field and the score updates automatically.
What's not in Phase 1 (planned for Phase 2)
Department machine-schedule sheets (Offset Printing, PFL, Thermal, Woven,
Screen Print, Heat Transfer, Cutting) — these need machine assignment as
manual input since your ERP export doesn't carry a machine field for most
departments.
Reference/lookup tables: Plate Data, Ups, Peak-cut (machine specs) —
maintained by Admin, used to support the department schedules above.
6. Managing who sees / edits what
There are two layers, and it helps to know how they fit together:
Role (Admin / Planning / Viewer) is enforced by Supabase itself
(Row Level Security). This is what actually allows a save to happen —
a Viewer's edits would be rejected by the database even if the app showed
them an edit box, so the app never shows Viewers one.
Page access (Manage Users → Manage page access) is an app-level
fine-tuning on top of that. For any user, tick which pages they can see,
and — if they're Planning or Admin — which of those pages they're allowed
to edit in. A Planning user could, say, be allowed to edit HOLD and
Committed EDD but only view (not edit) the Outsource page.
So: promote someone to Planning/Admin first if they need to save anything at
all, then use page access to narrow down exactly where.
Troubleshooting
"Supabase is not configured yet" banner → you haven't edited the
`SUPABASE_URL` / `SUPABASE_ANON_KEY` constants in `index.html`.
Can't import / no Import Data menu → your account is still `viewer`;
ask an Admin to promote you in Manage Users.
"User already registered" → that email already has an account; sign
in instead, or ask an Admin to check Supabase → Authentication → Users
if you think it should be yours.
Sign-up creates the account but sign-in never starts, or an
"Email not confirmed" error → "Confirm email" is ON in Supabase and
the account is waiting on a real confirmation email. Either check that
inbox for the link, or have an Admin turn "Confirm email" OFF in
Authentication → Settings for instant access going forward.
Forgot password → if "Confirm email"/SMTP is set up, the normal
password-reset flow works. Otherwise an Admin resets it manually in
Supabase → Authentication → Users → find the account → Reset password.
