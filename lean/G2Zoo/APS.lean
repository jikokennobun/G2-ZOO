/-!
# G2-Zoo: APS の公理 A1–A4

Beklemishev & Shamkanov (2016) "Some abstract versions of Gödel's second
incompleteness theorem based on non-classical logics" (arXiv:1602.05728) に
基づく公理系を Lean 4 で形式化する。

## 公理

- **A1 (単調性・反単調性)**: x ≤ y ⇒ □x ≤ □y  かつ  x ≤ y ⇒ ☒y ≤ ☒x
- **A2**: ⊤ ≤ ☒⊥
- **A3**: x ≤ □y ∧ x ≤ ☒y ⇒ x ≤ ☒⊤
- **A4**: ☒x ≤ □☒x
-/

import G2Zoo.Basic

namespace G2Zoo

/-- APS: 公理 A1–A4 を満たす PreAPS。 -/
class APS (α : Type) extends PreAPS α where
  /-- A1 (□ の単調性): x ≤ y ⇒ □x ≤ □y -/
  a1_box  : ∀ x y : α, le x y → le (box x) (box y)
  /-- A1 (☒ の反単調性): x ≤ y ⇒ ☒y ≤ ☒x -/
  a1_diam : ∀ x y : α, le x y → le (diam y) (diam x)
  /-- A2: ⊤ ≤ ☒⊥ -/
  a2      : le top (diam bot)
  /-- A3: x ≤ □y ∧ x ≤ ☒y ⇒ x ≤ ☒⊤ -/
  a3      : ∀ x y : α, le x (box y) → le x (diam y) → le x (diam top)
  /-- A4: ☒x ≤ □☒x -/
  a4      : ∀ x : α, le (diam x) (box (diam x))

/-- FixedPointAPS: ☒-不動点 p ≡ ☒p を持つ PreAPS。
    B&S 2016 の主定理は APS + FixedPointAPS を要する。 -/
class FixedPointAPS (α : Type) extends PreAPS α where
  /-- ☒-不動点の存在: ∃ p, p ≡ ☒p -/
  diamFP    : α
  diamFP_le : le diamFP (diam diamFP)
  le_diamFP : le (diam diamFP) diamFP

/-- 含意 (→) を持つ APS。
    期待される性質: ⊤ ≤ x→y ⟺ x ≤ y  (内在化)。 -/
class ImpAPS (α : Type) extends APS α where
  imp : α → α → α

end G2Zoo
