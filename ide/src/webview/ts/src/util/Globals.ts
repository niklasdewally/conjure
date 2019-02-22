import Node from './Node';
import Data from './Data';
import Tree from './Tree';

declare var acquireVsCodeApi: any;
declare var d3: any;

export default class Globals {
    public static data = new Data();
    public static vscode = acquireVsCodeApi();

    public static nextNode = () => {

        let stepSize = Number($("#stepSize").val());

        if (Globals.data.id2Node[Globals.data.selectedId]._children) {
            Globals.data.toggleNode(Globals.data.selectedId);
            return
        }

        if (!Globals.data.id2Node[Globals.data.selectedId + stepSize]) {
            Globals.loadNNodes();
            // console.log("NEXT")
        }
        else {
            // exports.selectedId = exports.currentId;
            Globals.data.selectedId += stepSize;
            Tree.selectNode(Globals.data.selectedId);
        }
    }

    //TODO check that the previous node is not withn a collapsed node
    public static previousNode = () => {
        if (Globals.data.selectedId > 1) {
            Globals.data.selectedId--;
            Tree.selectNode(Globals.data.selectedId);
        }
    }

    public static rightNode = () => {
        if (Globals.data.id2Node[Globals.data.selectedId].children) {
            let childCount = Globals.data.id2Node[Globals.data.selectedId].children.length;
            if (childCount > 1) {
                Globals.data.selectedId = Globals.data.id2Node[Globals.data.selectedId].children[childCount - 1].id;
            }
            Tree.selectNode(Globals.data.selectedId);
        }
    }

    public static upNode = () => {
        if (Globals.data.selectedId > Globals.data.rootId) {
            // exports.selectedId = exports.id2Parent[exports.selectedId].id;
            Globals.data.selectedId = Globals.data.id2Node[Globals.data.selectedId].parent.id;
        }
        Tree.selectNode(Globals.data.selectedId);
    }

    public static loadNNodes = () => {

        if (!Globals.data.waiting) {

            // console.log("requesting more");

            Globals.vscode.postMessage({
                command: 'loadNodes',
                amount: Number($("#stepSize").val()),
                start: Globals.data.selectedId
                // start: exports.currentId
            });

            // console.log("SET WAIT TRUE NODES");
            Globals.data.waiting = true;
        }
        else {
            // console.log("waiting");

        }
    }

    public static loadDomains = () => {

        // console.log(exports.waiting);

        if (!Globals.data.waiting) {

            if (Globals.data.pretty) {
                Globals.sendPrettyRequest()
            }
            else {
                Globals.sendSimpleRequest()
            }

            Globals.data.waiting = true;
        }
        // console.log("SET WAIT TRUE DOMAINS, pretty: " + exports.pretty );
    }
    public static sendSimpleRequest = () => {
        Globals.vscode.postMessage({
            command: "simpleDomains",
            amount: Number($("#domCount").val()),
            start: Globals.data.currentDomainId,
            nodeId: Globals.data.selectedId,
        });
    }

    public static sendPrettyRequest = () => {
        Globals.vscode.postMessage({
            command: "prettyDomains",
            nodeId: Globals.data.selectedId,
            paths: Globals.data.pathList.join(":")
        });
    }



    public static tabulate = () => {
        var table = d3.select('#pane').append('table')
        var thead = table.append('thead')

        // append the header row
        thead.append('tr')
            .selectAll('th')
            .data(Globals.data.columns).enter()
            .append('th')
            .text(function (column: any) { return column; });
    }

    public static appendRows = (data: any) => {
        var table = d3.select('#pane').append('table');
        var tbody = table.append('tbody');

        var rows = tbody.selectAll('tr')
            .data(data)
            .enter()
            .append('tr')
            .attr("id", (d: any, i: any) => {
                // console.log(d);
                // return "row" + (i + exports.currentDomainId - Number($("#domCount").val())) 
                return d.name;
            })

        // create a cell in each row for each column
        var cells = rows.selectAll('td')
            .data((row: any) => {
                return Globals.data.columns.map((column) => {
                    //dasdas
                    ////dasdas
                    return { column: column, value: row[column] };
                });
            })
            .enter()
            .append('td')
            .text((d: any) => { return d.value; });
    }

    public static getChildren = (parentId: number) => {
        Globals.vscode.postMessage({
            command: 'children',
            parentId: parentId,
        });
    }

    public static initialize = () => {
        Globals.vscode.postMessage({
            command: 'init',
        });

        Globals.vscode.postMessage({
            command: 'correctPath',
        });

        Globals.vscode.postMessage({
            command: 'longestBranchingVariable',
        });

        Globals.vscode.postMessage({
            command: 'loadCore',
        });

        Globals.vscode.postMessage({
            command: 'simpleDomains',
            amount: Number($("#domCount").val()),
            start: 0,
            nodeId: Globals.data.rootId,
        });
    }
}