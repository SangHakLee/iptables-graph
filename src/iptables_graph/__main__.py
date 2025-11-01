#!/usr/bin/env python3
import argparse
import sys
import re
import tempfile
import subprocess
import os

# Table names
raw = "raw"
mangle = "mangle"
nat = "nat"
filter = "filter"

# Chain names
PREROUTING = "PREROUTING"
INPUT = "INPUT"
FORWARD = "FORWARD"
OUTPUT = "OUTPUT"
POSTROUTING = "POSTROUTING"

# Policy names
RETURN = "RETURN"
ACCEPT = "ACCEPT"
DROP = "DROP"

TABLE_PREFIX = "*"

# Default lists
default_table_list = [raw, filter, nat, mangle]
default_chain_list = [PREROUTING, FORWARD, INPUT, OUTPUT, POSTROUTING]
default_policy_list = [RETURN, ACCEPT, DROP]


def parse_iptables(input_string):
    """Parse iptables-save output and return chains and policies."""
    all_chains = {
        raw: {PREROUTING: [], OUTPUT: []},
        filter: {INPUT: [], OUTPUT: [], FORWARD: []},
        nat: {PREROUTING: [], OUTPUT: [], POSTROUTING: []},
        mangle: {PREROUTING: [], INPUT: [], OUTPUT: [], FORWARD: [], POSTROUTING: []}
    }

    datas = {
        raw: {"policy": {}},
        filter: {"policy": {}},
        nat: {"policy": {}},
        mangle: {"policy": {}},
    }

    line_list = input_string.splitlines()
    current_table = None

    for line in line_list:
        token_list = line.split()
        if not token_list:
            continue

        # Detect table switch (*raw, *filter, etc.)
        if token_list[0].startswith('*') and token_list[0][1:] in all_chains.keys():
            current_table = token_list[0][1:]
            continue

        # Parse chain rules (-A CHAIN ...)
        if token_list[0] == '-A':
            current_chain = token_list[1]
            if current_chain not in all_chains[current_table]:
                all_chains[current_table][current_chain] = []

            rule_body = ''
            target = ''
            if len(token_list) >= 4 and token_list[-2] == '-j' and token_list[-1] not in [RETURN, ACCEPT, DROP]:
                target = token_list[-1]
                if target not in all_chains[current_table]:
                    all_chains[current_table][target] = []
                rule_body = ' '.join(token_list[2:])
            else:
                rule_body = ' '.join(token_list[2:])

            all_chains[current_table][current_chain].append({
                'rule_body': rule_body,
                'target': target
            })
            continue

        # Parse chain policies (:CHAIN POLICY)
        elif re.search(':(PREROUTING|INPUT|FORWARD|OUTPUT|POSTROUTING)', token_list[0]):
            current_chain = token_list[0].replace(':', '')
            current_chain_policy = token_list[1]
            datas[current_table]["policy"][current_chain] = current_chain_policy

    return all_chains, datas


def get_node_name(table_name, chain_name):
    """Generate a DOT-safe node name from table and chain."""
    return re.sub('[^a-zA-Z0-9]', '', table_name) + '_' + re.sub('[^a-zA-Z0-9]', '', chain_name)


def get_port_name(rule_index):
    """Generate a port name for a rule."""
    return "rule_" + str(rule_index)


def style_table_bgcolor(table):
    """Return background color for a table."""
    colors = {
        raw: "#FA7070",
        mangle: "#AEE2FF",
        nat: "#E5D1FA",
        filter: "#BEF0CB"
    }
    return colors.get(table, "#FFFFFF")


def style_default_table(table):
    """Style a table name."""
    return "<i>" + TABLE_PREFIX + table + "</i>"


def style_default_chain(chain):
    """Style a chain name."""
    return "<b>" + chain + "</b>"


def style_default_chain_policy(table, chain, datas):
    """Style a chain with its policy."""
    policy = datas[table]["policy"]
    if chain in policy:
        return "<b>" + chain + "</b><br/>" + policy[chain]
    return "<b>" + chain + "</b>"


def default_chain_link(src_table_name, src_chain_name, dst_table_name, dst_chain_name, options="[color=black]"):
    """Generate a link between two chains."""
    source_node = get_node_name(src_table_name, src_chain_name) + ':end'
    target_node = get_node_name(dst_table_name, dst_chain_name) + ':begin'
    return source_node + " -> " + target_node + options + ";\n"


