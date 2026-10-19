# Build log

## 2026-10-19 — released

Second print **worked flawlessly**: the ring clears the wall wart, the ribs hold the plug
snugly, and the screw threads all the way in and clamps the camera. Current STLs are final.

## 2026-10-19 — second print: lift, ribs, looser thread

First print results: **the camera ring fits perfectly.** Three problems:

1. **Camera hit the wall wart.** Added `lift` = 20 mm: a web between sleeve and ring, full
   sleeve length at the bottom and ring depth at the top. Its sloped back faces up when
   printed, so it still needs no support.
2. **Sleeve a bit loose on the plug** at `usb_fit` 0.15. Added four half-round retention ribs
   along the plug axis, two on each wide face, standing `rib_h` = 0.35 mm off the wall
   (0.20 mm grip). They taper to nothing over the 2.5 mm at the wall-side end where the
   plug enters.
3. **Screw would not go all the way in.** Taken to be binding: the threaded hole prints on its
   side, so its roof sags and it comes out undersized. `scr_clear` 0.25 → 0.40, a lead-in
   chamfer on the boss, `scr_len` 9 → 10. Also exported `screw_thin.stl`, 0.15 mm smaller
   per side, so a tight hole can be fixed without reprinting the frame.

Screw re-checked on the hole's helix: clear through its travel; the head bottoms with the tip
about 3 mm into the camera pocket. Frame 9.3 cm³, watertight single body. (The web's top was
first drawn flush with the pocket floor, which left three non-manifold edges; it now stops
halfway up the ring wall.)

## 2026-10-19 — first print

Concept settled after one wrong turn: the first sketch put the camera in front of the plug
on a 30 mm-deep flared cup. What was wanted is the camera *above* the plug, its face flush
with the plug's outer end, held by a thin ring. That makes the part flat and prints face
down with no supports.

Exported `stl/frame.stl` (5.1 cm³) and `stl/screw.stl` (0.4 cm³). Both watertight single
bodies, min z = 0.

Checks done in the model:

- **Set-screw boss** was 12 mm across on an 8 mm-deep ring and stuck 2 mm out past the front
  face, which would have hung below the bed. Trimmed it to the ring's depth.
- **Non-manifold frame mesh.** The twisted thread's slice planes landed exactly on the ring's
  inner face and the boss base, which left sliver faces. Fixed by starting the hole at an odd
  offset (1.037 mm).
- **Screw vs. hole**, intersected with the screw phased onto the hole's helix: no overlap
  through the travel. The head bottoms out on the boss with the tip about 2 mm into the camera
  pocket, so there's clamping travel to spare over the 0.25 mm side clearance.

**Unproven, to check on the first print:**

- Whether the camera's body clears the wall wart. It extends back toward the wall right above
  the plug; wart height above the plug and camera depth were never measured. If it hits, add
  a spacer between ring and sleeve.
- Sleeve grip on the plug (`usb_fit` 0.15) and camera fit (`cam_fit` 0.25).
- Whether the printed 6 mm thread runs freely. It prints horizontally in the frame, so it may
  come out slightly oval.
