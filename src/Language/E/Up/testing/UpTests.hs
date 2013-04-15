module Main ( main ) where

import Language.E

import Language.E.Up.EprimeToEssence
import Language.E.Up.IO (getTestSpecs, getSpec)
import Language.E.NormaliseSolution(normaliseSolutionEs)

import System.FilePath

import qualified Data.Text as T
import qualified Data.Text.IO as T

import Test.Hspec hiding (Spec)
import qualified Test.Hspec as Hspec
import Test.Hspec.HUnit ()

type EssenceF        = FilePath
type EprimeF         = FilePath
type SolutionF       = FilePath
type EprimeSolutionF = FilePath
type ParamF          = FilePath
type EssenceParamF   = FilePath
type LogsF           = FilePath


eprimes :: IO [EprimeF]
-- Every test
{-eprimes = allFilesWithSuffix ".eprime" "files/uptests/"-}

-- All tests that take less then 1/8 of second
{-
eprimes =  filter (flip notElem ["tupley32-8Complex5"]
        .   takeFileName . takeDirectory )
       <$> allFilesWithSuffix ".eprime" "files/uptests/"
-}

eprimes = _eprimeDirs "files/uptests/" ["___simple","___parts","___types","__easy","__reps"
                                       ,"_relations", "_indexes", "__failed"
                                       ]


-- Basic tests
--eprimes = _eprimeDirs "files/uptests/" ["___parts","___simple","___types"]

-- Tuples and matrixes
--eprimes = _eprimeDirs "files/uptests/" ["___simple", "_tuples_of_matrix", "_matrix_of_tuples","_zznested_singletons","_zothers"]


_eprimeDirs :: FilePath -> [FilePath] -> IO [EprimeF]
_eprimeDirs base arr =
    concatMapM ( allFilesWithSuffix ".eprime") (map (base </>) arr)

specs :: IO [((EprimeF, EprimeSolutionF, EssenceF, Maybe ParamF, Maybe EssenceParamF), SolutionF,LogsF )]
specs = do
    es <- eprimes
    return $ map getFiles es

    where
        getFiles f =
            let base = takeDirectory f
                name = takeFileName base
                in
            (
             (
                 f,
                 addExtension f "solution",
                 addExtension base  "essence",
                 Just $  addExtension (joinPath [base,name])  "param",
                 Just $  addExtension (joinPath [base,name])  "essence-param"
             ),
              replaceExtension f "solution",
              addExtension f "logs"
            )

runSpec :: ((EprimeF, EprimeSolutionF, EssenceF, Maybe ParamF, Maybe EssenceParamF), SolutionF,LogsF ) -> IO ()
runSpec  (sps@(_, _,_,_,_),ansF,logsF) = do
    (spec,sol,org,orgP) <- getTestSpecs sps

    ansS <- getSpec ansF
    let ans = normaliseSolutionEs . es $ ansS

    logs <- liftM T.lines (T.readFile logsF)

    let resultEssence = normaliseSolutionEs $  mainPure' True (spec,sol,org,orgP,logs)

    show (pretty resultEssence) `shouldBe` show (pretty ans)
    where
    es :: Language.E.Spec -> [E]
    es (Spec _ xs) = statementAsList xs

tests :: IO Hspec.Spec
tests = do
    xs <- specs
    return $
        describe "Converting eprime back to essence" $
            forM_ xs $ \every@( (specF,_,_,_,_),_,_) ->
                it specF $ runSpec every

main :: IO ()
main = do
    ts <- tests
    hspec ts
