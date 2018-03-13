module Main where

import Test.QuickCheck
import Data.List (sort, sortBy)

-- Typen fuer die Schemaseite
type Cols = [String]
data Table = T String Cols deriving (Eq, Show)
type Schema = [Table]

-- Typen für die Klassenseite
data ClassName = C [String] deriving (Eq, Show, Ord)
data CL = CL ClassName Cols deriving (Eq, Show)
type Classes = [CL]

-- fuer Quickcheck
instance Arbitrary Table where
  arbitrary = do
    tn <- arbitrary
    cols <- arbitrary
    return $ T tn cols

-- ein paar Beispielschema
ex0 :: Schema
ex0 = []
ex1 :: Schema
ex1 = [T "a" [ "c2",  "c1" ]]
ex2 :: Schema
ex2 = [T "c" ["cc", "c1", "c2", "dc", "d1"], T "b" ["cb", "c1", "c3", "db", "d1"], T "a" ["ca", "c3", "c2"]]
ex3 :: Schema
ex3 = [T "a" [], T "b" ["c1"], T "a" ["c2",""], T "c" []]
ex4 :: Schema
ex4 = [T "" []]
ex5 :: Schema
ex5 = [T "" [""]]
ex6 :: Schema
ex6 = [T "" ["a", "b", "a"], T "" [""]]

-- Sortiere Tabelle und Spalten
-- entferne Doppelte Tabellennamen
-- entferne Doppelte Schemaname
-- Jede Tabelle hat mindestens eine Spalte, im Zweifel wird "" ergaenzt
-- Diese Funktion sorgt für "ordentliche" Schemata
-- und normiert die Namen durch Sortierung
normalizeTable :: Schema -> Schema
normalizeTable = filterleere . filterdoppelte . (sortBy cmptable) where
  cmptable (T a _) (T b _) = a `compare` b
  filterdoppelte :: Schema -> Schema
  filterdoppelte [] = []
  filterdoppelte ((T tn cols):xs) = fds tn cols xs where
    fds :: String -> Cols -> Schema -> Schema
    fds tn cols [] = [T tn cols]
    fds tn cols ((T tn1 cols1):xs) =
      if tn == tn1
      then fds tn (cols ++ cols1) xs
      else ((T tn cols):(fds tn1 cols1 xs))
  filterleere :: Schema -> Schema
  filterleere [] = []
  filterleere ((T tn cols):xs) =
    if cols == []
    then ((T tn [""]):filterleere xs)
    else ((T tn (colfilter . sort $ cols)):filterleere xs) where
      colfilter :: [String] -> [String]
      colfilter [] = []
      colfilter (x :xs) = cf x xs where
        cf :: String -> [String] -> [String]
        cf name [] = [name]
        cf name (x:xs) =
          if name == x
          then cf name xs
          else (name:cf x xs)

-- ich brauche die nicht, aber ihr vielleicht schon
normalizeClasses :: Classes -> Classes
normalizeClasses = id

-- Hilfsfunktion: Bestimme Classname zu einem Feldnamen
colInTables :: Schema -> String -> ClassName
colInTables s x = toClass $ filter (inTable x) (normalizeTable s) where
  inTable :: String -> Table -> Bool
  inTable x (T _ cols) = elem x cols
  toClass :: Schema -> ClassName
  toClass x = C $ tablenames x where
    tablenames [] = []
    tablenames ((T x _):xs) = (x:tablenames xs)

-- Hilfsfunktion: Bestimme alle Feldnamen eines Schemas
allCols :: Schema -> [String]
allCols s = filterdups.sort.concat $ toCols $ normalizeTable s where
  toCols :: Schema -> [Cols]
  toCols [] = []
  toCols ((T _ c):xs) = (c:toCols xs)
  filterdups :: [String] -> [String]
  filterdups [] = []
  filterdups (x:xs) = dropeq x xs where
    dropeq :: String -> [String] -> [String]
    dropeq x [] = [x]
    dropeq last (x:xs) = if last == x then dropeq last xs else (last:dropeq x xs)

-- bestimmt fuer alle Spaltennamen den zugehoerigen Klassennamen
allClassNames :: Schema -> [(ClassName, String)]
allClassNames schema = (\x -> ((colInTables schema) x,x)) <$> (allCols schema)

