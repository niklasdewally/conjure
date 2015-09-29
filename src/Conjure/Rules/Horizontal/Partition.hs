{-# LANGUAGE QuasiQuotes #-}

module Conjure.Rules.Horizontal.Partition where

import Conjure.Rules.Import


rule_Comprehension_Literal :: Rule
rule_Comprehension_Literal = "partition-comprehension-literal" `namedRule` theRule where
    theRule (Comprehension body gensOrConds) = do
        (gocBefore, (pat, p), gocAfter) <- matchFirst gensOrConds $ \ goc -> case goc of
            Generator (GenInExpr pat@Single{} expr) -> return (pat, matchDef opParts expr)
            _ -> na "rule_Comprehension_Literal"
        (TypePartition tau, elems) <- match partitionLiteral p
        let outLiteral = make matrixLiteral
                            (TypeMatrix TypeInt (TypeSet tau))
                            (DomainInt [RangeBounded 1 (fromInt (genericLength elems))])
                            [ AbstractLiteral (AbsLitSet e)
                            | e <- elems
                            ]
        let upd val old = lambdaToFunction pat old val
        return
            ( "Comprehension on partition literals"
            , do
                 (iPat, i) <- quantifiedVar
                 return $ Comprehension (upd i body)
                         $  gocBefore
                         ++ [Generator (GenInExpr iPat outLiteral)]
                         ++ transformBi (upd i) gocAfter
            )
    theRule _ = na "rule_Comprehension_PartitionLiteral"


rule_Eq :: Rule
rule_Eq = "partition-eq" `namedRule` theRule where
    theRule p = do
        (x,y)           <- match opEq p
        TypePartition{} <- typeOf x
        TypePartition{} <- typeOf y
        return
            ( "Horizontal rule for partition equality"
            , return $ make opEq (make opParts x) (make opParts y)
            )


rule_Neq :: Rule
rule_Neq = "partition-neq" `namedRule` theRule where
    theRule [essence| &x != &y |] = do
        TypePartition{} <- typeOf x
        TypePartition{} <- typeOf y
        return
            ( "Horizontal rule for partition dis-equality"
               , do
                    (iPat, i) <- quantifiedVar
                    return [essence|
                            (exists &iPat in &x . !(&i in &y))
                            \/
                            (exists &iPat in &y . !(&i in &x))
                        |]
            )
    theRule _ = na "rule_Neq"


rule_DotLt :: Rule
rule_DotLt = "partition-DotLt" `namedRule` theRule where
    theRule p = do
        (a,b)           <- match opDotLt p
        TypePartition{} <- typeOf a
        TypePartition{} <- typeOf b
        sameRepresentation a b
        ma <- tupleLitIfNeeded <$> downX1 a
        mb <- tupleLitIfNeeded <$> downX1 b
        return
            ( "Horizontal rule for partition .<" <+> pretty (make opDotLt ma mb)
            , return $ make opDotLt ma mb
            )


rule_DotLeq :: Rule
rule_DotLeq = "partition-DotLeq" `namedRule` theRule where
    theRule p = do
        (a,b)           <- match opDotLeq p
        TypePartition{} <- typeOf a
        TypePartition{} <- typeOf b
        sameRepresentation a b
        ma <- tupleLitIfNeeded <$> downX1 a
        mb <- tupleLitIfNeeded <$> downX1 b
        return
            ( "Horizontal rule for partition .<=" <+> pretty (make opDotLeq ma mb)
            , return $ make opDotLeq ma mb
            )


rule_Together :: Rule
rule_Together = "partition-together" `namedRule` theRule where
    theRule [essence| together(&x,&p) |] = do
        TypePartition{} <- typeOf p
        return
            ( "Horizontal rule for partition-together"
            , do
                 (iPat, i) <- quantifiedVar
                 return [essence| exists &iPat in parts(&p) . &x subsetEq &i |]
            )
    theRule _ = na "rule_Together"


rule_Apart :: Rule
rule_Apart = "partition-apart" `namedRule` theRule where
    theRule [essence| apart(&x,&p) |] = do
        TypePartition{} <- typeOf p
        return
            ( "Horizontal rule for partition-apart"
            , return [essence| !together(&x,&p) |]
            )
    theRule _ = na "rule_Apart"


rule_Party :: Rule
rule_Party = "partition-party" `namedRule` theRule where
    theRule (Comprehension body gensOrConds) = do
        (gocBefore, (pat, expr), gocAfter) <- matchFirst gensOrConds $ \ goc -> case goc of
            Generator (GenInExpr pat@Single{} expr) -> return (pat, expr)
            _ -> na "rule_Comprehension_Literal"
        (mkModifier, expr2) <- match opModifier expr
        (wanted, p)         <- match opParty expr2
        let upd val old = lambdaToFunction pat old val
        return
            ( "Comprehension on a particular part of a partition"
            , do
                 (iPat, i) <- quantifiedVar
                 (jPat, j) <- quantifiedVar
                 return $ WithLocals
                     (Comprehension (upd j body)
                         $  gocBefore
                         ++ [ Generator (GenInExpr iPat (make opParts p))
                            , Condition [essence| &wanted in &i |]
                            , Generator (GenInExpr jPat (mkModifier i))
                            ]
                         ++ transformBi (upd j) gocAfter)
                    (DefinednessConstraints [ [essence| &wanted in participants(&p) |] ])
            )
    theRule _ = na "rule_Party"


rule_Participants :: Rule
rule_Participants = "partition-participants" `namedRule` theRule where
    theRule (Comprehension body gensOrConds) = do
        (gocBefore, (pat, expr), gocAfter) <- matchFirst gensOrConds $ \ goc -> case goc of
            Generator (GenInExpr pat@Single{} expr) -> return (pat, expr)
            _ -> na "rule_Comprehension_Literal"
        p <- match opParticipants expr
        let upd val old = lambdaToFunction pat old val
        return
            ( "Comprehension on participants of a partition"
            , do
                 (iPat, i) <- quantifiedVar
                 (jPat, j) <- quantifiedVar
                 return $ Comprehension (upd j body)
                         $  gocBefore
                         ++ [ Generator (GenInExpr iPat (make opParts p))
                            , Generator (GenInExpr jPat i)
                            ]
                         ++ transformBi (upd j) gocAfter
            )
    theRule _ = na "rule_Participants"


rule_Card :: Rule
rule_Card = "partition-card" `namedRule` theRule where
    theRule p = do
        partition_      <- match opTwoBars p
        TypePartition{} <- typeOf partition_
        return
            ( "Cardinality of a partition"
            , return $ make opTwoBars $ make opParticipants partition_
            )


rule_In :: Rule
rule_In = "partition-in" `namedRule` theRule where
    theRule [essence| &x in &p |] = do
        TypePartition{} <- typeOf p
        return
            ( "Horizontal rule for partition-in."
            , return [essence| &x in parts(&p) |]
            )
    theRule _ = na "rule_In"
