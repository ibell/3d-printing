# Reference models

`adafruit-4885-sht40.stl` — Adafruit's own 3D model of the SHT40 STEMMA QT
breakout (product 4885), from
<https://github.com/adafruit/Adafruit_CAD_Parts> ("4885 SHT40 Sensor").

Vendored here so `tests/check_fit.py` can check the cradle and clip against the
manufacturer's actual geometry rather than against numbers retyped from a
drawing. Every SHT40 dimension in `pi4_dht22_enclosure.scad` was measured off
this file.

Note the model is **not watertight** (14 separate bodies), so point-containment
queries against it are unreliable. Use it for solid intersections and bounding
measurements, which is what the fit checks do.
