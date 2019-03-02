import unittest, intsets
include util/main

let pathPrefix = "../test/testData/sets/"


proc getSet(nodeId: string): Set =
    for d in getPrettyDomainsOfNode(db, nodeId):
        if d of Set:
            return Set(d)
    return nil

suite "core":
    test "MMMM":
        init(pathPrefix & "recursive/markerMarkerMarkerMarker")
        let d = getSet("2")
        let mS = MarkerSet(d)

        let child1 = ms.children[0]
        let grandkid1 = child1.children[0]
        let greatGrandKid1 = grandkid1.children[0]
        check(greatGrandKid1.included.toSeq() == @[1])

    test "FFFF":
        init(pathPrefix & "recursive/ffff")
        let d = getSet("2")
        let s = FlagSet(d)
        # echo s
        let child1 = s.children[0]
        let grandkid1 = child1.children[0]
        let greatGrandKid1 = grandkid1.children[0]
        check(greatGrandKid1.included.toSeq() == @[1])

    test "FFF":
        init(pathPrefix & "recursive/flagsFlagsFlags")

        let d = getSet("15")
        let s = FlagSet(d)

        let child1 = s.children[0]
        check(child1 of FlagSet)

        let grandkid1 = child1.children[0]
        check(grandkid1 of FlagSet)
        check(grandkid1.included.toSeq() == @[1])

        let child2 = s.children[1]
        check(child2 of FlagSet)

        let grandkid2 = child2.children[0]
        check(grandkid2.included.toSeq() == @[2])
        check(grandkid2 of FlagSet)

    test "FFM":
        init(pathPrefix & "recursive/flagsFlagsMarker")

        # for d in getPrettyDomainsOfNode(db, "13"):
        let d = getSet("13")
        let s = FlagSet(d)
        # echo s

        let child1 = s.children[0]
        check(child1 of FlagSet)

        let grandkid1 = child1.children[0]
        check(grandkid1 of MarkerSet)
        check(grandkid1.included.toSeq() == @[1])

        let child2 = s.children[1]
        check(child2 of FlagSet)

        let grandkid2 = child2.children[0]
        check(grandkid2.included.toSeq() == @[2])
        check(grandkid2 of MarkerSet)

    test "FMF":
        init(pathPrefix & "recursive/flagsMarkerFlags")

        let d = getSet("13")
        let s = FlagSet(d)

        let child1 = s.children[0]
        check(child1 of MarkerSet)

        let grandkid1 = child1.children[0]
        check(grandkid1 of FlagSet)
        check(grandkid1.included.toSeq() == @[1])

        let child2 = s.children[1]
        check(child2 of MarkerSet)

        let grandkid2 = child2.children[0]
        check(grandkid2.included.toSeq() == @[2])
        check(grandkid2 of FlagSet)

    test "MFF":
        init(pathPrefix & "recursive/markerFlagsFlags")

        let d = getSet("13")
        let s = MarkerSet(d)
        # echo s

        let child1 = s.children[0]
        check(child1 of FlagSet)

        let grandkid1 = child1.children[0]
        check(grandkid1 of FlagSet)
        check(grandkid1.included.toSeq() == @[1])

        let child2 = s.children[1]
        check(child2 of FlagSet)

        let grandkid2 = child2.children[0]
        check(grandkid2.included.toSeq() == @[2])
        check(grandkid2 of FlagSet)

    test "MMF":
        init(pathPrefix & "recursive/markerMarkerFlags")

        let d = getSet("11")
        let s = MarkerSet(d)
                # echo s
        let child1 = s.children[0]
        check(child1 of MarkerSet)

        let grandkid1 = child1.children[0]
        check(grandkid1 of FlagSet)
        check(grandkid1.included.toSeq() == @[1])

        let child2 = s.children[1]
        check(child2 of MarkerSet)

        let grandkid2 = child2.children[0]
        check(grandkid2.included.toSeq() == @[2])
        check(grandkid2 of FlagSet)

    test "FMM":
        init(pathPrefix & "recursive/flagsMarkerMarker")

        let d = getSet("11")
        let s = FlagSet(d)

        let child1 = s.children[0]
        check(child1 of MarkerSet)

        let grandkid1 = child1.children[0]
        check(grandkid1 of MarkerSet)
        check(grandkid1.included.toSeq() == @[1])

        let child2 = s.children[1]
        check(child2 of MarkerSet)

        let grandkid2 = child2.children[0]
        check(grandkid2.included.toSeq() == @[2])
        check(grandkid2 of MarkerSet)


    test "MMM":
        init(pathPrefix & "recursive/markerMarkerMarker")

        let d = getSet("9")
        let s = MarkerSet(d)

        let child1 = s.children[0]
        check(child1 of MarkerSet)

        let grandkid1 = child1.children[0]
        check(grandkid1.included.toSeq() == @[1])
        check(grandkid1 of MarkerSet)

        let child2 = s.children[1]
        check(child2 of MarkerSet)

        let grandkid2 = child2.children[0]
        check(grandkid2.included.toSeq() == @[2])
        check(grandkid2 of MarkerSet)



    test "FF":
        init(pathPrefix & "recursive/flagsFlags")
        let d = getSet("8")
        let s = FlagSet(d)

        # echo s
        # echo typeof(s)

        check(s.getCardinality() == "int(1)")

        let child1 = s.children[0]
        check(child1 of FlagSet)
        check(child1.included.toSeq() == @[3])
        check(child1.getCardinality() == "int(1)")

    test "F":
        init(pathPrefix & "flags")
        let d = getSet("7")
        let s = FlagSet(d)
        check(s.included.toSeq() == @[1,2,3])
        check(s.getCardinality() == "int(3)")

    test "FNotExcluded":
        init(pathPrefix & "flags")
        let d = getSet("4")
        let s = FlagSet(d)
        check(s.getCardinality() == "int(1..8)")
        check(s.notExcluded.toSeq() == @[1,2,3,4,5,6,7,8,9])
        check((s.included - s.notExcluded).toSeq().len() == 0)
        # check(s.excluded.toSeq().len() == 0)
                
    test "M":
        init(pathPrefix & "marker")
        let d = getSet("4")
        let s = MarkerSet(d)
        check(s.included.toSeq() == @[6])
        check(s.getCardinality() == "int(1)")

    test "MNotExcluded":
        init(pathPrefix & "marker")
        let d = getSet("2")
        let s = MarkerSet(d)
        check(s.getCardinality() == "int(1..5)")
        check(s.included.toSeq().len() == 0)
        check(s.notExcluded.toSeq() == @[1,2,3,4,5,6,7,8,9])

    test "MM":
        init(pathPrefix & "recursive/markerMarker")

        let d = getSet("5")
        let s = MarkerSet(d)

        check(s.getCardinality() == "int(1)")

        let child1 = s.children[0]
        check(child1 of MarkerSet)

        check(child1.included.toSeq() == @[1, 2])
        check(child1.getCardinality() == "int(2)")
    
    test "MF":
        init(pathPrefix & "recursive/markerFlags")
        let d = getSet("8")
        let s = MarkerSet(d)

        check(s.getCardinality() == "int(1)")

        let child1 = s.children[0]
        check(child1 of FlagSet)
        check(child1.included.toSeq() == @[3])
        check(child1.getCardinality() == "int(1)")

    test "FM":
        init(pathPrefix & "recursive/flagsMarker")
        let d = getSet("8")
        let s = FlagSet(d)
        check(s.getCardinality() == "int(1)")

        # echo s

        let child1 = s.children[0]
        check(child1 of MarkerSet)
        check(child1.included.toSeq() == @[3])
        check(child1.getCardinality() == "int(1)")

