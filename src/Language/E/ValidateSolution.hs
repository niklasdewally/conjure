{-# LANGUAGE QuasiQuotes, ViewPatterns, OverloadedStrings #-}

module Language.E.ValidateSolution
    ( validateSolution
    , validateSolutionPure
    ) where

import qualified Data.HashMap.Strict as M

import Bug
import Language.E
import Language.E.Pipeline.AtMostOneSuchThat ( atMostOneSuchThat )
import Language.E.Pipeline.ExplodeStructuralVars ( explodeStructuralVars )
import Language.E.Pipeline.HandlingEnums ( handleEnums )
import Language.E.Pipeline.HandlingUnnameds ( handleUnnameds )
import Language.E.Pipeline.InlineLettings ( inlineLettings )
import Language.E.Pipeline.NoTuples ( allNoTuplesSpec )


type Essence  = Spec
type Param    = Maybe Spec
type Solution = Spec

validateSolution :: Essence -> Param -> Solution -> IO ()
validateSolution essence param solution =
    if validateSolutionPure essence param solution
        then return ()
        else error "Not a valid solution."


-- this will return True is it's valid, False if not
-- the validator might use error
validateSolutionPure :: Essence -> Param -> Solution -> Bool
validateSolutionPure essence param solution =
    let
        (mresult, _logs) = runCompESingle "validating solution" helper
    in
        case mresult of
            Left  x      -> userErr x
            Right result -> result

    where

        helper = do

            case param of
                Nothing -> return ()
                Just (Spec _ s) -> mapM_ introduceStuff (statementAsList s)
            -- bindersDoc >>= mkLog "binders 1"

            case solution of
                Spec _ s        -> mapM_ introduceStuff (statementAsList s)
            -- bindersDoc >>= mkLog "binders 2"

            let essenceCombined =
                    case (essence, param) of
                        (Spec l s, Just (Spec _ p)) -> Spec l (listAsStatement $ statementAsList p ++ statementAsList s)
                        _ -> essence

            let pipeline0 = recordSpec "init"
                    >=> explodeStructuralVars   >=> recordSpec "explodeStructuralVars"
                    >=> inlineLettings          >=> recordSpec "inlineLettings"
                    >=> fullyInline             >=> recordSpec "fullyInline"
                    >=> stripDecls              >=> recordSpec "stripDecls"
                    >=> handleEnums             >=> recordSpec "handleEnums"
                    >=> handleUnnameds          >=> recordSpec "handleUnnameds"
                    >=> inlineLettings          >=> recordSpec "inlineLettings"
                    >=> stripDecls              >=> recordSpec "stripDecls"
                    >=> allNoTuplesSpec         >=> recordSpec "allNoTuplesSpec"
                    >=> fullyEvaluate           >=> recordSpec "fullyEvaluate"

            Spec _ s <- pipeline0 essenceCombined

            let checks = map isPartOfValidSolution (statementAsList s)
            if all isJust checks
                then return (and $ catMaybes checks)
                else bug $ vcat [ "Cannot fully evaluate."
                                , pretty s
                                , prettyAsTree s
                                , prettyAsPaths s
                                ]



isPartOfValidSolution :: E -> Maybe Bool
isPartOfValidSolution [xMatch| [Prim (B b)] := topLevel.suchThat.value.literal |] = Just b
isPartOfValidSolution [xMatch| [Prim (B b)] := topLevel.where   .value.literal |] = Just b
isPartOfValidSolution [xMatch| _ := topLevel.objective   |] = Just True
isPartOfValidSolution [xMatch| _ := topLevel.branchingOn |] = Just True
isPartOfValidSolution _ = Nothing


fullyEvaluate :: MonadConjure m => Spec -> m Spec
fullyEvaluate
    = recordSpec "entering fullyEvaluate"
    >=> explodeStructuralVars           >=> recordSpec "explodeStructuralVars"
    >=> fullySimplifySpec               >=> recordSpec "fullySimplifySpec"
    >=> return . atMostOneSuchThat True >=> recordSpec "atMostOneSuchThat"


fullyInline :: MonadConjure m => Spec -> m Spec
fullyInline inp = do
    bs <- gets binders
    typesMap <- fmap M.fromList
        $ forM (getDecls inp)
        $ \ (nm, dom) -> do
            itsType <- typeOf dom
            return (nm, itsType)
    let bindingsMap = M.fromList [ (nm, val) | Binder nm val <- bs ]
    inliner typesMap bindingsMap inp

    where

        inliner typesMap bindingsMap (Spec v s) = Spec v <$> rewriteM f s
            where
                f x@[xMatch| [Prim (S nm)] := reference |]
                    = case (M.lookup nm typesMap, M.lookup nm bindingsMap) of
                        (_, Just [xMatch| _ := type |]) -> return Nothing
                        (Just theType, Just binding) -> do
                            theType' <- typeOf x
                            if typeUnify theType theType'
                                then return $ Just [xMake| typed.left               := [binding]
                                                         | typed.right.domainInExpr := [theType]
                                                         |]
                                else error $ show $ vcat [ "Type mismatch for" <+> pretty nm
                                                         , "    Expected:" <+> pretty theType
                                                         , "    Found:   " <+> pretty theType'
                                                         ]
                        (Nothing, Just binding) -> do
                            theType <- typeOf x
                            f [xMake| typed.left               := [binding]
                                    | typed.right.domainInExpr := [theType]
                                    |]
                        _           -> return Nothing
                f x@[xMatch| [_] := structural.single.reference |] = return (Just x)
                f _ = return Nothing

        getDecls (Spec _ x) =
            [ (nm, dom)
            | [xMatch| [Prim (S nm)] := topLevel.declaration.find.name.reference
                     | [dom]         := topLevel.declaration.find.domain
                     |] <- statementAsList x
            ] ++
            [ (nm, dom)
            | [xMatch| [Prim (S nm)] := topLevel.declaration.given.name.reference
                     | [dom]         := topLevel.declaration.given.domain
                     |] <- statementAsList x
            ]


stripDecls :: MonadConjure m => Spec -> m Spec
stripDecls (Spec language stmt) = return $ Spec language $ listAsStatement
    [ i
    | i <- statementAsList stmt
    , case i of
        [xMatch| _ := topLevel.declaration    |] -> False
        [xMatch| _ := topLevel.letting.domain |] -> False
        _ -> True
    ]


