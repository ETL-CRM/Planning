# Enam Trims — Production Planning System (Phase 1)

A live, shared web app that replaces manual copy/paste into 24 Excel tabs.
Import your ERP export once, and Check / Partial / HOLD / Outsource / WFM /
Committed / risk dashboard all update automatically.

Files:
- `schema.sql` — run once in Supabase (or re-run — it's safe to run again)
- `index.html` — the whole app (no build step)

## What's new in this update

- **Browser can save your username/password**, the same way it does on other
  sites — sign in once, choose "Save password" when the browser offers, and
  it'll auto-fill next time.
- **Dark / light mode** — toggle at the bottom of the sidebar. Remembers your
  choice per device.
- **Per-user, per-page permissions** — as Admin, go to *Manage Users →
  Manage page access* for any user to control exactly which pages they can
  see, and (for Planning/Admin accounts) which pages they can edit in.
- **Every column is now editable** (not just Committed EDD / Hold Reason) —
  click any cell on a page you have edit rights to and type directly, like a
  spreadsheet. Press Enter to save, Esc to cancel, or just click away.
- **Every column has a filter** — click the ▾ next to any column header for
  an Excel-style checklist filter, searchable, with your active filters shown
  next to the search box (and a "Clear column filters" button).

⚠️ **If you already have this app deployed:** you only need to re-run the
updated `schema.sql` once in Supabase's SQL Editor — it adds a new
`permissions` column to `profiles` and is safe to run on top of your existing
data (nothing is dropped or overwritten). Then replace `index.html` with this
new version (keep your existing `SUPABASE_URL` / `SUPABASE_ANON_KEY` lines).

---

## 1. Set up Supabase (5 minutes)

1. Go to https://supabase.com → your project (or create a new one).
2. Open **SQL Editor** → paste the entire contents of `schema.sql` → **Run**.
   This creates the `jobs`, `profiles`, and `import_log` tables plus security rules.
3. Open **Authentication → Providers** → make sure **Email** is enabled.
   (Optional: under Authentication → Settings, turn OFF "Confirm email" for
   faster internal testing — turn it back on for production use.)
4. Open **Project Settings → API**. Copy two values:
   - **Project URL** (looks like `https://xxxxx.supabase.co`)
   - **anon public** key (a long string — NOT the `service_role` key)

## 2. Configure the app

Open `index.html` in a text editor. Near the top, find:

```js
const SUPABASE_URL = "YOUR_SUPABASE_PROJECT_URL";
const SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_PUBLIC_KEY";
```

Replace both with the values from step 1.4. Save the file.

## 3. Create your first account and make yourself Admin

1. Deploy the app first (step 4 below), or just open `index.html` locally in
   a browser (double-click it — it works without a server).
2. Click **"Create an account"**, sign up with your work email + a password.
3. Back in Supabase → **SQL Editor**, run:
   ```sql
   update profiles set role = 'admin' where email = 'you@yourcompany.com';
   ```
4. Refresh the app and sign in. You'll now see **Import Data** and
   **Manage Users** in the sidebar.
5. From **Manage Users**, promote your Planning coordinator's account to
   the **Planning** role once they sign up (they can edit committed EDD,
   hold reasons, and import data; they can't delete jobs or change roles).

## 4. Deploy (GitHub + Vercel)

1. Create a new GitHub repo, upload `index.html` (and this README) to it.
2. Go to https://vercel.com → **Add New Project** → import that repo.
3. Framework preset: **Other** (it's a static file, no build command needed).
4. Deploy. Vercel will give you a URL like `https://your-app.vercel.app`.
5. Share that URL with your team. Each person signs up with their email;
   you assign their role from **Manage Users**.

## 5. Day-to-day use

- **Import Data** (Admin/Planning only): paste rows copied straight from
  your ERP export (include the header row), or upload the `.csv`/`.xlsx`
  export file directly. The app matches columns automatically — it's
  built to read the same columns as your ERP "Job Register" export
  (Job No, Customer, Department, EDD, Hold Status, Delivered Qty,
  Required Qty, etc.). Existing jobs are updated by **Job No**; new ones
  are added. Nothing is deleted by an import.
- **Dashboard**: risk-ranked list of jobs, department load, and hold/material/
  overdue snapshot — built for management to see what's at risk and why.
- **Committed EDD** and **Hold Reason** are the two fields you can edit
  directly in the tables (click the dashed-underline cells) — everything
  else comes from your ERP import.

## How the risk score works

Each open job accumulates points (capped at 100), so multiple problems on
the same job stack up:

| Condition | Points |
|---|---|
| Overdue vs EDD (not yet delivered) | +40 |
| On Hold | +30 |
| Material shortage (Required Qty > 0) | +20 |
| Partially delivered with EDD ≤ 2 days away | +10 |

Bands: **70+ Critical · 40–69 High · 20–39 Medium · 1–19 Low · 0 On Track**

The Risk column itself isn't directly editable — it's always calculated live
from the fields above it (EDD, Hold, Required Qty, Delivered Qty). To change
a job's risk, edit the underlying field and the score updates automatically.

## What's not in Phase 1 (planned for Phase 2)

- Department machine-schedule sheets (Offset Printing, PFL, Thermal, Woven,
  Screen Print, Heat Transfer, Cutting) — these need machine assignment as
  manual input since your ERP export doesn't carry a machine field for most
  departments.
- Reference/lookup tables: Plate Data, Ups, Peak-cut (machine specs) —
  maintained by Admin, used to support the department schedules above.

## 6. Managing who sees / edits what

There are two layers, and it helps to know how they fit together:

- **Role** (Admin / Planning / Viewer) is enforced by Supabase itself
  (Row Level Security). This is what actually allows a save to happen —
  a Viewer's edits would be rejected by the database even if the app showed
  them an edit box, so the app never shows Viewers one.
- **Page access** (Manage Users → Manage page access) is an app-level
  fine-tuning on top of that. For any user, tick which pages they can see,
  and — if they're Planning or Admin — which of those pages they're allowed
  to edit in. A Planning user could, say, be allowed to edit HOLD and
  Committed EDD but only view (not edit) the Outsource page.

So: promote someone to Planning/Admin first if they need to save anything at
all, then use page access to narrow down exactly where.

## Troubleshooting

- **"Supabase is not configured yet" banner** → you haven't edited the
  `SUPABASE_URL` / `SUPABASE_ANON_KEY` constants in `index.html`.
- **Can't import / no Import Data menu** → your account is still `viewer`;
  ask an Admin to promote you in Manage Users.
- **Sign-up says "check your email" but no email arrives** → in Supabase,
  Authentication → Settings, either disable "Confirm email" for testing or
  check your SMTP/email settings for production use.
