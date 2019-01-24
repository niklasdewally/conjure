import jester
import util/main

routes:

    get re"/init/(.*)":
        let path = request.matches[0]
        try:
            init(path)

        except EprimeParseException:
            resp HttpCode(503)
            echo "Failed to parse Eprime file"
        except MinionParseException:
            resp HttpCode(502)
            echo "Failed to parse Minion file"
        except :
            resp HttpCode(501)
            echo("IOERROR!!")

        resp "OK"

    get "/simpleDomains/@amount/@start/@nodeId":
        resp loadSimpleDomains(@"amount", @"start", @"nodeId")
        
    get "/prettyDomains/@amount/@start/@nodeId":
        resp loadPrettyDomains(@"amount", @"start", @"nodeId")

    get "/loadNodes/@amount/@start":
        resp loadNodes(@"amount", @"start")

    get "/correctPath":
        resp getCorrectPath()

    get "/longestBranchingVariable":
        resp getLongestBranchingVarName()
