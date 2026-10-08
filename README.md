# Team Performance Tracker

Employee reports, goal progress, private manager notes and a per-employee message thread.
Static web app (no build step) + Supabase (auth, database, realtime) + GitHub Pages hosting.

## 1. Supabase (5 min)
1. Create a free project at supabase.com.
2. SQL Editor > New query > paste `schema.sql` > Run.
3. Project Settings > API: copy the **Project URL** and **anon public key** into `config.js`.
4. Authentication > Providers > Email: turn off "Confirm email" while testing (or keep it on and have staff confirm by email).
5. Authentication > URL Configuration: set Site URL to your GitHub Pages address (step 2 below).

## 2. GitHub Pages
```bash
git init && git add . && git commit -m "Team tracker"
git branch -M main
git remote add origin https://github.com/<you>/team-tracker.git
git push -u origin main
```
On GitHub: Settings > Pages > Deploy from branch > `main` / root. Your app goes live at
`https://<you>.github.io/team-tracker/`. To run locally instead, open `index.html` (or `npx serve`).

## 3. First use
- **The first account created becomes the manager**, so sign up yourself first.
- Everyone else signs up and becomes an employee. Managers can open any person's page, set job titles, promote someone to manager, add goals and move progress.
- Employees see only their own page: their reports, goals and message thread. Private notes are manager-only.
  This is enforced by Row Level Security in `schema.sql`, not just hidden in the UI.

## Notes
- The anon key in `config.js` is meant to be public. Never put the `service_role` key here.
- To delete or edit reports/messages, add `update`/`delete` policies in `schema.sql`.
