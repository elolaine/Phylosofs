# Copyright (c) 2014-2018: Diego Javier Zea.
# This code is part of the phylosofs package and governed by its license.
# Please see the LICENSE.txt file included as part of this package.

import networkx as nx
from distutils.version import LooseVersion

# successors, predecessors and edges returns a generator/iterator after v2.0 :
if LooseVersion(nx.__version__) < LooseVersion('2.0'):
    def successors(nx_graph, node):
        return nx_graph.successors(node)

    def predecessors(nx_graph, node):
        return nx_graph.predecessors(node)

    def get_edge_list(nx_graph):
        return nx_graph.edges()
else:
    def successors(nx_graph, node):
        # Use list to get a list from the generator
        return list(nx_graph.successors(node))

    def predecessors(nx_graph, node):
        return list(nx_graph.predecessors(node))

    def get_edge_list(nx_graph):
        return [e for e in nx_graph.edges()]

# NetworkX 2.0: The degree of an individual node can be calculated by
# G.degree[node]
if LooseVersion(nx.__version__) < LooseVersion('2.0'):
    def get_out_degree(nx_graph, node):
        return nx_graph.out_degree(node)
else:
    def get_out_degree(nx_graph, node):
        return nx_graph.out_degree[node]

# NetworkX 2.0: *_iter methods are deprecated
if LooseVersion(nx.__version__) < LooseVersion('2.0'):
    def get_in_degree_of_nodes(nx_graph):
        return nx_graph.in_degree_iter(nx_graph.nodes_iter())
else:
    def get_in_degree_of_nodes(nx_graph):
        return nx_graph.in_degree(nx_graph.nodes())

# NetworkX deprecates max_flow in favor of maximum_flow_value in version 1.9 :
if LooseVersion(nx.__version__) < LooseVersion('1.9'):
    def maximum_flow_value(g, x, y):
        return nx.max_flow(g, x, y)
else:
    def maximum_flow_value(g, x, y):
        return nx.maximum_flow_value(g, x, y)

# NetworkX 2.0 changed the nodes method to the nodes attribute
if LooseVersion(nx.__version__) < LooseVersion('2.0'):
    def str_nodes(nx_graph):
        return str(nx_graph.nodes(1))
else:
    def str_nodes(nx_graph):
        return str([(i, nx_graph.nodes[i]) for i in nx_graph.nodes])