-- bestimmt alle Klassen aus einem Schema
allClasses :: Schema -> Classes
allClasses = sortcols . joinclasses . sort . allClassNames where
  joinclasses :: [(ClassName, String)] -> Classes
  joinclasses [] = []
  joinclasses ((cl,cols):xs) = jc cl [cols] xs where
    jc :: ClassName -> Cols -> [(ClassName, String)] -> Classes
    jc cl cols [] = [CL cl cols]
    jc cl cols ((cl1,cols1):xs) =
      if cl == cl1
      then jc cl (cols1:cols) xs
      else ((CL cl cols) : jc cl1 [cols1] xs)
  sortcols :: Classes -> Classes
  sortcols = fmap sortcol where
    sortcol (CL cl cols) = CL cl (sort cols)

-- bestimme Tabellen zu Klasse
-- die Inverse zu allClasses
allTables :: Classes -> Schema
allTables ch = (\x -> (T x (colsInClass ch x))) <$> allTableNames ch

-- Hilfsfunktion: Bestimme alle Feldnamen einer Klasse
colsInClass :: Classes -> String -> [String]
colsInClass cl tn = sort $ cinclass cl tn where
  cinclass :: Classes -> String -> [String]
  cinclass [] _ = []
  cinclass ((CL (C cn) cols):xs) tn =
    if elem tn cn
    then cols ++ (cinclass xs tn)
    else cinclass xs tn

-- Hilfsfunktion: Bestimme alle Tabellennamen eines Schemas
allTableNames :: Classes -> [String]
allTableNames x = filterdup . sort $ names x where
  names :: Classes -> [String]
  names [] = []
  names ((CL (C n) _):xs) = n ++ (names xs)
  filterdup :: [String] -> [String]
  filterdup [] = []
  filterdup (x:xs) = filter x xs where
    filter :: String -> [String] -> [String]
    filter last [] = [last]
    filter last (x:xs) = if last == x then filter x xs else (last:filter x xs)

-- Funktion fuer Recurrenztest:
-- Bestimmt man alle Klassen und daraus wieder alle Tabellen
-- gibt das wieder das normalisierte Schema
--   quickCheck recurrence sollte durchlaufen.
--   bei dieser Implementierung dauert das aber!
recurrence :: Schema -> Bool
recurrence x = (normalizeTable x) == (allTables $ allClasses x)

-- Ausgabe einer Tabelle
printTable :: Table -> String
printTable (T tab cols) = "TB " ++ tab ++ ": " ++ printColNames cols

-- Ausgabe einer Klasse
printClass :: CL -> String
printClass (CL cln cols) =
  "CL " ++ printClassName cln ++ ": " ++ printColNames cols

-- Ausgabe eines Klassennamens
printClassName :: ClassName -> String
printClassName (C []) = ""
printClassName (C (x:xs)) = x ++ printRest xs where
  printRest [] = ""
  printRest (x:xs) = "_" ++ x ++ printRest xs

-- Ausgabe einer Menge von Spaltennamen
printColNames :: Cols -> String
printColNames [] = ""
printColNames (x:xs) = x ++ pn xs where
  pn [] = ""
  pn (x:xs) = ", " ++ x ++ pn xs

-- Liste von Strings ausgeben
printStrings :: [String] -> IO ()
printStrings [] = return ()
printStrings (x:xs) = do
  putStrLn x
  printStrings xs

-- Referenzausgabe
printex :: String -> Schema -> IO ()
printex n t = do
  putStrLn $ "Test: " ++ n
  printStrings $ printTable <$> normalizeTable t
  printStrings $ printClass <$> allClasses t

-- Simple Eingabefunktion fuer eine Datein
-- Ergebnis ist nicht normiert!
readTable :: String -> IO [Table]
readTable x = do
  file <- readFile x
  return $ (toTable . words) <$> lines file

-- Macht aus einer Stringliste eine Table
-- ohne Denken
toTable :: [String] -> Table
toTable [] = undefined
toTable (x:xs) = T x xs

-- Datei einlesen, und Umsetzen
compileTable :: String -> IO()
compileTable filename = do
  t <- readTable filename
  printex filename t

main :: IO ()
main = do
  compileTable "in"
