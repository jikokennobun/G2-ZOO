-- | Case 達の回帰テスト + 有限モデル探索の回帰テスト.
module Main (main) where

import Data.Proxy   (Proxy (..))
import System.Exit  (exitFailure, exitSuccess)

import G2Zoo

main :: IO ()
main = do
  let failures = concatMap check (instanceChecks ++ searchChecks ++ autoChecks)
  mapM_ putStrLn failures
  if null failures
    then putStrLn "All checks passed." >> exitSuccess
    else putStrLn ("Failed: " ++ show (length failures)) >> exitFailure

data Check = Check
  { checkLabel :: String
  , checkExpected :: Bool
  , checkActual   :: Bool
  }

check :: Check -> [String]
check c
  | checkExpected c == checkActual c = []
  | otherwise = [ "FAIL " ++ checkLabel c
               ++ " expected=" ++ show (checkExpected c)
               ++ " actual="   ++ show (checkActual c)
               ]

-- ----------------------------------------------------------------------------
-- 個別インスタンスの回帰
-- ----------------------------------------------------------------------------

instanceChecks :: [Check]
instanceChecks = concat
  [ let p = Proxy :: Proxy Case1 in
    [ Check "Case1/A1"  True (checkA1 p)
    , Check "Case1/A2"  True (checkA2 p)
    , Check "Case1/A3"  True (checkA3 p)
    , Check "Case1/A4"  True (checkA4 p)
    , Check "Case1/G2"  True (checkG2 p)
    , Check "Case1/FG2" False (checkFG2 p)
    , Check "Case1/HasDiamFP" False (checkHasDiamFP p)
    ]

  , let p = Proxy :: Proxy Case2 in
    [ Check "Case2/A1-A4" True (checkAllAPSAxioms p)
    , Check "Case2/G2"        True  (checkG2 p)
    , Check "Case2/HasDiamFP" False (checkHasDiamFP p)
    ]

  , let p = Proxy :: Proxy Case3 in
    [ Check "Case3/A1"        True  (checkA1 p)
    , Check "Case3/A2"        True  (checkA2 p)
    , Check "Case3/A3"        False (checkA3 p)
    , Check "Case3/A4"        True  (checkA4 p)
    , Check "Case3/HasDiamFP" True  (checkHasDiamFP p)
    , Check "Case3/FG2"       False (checkFG2 p)
    , Check "Case3/G2"        False (checkG2 p)
    ]

  , let p = Proxy :: Proxy Case4 in
    [ Check "Case4/A1"        True  (checkA1 p)
    , Check "Case4/A2"        True  (checkA2 p)
    , Check "Case4/A3"        True  (checkA3 p)
    , Check "Case4/A4"        False (checkA4 p)
    , Check "Case4/A4'"       True  (checkA4' p)
    , Check "Case4/HasDiamFP" True  (checkHasDiamFP p)
    ]

  , let p = Proxy :: Proxy Trivial2 in
    [ Check "Trivial2/A1" True (checkA1 p)
    , Check "Trivial2/A3" True (checkA3 p)
    , Check "Trivial2/A4" True (checkA4 p)
    , Check "Trivial2/Consistent" True (checkConsistency p)
    ]
  ]

-- ----------------------------------------------------------------------------
-- 有限モデル探索の回帰
-- ----------------------------------------------------------------------------

isJust :: Maybe a -> Bool
isJust (Just _) = True
isJust _        = False

searchChecks :: [Check]
searchChecks =
  -- Case1 系: A1-A4 を満たすが FG2 を満たさないモデルは存在する
  [ Check "Search/A1A2A3A4 ⇏ FG2"
      True
      (isJust (searchSeparation linearCarrier3
        [ hyp "A1" apsA1, hyp "A2" apsA2, hyp "A3" apsA3, hyp "A4" apsA4 ]
        (hyp "FG2" apsFG2)))

  -- Case3 系: A1+A2+A4 + ∃☒-FP を満たすが FG2 を満たさないモデルは存在する
  , Check "Search/A1A2A4+DFP ⇏ FG2"
      True
      (isJust (searchSeparation linearCarrier3
        [ hyp "A1" apsA1, hyp "A2" apsA2, hyp "A4" apsA4
        , hyp "∃☒-FP" apsHasDiamFP
        ]
        (hyp "FG2" apsFG2)))

  -- Syntactical Fact: A1+A2+FG2 ⇒ G2 は 3 点線形上で反例なし
  , Check "Search/A1A2+FG2 ⇒ G2 has no counterexample"
      False
      (isJust (searchSeparation linearCarrier3
        [ hyp "A1" apsA1, hyp "A2" apsA2, hyp "FG2" apsFG2 ]
        (hyp "G2" apsG2)))

  -- B&S 2016 主定理: APS + ∃☒-FP ⇒ FG2 は反例なし
  , Check "Search/APS+DFP ⇒ FG2 has no counterexample"
      False
      (isJust (searchSeparation linearCarrier3
        [ hyp "A1" apsA1, hyp "A2" apsA2, hyp "A3" apsA3, hyp "A4" apsA4
        , hyp "∃☒-FP" apsHasDiamFP
        ]
        (hyp "FG2" apsFG2)))

  -- B&S 2016 主定理: APS + ∃☒-FP ⇒ G2 は反例なし
  , Check "Search/APS+DFP ⇒ G2 has no counterexample"
      False
      (isJust (searchSeparation linearCarrier3
        [ hyp "A1" apsA1, hyp "A2" apsA2, hyp "A3" apsA3, hyp "A4" apsA4
        , hyp "∃☒-FP" apsHasDiamFP
        ]
        (hyp "G2" apsG2)))

  -- A1 上で FG2 ⇒ ∃☒-FP は 3 点線形上で反例なし
  , Check "Search/A1+FG2 ⇒ ∃☒-FP has no counterexample"
      False
      (isJust (searchSeparation linearCarrier3
        [ hyp "A1" apsA1, hyp "FG2" apsFG2 ]
        (hyp "∃☒-FP" apsHasDiamFP)))

  -- 逆向き A1 + ∃☒-FP ⇏ FG2 は反例あり
  , Check "Search/A1+∃☒-FP ⇏ FG2"
      True
      (isJust (searchSeparation linearCarrier3
        [ hyp "A1" apsA1, hyp "∃☒-FP" apsHasDiamFP ]
        (hyp "FG2" apsFG2)))
  ]

-- ----------------------------------------------------------------------------
-- AutoZoo の回帰
-- ----------------------------------------------------------------------------

autoEdges :: [Edge]
autoEdges = buildAutoZoo linearCarrier3 defaultAutoContexts defaultAutoProps

hasProvedEdge :: Prop -> Prop -> [Edge] -> Bool
hasProvedEdge p q = any
  (\e -> edgeFrom e == p && edgeTo e == q && edgeKind e == Proved)

hasSeparatedEdge :: Prop -> Prop -> [Edge] -> Bool
hasSeparatedEdge p q = any
  (\e -> edgeFrom e == p && edgeTo e == q && edgeKind e == Separated)

autoChecks :: [Check]
autoChecks =
  [ Check "Auto/FG2 -> G2 proved"
      True (hasProvedEdge PFG2 PG2 autoEdges)
  , Check "Auto/∃☒-FP -> FG2 proved"
      True (hasProvedEdge PHasDiamFP PFG2 autoEdges)
  , Check "Auto/∃☒-FP -> G2 proved"
      True (hasProvedEdge PHasDiamFP PG2 autoEdges)
  , Check "Auto/FG2 -> ∃☒-FP proved (on A1)"
      True (hasProvedEdge PFG2 PHasDiamFP autoEdges)
  -- 逆向き反例が記録されている
  , Check "Auto/G2 -> FG2 separated"
      True (hasSeparatedEdge PG2 PFG2 autoEdges)
  ]
