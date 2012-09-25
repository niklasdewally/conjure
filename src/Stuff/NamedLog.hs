{-# LANGUAGE FlexibleContexts #-}

module Stuff.NamedLog where

import Data.Hashable
import Data.List ( isPrefixOf )
import Text.PrettyPrint ( Doc, (<+>), vcat, brackets, text )


data NamedLog = NamedLog String Doc
    deriving Show

instance Hashable NamedLog where
    hash (NamedLog a b) = hash (a, show b)

suppress :: [String]
suppress = [ "restoreState"
           , "patternMatch.core"
           , "patternMatch"
           , "rule-fail"
           , "Simplify"
           , "Evaluator"
           , "Evaluator.hasType"
           , "Evaluator.hasDomain"
           , "Evaluator.hasRepr"
           , "Evaluator.domSize"
           , "Evaluator.indices"
           , "Evaluator.replace"
           ]

buildLog :: String -> Doc -> Maybe NamedLog
-- buildLog nm _ | "debug:" `isPrefixOf` nm = Nothing
buildLog nm _ | nm `elem` suppress       = Nothing
buildLog nm doc = Just (NamedLog nm doc)

prettyLogs :: [NamedLog] -> Doc
-- prettyLogs = vcat . map (\ (NamedLog nm doc) -> brackets (text nm) <+> doc )
prettyLogs = vcat . map (\ (NamedLog nm doc) -> brackets (text nm) <+> doc ) . nubKeepOrder

nubKeepOrder :: Hashable a => [a] -> [a]
nubKeepOrder = go []
    where
        go :: Hashable a => [Int] -> [a] -> [a]
        go _ [] = []
        go seen (x:xs) = let hashx = hash x in
            if hashx `elem` seen
                then go seen xs
                else x : go (hashx : seen) xs
