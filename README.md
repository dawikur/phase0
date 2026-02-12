# phase

```bash
make [build|simulate|clean|help]
```

## TODO

* Metrics
  * Core
    * CAL calories
    * DST distance (today), km/mi
    * ACT active minutes
  * Outdoor
    * ALT altitude
    * GPS heading
    * TEMP temperature
  * Advanced
    * REC recovery
    * VO2 vo2 max
    * RHR resting HR
    * LOAD training load
  * Other
    * pushes
    * respiration rate
    * time to recover
    * intensity minutes
    * training status
* Bars
  * Battery %
  * HR %
  * Steps Goal %
  * Calories Goal %
  * Active minutes Goal %
  * ... any other Goal %
  * Hydration
  * Stress
* Icons
  * Phone disconnected icon

## Checklist

* Visual polish
  * Optical centering audit
    * Check HH:MM vs side bars vs icons at 1× scale
    * Pixel fonts often need manual nudging by 1 px
  * Bar consistency
    * Ensure all 3 bars:
      * Same height
      * Same fill direction
      * Same segmentation logic (even if hidden)
    * Avoid one feeling “thicker” than the others
  * Icon weight matching
    * Status icons should visually weigh ≈ one digit segment
    * If one pops more, reduce pixel count
  * Accent color discipline
    * Use accent color for:
      * Time
      * Labels
      * Active/positive states only
    * Never for background info (weather text, battery outline)
* Data polish
  * Graceful N/A handling
    * If data is missing:
      * Hide field entirely
      * Don’t show zero
    * Especially important for GPS, weather, floors
  * Quantization rules
    * Lock level indicators to 3 states
    * Don’t let them “flicker” between boundaries
  * Update cadence
    * Seconds update every second (obviously)
    * Bars update:
      * On minute change
      * Or on metric update
    * Avoid continuous redraws
* UX micro-interactions
  * Charging state
    * Brighten battery (you already do this 👍)
    * Optionally freeze seconds during charge (calmer feel)
  * Notification presence
    * Hide bell if zero
    * No animation — presence alone is enough
