# Improvement Plan for Five Issues

## 1. Non-Executable Pseudocode

- **Establish an “executable pseudocode” standard:**  
  Pseudocode must be either directly runnable (a minimal runnable snippet) or explicitly labeled as “not runnable; logic illustration only.”
- **Recommended practice:**  
  Convert critical logic into executable examples (minimal function + input/output) that can later be reused in unit tests.  
  Pseudocode serves as a design sketch and must **not** be copy-pasted into implementation code.

## 2. Outdated Library Usage

- **Add a “dependency knowledge validation” gate in the loop:**  
  All library calls in the spec must match the locked versions.
- **Recommendation:**  
  Specs should explicitly include `library@version` plus compatibility notes.  
  If using online docs (e.g., Context7), record the documentation snapshot timestamp and source in the spec to avoid drift.

## 3. Unit Tests Pass, Integration Fails

- **Require a “module boundary contract” in the spec:**  
  Cross-module data structures must have an explicit schema (e.g., JSON Schema, Zod, Pydantic, Proto).
- **Add interface consistency tests:**  
  Introduce backpressure: fail on any schema mismatch, with higher priority than unit tests.

## 4. Mocks Diverge from Real API Data Structures

- **Add contract testing and record/replay:**  
  Use real API responses as golden fixtures, and require mocks to pass schema validation.
- **Standard:**  
  Mock generators must be derived directly from schemas, not hand-written.

## 5. Implementation Shortcuts: Mocked or Missing Details

- **Add a “Must Implement List” to the spec:**  
  Explicitly name the classes or modules that must be implemented for real (must not be mocked).
- **Add backpressure in the Ralph loop:**  
  If a critical module is mocked, fail immediately.

---

# Must-Have Criteria

## Definition of Ready (Ready for Implementation)

- The core flow (happy path plus common failure cases) has clearly defined inputs and outputs.
- All cross-module interfaces have explicit schemas.
- Key dependencies have version locks and fallback alternatives specified.
- At least 3 end-to-end examples using real payloads are provided.

## Definition of Done (Spec Complete)

- Passes the spec review loop’s high-bar screening (with existing threshold optimizations).
- At least one contract consistency check has been executed.
