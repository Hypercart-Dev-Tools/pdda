# Stack Adapter: JS/TS React + Supabase (Default)

Pluggable by design. This is the default adapter; to target a different stack,
add a `stack-adapter-[name].md` and point milestone generation at it. Business
logic lives in hooks/services, so the adapter swaps without rewriting the app.

## Frontend
- **Framework:** React 18+ with TypeScript
- **Styling:** Tailwind CSS (assumed for speed, swappable)
- **Components:** shadcn/ui or an equivalent accessible component library
- **State:** React hooks + Zustand or Context (keep it simple)

## Backend / Data
- **Platform:** Supabase
- **Database:** PostgreSQL (managed)
- **Auth:** Supabase Auth (email, OAuth, magic link)
- **Realtime:** Supabase Realtime (where needed)
- **Storage:** Supabase Storage (files/images)

## Alternative: Lovable-Managed
If building in Lovable:
- Stack is abstracted — Lovable handles the backend.
- Still output the React + TS structure for transparency.
- Note in the spec: "Lovable manages deployment and backend. This spec assumes
  Lovable's conventions."

## Table Stakes Implementation
- **Modern attractive design:** a clean design system (shadcn, Radix, or
  equivalent).
- **Mobile responsive:** Tailwind breakpoints, mobile-first CSS, touch targets ≥
  44px.

## Migration Path (swap this stack later)
1. Replace the Supabase client with your new backend adapter.
2. Keep the React components — business logic is in hooks/services, not the UI.
3. Port the database schema to any Postgres-compatible system.
4. Auth migration: export users, re-import with the new provider.

> This stack is chosen for **speed**. The migration path is deliberately short so
> "picked for speed" never becomes "locked in."
