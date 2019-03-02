import unittest, json
include util/main
# include util/process

suite "initParser":
    test "validPath":
        let minionPath = absolutePath("../test/testData/sets/recursive/flagsFlagsFlags/model000001.eprime-minion")
        let eprimePath = absolutePath("../test/testData/sets/recursive/flagsFlagsFlags/model000001.eprime")
        let db = open("../test/testData/sets/recursive/flagsFlagsFlags/test.db", "", "", "") 
        initParser(db, minionPath, eprimePath)

    
suite "process":
    let minionPath = absolutePath("../test/testData/sets/recursive/flagsFlagsFlags/model000001.eprime-minion")
    let eprimePath = absolutePath("../test/testData/sets/recursive/flagsFlagsFlags/model000001.eprime")
    let db = open("../test/testData/sets/recursive/flagsFlagsFlags/test.db", "", "", "") 
    initParser(db, minionPath, eprimePath)

    test "simple":
        let noExpression = getSimpleDomainsOfNode(db, "15", false)
        let withExpression = getSimpleDomainsOfNode(db, "15", true)
        check(noExpression.len() < withExpression.len())
        # echo noExpression


    test "pretty":
        let prettyDomains = getPrettyDomainsOfNode(db, "15")
        check(prettyDomains[0].name == "y")
        check(prettyDomains[0].rng == "int(1)")

        check(prettyDomains[1].name == "s")

        check(prettyDomains[2].name == "z")
        check(prettyDomains[2].rng == "int(1)")

        check(prettyDomains[3].name == "x")
        check(prettyDomains[3].rng == "int(1)")

suite "experiment":
    let minionPath = absolutePath("/home/tom/minion-private/build/golomb/model000001-03.eprime-minion")
    let eprimePath = absolutePath("/home/tom/minion-private/build/golomb/model000001.eprime")
    initParser(db, minionPath, eprimePath)
    let db = open("/home/tom/minion-private/build/golomb/test.db", "", "", "") 

    test "golomb":
        let noExpression = getSimpleDomainsOfNode(db, "0", false)
        # echo noExpression