# Iptables-graph

Tools for iptables to generate call graph.

## Prerequirements
1. [graphviz](https://www.graphviz.org/download) as known as **dot**
    - [Install](https://www.graphviz.org/download/)


## Example Command

Generate iptables of your local linux in graphviz graph foramt.
```bash
$ sudo iptables-save | ./iptables-graph
```

```
digraph {
    graph [pad="0.5", nodesep="0.5", ranksep="2"];
    node [shape=plain]
    rankdir=LR;
...
```

## Test Command

Generate iptables graph to svg file.

```bash
$ cat example.txt | ./iptables-graph > a.dot
$ dot -Tsvg a.dot -o a.svg
```

### Example Graph
![example.svg](https://raw.githubusercontent.com/AChingYo/iptables-graph/main/example.svg)