suite "occurrence":

    test "O":
        init(pathPrefix & "occurrence")
        let d = getSet("7")
        let s = OccurrenceSet(d)
        check(s.getCardinality() == "int(1)")
        check(s.included.toSeq() == @[6])

    test "ONotExcluded":
        init(pathPrefix & "occurrence")
        let d = getSet("4")
        let s = OccurrenceSet(d)
        check(s.getCardinality() == "int(0..4)")
        check(s.notExcluded.toSeq() == @[3,4,5,6])

    test "MO":
        init(pathPrefix & "recursive/markerOccurrence")

        let d = getSet("7")
        let s = MarkerSet(d)
        check(s.getCardinality() == "int(1)")

        let child1 = s.children[0]
        check(child1 of OccurrenceSet)
        check(child1.included.toSeq() == @[3])

    test "FO":
        init(pathPrefix & "recursive/flagsOccurrence")
        let d = getSet("7")
        let s = FlagSet(d)
        check(s.getCardinality() == "int(1)")

        let child1 = s.children[0]
        check(child1 of OccurrenceSet)
        check(child1.included.toSeq() == @[3])

    test "MMO":
        init(pathPrefix & "recursive/markerMarkerOccurrence")

        let d = getSet("8")
        let s = MarkerSet(d)

        let child1 = s.children[0]
        check(child1 of MarkerSet)

        let grandkid1 = child1.children[0]
        check(grandkid1 of OccurrenceSet)
        check(grandkid1.included.toSeq() == @[2])

        let child2 = s.children[1]
        check(child2 of MarkerSet)

        let grandkid2 = child2.children[0]
        check(grandkid2 of OccurrenceSet)
        check(grandkid2.included.toSeq() == @[1])

    test "FFO":
        init(pathPrefix & "recursive/flagsFlagsOccurrence")

        let d = getSet("12")
        let s = FlagSet(d)

        let child1 = s.children[0]
        check(child1 of FlagSet)

        let grandkid1 = child1.children[0]
        check(grandkid1 of OccurrenceSet)
        check(grandkid1.included.toSeq() == @[2])

        let child2 = s.children[1]
        check(child2 of FlagSet)

        let grandkid2 = child2.children[0]
        check(grandkid2 of OccurrenceSet)
        check(grandkid2.included.toSeq() == @[1])

    test "FFFO":
        init(pathPrefix & "recursive/flagsFlagsFlagsOccurrence")

        let d = getSet("2")
        let s = FlagSet(d)
                # echo s
        let child1 = s.children[0]
        check(child1 of FlagSet)

        let grandkid1 = child1.children[0]
        check(grandkid1 of FlagSet)

        let greatGrandKid1 = grandkid1.children[0]
        check(greatGrandKid1 of OccurrenceSet)
        check(greatGrandKid1.included.toSeq() == @[1])

