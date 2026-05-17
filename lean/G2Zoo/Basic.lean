/-!
# G2-Zoo: 前順序・Box・Diamond

APS (Abstract Provability Structure) の基礎構造を Lean 4 で形式化する。
Haskell 実装 (G2Zoo.PreOrder, G2Zoo.APS) に対応する。
-/

namespace G2Zoo

/-- 前順序: ⊤（最大元）と ⊥（最小元）を持つ反射的・推移的二項関係。 -/
class PreOrder (α : Type) where
  /-- 順序関係 x ≤ y -/
  le       : α → α → Prop
  /-- 最大元 ⊤ -/
  top      : α
  /-- 最小元 ⊥ -/
  bot      : α
  le_refl  : ∀ x : α, le x x
  le_trans : ∀ x y z : α, le x y → le y z → le x z
  le_top   : ∀ x : α, le x top
  bot_le   : ∀ x : α, le bot x

/-- 同値関係: x ≡ y ⟺ x ≤ y ∧ y ≤ x -/
def PreOrder.equiv {α : Type} [PreOrder α] (x y : α) : Prop :=
  PreOrder.le x y ∧ PreOrder.le y x

/-- Box 演算子 □: PreOrder 上の単調写像を意図する。 -/
class Box (α : Type) extends PreOrder α where
  box : α → α

/-- Diamond 演算子 ☒: PreOrder 上の反単調写像を意図する。 -/
class Diamond (α : Type) extends PreOrder α where
  diam : α → α

/-- Box と Diamond の両方を持つ前順序 (APS の土台)。 -/
class PreAPS (α : Type) extends Box α, Diamond α

end G2Zoo
