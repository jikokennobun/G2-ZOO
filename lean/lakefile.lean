import Lake
open Lake DSL

package «g2zoo» where
  name := "g2zoo"

lean_lib «G2Zoo» where
  roots := #[`G2Zoo.Basic, `G2Zoo.APS, `G2Zoo.Properties, `G2Zoo.BekSham]