suite "dummy":

    test "D":
        init(pathPrefix & "dummy")
        let d = getSet("7")
        let s = DummySet(d)
        check(s.getCardinality() == "int(3)")
        check(s.included.toSeq() == @[1, 2, 3])

    test "MD":
        init(pathPrefix & "recursive/markerDummy")
        let d = getSet("7")
        let s = MarkerSet(d)
        check(s.getCardinality() == "int(1)")

        let child1 = s.children[0]
        check(child1 of DummySet)
        check(child1.included.toSeq() == @[1,2])

    test "MDNotExcluded":
        init(pathPrefix & "recursive/markerDummy")
        let d = getSet("5")
        let s = MarkerSet(d)
        check(s.getCardinality() == "int(1)")

        let child1 = s.children[0]
        check(child1 of DummySet)
        check(child1.getCardinality() == "int(0..3)")
        check(child1.notExcluded.toSeq() == @[1,2,3])

    test "FD":
        init(pathPrefix & "recursive/flagsDummy")
        let d = getSet("7")
        let s = FlagSet(d)
        check(s.getCardinality() == "int(1)")
        let child1 = s.children[0]
        check(child1 of DummySet)
        check(child1.included.toSeq() == @[1,2])

    test "MMD":
        init(pathPrefix & "recursive/markerMarkerDummy")

        let d = getSet("10")
        let s = MarkerSet(d)
                # echo s
        let child1 = s.children[0]
        check(child1 of MarkerSet)

        let grandkid1 = child1.children[0]
        check(grandkid1 of DummySet)
        check(grandkid1.included.toSeq() == @[1])

        let child2 = s.children[1]
        check(child2 of MarkerSet)

        let grandkid2 = child2.children[0]
        check(grandkid2 of DummySet)
        check(grandkid2.included.toSeq() == @[2])

    test "FFD":
        init(pathPrefix & "recursive/flagsFlagsDummy")

        let d = getSet("14")
        let s = FlagSet(d)
                # echo s
        let child1 = s.children[0]
        check(child1 of FlagSet)

        let grandkid1 = child1.children[0]
        check(grandkid1 of DummySet)
        check(grandkid1.included.toSeq() == @[1])

        let child2 = s.children[1]
        check(child2 of FlagSet)

        let grandkid2 = child2.children[0]
        check(grandkid2 of DummySet)
        check(grandkid2.included.toSeq() == @[2])


    test "FFFD":
        init(pathPrefix & "recursive/flagsFlagsFlagsDummy")
                # echo s
        let d = getSet("2")
        let s = FlagSet(d)

        let child1 = s.children[0]
        check(child1 of FlagSet)

        let grandkid1 = child1.children[0]
        check(grandkid1 of FlagSet)

        let greatGrandKid1 = grandkid1.children[0]
        check(greatGrandKid1 of DummySet)
        check(greatGrandKid1.included.toSeq() == @[1])

