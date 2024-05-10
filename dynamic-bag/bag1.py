from pgmpy.models import BayesianNetwork
from pgmpy.factors.discrete import TabularCPD
from pgmpy.inference import VariableElimination
import matplotlib.pyplot as plt
import logging
import numpy as np  # Import numpy for numerical calculations
from datetime import datetime, timedelta

def get_month_from_day(day_number, year=2024):
    # Start from the first day of the year
    start_date = datetime(year, 1, 1)
    # Calculate the date by adding the day number minus one (since day 1 is January 1st)
    target_date = start_date + timedelta(days=day_number - 1)
    # Return the month number
    return target_date.month

def get_day_of_month(day_number, year=2024):
    # Create a date object starting from the first day of the year
    start_date = datetime(year, 1, 1)
    
    # Calculate the actual date by adding the day_number offset
    # Subtracting one because day_number is 1-based and timedelta is 0-based
    actual_date = start_date + timedelta(days=day_number - 1)
    
    # Return the month name and the day of the month
    return actual_date.day


def todays_weekday(day_number, year=2024):
    # Start from the first day of the year
    start_date = datetime(year, 1, 1)
    # Calculate the date by adding the day number minus one
    target_date = start_date + timedelta(days=day_number - 1)
    # Check if the day is a Monday (.weekday() returns 0 for Monday, 1 for Tuesday, ..., 6 for Sunday)
    return target_date.weekday()


# Disable pgmpy warnings about replacing CPDs
logger = logging.getLogger('pgmpy')
logger.setLevel(logging.ERROR)  # Ignore warnings and below, only log errors

# Initialize the Bayesian Network Structure
model = BayesianNetwork([
    ('E-store', 'Inventory Processor'),
    ('E-store', 'Web-Server'),
    ('Company Website', 'Web-Server'),
    ('Web-Server', 'Inventory Processor'),
    ('Inventory Processor', 'Database'),
    ('Inventory Processor', 'Tool Server'),
    ('Tool Server', 'Database')
])


weekdays_normalized_2023 = [0.02, 0.373, 0.711, 0.265, 0.241, 0.072, 0.8]

# Normalized Cybersecurity Incidents for 2023
normalized_2023 = np.array([1.00, 0.65, 0.50, 0.56, 0.69, 0.47, 0.34, 0.44, 0.55, 0.54, 0.66, 0.49])


def rate_of_today(today):
    return (normalized_2023[get_month_from_day(today)-1]+1) * (weekdays_normalized_2023[todays_weekday(today)] + 1)

global newApp

newApp = False

def release_rate_of_today(today):
    return 1
    global newApp
    if newApp:
        return 0.7
    if get_month_from_day(today) == 6:
        if get_day_of_month(today) == 20:
            return 1.05
        if get_day_of_month(today) == 21:
            return 1.1
        if get_day_of_month(today) == 22:
            return 1.1
        if get_day_of_month(today) == 23:
            return 1.15
        if get_day_of_month(today) == 24:
            return 1.3
        if get_day_of_month(today) == 25:
            return 1.4
        if get_day_of_month(today) == 26:
            return 1.5
        if get_day_of_month(today) == 27:
            return 1.5
        if get_day_of_month(today) == 28:
            return 1.4
        if get_day_of_month(today) == 29:
            return 1.4
        if get_day_of_month(today) == 30:
            return 1.3
    if get_month_from_day(today) == 7:
        if get_day_of_month(today) == 1:
            return 1.3
        if get_day_of_month(today) == 2:
            return 1.2
        if get_day_of_month(today) == 3:
            return 1.2
        if get_day_of_month(today) == 4:
            return 1.2
        if get_day_of_month(today) == 5:
            return 1.1
        if get_day_of_month(today) == 6:
            return 1.1
        if get_day_of_month(today) == 7:
            return 1.1
        if get_day_of_month(today) == 8:
            return 1.1
        if get_day_of_month(today) == 9:
            return 1.05
        if get_day_of_month(today) == 10:
            return 1.03
        if get_day_of_month(today) == 11:
            return 1
        if get_day_of_month(today) == 12:
            return 0.98
        if get_day_of_month(today) == 13:
            return 0.95
        if get_day_of_month(today) == 14:
            return 0.9
        if get_day_of_month(today) == 15:
            return 0.85
        if get_day_of_month(today) == 16:
            return 0.8
        if get_day_of_month(today) == 17:
            return 0.75
        if get_day_of_month(today) == 18:
            newApp = True
            return 0.72
    return 1


skill = 70
avg_nb_of_attackers_per_day = 43.80558 / 365

# Define initial CPDs
cpd_e_store = TabularCPD(variable='E-store', variable_card=2, values=[[0], [1]])
cpd_website = TabularCPD(variable='Company Website', variable_card=2, values=[[0], [1]])

# Add initial CPDs to the model
model.add_cpds(cpd_e_store, cpd_website)

# Simulation loop for 365 days
probabilities_over_time = []