def generate_dot(all_chains, datas):
    """Generate DOT format graph from parsed iptables data."""
    output = """digraph {
    graph [pad="0.5", nodesep="0.5", ranksep="2"];
    node [shape=plain]
    rankdir=LR;

    afterNat_PREROUTING   [shape=diamond, label="to localhost?"]
    afterMangle_PREROUTING [shape=diamond, label="from localhost?"]
    in_packet  [shape=oval, style=filled, label="Incoming Packet"]
    out_packet [shape=oval, style=filled, label="Outgoing Packet"]

"""

    # Generate nodes for each table/chain
    for table in all_chains:
        for chain in all_chains[table]:
            node_name = get_node_name(table, chain)
            tmp_body = node_name + """ [label=<<table border="0" cellborder="1" cellspacing="0">"""
            is_default_chain = chain in default_chain_list

            if is_default_chain:
                tmp_body += """
        <tr><td bgcolor=\"""" + style_table_bgcolor(table) + """\">""" + style_default_table(table) + """</td></tr>
        <tr><td port="begin" bgcolor="#EEEEEE">""" + style_default_chain(chain) + """</td></tr>"""
            else:
                tmp_body += """
        <tr><td><i>""" + style_default_table(table) + """</i></td></tr>
        <tr><td port="begin"><i>""" + style_default_chain(chain) + """</i></td></tr>"""

            # Add rules
            for i in range(len(all_chains[table][chain])):
                rule = all_chains[table][chain][i]
                tmp_body += """
        <tr><td port=\"""" + get_port_name(i) + """\">""" + rule["rule_body"] + """</td></tr>"""

            # Add policy for default chains
            if is_default_chain:
                tmp_body += """
        <tr><td port="begin" bgcolor="#EEEEEE">""" + style_default_chain_policy(table, chain, datas) + """</td></tr>"""

            tmp_body += """
        <tr><td port="end" bgcolor=\"""" + (style_table_bgcolor(table) if is_default_chain else "#FFFFFF") + """\"><b>end</b></td></tr>
    </table>>];
"""
            tmp_body = tmp_body.replace("->", "-&gt;")
            output += tmp_body

    # Generate edges between rules and their targets
    for table in all_chains:
        for chain in all_chains[table]:
            for i in range(len(all_chains[table][chain])):
                rule = all_chains[table][chain][i]
                if rule['target']:
                    source_node = get_node_name(table, chain) + ':' + get_port_name(i)
                    target_node = get_node_name(table, rule['target']) + ':begin'
                    output += source_node + " -> " + target_node + ";\n"

    # Add default packet flow links
    output += default_chain_link("in", "packet", raw, PREROUTING)
    output += default_chain_link(raw, PREROUTING, mangle, PREROUTING)
    output += default_chain_link(mangle, PREROUTING, "afterMangle", PREROUTING)
    output += default_chain_link("afterMangle", PREROUTING, nat, PREROUTING, "[label=\"N\"]")
    output += default_chain_link("afterMangle", PREROUTING, mangle, INPUT, "[label=\"Y\"]")
    output += default_chain_link(nat, PREROUTING, "afterNat", PREROUTING)
    output += default_chain_link("afterNat", PREROUTING, mangle, FORWARD, "[label=\"N\"]")
    output += default_chain_link("afterNat", PREROUTING, mangle, INPUT, "[label=\"Y\"]")
    output += default_chain_link(mangle, INPUT, filter, INPUT)
    output += default_chain_link(filter, INPUT, raw, OUTPUT)
    output += default_chain_link(raw, OUTPUT, mangle, OUTPUT)
    output += default_chain_link(mangle, OUTPUT, nat, OUTPUT)
    output += default_chain_link(nat, OUTPUT, filter, OUTPUT)
    output += default_chain_link(filter, OUTPUT, mangle, POSTROUTING)
    output += default_chain_link(mangle, POSTROUTING, nat, POSTROUTING)
    output += default_chain_link(mangle, FORWARD, filter, FORWARD)
    output += default_chain_link(filter, FORWARD, mangle, POSTROUTING)
    output += default_chain_link(nat, POSTROUTING, "out", "packet")

    output += "\n}\n"
    return output


def convert_dot(dot_text, fmt):
    """Convert DOT text to specified format (svg or png)."""
    with tempfile.NamedTemporaryFile(mode="w", delete=False, suffix=".dot") as tmp_dot:
        tmp_dot.write(dot_text)
        tmp_dot_path = tmp_dot.name

    tmp_output_path = tmp_dot_path + f".{fmt}"
    try:
        subprocess.run(
            ["dot", f"-T{fmt}", tmp_dot_path, "-o", tmp_output_path],
            check=True,
            stderr=subprocess.PIPE
        )
        with open(tmp_output_path, "rb") as f:
            return f.read()
    finally:
        if os.path.exists(tmp_dot_path):
            os.remove(tmp_dot_path)
        if os.path.exists(tmp_output_path):
            os.remove(tmp_output_path)


def main():
    """Main function."""
    parser = argparse.ArgumentParser(
        description="iptables-save output → Graphviz converter (dot/svg/png)"
    )
    parser.add_argument(
        "-i", "--input",
        help="Input file (default: stdin)",
        type=argparse.FileType('r'),
        default=sys.stdin
    )
    parser.add_argument(
        "-o", "--output",
        help="Output file (default: stdout)"
    )
    parser.add_argument(
        "-f", "--format",
        choices=["dot", "svg", "png"],
        default="dot",
        help="Output format: dot (default), svg, or png"
    )

    args = parser.parse_args()

    # Check for input
    if args.input == sys.stdin and sys.stdin.isatty():
        print("❌ No input provided. Use -i <file> or pipe data via stdin.", file=sys.stderr)
        print("\nExamples:", file=sys.stderr)
        print("  iptables-graph -i iptables.txt", file=sys.stderr)
        print("  sudo iptables-save | iptables-graph", file=sys.stderr)
        sys.exit(1)

    # Read and parse input
    input_data = args.input.read()
    all_chains, datas = parse_iptables(input_data)

    # Generate DOT output
    dot_output = generate_dot(all_chains, datas)

    # Output in requested format
    if args.format == "dot":
        if args.output:
            with open(args.output, 'w') as f:
                f.write(dot_output)
        else:
            print(dot_output, end='')

    elif args.format == "svg":
        svg_data = convert_dot(dot_output, "svg")
        if args.output:
            with open(args.output, "wb") as f:
                f.write(svg_data)
        else:
            sys.stdout.buffer.write(svg_data)

    elif args.format == "png":
        png_data = convert_dot(dot_output, "png")
        if args.output:
            with open(args.output, "wb") as f:
                f.write(png_data)
        else:
            sys.stdout.buffer.write(png_data)


if __name__ == "__main__":
    main()