suite "explicit":
    test "E":
        init(pathPrefix & "explicit")
        let d = getSet("4")
        let s = ExplicitSet(d)
                # echo s
        check(s.getCardinality() == "int(3)")
        check(s.included.toSeq() == @[1, 2, 3])

    test "ENotExcluded":
        init(pathPrefix & "explicit")
        let d = getSet("2")
        let s = ExplicitSet(d)
        #         # echo s
        check(s.getCardinality() == "int(3)")
        check(s.notExcluded.toSeq() == @[1, 2, 3, 4, 5, 6, 7, 8, 9])

    test "EE":
        init(pathPrefix & "recursive/explicitExplicit")
        let d = getSet("8")
        let s = ExplicitSet(d)
        check(s.getCardinality() == "int(2)")
        # echo s
        let child1 = s.children[0]
        check(child1.getCardinality() == "int(2)")
        check(child1 of ExplicitSet)
        check(child1.included.toSeq() == @[1, 2])

        let child2 = s.children[1]
        check(child2.getCardinality() == "int(2)")
        check(child2 of ExplicitSet)
        check(child2.included.toSeq() == @[1, 3])

    test "EM":
        init(pathPrefix & "recursive/explicitMarker")
        let d = getSet("7")
        let s = ExplicitSet(d)
        check(s.getCardinality() == "int(2)")
        # echo s
        let child1 = s.children[0]
        check(child1.getCardinality() == "int(0)")
        check(child1 of MarkerSet)
        check(child1.included.toSeq().len() == 0)

        let child2 = s.children[1]
        check(child2.getCardinality() == "int(1)")
        check(child2 of MarkerSet)
        check(child2.included.toSeq() == @[3])

    test "EME":
        init(pathPrefix & "recursive/explicitMarkerExplicit")
        let d = getSet("10")
        let s = ExplicitSet(d)
        check(s.getCardinality() == "int(2)")

        # echo s
        let child1 = s.children[0]
        check(child1.getCardinality() == "int(1)")
        check(child1 of MarkerSet)

        let grandkid1 = child1.children[0]
        check(grandkid1.getCardinality() == "int(2)")
        check(grandkid1 of ExplicitSet)
        check(grandkid1.included.toSeq() == @[1, 2])

        let child2 = s.children[1]
        check(child2.getCardinality() == "int(1)")
        check(child2 of MarkerSet)

        let grandkid2 = child2.children[0]
        check(grandkid2.getCardinality() == "int(2)")
        check(grandkid2 of ExplicitSet)
        check(grandkid2.included.toSeq() == @[1, 3])

    test "EMF":
        init(pathPrefix & "recursive/explicitMarkerFlags")
        let d = getSet("9")
        let s = ExplicitSet(d)
        check(s.getCardinality() == "int(2)")
        # echo s

        let child1 = s.children[0]
        check(child1.getCardinality() == "int(1)")
        check(child1 of MarkerSet)

        let grandkid1 = child1.children[0]
        check(grandkid1.getCardinality() == "int(0)")
        check(grandkid1 of FlagSet)
        check(grandkid1.included.toSeq().len() == 0)

        let child2 = s.children[1]
        check(child2.getCardinality() == "int(1)")
        check(child2 of MarkerSet)

        let grandkid2 = child2.children[0]
        check(grandkid2.getCardinality() == "int(1)")
        check(grandkid2 of FlagSet)
        check(grandkid2.included.toSeq() == @[3])

    test "ME":
        init(pathPrefix & "recursive/markerExplicit")
        let d = getSet("5")
        let s = MarkerSet(d)
        check(s.getCardinality() == "int(1)")
        # echo s
        let child1 = s.children[0]
        check(child1.getCardinality() == "int(2)")
        check(child1 of ExplicitSet)
        check(child1.included.toSeq() == @[1, 2])

    test "FFE":
        init(pathPrefix & "recursive/flagsFlagsExplicit")

        let d = getSet("11")
        let s = FlagSet(d)
                # echo s

        let child1 = s.children[0]
        check(child1 of FlagSet)

        let grandkid1 = child1.children[0]
        check(grandkid1 of ExplicitSet)
        check(grandkid1.included.toSeq() == @[1])

        let child2 = s.children[1]
        check(child2 of FlagSet)

        let grandkid2 = child2.children[0]
        check(grandkid2 of ExplicitSet)
        check(grandkid2.included.toSeq() == @[2])


    test "EEE":
        init(pathPrefix & "recursive/explicitExplicitExplicit")
        let d = getSet("40")
        let s = ExplicitSet(d)
        check(s.getCardinality() == "int(2)")
        # echo s

        let child1 = s.children[0]
        check(child1.getCardinality() == "int(2)")
        check(child1 of ExplicitSet)

        let grandkid1 = child1.children[0]
        check(grandkid1.getCardinality() == "int(2)")
        check(grandkid1 of ExplicitSet)
        check(grandkid1.included.toSeq() == @[1, 2])

        let grandkid2 = child1.children[1]
        check(grandkid2.getCardinality() == "int(2)")
        check(grandkid2 of ExplicitSet)
        check(grandkid2.included.toSeq() == @[1, 3])

        let child2 = s.children[1]
        check(child2.getCardinality() == "int(2)")
        check(child2 of ExplicitSet)

        let grandkid3 = child2.children[0]
        check(grandkid3.getCardinality() == "int(2)")
        check(grandkid3 of ExplicitSet)
        check(grandkid3.included.toSeq() == @[1, 2])

        let grandkid4 = child2.children[1]
        check(grandkid4.getCardinality() == "int(2)")
        check(grandkid4 of ExplicitSet)
        check(grandkid4.included.toSeq() == @[1, 4])

    test "EEEE":
        init(pathPrefix & "recursive/explicitExplicitExplicitExplicit")
        let d = getSet("2")
        let s = ExplicitSet(d)
        check(s.getCardinality() == "int(1)")
        check(s.children[0].children[0].children[0].included.toSeq() == @[1])

    test "EEEO":
        init(pathPrefix & "recursive/explicitExplicitExplicitOccurrence")
        let d = getSet("2")
        let s = ExplicitSet(d)
        check(s.getCardinality() == "int(1)")
        # echo s

        let greatGrandKid1 = s.children[0].children[0].children[0] 
        check(greatGrandKid1 of OccurrenceSet)
        check(greatGrandKid1.included.toSeq() == @[1])