#!/usr/local/bin/python

import random

# Seed our random number generator so we get a consistant random number based on host number
random.seed(001)
# Print result
print random.randint(1,60)

random.seed(002)
print random.randint(1,60)
random.seed(003)
print random.randint(1,60)
random.seed(004)
print random.randint(1,60)
random.seed(005)
print random.randint(1,60)
