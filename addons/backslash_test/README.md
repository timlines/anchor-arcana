# Backslash Test Addon

A modular, self-contained testing framework for **Godot 4.6+** projects. This addon houses the automated test suite verifying player lifecycle dynamics, timeline schedules, active combat casts, virtual controllers, path visualization, and the explosion system.

---

## 📂 Directory Structure

```
addons/backslash_test/
├── plugin.cfg          # Godot Editor addon metadata
├── plugin.gd           # EditorPlugin initializer script
├── test_runner.gd      # Main automated test runner script
├── test_runner.tscn    # Scene wrapper for test_runner.gd
├── test_timeline.gd    # SceneTree testing fallback script
└── README.md           # This documentation
```

---

## 🛠️ Testing Environment Setup

To keep local test executions fast and consistent without relying on system-wide configurations, a local Godot executable console build is placed in the project root:

- **Location**: `res://godot.exe` (ignored by Git)
- **Role**: Allows immediate, zero-configuration headless execution of tests via command-line pipes.

---

## 🧪 Running the Tests

### 1. Main Headless Test Suite (Recommended)
This runs the full test suite in headless mode. The suite executes all lifecycle, combat, and plugin validations, printing output directly to the console before quitting with an appropriate exit code.

```bash
# From the project root directory
./godot.exe --headless --scene res://addons/backslash_test/test_runner.tscn
```

### 2. SceneTree Timeline Execution
This executes the legacy timeline script directly under a custom SceneTree loop.

```bash
# From the project root directory
./godot.exe --headless -s res://addons/backslash_test/test_timeline.gd
```

---

## 📝 Test Case Specifications

The suite executes the following sequential validation phases:

1. **[Test 1] Player Status Effect Management**:
   - Validates player instantiation and health/shield damage mitigation sequencing.
   - Verifies shield absorption offsets direct health damage, healing caps out correctly at `max_hp`, and direct HP damage reduces health.
2. **[Test 2] Symmetrical Active Card Casts**:
   - Instantiates active player cards (HEAL, SHIELD, DAMAGE) and triggers active combat casts.
   - Checks projectile spawn parameters, collision masks, speed, and programmatic 13-frame sprite sheets.
3. **[Test 3] Totem Passive Loops**:
   - Tests card insertion on totem towers and verifies passive visual auric pulse changes and automated periodic firing timers.
4. **[Test 4] Map Mode & Camera Zoom**:
   - Simulates map mode toggling, verifying player movement lock (velocity set to `Vector2.ZERO`) and UI indicator visibilities.
5. **[Test 5] Path Visualizer Line2D**:
   - Validates programmatic spawning of the translucently modulated routing Line2D, verifying phase-dependent visibility transitions (visible in `PLAN`, hidden in `DEFEND`).
6. **[Test 6] BackslashExplode Plugin Validation**:
   - Verifies the `BackslashExplode` autoload singleton is correctly loaded and reachable.
   - Asserts string-to-element mapping and enum integration logic.
   - Tests `explode()` and `sparkle()` APIs, verifying visual Sprite/Smoke/CPUParticles2D states and automated object pool recycling.
