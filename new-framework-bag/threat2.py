from pgmpy.models import BayesianNetwork
from pgmpy.factors.discrete import TabularCPD
from pgmpy.inference import VariableElimination
import networkx as nx
import matplotlib.pyplot as plt

# Creating the Bayesian Network Structure
model = BayesianNetwork([
    ('Inventory App', 'Workstation'),           # E-store leads to Inventory Processor compromise
    ('Workstation', 'Inventory Processor'),                    # E-store leads to Web-Server compromise
    ('Inventory App', 'Inventory Processor'),                # 
    ('Inventory Processor', 'Tool Server'),            # Company Website to Web-Server compromise
    ('Inventory Processor', 'Database'),          # Inventory Processor leads to Database compromise
    ('Tool Server', 'Database')                   # Tool Server leads directly to Database compromise
])
skill = 25
avg_nb_of_attackers = 8.65017
# Defining Conditional Probability Tables (CPTs)
# Probabilities for E-store being compromised
cpd_inv_app = TabularCPD(variable='Inventory App', variable_card=2, 
                         values=[[0], [1]])  # 99% chance not compromised, 1% chance compromised
print(cpd_inv_app)
# Probabilities for Inventory App being compromised given Inventory App is compromised
cpd_workstation = TabularCPD(variable='Workstation', variable_card=2,
                                     values=[[1, 1 - skill/60],  # Not compromised if E-store is not compromised
                                             [0, skill/60 ]],  # 5% chance of being compromised if E-store is compromised
                                     evidence=['Inventory App'], evidence_card=[2])
print(cpd_workstation)
# Probabilities for Web-Server being compromised given E-store is compromised
cpd_inventory_processor = TabularCPD(variable='Inventory Processor', variable_card=2,
                            values=[[1, 1 - (1/120 + 1/61), 1 - (skill/200), 1- max(1/120 + 1/61,skill/200)],  # Not compromised if E-store and Company Website is not compromised
                                    [0, 1/120 + 1/61 , skill/200, max(1/120 + 1/61,skill/200)]],  # 100/5000 chance of being compromised if E-store is compromised 1/146 + 1/730 chance if company website is compromised
                            evidence=['Inventory App','Workstation'], evidence_card=[2, 2])
print(cpd_inventory_processor)
#Inventory App  Workstation	P(Inv Processor=False)	   P(Inv Processor=True)
#     0                  0	               1	                0
#     0	                 1	               1-~	                skill/80
#     1                  0	               1-~	                1/120 + 1/61
#     1	                 1	               1-~	                max(1/120 + 1/61,skill/80)
# Probabilities for Tool Server being compromised
# Probabilities for Tool Server being compromised
cpd_tool_server = TabularCPD(variable='Tool Server', variable_card=2,
                             values=[[1, 1-skill/4000],  # Not compromised if Inventory Processor not compromised
                                      [0, skill/4000]], # 2% chance of being compromised if Inventory Processor is compromised
                             evidence=['Inventory Processor'], evidence_card=[2])

print(cpd_tool_server)
# Probabilities for Database being compromised
# The CPT for Database reflects the OR relationship with its parent nodes.
cpd_database = TabularCPD(variable='Database', variable_card=2,
                          values=[
                              # The first entry is the probability of Database being not compromised if all parents are not compromised
                              [1, 1-skill/3000, 1-(1/200+1/73), 1-max(skill/3000,1/100+1/73)],  
                              # The second entry is the probability of Database being compromised if any parent is compromised
                              [0, skill/3000, (1/100+1/73), max(skill/3000,1/100+1/73)]],  
                          evidence=['Tool Server', 'Inventory Processor'],
                          evidence_card=[2, 2])
print(cpd_database)
# USE THE TABLE BELOW TO MAKE SENSE OF DATABASE CPD
#Tool Server  Inventory Processo	P(Database=False)	P(Database=True)
#     0              0	               1	                0
#     0	             1	               1-~	                skill/3000
#     1              0	               1-~	                1/100 + 1/73
#     1	             1	               1-~	                max(1/100 + 1/73,skill/3000)
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
print(f"The probability that at least one attacker succeeds is approximately {p_at_least_one_success*100:.4f}%")


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