for day in range(365):
    rate_today = rate_of_today(day)
    release_rate = release_rate_of_today(day)
    # Web Server CPD
    cpd_web_server = TabularCPD(
        variable='Web-Server', variable_card=2,
        values=[
            [1, 1 - rate_today * ((1 / 146) + (1 / 730)),
                1 - release_rate * skill / 5000,
                1 - max(rate_today * ((1 / 146) + (1 / 730)), release_rate * skill / 5000)],
            [0, rate_today * ((1 / 146) + (1 / 730)),
                release_rate * skill / 5000,
                max(rate_today * ((1 / 146) + (1 / 730)), release_rate * skill / 5000)]
        ],
        evidence=['E-store', 'Company Website'], evidence_card=[2, 2]
    )

    # Inventory Processor CPD
    cpd_inventory_processor = TabularCPD(
        variable='Inventory Processor', variable_card=2,
        values=[
            [1, 1 - rate_today * ((1 / 100) + (1 / 73)),
                1 - release_rate * skill / 4000,
                1 - max(release_rate * skill / 4000, rate_today* ((1 / 100) + (1 / 73)))],
            [0, rate_today * ((1 / 100) + (1 / 73)),
                release_rate * skill / 4000,
                max(release_rate * skill / 4000, rate_today * ((1 / 100) + (1 / 73)))]
        ],
        evidence=['E-store', 'Web-Server'], evidence_card=[2, 2]
    )

    # Tool Server CPD
    cpd_tool_server = TabularCPD(
        variable='Tool Server', variable_card=2,
        values=[
            [1, 1 - skill / 4000],
            [0, skill / 4000]
        ],
        evidence=['Inventory Processor'], evidence_card=[2]
    )

    # Database CPD
    cpd_database = TabularCPD(
        variable='Database', variable_card=2,
        values=[
            [1, 1 - skill / 3000,
                1 - ((1 / 100) + (1 / 73)),
                1 - max(skill / 3000, ((1 / 100) + (1 / 73)))],
            [0, skill / 3000,
                ((1 / 100) + (1 / 73)),
                max(skill / 3000, ((1 / 100) + (1 / 73)))]
        ],
        evidence=['Tool Server', 'Inventory Processor'], evidence_card=[2, 2]
    )

    # Update model with new CPDs
    model.add_cpds(cpd_web_server, cpd_inventory_processor, cpd_tool_server, cpd_database)

    # Perform inference
    inference = VariableElimination(model)
    prob_database = inference.query(variables=['Database'], show_progress=False)
    daily_probability = prob_database.get_value(Database=1)
    probabilities_over_time.append(daily_probability)

    # Print daily probability
    print(f"Day {day + 1}: Probability of Database Compromise = {daily_probability:.50f}")

# Calculate the probability of no event happening any day
# Calculate the probability of no compromise each day and aggregate
prob_no_event_all_days = np.prod([1 - p for p in probabilities_over_time])

# Calculate the yearly probability of at least one compromise
prob_at_least_one_event_yearly = 1 - prob_no_event_all_days

# Incorporate the average number of attackers
prob_at_least_one_event_multiple_attackers = 1 - (1 - prob_at_least_one_event_yearly) ** avg_nb_of_attackers_per_day

# Split the array into quarters
q1 = probabilities_over_time[:90]
q2 = probabilities_over_time[90:181]
q3 = probabilities_over_time[181:273]
q4 = probabilities_over_time[273:365]

def calculate_at_least_one_event(probabilities):
    prob_no_event_all_days = np.prod([1 - p for p in probabilities])
    return 1 - (1 - (1 - prob_no_event_all_days)) ** avg_nb_of_attackers_per_day

# Calculate the probability for each quarter
prob_at_least_one_event_q1 = calculate_at_least_one_event(q1)
prob_at_least_one_event_q2 = calculate_at_least_one_event(q2)
prob_at_least_one_event_q3 = calculate_at_least_one_event(q3)
prob_at_least_one_event_q4 = calculate_at_least_one_event(q4)

# Print results
print(f"Probability of event occuring in Q1: {prob_at_least_one_event_q1:.4f}")
print(f"Probability of event occuring in Q2: {prob_at_least_one_event_q2:.4f}")
print(f"Probability of event occuring in Q3: {prob_at_least_one_event_q3:.4f}")
print(f"Probability of event occuring in Q4: {prob_at_least_one_event_q4:.4f}")

# Debugging output of the final probability
print(f"At least one : {prob_at_least_one_event_multiple_attackers:.50f}")

# Plotting the daily probabilities
plt.figure(figsize=(20, 10))
plt.plot(probabilities_over_time, label='Daily Probability of Database Compromise')
plt.xlabel('Day')
plt.ylabel('Probability')
plt.title('Daily Probability of Database Compromise Over 365 Days')
plt.ylim(0, 0.001)  # Adjusted for better visualization of small probability changes

# Draw horizontal line for the yearly probability
plt.axhline(y=prob_at_least_one_event_multiple_attackers, color='r', linestyle='--', label='Yearly Probability of at Least One Compromise')

# Adding vertical lines for each quarter
plt.axvline(x=90, color='g', linestyle='--', label='End of Q1')
plt.axvline(x=180, color='b', linestyle='--', label='End of Q2')
plt.axvline(x=270, color='pink', linestyle='--', label='End of Q3')
plt.axvline(x=365, color='purple', linestyle='--', label='End of Q4')


plt.legend()
plt.grid(True)

# Save the plot to a file
plt.savefig('Yearly_Database_Compromise_Probability.png', format='png', dpi=300)  # Adjust dpi for higher resolution