from pgmpy.models import BayesianNetwork
from pgmpy.factors.discrete import TabularCPD
from pgmpy.inference import VariableElimination
import networkx as nx
import matplotlib.pyplot as plt

# Creating the Bayesian Network Structure
model = BayesianNetwork([
    ('Inventory App', 'Workstation'),           # E-store leads to Inventory Processor compromise
    ('Workstation', 'Inventory Processor'),                    # E-store leads to Web-Server compromise
    ('Inventory App', 'Inventory Processor'),                # Invwntory App leads to Inventory Processor compromise
    ('Inventory Processor', 'Tool Server'),            # Company Website to Web-Server compromise
    ('Inventory Processor', 'Database'),          # Inventory Processor leads to Database compromise
    ('Tool Server', 'Database')                   # Tool Server leads directly to Database compromise
])
avg_nb_of_attackers = 8.65017
# Defining Conditional Probability Tables (CPTs)
# Probabilities for E-store being compromised
cpd_inv_app = TabularCPD(variable='Inventory App', variable_card=2, 
                         values=[[0], [1]])  # 0% chance not compromised, 100% chance compromised
print(cpd_inv_app)
# Probabilities for Inventory App being compromised given Inventory App is compromised
cpd_workstation = TabularCPD(variable='Workstation', variable_card=2,
                                     values=[[1, 1 - 10/100],  # Not compromised if E-store is not compromised
                                             [0, 10/100 ]],  # 5% chance of being compromised if E-store is compromised
                                     evidence=['Inventory App'], evidence_card=[2])
print(cpd_workstation)
# Probabilities for Web-Server being compromised given E-store is compromised
cpd_inventory_processor = TabularCPD(variable='Inventory Processor', variable_card=2,
                            values=[[1, 1 - 8/100, 1 - 5/100, 1- max(5/100,8/100)],  # Not compromised if E-store and Company Website is not compromised
                                    [0, 8/100 , 5/100, max(5/100,8/100)]],  # 100/5000 chance of being compromised if E-store is compromised 1/146 + 1/730 chance if company website is compromised
                            evidence=['Inventory App','Workstation'], evidence_card=[2, 2])
print(cpd_inventory_processor)
#Inventory App  Workstation	P(Inv Processor=False)	   P(Inv Processor=True)
#     0                  0	               1	                0
#     0	                 1	               1-~	                skill/80
#     1                  0	               1-~	                1/120 + 1/61
#     1	                 1	               1-~	                max(1/120 + 1/61,skill/80)
# Probabilities for Tool Server being compromised
cpd_tool_server = TabularCPD(variable='Tool Server', variable_card=2,
                             values=[[1, 1-0.8/100],  # Not compromised if Inventory Processor not compromised
                                      [0, 0.8/100]], # 2% chance of being compromised if Inventory Processor is compromised
                             evidence=['Inventory Processor'], evidence_card=[2])
print(cpd_tool_server)
# Probabilities for Database being compromised
# The CPT for Database reflects the OR relationship with its parent nodes.
cpd_database = TabularCPD(variable='Database', variable_card=2,
                          values=[
                              # The first entry is the probability of Database being not compromised if all parents are not compromised
                              [1, 1-2.5/100, 1-3/100, 1-max(3/100,2.5/100)],  
                              # The second 4entry is the probability of Database being compromised if any parent is compromised
                              [0, 2.5/100, 3/100, max(3/100,2.5/100)]],  
                          evidence=['Tool Server', 'Inventory Processor'],
                          evidence_card=[2, 2])
print(cpd_database) 
# Adding CPTs to the model
model.add_cpds(cpd_inv_app, cpd_workstation, cpd_inventory_processor, cpd_tool_server, cpd_database)

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
plt.savefig('bag2.png')
