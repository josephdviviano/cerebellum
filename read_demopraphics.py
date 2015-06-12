import os, sys
import numpy as np

# load in the subject numbers from each file
demo = np.genfromtxt('demographics.csv',
            delimiter=',', dtype=('<i8','|S2','<i8','<i8','<f8','<f8','<f8'),
            deletechars='"', skip_header=1)

subjects = []
gender = []
hand = []
age = []
# height = []
# weight = []
# bmi = []

# get subjects -- removed! 209733, 528446, 
subjlist = [subj for subj in os.listdir(os.getcwd()) 
                 if os.path.isdir(os.path.join(os.getcwd(), subj)) == True]
subjlist.sort()

for vector in demo:
    if str(vector[0]) in subjlist:
        
        print(vector[0])
        if vector[1] == 'M':
            gender.append(0)
        elif vector[1] == 'F':
        	gender.append(1)
        hand.append(vector[2])
        age.append(vector[3])


np.savetxt('demo-gender.csv', gender, fmt='%1i')
np.savetxt('demo-hand.csv', hand, fmt='%3i')
np.savetxt('demo-age.csv', age, fmt='%2i')