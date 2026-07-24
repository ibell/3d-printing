# Build log

## 2026-07-24 — DONE. Production printed and confirmed on the real frame.

Full assembly printed (`job1_two_plates` + `job2_brace`), assembled, and it
fits the folding frame well. Lip engagement, stance, and snap all confirmed in
the final part. Design complete — nothing outstanding.

---

## 2026-07-24 — linkage verified, production released

- **Snap linkage: verified in PLA.** `link_test` printed and assembled cleanly
  — firm click, holds, both ends. This proved the `brace_holes` fix (finger
  holes enlarged inward by `barb_h` so the finger can flex clear of the barb as
  it crosses the plate; the original snug hole jammed at 0.15 mm vs 0.65 mm
  needed). Same fix is in the production plates.
- **Frame-fit rig skipped** — went straight to production ("YOLO"). The only
  unproven item is the lip: 3 mm proud, assumed ~9.5 mm bottom border and a flat
  front edge. If it clips the photo or misses the edge, change `lip_proud` and
  reprint plates only (brace unaffected).

### Geometry frozen at release
- Hinge on the FRONT faces; `hinge_gap` = 4.175 mm (measured 1/8" + 1 mm margin)
- `fold_d` = 9.52 mm; cradle lip→vertex = 132.17 mm
- Bottom panel treated 2 mm longer than top (`frame_h_bot = frame_h + 2`)
- Posture 30° / 82°

### Production files (Bambu A1 mini, 180×180, flat, no supports)
- `stl/job1_two_plates.stl` — two plates nested, 157×157 mm, ~66 g
- `stl/job2_brace.stl` — brace, 150.7×60 mm, ~30 g
- Nest is provably disjoint (union == 2× one plate); 3.14 mm part clearance
- Assembly: snap brace into ONE plate, then bring the second plate onto the
  free end.

### Confirmed in plastic (final)
- Lip engagement / photo clearance — good
- Overall stance and angles with the real frame — good
- Snap linkage — good
- Fits the folding frame well. Design complete.
