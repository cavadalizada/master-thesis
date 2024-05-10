from pgmpy.models import BayesianNetwork
from pgmpy.factors.discrete import TabularCPD
from pgmpy.inference import VariableElimination
import networkx as nx
import matplotlib.pyplot as plt

# Creating the Bayesian Network Structure
model = BayesianNetwork([
    ('E-store', 'Inventory Processor'),           # E-store leads to Inventory Processor compromise
    ('E-store', 'Web-Server'),                    # E-store leads to Web-Server compromise
    ('Company Website', 'Web-Server'),            # Company Website to Web-Server compromise
    ('Web-Server','Inventory Processor'),         # Web Server leads to Inventory Processor being compromised
    ('Inventory Processor', 'Database'),          # Inventory Processor leads to Database compromise
    ('Inventory Processor', 'Tool Server'),       # Inventory processor leads to Tool Server
    ('Tool Server', 'Database')                   # Tool Server leads directly to Database compromise
])

avg_nb_of_attackers = 42.09721

# Defining Conditional Probability Tables (CPTs)
# Probabilities for E-store being compromised
cpd_e_store = TabularCPD(variable='E-store', variable_card=2, 
                         values=[[0], [1]])  # 0% chance not compromised, 100% chance compromised
print(cpd_e_store)

# Probabilities for Company Website being compromised
cpd_website = TabularCPD(variable='Company Website', variable_card=2, 
                         values=[[0], [1]])  # 0% chance not compromised, 100% chance compromised
print(cpd_website)

# Probabilities for Web-Server being compromised given E-store is compromised
cpd_web_server = TabularCPD(variable='Web-Server', variable_card=2,
                            values=[[1, 1-6.4/100, 1-1.3/100, 1-max(6.4/100,1.3/100)],  # Not compromised if E-store and Company Website is not compromised
                                    [0, 6.4/100, 1.3/100, max(6.4/100,1.3/100)]],  # skill/5000 chance of being compromised if E-store is compromised 1/146 + 1/730 chance if company website is compromised
                            evidence=['E-store','Company Website'], evidence_card=[2, 2])
print(cpd_web_server)

# Probabilities for Inventory Processor being compromised given E-store is compromised
cpd_inventory_processor = TabularCPD(variable='Inventory Processor', variable_card=2,
                                     values=[[1, 1-7.7/100,1-1.3/100,1-max(7.7/100,1.3/100)],  # Not compromised if E-store is not compromised
                                             [0, 7.7/100,1.3/100,max(7.7/100,1.3/100)]],  # 5% chance of being compromised if E-store is compromised
                                     evidence=['E-store','Web-Server'], evidence_card=[2,2])
print(cpd_inventory_processor)

# Probabilities for Tool Server being compromised
cpd_tool_server = TabularCPD(variable='Tool Server', variable_card=2,
                             values=[[1, 1-2.6/100],  # Not compromised if Inventory Processor not compromised
                                      [0, 2.6/100]], # 2% chance of being compromised if Inventory Processor is compromised
                             evidence=['Inventory Processor'], evidence_card=[2])
print(cpd_tool_server)

# Probabilities for Database being compromised
# The CPT for Database reflects the OR relationship with its parent nodes.
cpd_database = TabularCPD(variable='Database', variable_card=2,
                          values=[
                              # The first entry is the probability of Database being not compromised if all parents are not compromised
                              [1, 1-7.7/100, 1-9/100, 1-max(9/100,7.7/100)],  
                              # The second 4entry is the probability of Database being compromised if any parent is compromised
                              [0, 7.7/100, 9/100, max(9/100,7.7/100)]],  
                          evidence=['Tool Server', 'Inventory Processor'],
                          evidence_card=[2, 2])
print(cpd_database)
model.add_cpds(cpd_e_store, cpd_website, cpd_inventory_processor, cpd_web_server, cpd_tool_server, cpd_database)

# Check model correctness
assert model.check_model()

# Performing inference
inference = VariableElimination(model)

# Calculating the probability of Database being compromised
prob_database = inference.query(variables=['Database'])
print(prob_database)

print("Number of events per year : avg_number_of_attackers x success of one attack = ", prob_database.get_value(Database=1) * avg_nb_of_attackers)

# Calculate the probability that at least one attacker succeeds
p_at_least_one_success = 1 - (1 - prob_database.get_value(Database=1)) ** avg_nb_of_attackers

# Print the probability
print(f"The probability that at least one attacker succeeds is : 1 - ( 1 - p) ^ avg_nb_of_attackers {p_at_least_one_success:.4f}")

# Create a NetworkX graph object for visualization
G = nx.DiGraph()
G.add_nodes_from(model.nodes)
G.add_edges_from(model.edges)

# Customize visualization (optional)
node_colors = ['lightblue' if node != 'Database' else 'lightcoral' for node in G.nodes()]
pos = nx.spring_layout(G)  # Or use another layout algorithm

nx.draw(G, pos, with_labels=True, node_color=node_colors)
plt.title("Bayesian Attack Graph with Probabilities")
plt.savefig('bag3.png')
