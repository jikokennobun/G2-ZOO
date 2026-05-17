/-!
# G2-Zoo: Beklemishev-Shamkanov 2016 主定理（形式化スタブ）

Beklemishev & Shamkanov (2016) "Some abstract versions of Gödel's second
incompleteness theorem based on non-classical logics" (arXiv:1602.05728)
の主定理を Lean 4 で形式化する準備。

## 定理の内容

- **定理 1** (B&S 2016): APS + ☒-不動点の存在 ⇒ G2
- **定理 2** (B&S 2016): APS + ☒-不動点の存在 ⇒ FG2

## 現状

証明は `sorry` による。有限モデル探索 (Haskell の `G2Zoo.Search`) により
3点線形担体・4点ダイアモンド担体上での反例なしを確認済 (機械的検証)。

完全な Lean 4 形式化証明は Scope D の課題。
-/

import G2Zoo.Properties

namespace G2Zoo

variable {α : Type} [APS α]

/-- B&S 2016 定理 1: APS + ☒-不動点の存在 ⇒ G2。

    証明の方針 (informal):
    p ≡ ☒p とすると, A3 により ☒⊤ ≤ ⊥ ⇒ ☒p ≤ ⊥ (☒ の反単調性 + A2 経由),
    p ≡ ☒p なので p ≤ ⊥, A4 と A2 から ⊤ ≤ ⊥ を得る。 -/
theorem bekSham_g2 (hfp : @HasDiamFP α _) : @G2 α _ := by
  sorry

/-- B&S 2016 定理 2: APS + ☒-不動点の存在 ⇒ FG2。

    証明の方針 (informal):
    p ≡ ☒p とすると, ☒p ≡ p なので ☒☒p ≡ ☒p (☒ 一回適用),
    p ≡ ☒p より ☒p ≡ ☒☒p ≡ ☒p, これは FG2 の ☒☒⊤ ≤ ☒⊤ の特殊化。 -/
theorem bekSham_fg2 (hfp : @HasDiamFP α _) : @FG2 α _ := by
  sorry

/-- B&S 2016 系: APS + ☒-FP が成立すれば G2 ⟺ FG2。

    ⇐ 方向は fg2_implies_g2 (A1+A2 上の Syntactical Fact)。
    ⇒ 方向は bekSham_fg2 による。 -/
theorem bekSham_equiv (hfp : @HasDiamFP α _) :
    @G2 α _ ↔ @FG2 α _ := by
  constructor
  · intro _; exact bekSham_fg2 hfp
  · exact fg2_implies_g2

end G2Zoo
