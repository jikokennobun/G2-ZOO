/-!
# G2-Zoo: 命題 G2, FG2, Löb の形式化

各命題は APS モデルの型上の命題 (Prop) として定義する。
-/

import G2Zoo.APS

namespace G2Zoo

variable {α : Type} [APS α]

/-- G2 (第二不完全性定理): ☒⊤ ≤ ⊥ ⇒ ⊤ ≤ ⊥。
    「☒⊤ が ⊥ 以下 ⟹ 系は矛盾している」という形式。 -/
def G2 : Prop :=
  APS.le (APS.diam APS.top) APS.bot → APS.le APS.top APS.bot

/-- FG2 (形式化第二不完全性定理): ☒☒⊤ ≤ ☒⊤。 -/
def FG2 : Prop :=
  APS.le (APS.diam (APS.diam APS.top)) (APS.diam APS.top)

/-- Löb 規則: ∀x. □x ≤ x ⇒ ⊤ ≤ x。
    「□x から x が従うなら x は定理」という形式。 -/
def Loeb : Prop :=
  ∀ x : α, APS.le (APS.box x) x → APS.le APS.top x

/-- ☒-不動点の存在: ∃ p, p ≡ ☒p。 -/
def HasDiamFP : Prop :=
  ∃ p : α, APS.le p (APS.diam p) ∧ APS.le (APS.diam p) p

/-- □-不動点の存在: ∃ p, p ≡ □p。 -/
def HasBoxFP : Prop :=
  ∃ p : α, APS.le p (APS.box p) ∧ APS.le (APS.box p) p

/-- 整合性 (無矛盾性): ¬(⊤ ≤ ⊥)。 -/
def Consistent : Prop :=
  ¬ APS.le APS.top APS.bot

/-- FG2 ⇒ G2: A1 + A2 が成立すれば FG2 から G2 が従う。

    証明スタブ (`sorry`): Haskell の Search モジュールにより
    3点線形担体上で反例なしを確認済 (Syntactical Fact)。 -/
theorem fg2_implies_g2 [APS α] (h : @FG2 α _) : @G2 α _ := by
  sorry

end G2Zoo
